import Foundation
import CompanyiOSKit

/// Tracks runtime application errors and detects suspicious patterns like recursive retry loops and cascading failures.
public final class RuntimeErrorTracker: @unchecked Sendable {
    public static let shared = RuntimeErrorTracker()

    private let lock = NSLock()
    private var errorCounts: [String: (count: Int, firstSeen: Date, lastSeen: Date)] = [:]
    private let loopThresholdCount: Int
    private let loopThresholdWindow: TimeInterval

    public init(loopThresholdCount: Int = 3, loopThresholdWindow: TimeInterval = 10.0) {
        self.loopThresholdCount = loopThresholdCount
        self.loopThresholdWindow = loopThresholdWindow
    }

    /// Records an application error with source attribution.
    public func record(
        error: Error,
        source: String = #file,
        function: String = #function,
        line: Int = #line,
        severity: DefectSeverity = .high,
        context: [String: String] = [:]
    ) {
        lock.lock()
        defer { lock.unlock() }

        let errorKey = "\(type(of: error)):\(error.localizedDescription)"
        let now = Date()

        // 1. Update frequency statistics
        if let existing = errorCounts[errorKey] {
            let newCount = existing.count + 1
            errorCounts[errorKey] = (count: newCount, firstSeen: existing.firstSeen, lastSeen: now)

            // 2. Pattern Detection: Check for retry loop / cascade
            if newCount >= loopThresholdCount && (now.timeIntervalSince(existing.firstSeen) <= loopThresholdWindow) {
                RuntimeTelemetryStore.shared.record(
                    category: .repeatedFailurePattern,
                    severity: .critical,
                    title: "Suspicious Failure Loop Detected: '\(errorKey)'",
                    details: "Error occurred \(newCount) times within \(String(format: "%.1f", now.timeIntervalSince(existing.firstSeen))) seconds. Potential infinite retry loop.",
                    sourceLocation: "\(source):\(line)",
                    contextMetadata: context.merging(["occurrenceCount": "\(newCount)"]) { _, new in new }
                )
            }
        } else {
            errorCounts[errorKey] = (count: 1, firstSeen: now, lastSeen: now)
        }

        // 3. Record raw unhandled error
        let fileName = (source as NSString).lastPathComponent
        RuntimeTelemetryStore.shared.record(
            category: .unhandledError,
            severity: severity,
            title: "Unhandled Error: \(type(of: error))",
            details: error.localizedDescription,
            sourceLocation: "\(fileName):\(line) (\(function))",
            stackTrace: Thread.callStackSymbols,
            contextMetadata: context
        )
    }

    /// Resets error statistics.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        errorCounts.removeAll()
    }
}
