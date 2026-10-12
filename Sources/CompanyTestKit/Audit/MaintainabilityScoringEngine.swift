import Foundation
import CompanyiOSKit

/// Category deduction item contributing to the maintainability calculation.
public struct ScoringDeduction: Codable, Sendable, Equatable {
    public let ruleId: String
    public let description: String
    public let pointsDeducted: Int
    public let sourceFile: String
    public let line: Int?

    public init(ruleId: String, description: String, pointsDeducted: Int, sourceFile: String, line: Int? = nil) {
        self.ruleId = ruleId
        self.description = description
        self.pointsDeducted = pointsDeducted
        self.sourceFile = sourceFile
        self.line = line
    }
}

/// Maintainability quality rating tier.
public enum MaintainabilityGrade: String, Codable, Sendable {
    case excellent = "A (Excellent, 90-100)"
    case good = "B (Good, 75-89)"
    case needsAttention = "C (Needs Attention, 50-74)"
    case highRisk = "D (High Risk, 0-49)"

    public static func grade(for score: Int) -> MaintainabilityGrade {
        switch score {
        case 90...100: return .excellent
        case 75...89: return .good
        case 50...74: return .needsAttention
        default: return .highRisk
        }
    }
}

/// Comprehensive report of calculated code maintainability for a module or project.
public struct MaintainabilityReport: Codable, Sendable, Equatable {
    public let targetName: String
    public let analyzedFilesCount: Int
    public let finalScore: Int
    public let grade: MaintainabilityGrade
    public let deductions: [ScoringDeduction]
    public let deductionSummaryByCategory: [String: Int]
    public let formulaExplanation: String

    public init(
        targetName: String,
        analyzedFilesCount: Int,
        finalScore: Int,
        grade: MaintainabilityGrade,
        deductions: [ScoringDeduction],
        deductionSummaryByCategory: [String: Int],
        formulaExplanation: String
    ) {
        self.targetName = targetName
        self.analyzedFilesCount = analyzedFilesCount
        self.finalScore = finalScore
        self.grade = grade
        self.deductions = deductions
        self.deductionSummaryByCategory = deductionSummaryByCategory
        self.formulaExplanation = formulaExplanation
    }
}

/// Computes quantitative, documented maintainability scores (0-100) from actual static findings.
public struct MaintainabilityScoringEngine: Sendable {
    public init() {}

    /// Calculates project-wide maintainability score based on actual static and security findings.
    public func evaluateProject(
        targetName: String = "iOS_QA_Framework",
        scannedFileCount: Int,
        staticFindings: [StaticCodeFinding],
        securityFindings: [SecurityFinding],
        complianceIssues: [ComplianceIssue] = []
    ) -> MaintainabilityReport {
        var deductions: [ScoringDeduction] = []
        var categoryTotals: [String: Int] = [
            "Security & Credentials": 0,
            "Concurrency & Threading": 0,
            "Unsafe Force Unwrapping": 0,
            "Error Handling Quality": 0,
            "App Store Compliance": 0
        ]

        // 1. Security deductions (-15 pts for Critical, -10 pts for High)
        for finding in securityFindings {
            let pts = (finding.severity == .critical) ? 15 : 10
            deductions.append(ScoringDeduction(
                ruleId: finding.category.rawValue,
                description: finding.evidence,
                pointsDeducted: pts,
                sourceFile: finding.sourceFile,
                line: finding.sourceLine
            ))
            categoryTotals["Security & Credentials", default: 0] += pts
        }

        // 2. Static Code Findings deductions
        for finding in staticFindings {
            let pts: Int
            let category: String
            switch finding.ruleId {
            case "MAIN_THREAD_DEADLOCK", "BLOCKING_MAIN_THREAD":
                pts = 10
                category = "Concurrency & Threading"
            case "UNSAFE_FORCE_UNWRAP":
                pts = 5
                category = "Unsafe Force Unwrapping"
            case "SWALLOWED_ERROR", "EMPTY_CATCH":
                pts = 4
                category = "Error Handling Quality"
            case "HIGH_CYCLOMATIC_COMPLEXITY":
                pts = 3
                category = "Error Handling Quality"
            default:
                pts = 2
                category = "Error Handling Quality"
            }

            deductions.append(ScoringDeduction(
                ruleId: finding.ruleId,
                description: finding.message,
                pointsDeducted: pts,
                sourceFile: finding.sourceFile,
                line: finding.sourceLine
            ))
            categoryTotals[category, default: 0] += pts
        }

        // 3. Compliance issues (-8 pts each)
        for issue in complianceIssues {
            let pts = 8
            deductions.append(ScoringDeduction(
                ruleId: issue.guideline,
                description: issue.title,
                pointsDeducted: pts,
                sourceFile: issue.sourceFile ?? "Configuration",
                line: issue.sourceLine
            ))
            categoryTotals["App Store Compliance", default: 0] += pts
        }

        // Calculate final score with baseline 100, clamped between 0 and 100
        let totalDeductions = deductions.reduce(0) { $0 + $1.pointsDeducted }
        let score = max(0, min(100, 100 - totalDeductions))
        let grade = MaintainabilityGrade.grade(for: score)

        let formula = """
        Baseline Score: 100
        Deduction Rules:
        - Critical Security Leak: -15 pts
        - High Security / Credential Risk: -10 pts
        - Main Thread Hang / Sync: -10 pts
        - App Store / Privacy Violation: -8 pts
        - Force Unwrap (!): -5 pts
        - Swallowed Error: -4 pts
        - High Cyclomatic Complexity (>10): -3 pts
        Total Points Deducted: \(totalDeductions) across \(deductions.count) findings in \(scannedFileCount) scanned files.
        """

        return MaintainabilityReport(
            targetName: targetName,
            analyzedFilesCount: scannedFileCount,
            finalScore: score,
            grade: grade,
            deductions: deductions,
            deductionSummaryByCategory: categoryTotals,
            formulaExplanation: formula
        )
    }
}
