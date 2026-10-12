import Foundation
import CompanyiOSKit

/// Real in-memory and persistent store of executed automated test results.
public final class TestExecutionStore: @unchecked Sendable {
    public static let shared = TestExecutionStore()

    private let lock = NSLock()
    private var executedResults: [TestCaseResult] = []
    private var lastRunTimestamp: Date?

    private init() {}

    /// Records an actually executed test outcome.
    public func recordResult(_ result: TestCaseResult) {
        lock.lock()
        defer { lock.unlock() }

        // Replace previous outcome for same test name/suite if re-run
        if let idx = executedResults.firstIndex(where: { $0.suite == result.suite && $0.name == result.name }) {
            executedResults[idx] = result
        } else {
            executedResults.append(result)
        }
        lastRunTimestamp = Date()
    }

    /// Bulk records executed test results.
    public func recordResults(_ results: [TestCaseResult]) {
        for res in results {
            recordResult(res)
        }
    }

    /// All genuinely executed test results.
    public var allResults: [TestCaseResult] {
        lock.lock()
        defer { lock.unlock() }
        return executedResults
    }

    /// Indicates whether any tests have actually been executed.
    public var hasExecutedTests: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !executedResults.isEmpty
    }

    public var timestampOfLastRun: Date? {
        lock.lock()
        defer { lock.unlock() }
        return lastRunTimestamp
    }

    /// Clears test execution outcomes.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        executedResults.removeAll()
        lastRunTimestamp = nil
    }
}
