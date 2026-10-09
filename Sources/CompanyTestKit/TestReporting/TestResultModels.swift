import Foundation

/// Status of an executed test.
public enum TestStatus: String, Codable, Sendable {
    case passed = "PASSED"
    case failed = "FAILED"
    case skipped = "SKIPPED"
    case blocked = "BLOCKED"
    case flaky = "FLAKY"
    case notExecuted = "NOT_EXECUTED"
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
public enum TestCategory: String, Codable, Sendable, CaseIterable {
    case unit = "Unit"
    case api = "API"
    case integration = "Integration"
    case ui = "UI"
    case e2e = "E2E"
    case regression = "Regression"
    case performance = "Performance"
    case security = "Security"
    case accessibility = "Accessibility"
}

/// Result of an individual test case execution.
public struct TestCaseResult: Codable, Sendable, Equatable {
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

// MARK: - Legacy Quality Report (Preserved for Backward Compatibility)

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

// MARK: - Three-Tier Quality Gate System (Requirement 11)

/// 1. Pure Technical Quality assessment of automated checks.
public struct TechnicalQualityReport: Codable, Sendable, Equatable {
    public let totalExecuted: Int
    public let passedCount: Int
    public let failedCount: Int
    public let skippedCount: Int
    public let blockedCount: Int
    public let flakyCount: Int
    public let passRatePercentage: Double
    public let totalDuration: TimeInterval
    public let isTechnicallyPassing: Bool

    public init(
        totalExecuted: Int,
        passedCount: Int,
        failedCount: Int,
        skippedCount: Int,
        blockedCount: Int,
        flakyCount: Int,
        passRatePercentage: Double,
        totalDuration: TimeInterval,
        isTechnicallyPassing: Bool
    ) {
        self.totalExecuted = totalExecuted
        self.passedCount = passedCount
        self.failedCount = failedCount
        self.skippedCount = skippedCount
        self.blockedCount = blockedCount
        self.flakyCount = flakyCount
        self.passRatePercentage = passRatePercentage
        self.totalDuration = totalDuration
        self.isTechnicallyPassing = isTechnicallyPassing
    }

    /// Convenience alias for passRatePercentage.
    public var passRate: Double { passRatePercentage }
}

/// Status of QA Handoff readiness.
public enum QAHandoffStatus: String, Codable, Sendable {
    case approvedForQA = "APPROVED FOR QA"
    case approvedWithCaveats = "APPROVED WITH CAVEATS"
    case blockedForQA = "BLOCKED FOR QA"
}

/// 2. QA Handoff Decision assessing suitability for formal exploratory testing.
public struct QAHandoffDecision: Codable, Sendable, Equatable {
    public let status: QAHandoffStatus
    public let knownRisksDisclosed: [String]
    public let blockingReasons: [String]
    public let recommendedTestingFocus: [String]

    public init(
        status: QAHandoffStatus,
        knownRisksDisclosed: [String] = [],
        blockingReasons: [String] = [],
        recommendedTestingFocus: [String] = []
    ) {
        self.status = status
        self.knownRisksDisclosed = knownRisksDisclosed
        self.blockingReasons = blockingReasons
        self.recommendedTestingFocus = recommendedTestingFocus
    }
}

/// Status of Production Release Readiness.
public enum ProductionReleaseStatus: String, Codable, Sendable {
    case releaseReady = "RELEASE READY"
    case releaseBlocked = "RELEASE BLOCKED"
}

/// 3. Release Readiness Decision enforcing strict production release criteria.
public struct ReleaseReadinessDecision: Codable, Sendable, Equatable {
    public let status: ProductionReleaseStatus
    public let blockingReasons: [String]
    public let policyViolations: [String]
    public let verifiedDefectsCount: Int
    public let unverifiedDefectsCount: Int
    public let timestamp: Date

    public init(
        status: ProductionReleaseStatus,
        blockingReasons: [String],
        policyViolations: [String] = [],
        verifiedDefectsCount: Int = 0,
        unverifiedDefectsCount: Int = 0,
        timestamp: Date = Date()
    ) {
        self.status = status
        self.blockingReasons = blockingReasons
        self.policyViolations = policyViolations
        self.verifiedDefectsCount = verifiedDefectsCount
        self.unverifiedDefectsCount = unverifiedDefectsCount
        self.timestamp = timestamp
    }
}

/// Policy governing release and QA handoff gates.
public struct QualityGatePolicy: Codable, Sendable, Equatable {
    public var blockReleaseOnCriticalOrHighDefects: Bool
    public var blockReleaseOnUnclassifiedBugs: Bool
    public var blockReleaseOnFailedRegressions: Bool
    public var minimumPassRateForRelease: Double
    public var minimumPassRateForQAHandoff: Double

