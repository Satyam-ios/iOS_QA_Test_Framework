import Foundation
import CompanyiOSKit

/// In-memory implementation of TokenManaging for unit and integration testing.
public actor MockTokenManager: TokenManaging {
    private var token: AuthToken?

    public init(initialToken: AuthToken? = nil) {
        self.token = initialToken
    }

    public func getAccessToken() -> String? {
        return token?.accessToken
    }

    public func getRefreshToken() -> String? {
        return token?.refreshToken
    }

    public func saveTokens(_ token: AuthToken) {
        self.token = token
    }

    public func clearTokens() {
        self.token = nil
    }

    public func isAccessTokenValid() -> Bool {
        guard let token = token else { return false }
        return !token.isExpired
    }
}

/// In-memory implementation of KeychainManaging preventing host Keychain pollution.
public final class MockKeychainManager: KeychainManaging, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public func save(key: String, data: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = data
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
        return storage[key]
    }

    public func readString(key: String) throws -> String? {
        guard let data = try readData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    public func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
