import Foundation
import Security

/// Specific errors thrown by Keychain operations.
public enum KeychainError: LocalizedError, Sendable, Equatable {
    case duplicateItem
    case itemNotFound
    case unhandledError(status: OSStatus)
    case dataConversionFailed

    public var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Item already exists in Keychain."
        case .itemNotFound:
            return "Item not found in Keychain."
        case .unhandledError(let status):
            return "Keychain operation failed with OSStatus \(status)."
        case .dataConversionFailed:
            return "Failed to encode or decode Keychain data."
        }
    }
}

/// Interface for storing and retrieving secrets securely.
public protocol KeychainManaging: Sendable {
    func save(key: String, data: Data) throws
    func save(key: String, string: String) throws
    func readData(key: String) throws -> Data?
    func readString(key: String) throws -> String?
    func delete(key: String) throws
    func deleteAll() throws
}

/// Standard production implementation of KeychainManaging utilizing Apple's Security framework.
public final class KeychainManager: KeychainManaging, @unchecked Sendable {
    public static let shared = KeychainManager()

    private let service: String
    private let accessGroup: String?
    private let lock = NSLock()

    public init(service: String = "com.company.ioskit.keychain", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func save(key: String, data: Data) throws {
        lock.lock()
        defer { lock.unlock() }

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data

        // Check if item exists first
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery = baseQuery(for: key)
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func save(key: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        try save(key: key, data: data)
    }

    public func readData(key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        var query = baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        return dataTypeRef as? Data
    }

    public func readString(key: String) throws -> String? {
        guard let data = try readData(key: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        return string
    }

    public func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