    public init(
        blockReleaseOnCriticalOrHighDefects: Bool = true,
        blockReleaseOnUnclassifiedBugs: Bool = true,
        blockReleaseOnFailedRegressions: Bool = true,
        minimumPassRateForRelease: Double = 100.0,
        minimumPassRateForQAHandoff: Double = 90.0
    ) {
        self.blockReleaseOnCriticalOrHighDefects = blockReleaseOnCriticalOrHighDefects
        self.blockReleaseOnUnclassifiedBugs = blockReleaseOnUnclassifiedBugs
        self.blockReleaseOnFailedRegressions = blockReleaseOnFailedRegressions
        self.minimumPassRateForRelease = minimumPassRateForRelease
        self.minimumPassRateForQAHandoff = minimumPassRateForQAHandoff
    }

    public static let `default` = QualityGatePolicy()
}

/// Complete comprehensive quality evaluation separating the 3 core decisions.
public struct ComprehensiveQualityEvaluation: Codable, Sendable, Equatable {
    public let projectName: String
    public let technicalQuality: TechnicalQualityReport
    public let qaHandoff: QAHandoffDecision
    public let releaseReadiness: ReleaseReadinessDecision
    public let timestamp: Date

    public init(
        projectName: String,
        technicalQuality: TechnicalQualityReport,
        qaHandoff: QAHandoffDecision,
        releaseReadiness: ReleaseReadinessDecision,
        timestamp: Date = Date()
    ) {
        self.projectName = projectName
        self.technicalQuality = technicalQuality
        self.qaHandoff = qaHandoff
        self.releaseReadiness = releaseReadiness
        self.timestamp = timestamp
    }
}

// MARK: - Quality Gate Evaluator

/// Evaluates test results, defect states, and security checks against release policies.
public struct QualityGateEvaluator: Sendable {
    public init() {}

    /// Static convenience for evaluating test results.
    public static func evaluate(results: [TestCaseResult], projectName: String = "iOS_QA_Framework") -> QualityReport {
        QualityGateEvaluator().evaluate(results: results, projectName: projectName)
    }

    /// Static convenience for evaluating technical quality, QA handoff, and production release readiness.
    public static func evaluateComprehensive(
        results: [TestCaseResult],
        defects: [DefectRecord] = [],
        policy: QualityGatePolicy = .default,
        projectName: String = "iOS_QA_Framework"
    ) -> ComprehensiveQualityEvaluation {
        QualityGateEvaluator().evaluateComprehensive(results: results, defects: defects, policy: policy, projectName: projectName)
    }

    /// Legacy evaluation method preserved for 100% backward compatibility.
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

