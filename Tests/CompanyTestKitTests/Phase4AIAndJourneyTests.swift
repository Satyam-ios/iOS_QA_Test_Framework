import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class Phase4AIAndJourneyTests: XCTestCase {

    // MARK: - 1. AI Code Review Engine Tests

    func testAICodeReviewEngine_SynthesizesUnifiedDiffPatches_ForDefect() {
        let defect = DefectRecord(
            id: "DEF-CRASH-01",
            title: "Crash on force unwrap in LoginView",
            affectedScreen: "LoginView",
            rootCause: "Unchecked force unwrap of session token",
            regressionPattern: "ForceUnwrapPattern",
            riskLevel: .critical,
            status: .new,
            severity: .critical,
            category: .crash,
            sourceFile: "Sources/Login/LoginView.swift",
            lineRange: "L42-L46"
        )

        let engine = AICodeReviewEngine()
        let review = engine.generateRecommendation(for: defect)

        XCTAssertEqual(review.defectOrFindingId, "DEF-CRASH-01")
        XCTAssertEqual(review.sourceFile, "Sources/Login/LoginView.swift")
        XCTAssertTrue(review.suggestedPatchDiff.contains("--- a/Sources/Login/LoginView.swift"))
        XCTAssertTrue(review.suggestedPatchDiff.contains("+++ b/Sources/Login/LoginView.swift"))
        XCTAssertTrue(review.suggestedPatchDiff.contains("guard let token"))
        XCTAssertFalse(review.alternativeApproaches.isEmpty)
        XCTAssertGreaterThan(review.confidenceScore, 0.9)
    }

    func testAICodeReviewEngine_SynthesizesPatches_ForSecurityDefect() {
        let defect = DefectRecord(
            id: "DEF-SEC-01",
            title: "Auth token stored in UserDefaults",
            affectedScreen: "TokenManager",
            rootCause: "Insecure persistence mechanism",
            regressionPattern: "InsecureStorage",
            riskLevel: .critical,
            status: .new,
            severity: .critical,
            category: .security,
            sourceFile: "Sources/TokenManager.swift"
        )

        let engine = AICodeReviewEngine()
        let review = engine.generateRecommendation(for: defect)

        XCTAssertTrue(review.suggestedPatchDiff.contains("KeychainManager.shared.save"))
    }

    // MARK: - 2. JourneyRunner Checkpoint Tracing & Defect Synthesis Tests

    func testJourneyRunner_ExecutesSuccessfulJourney_WithCheckpointTraces() async {
        let screen = ScreenDefinition(
            id: "screen_checkout",
            name: "Checkout Screen",
            route: "/checkout",
            elements: [
                UIElementDescriptor(id: "btn_pay", type: .button, isEnabled: true, isVisible: true)
            ]
        )

        let runner = JourneyRunner(screens: [screen])
        let journey = UserJourney(
            id: "checkout_flow",
            name: "Checkout Flow",
            initialRoute: "/checkout",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_checkout", actionName: "Tap Pay", targetElementId: "btn_pay")
            ]
        )

        let result = await runner.execute(journey: journey)

        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.executedSteps, 1)
        XCTAssertNil(result.synthesizedDefectId)
        XCTAssertEqual(result.stepResults.first?.targetElementId, "btn_pay")
        XCTAssertTrue(result.stepResults.first?.isSuccessful ?? false)
    }

    func testJourneyRunner_WhenStepFails_SynthesizesDefectInCatalog() async {
        let screen = ScreenDefinition(
            id: "screen_profile",
            name: "Profile Screen",
            route: "/profile",
            elements: [
                UIElementDescriptor(id: "btn_edit", type: .button, isEnabled: false, isVisible: true) // disabled!
            ]
        )

        let runner = JourneyRunner(screens: [screen])
        let journey = UserJourney(
            id: "profile_edit_flow",
            name: "Profile Edit Flow",
            initialRoute: "/profile",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_profile", actionName: "Tap Edit", targetElementId: "btn_edit")
            ]
        )

        let result = await runner.execute(journey: journey, recordDefectOnFailure: true)

        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.failedStepNumber, 1)
        XCTAssertNotNil(result.synthesizedDefectId)

        // Verify defect was actually recorded in DefectCatalog
        if let defectId = result.synthesizedDefectId {
            let defect = DefectCatalog.shared.findDefect(id: defectId)
            XCTAssertNotNil(defect)
            XCTAssertEqual(defect?.affectedScreen, "screen_profile")
            XCTAssertEqual(defect?.status, .new)
            XCTAssertEqual(defect?.severity, .high)
            XCTAssertTrue(defect?.title.contains("Profile Edit Flow") ?? false)
        }
    }
}
