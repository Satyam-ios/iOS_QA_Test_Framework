import Foundation
import CompanyiOSKit

/// Captures logs in memory during test runs for inspection.
public final class TestLogCollector: LoggerProtocol, @unchecked Sendable {
    public struct Record: Sendable, Equatable {
        public let message: String
        public let level: LogLevel
        public let category: String
        public let line: Int
    }

    private let lock = NSLock()
    private var records: [Record] = []
    public var minimumLogLevel: LogLevel

    public init(minimumLogLevel: LogLevel = .verbose) {
        self.minimumLogLevel = minimumLogLevel
    }

    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLogLevel else { return }
        lock.lock()
        defer { lock.unlock() }
        records.append(Record(message: message(), level: level, category: category, line: line))
    }

    public var capturedRecords: [Record] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }

    public func containsMessage(matching substring: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return records.contains { $0.message.contains(substring) }
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        records.removeAll()
    }
}
