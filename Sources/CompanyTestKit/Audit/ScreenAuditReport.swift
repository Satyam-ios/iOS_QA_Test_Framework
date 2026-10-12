import Foundation
import CompanyiOSKit

/// Detailed QA and engineering audit record for an individual discovered screen.
public struct ScreenAuditReport: Codable, Sendable, Identifiable, Equatable {
    public var id: String { screen.id }
    public let screen: ScreenDefinition
    public let accessibilityViolations: [AccessibilityViolation]
    public let touchTargetIssues: [String]
    public let missingStateHazards: [String]
    public let detectedApiDependencies: [String]
    public let associatedFindings: [StaticCodeFinding]
    public let screenMaintainabilityScore: Int
    public let testCoverageStatus: FindingStatus
    public let uiUxAuditStatus: FindingStatus
    public let auditNotes: [String]
    public var seniorQuality: ScreenSeniorQualityReport?

    public init(
        screen: ScreenDefinition,
        accessibilityViolations: [AccessibilityViolation] = [],
        touchTargetIssues: [String] = [],
        missingStateHazards: [String] = [],
        detectedApiDependencies: [String] = [],
        associatedFindings: [StaticCodeFinding] = [],
        screenMaintainabilityScore: Int = 100,
        testCoverageStatus: FindingStatus = .notExecuted,
        uiUxAuditStatus: FindingStatus = .notExecuted,
        auditNotes: [String] = [],
        seniorQuality: ScreenSeniorQualityReport? = nil
    ) {
        self.screen = screen
        self.accessibilityViolations = accessibilityViolations
        self.touchTargetIssues = touchTargetIssues
        self.missingStateHazards = missingStateHazards
        self.detectedApiDependencies = detectedApiDependencies
        self.associatedFindings = associatedFindings
        self.screenMaintainabilityScore = screenMaintainabilityScore
        self.testCoverageStatus = testCoverageStatus
        self.uiUxAuditStatus = uiUxAuditStatus
        self.auditNotes = auditNotes
        self.seniorQuality = seniorQuality
    }

    /// Evaluates whether the screen has any critical quality or accessibility violations.
    public var isPassingQuality: Bool {
        accessibilityViolations.isEmpty && touchTargetIssues.isEmpty && associatedFindings.isEmpty
    }
}
