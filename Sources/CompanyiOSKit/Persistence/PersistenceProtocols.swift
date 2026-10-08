import Foundation

/// Primary protocol defining key-value persistence.
public protocol StorageProtocol: Sendable {
    func save<T: Encodable & Sendable>(_ value: T, forKey key: String) async throws
    func read<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T?
    func remove(forKey key: String) async throws
    func removeAll() async throws
}

/// Actor-backed thread-safe memory cache supporting time-to-live expiration.
public actor MemoryCache: StorageProtocol {
    private struct CacheEntry {
        let data: Data
        let expirationDate: Date?
    }

    private var storage: [String: CacheEntry] = [:]
    private let defaultTTL: TimeInterval?

    public init(defaultTTL: TimeInterval? = nil) {
        self.defaultTTL = defaultTTL
    }

    public func save<T: Encodable & Sendable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        let expiration = defaultTTL.map { Date().addingTimeInterval($0) }
        storage[key] = CacheEntry(data: data, expirationDate: expiration)
    }

    public func read<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let entry = storage[key] else { return nil }
        if let expiration = entry.expirationDate, expiration <= Date() {
            storage.removeValue(forKey: key)
            return nil
        }
        return try JSONDecoder().decode(T.self, from: entry.data)
    }

    public func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }
}

/// Disk-backed storage adhering to StorageProtocol.
public actor DiskCache: StorageProtocol {
    private let fileManager: FileManager
    private let directoryURL: URL

    public init(folderName: String = "CompanyiOSKitCache", fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let baseURL = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.directoryURL = baseURL.appendingPathComponent(folderName)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    public func save<T: Encodable & Sendable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        let fileURL = directoryURL.appendingPathComponent(sanitizedKey(key))
        try data.write(to: fileURL, options: .atomic)
    }

    public func read<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        let fileURL = directoryURL.appendingPathComponent(sanitizedKey(key))
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func remove(forKey key: String) throws {
        let fileURL = directoryURL.appendingPathComponent(sanitizedKey(key))
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    public func removeAll() throws {
        if fileManager.fileExists(atPath: directoryURL.path) {
            let files = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        }
    }

    private func sanitizedKey(_ key: String) -> String {
        return key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
    }
}
