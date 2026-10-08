import Foundation

/// Credentials model for standard username/password authentication.
public struct UserCredentials: Sendable {
    public let username: String
    public let secret: String

    public init(username: String, secret: String) {
        self.username = username
        self.secret = secret
    }
}

/// Request model for one-time passcode verification.
public struct OTPVerification: Sendable {
    public let identifier: String
    public let code: String

    public init(identifier: String, code: String) {
        self.identifier = identifier
        self.code = code
    }
}

/// High-level authentication protocol.
public protocol AuthenticationManaging: Sendable {
    func login(credentials: UserCredentials) async throws -> AuthToken
    func verifyOTP(_ verification: OTPVerification) async throws -> AuthToken
    func logout() async throws
}
