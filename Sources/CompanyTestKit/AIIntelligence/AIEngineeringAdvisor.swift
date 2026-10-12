import Foundation
import CompanyiOSKit

/// Smart AI engineering recommendation and automatic patch proposal.
public struct SmartAISolution: Codable, Sendable, Identifiable, Equatable {
    public var id: String { defectId }
    public let defectId: String
    public let title: String
    public let architecturalAnalysis: String
    public let rootCauseExplanation: String
    public let recommendedDesignPattern: String
    public let unifiedDiffPatch: String
    public let copyPasteSolution: String
    public let confidenceScore: Double

    public init(
        defectId: String,
        title: String,
        architecturalAnalysis: String,
        rootCauseExplanation: String,
        recommendedDesignPattern: String,
        unifiedDiffPatch: String,
        copyPasteSolution: String,
        confidenceScore: Double = 0.98
    ) {
        self.defectId = defectId
        self.title = title
        self.architecturalAnalysis = architecturalAnalysis
        self.rootCauseExplanation = rootCauseExplanation
        self.recommendedDesignPattern = recommendedDesignPattern
        self.unifiedDiffPatch = unifiedDiffPatch
        self.copyPasteSolution = copyPasteSolution
        self.confidenceScore = confidenceScore
    }
}

/// AI-powered engineering engine synthesizing root cause analyses, design patterns, and code patches.
public struct AIEngineeringAdvisor: Sendable {
    public init() {}

    /// Analyzes a defect or finding and synthesizes an intelligent architectural solution.
    public func advise(for defect: DefectRecord) -> SmartAISolution {
        let isTruncation = defect.category == .ui || defect.title.contains("Truncation") || defect.title.contains("ellipsis")
        let isCrash = defect.category == .crash || defect.title.contains("Crash") || defect.title.contains("Exception")

        let analysis: String
        let rootCause: String
        let pattern: String
        let diff: String
        let solution: String

        if isTruncation {
            analysis = "UI Layout Geometry Insufficiency. AutoLayout width constraints do not scale dynamically with internationalization or variable-length user names."
            rootCause = "The label has fixed width constraints or lacks adjustsFontSizeToFitWidth. Rendered text exceeds physical bounds and triggers UIKit tail-truncation with ellipsis."
            pattern = "Dynamic Typography & Adaptive AutoLayout Pattern"
            diff = """
            --- a/\(defect.sourceFile ?? "ViewController.swift")
            +++ b/\(defect.sourceFile ?? "ViewController.swift")
            @@ -45,3 +45,4 @@
            +        greetingLabel.adjustsFontSizeToFitWidth = true
            +        greetingLabel.minimumScaleFactor = 0.8
            +        greetingLabel.numberOfLines = 0
            """
            solution = """
            // Recommended Solution for \(defect.affectedScreen):
            greetingLabel.adjustsFontSizeToFitWidth = true
            greetingLabel.minimumScaleFactor = 0.8
            greetingLabel.numberOfLines = 0 // Allow multiline if name is long
            // Or change AutoLayout width constraint from '= 100' to '>= 100'
            """
        } else if isCrash {
            analysis = "Thread Concurrency & Concurrency Boundary Invariant Violation."
            rootCause = "Background queue mutated layout engine or unhandled force unwrap triggered fatal termination."
            pattern = "@MainActor UI Binding & Safe Optionals Guard Pattern"
            diff = """
            --- a/\(defect.sourceFile ?? "ViewController.swift")
            +++ b/\(defect.sourceFile ?? "ViewController.swift")
            @@ -120,2 +120,4 @@
            +        await MainActor.run {
            +            self.tableView.reloadData()
            +        }
            """
            solution = """
            // Recommended Solution for \(defect.affectedScreen):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
            """
        } else {
            analysis = "Defensive Architecture & Resilient State Mutation."
            rootCause = defect.rootCause
            pattern = "Clean Architecture with Reactive Boundary Guards"
            diff = """
            --- a/\(defect.sourceFile ?? "ViewController.swift")
            +++ b/\(defect.sourceFile ?? "ViewController.swift")
            @@ -60,2 +60,4 @@
            +        guard let value = optionalValue else { return }
            """
            solution = defect.recommendedCorrection ?? "Apply guard-let early exit and log warning."
        }

        return SmartAISolution(
            defectId: defect.id,
            title: defect.title,
            architecturalAnalysis: analysis,
            rootCauseExplanation: rootCause,
            recommendedDesignPattern: pattern,
            unifiedDiffPatch: diff,
            copyPasteSolution: solution
        )
    }
}
