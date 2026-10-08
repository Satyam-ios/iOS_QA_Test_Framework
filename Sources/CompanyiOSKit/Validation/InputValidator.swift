import Foundation

/// Result of an input validation check.
public enum ValidationResult: Sendable, Equatable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    public var failureReason: String? {
        if case .invalid(let reason) = self { return reason }
        return nil
    }
}

/// Generic protocol for all field and data validators.
public protocol ValidatorProtocol: Sendable {
    associatedtype Input
    func validate(_ input: Input) -> ValidationResult
}

/// Validates email address format adhering to standard conventions.
public struct EmailValidator: ValidatorProtocol, Sendable {
    public static let shared = EmailValidator()

    private let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

    public init() {}

    public func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid(reason: "Email address cannot be empty.")
        }
        guard trimmed.count <= 254 else {
            return .invalid(reason: "Email address exceeds maximum length.")
        }
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return .invalid(reason: "Please enter a valid email address.")
        }
        return .valid
    }
}

/// Validates phone numbers (E.164 and standard international formats).
public struct PhoneValidator: ValidatorProtocol, Sendable {
    public static let shared = PhoneValidator()

    public init() {}

    public func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid(reason: "Phone number cannot be empty.")
        }

        // Strip allowed formatting characters: +, spaces, dashes, parentheses
        let digitsOnly = trimmed.filter { $0.isNumber }
        guard digitsOnly.count >= 7 else {
            return .invalid(reason: "Phone number is too short (minimum 7 digits).")
        }
        guard digitsOnly.count <= 15 else {
            return .invalid(reason: "Phone number exceeds maximum allowable length.")
        }

        return .valid
    }
}

/// Configurable password policy validator.
public struct PasswordValidator: ValidatorProtocol, Sendable {
    public let minLength: Int
    public let requireUppercase: Bool
    public let requireLowercase: Bool
    public let requireDigit: Bool
    public let requireSpecialCharacter: Bool

    public init(
        minLength: Int = 8,
        requireUppercase: Bool = true,
        requireLowercase: Bool = true,
        requireDigit: Bool = true,
        requireSpecialCharacter: Bool = true
    ) {
        self.minLength = minLength
        self.requireUppercase = requireUppercase
        self.requireLowercase = requireLowercase
        self.requireDigit = requireDigit
        self.requireSpecialCharacter = requireSpecialCharacter
    }

    public static let standard = PasswordValidator()

    public func validate(_ input: String) -> ValidationResult {
        guard input.count >= minLength else {
            return .invalid(reason: "Password must be at least \(minLength) characters long.")
        }
        if requireUppercase && !input.contains(where: { $0.isUppercase }) {
            return .invalid(reason: "Password must contain at least one uppercase letter.")
        }
        if requireLowercase && !input.contains(where: { $0.isLowercase }) {
            return .invalid(reason: "Password must contain at least one lowercase letter.")
        }
        if requireDigit && !input.contains(where: { $0.isNumber }) {
            return .invalid(reason: "Password must contain at least one digit.")
        }
        if requireSpecialCharacter {
            let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?`~")
            if input.rangeOfCharacter(from: specialCharacters) == nil {
                return .invalid(reason: "Password must contain at least one special character.")
            }
        }
        return .valid
    }
}
