import Foundation
import CompanyiOSKit

/// Unified status classification for audit findings and test items.
public enum FindingStatus: String, Codable, Sendable {
    case confirmed = "CONFIRMED"
    case potential = "POTENTIAL"
    case generated = "GENERATED"
    case passed = "PASSED"
    case failed = "FAILED"
    case blocked = "BLOCKED"
    case notExecuted = "NOT EXECUTED"
    case notApplicable = "NOT APPLICABLE"
}

/// Category classification for observable runtime events.
public enum RuntimeEventCategory: String, Codable, Sendable, CaseIterable {
    case crash = "CRASH"
    case unhandledError = "UNHANDLED_ERROR"
    case networkFailure = "NETWORK_FAILURE"
    case contractViolation = "CONTRACT_VIOLATION"
    case memoryWarning = "MEMORY_WARNING"
    case memoryGrowth = "MEMORY_GROWTH"
    case mainThreadHang = "MAIN_THREAD_HANG"
    case navigationFailure = "NAVIGATION_FAILURE"
    case accessibilityViolation = "ACCESSIBILITY_VIOLATION"
    case authSessionFailure = "AUTH_SESSION_FAILURE"
    case permissionFailure = "PERMISSION_FAILURE"
    case lifecycleTransition = "LIFECYCLE_TRANSITION"
    case repeatedFailurePattern = "REPEATED_FAILURE_PATTERN"
    case ui = "UI"
}

/// Structured record of an observable runtime occurrence.
public struct RuntimeEvent: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let timestamp: Date
    public let category: RuntimeEventCategory
    public let severity: DefectSeverity
    public let title: String
    public let details: String
    public let sourceLocation: String?
    public let stackTrace: [String]?
    public let contextMetadata: [String: String]
    public let status: FindingStatus

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        category: RuntimeEventCategory,
        severity: DefectSeverity,
        title: String,
        details: String,
        sourceLocation: String? = nil,
        stackTrace: [String]? = nil,
        contextMetadata: [String: String] = [:],
        status: FindingStatus = .confirmed
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.severity = severity
        self.title = title
        self.details = details
        self.sourceLocation = sourceLocation
        self.stackTrace = stackTrace
        self.contextMetadata = contextMetadata
        self.status = status
    }
}

/// Thread-safe in-memory ring buffer capturing runtime events with automatic capacity bounds.
public final class RuntimeTelemetryStore: @unchecked Sendable {
    public static let shared = RuntimeTelemetryStore()

    private let lock = NSLock()
    private var events: [RuntimeEvent] = []
    private let maxCapacity: Int

    public init(maxCapacity: Int = 1000) {
        self.maxCapacity = maxCapacity
    }

    /// Records a new runtime event into the telemetry store.
    public func record(_ event: RuntimeEvent) {
        lock.lock()
        defer { lock.unlock() }

        events.append(event)
        if events.count > maxCapacity {
            events.removeFirst(events.count - maxCapacity)
        }
    }

    /// Convenience record method.
    public func record(
        category: RuntimeEventCategory,
        severity: DefectSeverity,
        title: String,
        details: String,
        sourceLocation: String? = nil,
        stackTrace: [String]? = nil,
        contextMetadata: [String: String] = [:],
        status: FindingStatus = .confirmed
    ) {
        let event = RuntimeEvent(
            category: category,
            severity: severity,
            title: title,
            details: details,
            sourceLocation: sourceLocation,
            stackTrace: stackTrace,
            contextMetadata: contextMetadata,
            status: status
        )
        record(event)
    }

    /// Returns all captured runtime events in reverse chronological order.
    public var allEvents: [RuntimeEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events.reversed()
    }

    /// Returns events filtered by category.
    public func events(matching category: RuntimeEventCategory) -> [RuntimeEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events.filter { $0.category == category }.reversed()
    }

    /// Returns events filtered by minimum severity.
    public func events(atLeast severity: DefectSeverity) -> [RuntimeEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events.filter { $0.severity >= severity }.reversed()
    }

    /// Returns the total event count.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return events.count
    }

    /// Clears all recorded runtime telemetry.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        events.removeAll()
    }
}
