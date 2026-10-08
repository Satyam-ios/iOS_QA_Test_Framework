import Foundation

/// Utility responsible for scanning text and masking credentials, tokens, and PII.
public struct SensitiveDataRedactor: Sendable {
    public static let shared = SensitiveDataRedactor()

    public init() {}

    /// Redacts known sensitive patterns from the provided string.
    public func redact(_ input: String) -> String {
        guard !input.isEmpty else { return input }

        var sanitized = input

        // 1. Bearer tokens: Bearer <token>
        let bearerPattern = #"(?i)bearer\s+([A-Za-z0-9_\-\.]{8,})"#
        sanitized = sanitized.replacingOccurrences(
            of: bearerPattern,
            with: "Bearer [REDACTED_TOKEN]",
            options: .regularExpression
        )

        // 2. Authorization / API Key JSON or query patterns: ("apiKey"|"token"|"password"|"secret")\s*[:=]\s*["']?([^"',\s]+)
        let keyPattern = #"(?i)("(?:apiKey|token|password|secret|access_token|refreshToken)"\s*:\s*")[^"]+(")"#
        sanitized = sanitized.replacingOccurrences(
            of: keyPattern,
            with: "$1[REDACTED]$2",
            options: .regularExpression
        )

        // 3. Key-value assignment: (apiKey|password|token)=([^&\s]+)
        let kvPattern = #"(?i)(apiKey|password|token|secret)=([^&\s]+)"#
        sanitized = sanitized.replacingOccurrences(
            of: kvPattern,
            with: "$1=[REDACTED]",
            options: .regularExpression
        )

        return sanitized
    }
}