    /// Evaluates technical quality, QA handoff, and production release readiness without contradiction.
    public func evaluateComprehensive(
        results: [TestCaseResult],
        defects: [DefectRecord] = [],
        policy: QualityGatePolicy = .default,
        projectName: String = "iOS_QA_Framework"
    ) -> ComprehensiveQualityEvaluation {
        // 1. Technical Quality
        let total = results.count
        let passed = results.filter { $0.status == .passed }.count
        let failed = results.filter { $0.status == .failed }.count
        let skipped = results.filter { $0.status == .skipped }.count
        let blocked = results.filter { $0.status == .blocked }.count
        let flaky = results.filter { $0.status == .flaky }.count
        let duration = results.reduce(0.0) { $0 + $1.duration }
        let passRate = total > 0 ? (Double(passed) / Double(total)) * 100.0 : 0.0
        let isTechPassing = failed == 0 && passRate >= policy.minimumPassRateForRelease

        let techReport = TechnicalQualityReport(
            totalExecuted: total,
            passedCount: passed,
            failedCount: failed,
            skippedCount: skipped,
            blockedCount: blocked,
            flakyCount: flaky,
            passRatePercentage: passRate,
            totalDuration: duration,
            isTechnicallyPassing: isTechPassing
        )

        // 2. QA Handoff Assessment
        var qaBlocking: [String] = []
        var qaWarnings: [String] = []
        var qaFocus: [String] = []

        // Blocking for QA: Total build failure, crash defects, or pass rate < 90%
        let criticalBugs = defects.filter { $0.severity == .critical && $0.status != .verified && $0.status != .acceptedRisk }
        if !criticalBugs.isEmpty {
            qaBlocking.append("\(criticalBugs.count) unresolved CRITICAL bug(s) block testability: [\(criticalBugs.map { $0.title }.joined(separator: ", "))]")
        }
        if passRate < policy.minimumPassRateForQAHandoff && total > 0 {
            qaBlocking.append("Pass rate (\(String(format: "%.1f", passRate))%) is below minimum QA handoff threshold (\(policy.minimumPassRateForQAHandoff)%).")
        }

        // Warnings for QA: Disclose known non-critical bugs and blocked hardware tests
        let openMediumOrLow = defects.filter { ($0.severity == .medium || $0.severity == .low || $0.severity == .high) && $0.status != .verified }
        for bug in openMediumOrLow {
            qaWarnings.append("Known issue: [\(bug.id)] \(bug.title) (Status: \(bug.status.rawValue))")
            qaFocus.append("Verify workaround/reproduction for '\(bug.title)' on screen '\(bug.affectedScreen)'")
        }
        if blocked > 0 {
            qaWarnings.append("\(blocked) test(s) blocked on external dependencies (e.g. physical biometric/APNS).")
            qaFocus.append("Manual testing of blocked hardware interactions required.")
        }

        let qaStatus: QAHandoffStatus
        if !qaBlocking.isEmpty {
            qaStatus = .blockedForQA
        } else if !qaWarnings.isEmpty {
            qaStatus = .approvedWithCaveats
        } else {
            qaStatus = .approvedForQA
        }

        let qaDecision = QAHandoffDecision(
            status: qaStatus,
            knownRisksDisclosed: qaWarnings,
            blockingReasons: qaBlocking,
            recommendedTestingFocus: qaFocus
        )

        // 3. Production Release Readiness (Strict Release Policy)
        var releaseBlocking: [String] = []
        var policyViolations: [String] = []

        // A. Failed automated tests
        if failed > 0 {
            releaseBlocking.append("\(failed) automated test(s) failed in the test suite.")
            policyViolations.append("Failed test suites must be resolved before production release.")
        }

        // B. Critical or High open defects
        let openCriticalOrHigh = defects.filter {
            ($0.severity == .critical || $0.severity == .high) && $0.status != .verified && $0.status != .acceptedRisk
        }
        if policy.blockReleaseOnCriticalOrHighDefects && !openCriticalOrHigh.isEmpty {
            releaseBlocking.append("\(openCriticalOrHigh.count) open Critical/High defect(s) pending verification: [\(openCriticalOrHigh.map { $0.id }.joined(separator: ", "))]")
            policyViolations.append("Release policy requires 0 open Critical/High defects.")
        }

        // C. Unclassified open defects (e.g. New without triage)
        let unclassified = defects.filter { $0.status == .new }
        if policy.blockReleaseOnUnclassifiedBugs && !unclassified.isEmpty {
            releaseBlocking.append("\(unclassified.count) defect(s) are unclassified/new. All defects must be triaged.")
            policyViolations.append("All defects must reach a triaged or verified state prior to signoff.")
        }

        // D. Pass rate threshold
        if passRate < policy.minimumPassRateForRelease && total > 0 {
            releaseBlocking.append("Pass rate (\(String(format: "%.1f", passRate))%) does not satisfy 100% release criterion.")
            policyViolations.append("Release gate mandates 100% test pass rate.")
        }

        let verifiedCount = defects.filter { $0.status == .verified }.count
        let unverifiedCount = defects.filter { $0.status != .verified && $0.status != .acceptedRisk }.count

        let releaseStatus: ProductionReleaseStatus = releaseBlocking.isEmpty ? .releaseReady : .releaseBlocked
        let releaseDecision = ReleaseReadinessDecision(
            status: releaseStatus,
            blockingReasons: releaseBlocking,
            policyViolations: policyViolations,
            verifiedDefectsCount: verifiedCount,
            unverifiedDefectsCount: unverifiedCount,
            timestamp: Date()
        )

        return ComprehensiveQualityEvaluation(
            projectName: projectName,
            technicalQuality: techReport,
            qaHandoff: qaDecision,
            releaseReadiness: releaseDecision,
            timestamp: Date()
        )
    }
}
