import Foundation

/// Model representing authentication tokens.
public struct AuthToken: Codable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let expirationDate: Date?

    public init(accessToken: String, refreshToken: String? = nil, expirationDate: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }

    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate <= Date()
    }
}

/// Interface for storing, retrieving, and refreshing auth tokens.
public protocol TokenManaging: Sendable {
    func getAccessToken() async throws -> String?
    func getRefreshToken() async throws -> String?
    func saveTokens(_ token: AuthToken) async throws
    func clearTokens() async throws
    func isAccessTokenValid() async -> Bool
}

/// Keychain-backed implementation of TokenManaging.
public actor TokenManager: TokenManaging {
    private let secureStorage: SecureStorage
    private let tokenKey = "auth_session_token"

    public init(secureStorage: SecureStorage = SecureStorage()) {
        self.secureStorage = secureStorage
    }

    public func getAccessToken() throws -> String? {
        let token = try secureStorage.get(AuthToken.self, forKey: tokenKey)
        return token?.accessToken
    }

    public func getRefreshToken() throws -> String? {
        let token = try secureStorage.get(AuthToken.self, forKey: tokenKey)
        return token?.refreshToken
    }

    public func saveTokens(_ token: AuthToken) throws {
        try secureStorage.set(token, forKey: tokenKey)
    }

    public func clearTokens() throws {
        try secureStorage.remove(forKey: tokenKey)
    }

    public func isAccessTokenValid() -> Bool {
        do {
            guard let token = try secureStorage.get(AuthToken.self, forKey: tokenKey) else {
                return false
            }
            return !token.isExpired
        } catch {
            return false
        }
    }
}
