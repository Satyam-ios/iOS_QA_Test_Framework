import Foundation
import CompanyiOSKit

/// Deterministic test fixtures for repeatable testing.
public struct TestUser: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let email: String
    public let role: String

    public init(id: String = "user_123", name: String = "Test User", email: String = "test.user@company.com", role: String = "QA_ENGINEER") {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }
}

/// Factory generating deterministic models and payloads for unit tests.
public enum TestDataFactory {
    public static func makeUser(
        id: String = "usr_\(UUID().uuidString.prefix(6))",
        name: String = "Standard Tester",
        email: String = "tester@company.com",
        role: String = "tester"
    ) -> TestUser {
        return TestUser(id: id, name: name, email: email, role: role)
    }

    public static func makeAuthToken(
        accessToken: String = "valid_access_token_\(UUID().uuidString)",
        refreshToken: String = "valid_refresh_token_\(UUID().uuidString)",
        expiresIn: TimeInterval = 3600
    ) -> AuthToken {
        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expirationDate: Date().addingTimeInterval(expiresIn)
        )
    }

    public static func makeExpiredAuthToken(
        accessToken: String = "expired_access_token",
        refreshToken: String = "expired_refresh_token"
    ) -> AuthToken {
        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expirationDate: Date().addingTimeInterval(-3600)
        )
    }

    public static func makeUserCredentials(
        username: String = "valid.user@company.com",
        secret: String = "SecureP@ssw0rd123!"
    ) -> UserCredentials {
        return UserCredentials(username: username, secret: secret)
    }
}
