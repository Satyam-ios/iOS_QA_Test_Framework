import Foundation

/// Standard date formatting utilities across the ecosystem.
public struct DateUtilities: Sendable {
    public static let shared = DateUtilities()

    public init() {}

    public func toISO8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    public func fromISO8601String(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: string) {
            return parsed
        }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: string)
    }

    public func formatRelativeTime(from date: Date, relativeTo now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

/// String extension utilities for sanitization and formatting.
public extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func masked(visiblePrefixCount: Int = 0, visibleSuffixCount: Int = 4, maskCharacter: Character = "*") -> String {
        guard count > (visiblePrefixCount + visibleSuffixCount) else {
            return String(repeating: maskCharacter, count: count)
        }
        let prefix = prefix(visiblePrefixCount)
        let suffix = suffix(visibleSuffixCount)
        let maskLength = count - visiblePrefixCount - visibleSuffixCount
        let mask = String(repeating: maskCharacter, count: maskLength)
        return "\(prefix)\(mask)\(suffix)"
    }
}
