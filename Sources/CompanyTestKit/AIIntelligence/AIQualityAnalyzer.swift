import Foundation

/// Risk tier discovered by AI evaluation.
public enum AIRiskLevel: String, Codable, Sendable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}

/// Area of architectural or quality risk identified through AI analysis.
public struct RiskArea: Codable, Sendable, Equatable {
    public let featureName: String
    public let riskLevel: AIRiskLevel
    public let reason: String
    public let recommendation: String

    public init(featureName: String, riskLevel: AIRiskLevel, reason: String, recommendation: String) {
        self.featureName = featureName
        self.riskLevel = riskLevel
        self.reason = reason
        self.recommendation = recommendation
    }
}

/// Kind of testing gap detected in the application.
public enum GapKind: String, Codable, Sendable {
    case uncoveredJourney = "Uncovered User Journey"
    case missingNegative = "Missing Negative Input Test"
    case missingBoundary = "Missing Boundary Test"
    case missingOfflineErrorHandling = "Missing Offline/Network Fallback"
    case unverifiedStatePersistence = "Unverified State Restoration"
    case missingAccessibility = "Missing Accessibility Traits"
}

/// Identified coverage gap with actionable remediation.
public struct CoverageGap: Codable, Sendable, Equatable {
    public let kind: GapKind
    public let target: String
    public let details: String

    public init(kind: GapKind, target: String, details: String) {
        self.kind = kind
        self.target = target
        self.details = details
    }
}

/// Test that cannot be automated without physical hardware or live external dependencies.
public struct UnexecutableTest: Codable, Sendable, Equatable {
    public let title: String
    public let reason: String

    public init(title: String, reason: String) {
        self.title = title
        self.reason = reason
    }
}

/// AI Quality Analysis Report evaluating total project testing integrity.
public struct AIAnalysisReport: Codable, Sendable, Equatable {
    public let riskAreas: [RiskArea]
    public let coverageGaps: [CoverageGap]
    public let unexecutableTests: [UnexecutableTest]
    public let suggestedScenarios: [String]
    public let overallConfidenceScore: Double

    public init(
        riskAreas: [RiskArea],
        coverageGaps: [CoverageGap],
        unexecutableTests: [UnexecutableTest],
        suggestedScenarios: [String],
        overallConfidenceScore: Double
    ) {
        self.riskAreas = riskAreas
        self.coverageGaps = coverageGaps
        self.unexecutableTests = unexecutableTests
        self.suggestedScenarios = suggestedScenarios
        self.overallConfidenceScore = overallConfidenceScore
    }
}

/// AI Quality Analyzer evaluating project coverage, gaps, risks, and unexecutable tests.
public struct AIQualityAnalyzer: Sendable {
    public init() {}

    /// Analyzes the application model and existing telemetry to produce an evidence-based quality evaluation.
    public func analyzeQuality(
        screens: [ScreenDefinition],
        journeys: [UserJourney],
        existingTests: [TestCaseResult] = [],
        defects: [DefectRecord] = []
    ) -> AIAnalysisReport {
        var risks: [RiskArea] = []
        var gaps: [CoverageGap] = []
        var unexecutable: [UnexecutableTest] = []
        var suggested: [String] = []

        // 1. Analyze Screen Coverage
        for screen in screens {
            // Check if screen has API dependencies but no error test in existing tests
            for endpoint in screen.apiDependencies {
                let hasApiTest = existingTests.contains { $0.category == .api && $0.name.contains(endpoint) }
                if !hasApiTest {
                    gaps.append(CoverageGap(
                        kind: .missingOfflineErrorHandling,
                        target: "\(screen.name) (\(endpoint))",
                        details: "Screen relies on network endpoint '\(endpoint)', but no explicit network failure or timeout test is registered."
                    ))
                }
            }

            // Check for text inputs lacking negative tests
            let textFields = screen.elements.filter { $0.type == .textField || $0.type == .secureField }
            if !textFields.isEmpty {
                let hasValidationTest = existingTests.contains { $0.category == .unit && $0.name.lowercased().contains("validation") }
                if !hasValidationTest {
                    gaps.append(CoverageGap(
                        kind: .missingNegative,
                        target: screen.name,
                        details: "Screen contains input fields (\(textFields.map { $0.id }.joined(separator: ", "))) without dedicated negative input assertions."
                    ))
                }
            }
        }

        // 2. Identify Uncovered Journeys
        if journeys.isEmpty {
            risks.append(RiskArea(
                featureName: "Navigation Architecture",
                riskLevel: .high,
                reason: "Zero multi-screen user journeys registered.",
                recommendation: "Model at least one primary happy-path workflow through ScreenRegistry.registerJourney()."
            ))
        }

        // 3. Mark Tests Requiring External Physical Dependencies as 'Not Executed' (Never fabricate passes!)
        unexecutable.append(UnexecutableTest(
            title: "Biometric_FaceID_Hardware_Sensor_Validation",
            reason: "Requires physical biometric sensor interaction; not executable in headless CI."
        ))
        unexecutable.append(UnexecutableTest(
            title: "Apple_Push_Notification_APNS_Receipt",
            reason: "Requires external Apple APNS Gateway connection and physical device APNS token."
        ))

        // 4. Correlate Historical Defects to Current Risks
        for defect in defects {
            risks.append(RiskArea(
                featureName: defect.affectedScreen,
                riskLevel: defect.riskLevel == .critical ? .critical : .high,
                reason: "Prior verified defect recorded: '\(defect.title)'",
                recommendation: "Ensure regression suite '\(defect.regressionPattern)' is executed before release."
            ))
            suggested.append("Execute regression validation for: \(defect.title)")
        }

        let totalGaps = gaps.count + risks.count
        let confidenceScore = max(0.5, 1.0 - (Double(totalGaps) * 0.05))

        return AIAnalysisReport(
            riskAreas: risks,
            coverageGaps: gaps,
            unexecutableTests: unexecutable,
            suggestedScenarios: suggested,
            overallConfidenceScore: confidenceScore
        )
    }
}
