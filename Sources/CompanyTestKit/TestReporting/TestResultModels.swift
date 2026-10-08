import Foundation

/// Status of an executed test.
public enum TestStatus: String, Codable, Sendable {
    case passed = "PASSED"
    case failed = "FAILED"
    case skipped = "SKIPPED"
    case blocked = "BLOCKED"
    case flaky = "FLAKY"
}

/// Architectural taxonomy for classifying failures.
public enum FailureClassification: String, Codable, Sendable {
    case bug = "BUG"
    case testIssue = "TEST_ISSUE"
    case environmentIssue = "ENVIRONMENT_ISSUE"
    case dataIssue = "DATA_ISSUE"
    case networkIssue = "NETWORK_ISSUE"
    case flakyTest = "FLAKY_TEST"
    case unsupportedAutomation = "UNSUPPORTED_AUTOMATION"
    case unknown = "UNKNOWN_REQUIRES_INVESTIGATION"
}

/// Kind of test executed.
public enum TestCategory: String, Codable, Sendable {
    case unit = "Unit"
    case api = "API"
    case integration = "Integration"
    case ui = "UI"
    case e2e = "E2E"
    case regression = "Regression"
    case performance = "Performance"
}

/// Result of an individual test case execution.
public struct TestCaseResult: Codable, Sendable {
    public let id: String
    public let name: String
    public let suite: String
    public let category: TestCategory
    public let status: TestStatus
    public let duration: TimeInterval
    public let failureReason: String?
    public let classification: FailureClassification?

    public init(
        id: String = UUID().uuidString,
        name: String,
        suite: String,
        category: TestCategory = .unit,
        status: TestStatus,
        duration: TimeInterval,
        failureReason: String? = nil,
        classification: FailureClassification? = nil
    ) {
        self.id = id
        self.name = name
        self.suite = suite
        self.category = category
        self.status = status
        self.duration = duration
        self.failureReason = failureReason
        self.classification = classification
    }
}

/// Evaluation decision for release quality gate.
public enum ReleaseStatus: String, Codable, Sendable {
    case releaseReady = "RELEASE READY"
    case releaseBlocked = "RELEASE BLOCKED"
}

/// Summary report of the entire test execution.
public struct QualityReport: Codable, Sendable {
    public let projectName: String
    public let timestamp: Date
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let blockedTests: Int
    public let flakyTests: Int
    public let testResults: [TestCaseResult]
    public let releaseStatus: ReleaseStatus
    public let blockingReasons: [String]

    public var passRatePercentage: Double {
        guard totalTests > 0 else { return 0.0 }
        return (Double(passedTests) / Double(totalTests)) * 100.0
    }
}

/// Evaluates test results against release criteria.
public struct QualityGateEvaluator: Sendable {
    public init() {}

    public func evaluate(results: [TestCaseResult], projectName: String = "iOS_QA_Framework") -> QualityReport {
        let total = results.count
        let passed = results.filter { $0.status == .passed }.count
        let failed = results.filter { $0.status == .failed }.count
        let skipped = results.filter { $0.status == .skipped }.count
        let blocked = results.filter { $0.status == .blocked }.count
        let flaky = results.filter { $0.status == .flaky }.count

        var blockingReasons: [String] = []

        if failed > 0 {
            let failedNames = results.filter { $0.status == .failed }.map { "\($0.suite).\($0.name)" }
            blockingReasons.append("\(failed) test(s) failed: [\(failedNames.joined(separator: ", "))]")
        }

        if blocked > 0 {
            blockingReasons.append("\(blocked) test(s) blocked on external dependencies.")
        }

        let status: ReleaseStatus = blockingReasons.isEmpty ? .releaseReady : .releaseBlocked

        return QualityReport(
            projectName: projectName,
            timestamp: Date(),
            totalTests: total,
            passedTests: passed,
            failedTests: failed,
            skippedTests: skipped,
            blockedTests: blocked,
            flakyTests: flaky,
            testResults: results,
            releaseStatus: status,
            blockingReasons: blockingReasons
        )
    }
}
