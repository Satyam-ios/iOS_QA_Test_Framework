import Foundation

/// High-level typed secure storage facade.
public struct SecureStorage: Sendable {
    private let keychain: any KeychainManaging

    public init(keychain: any KeychainManaging = KeychainManager.shared) {
        self.keychain = keychain
    }

    public func set<T: Encodable & Sendable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try keychain.save(key: key, data: data)
    }

    public func get<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try keychain.readData(key: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func remove(forKey key: String) throws {
        try keychain.delete(key: key)
    }

    public func removeAll() throws {
        try keychain.deleteAll()
    }
}
