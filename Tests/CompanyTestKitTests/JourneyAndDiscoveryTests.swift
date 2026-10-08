import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class JourneyAndDiscoveryTests: XCTestCase {

    func testJourneyRunner_WhenValidJourneyExecuted_CompletesAllStepsSuccessfully() async {
        let runner = JourneyRunner(screens: ScreenRegistry.shared.allScreens)
        let journey = ScreenRegistry.shared.allJourneys.first!

        let result = await runner.execute(journey: journey)

        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.executedSteps, journey.steps.count)
        XCTAssertNil(result.failedStepNumber)
        XCTAssertNil(result.failureReason)
    }

    func testJourneyRunner_WhenScreenNotRegistered_FailsGracefully() async {
        let runner = JourneyRunner(screens: []) // empty screens
        let invalidJourney = UserJourney(
            id: "j_invalid",
            name: "Unregistered Screen Journey",
            initialRoute: "/unknown",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "non_existent_screen", actionName: "Tap Button")
            ]
        )

        let result = await runner.execute(journey: invalidJourney)

        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.failedStepNumber, 1)
        XCTAssertTrue(result.failureReason?.contains("not registered") == true)
    }

    func testJourneyRunner_WhenTargetElementDisabled_FailsWithDescriptiveReason() async {
        let disabledScreen = ScreenDefinition(
            id: "screen_disabled",
            name: "Disabled Test Screen",
            route: "/disabled",
            elements: [
                UIElementDescriptor(id: "btn_submit", type: .button, isEnabled: false)
            ]
        )
        let runner = JourneyRunner(screens: [disabledScreen])
        let journey = UserJourney(
            id: "j_disabled",
            name: "Disabled Button Journey",
            initialRoute: "/disabled",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_disabled", actionName: "Tap Submit", targetElementId: "btn_submit")
            ]
        )

        let result = await runner.execute(journey: journey)

        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.failedStepNumber, 1)
        XCTAssertTrue(result.failureReason?.contains("is disabled") == true)
    }

    func testAccessibilityValidator_DetectsMissingIdentifiersAndLabels() {
        let validator = AccessibilityValidator()
        let nonCompliantScreen = ScreenDefinition(
            id: "screen_bad_a11y",
            name: "Inaccessible Screen",
            route: "/bad",
            elements: [
                UIElementDescriptor(id: "btn_hidden", type: .button, accessibilityIdentifier: "", accessibilityLabel: nil)
            ]
        )

        let violations = validator.validate(screen: nonCompliantScreen)

        XCTAssertFalse(violations.isEmpty)
        XCTAssertTrue(violations.contains { $0.issueType.contains("Identifier") || $0.issueType.contains("Label") })
    }

    func testTestGenerationEngine_SynthesizesFunctionalUIAndRegressionTests() {
        let engine = TestGenerationEngine()
        let screens = ScreenRegistry.shared.allScreens
        let journeys = ScreenRegistry.shared.allJourneys

        let plan = engine.generateTests(for: screens, journeys: journeys)

        XCTAssertGreaterThan(plan.testCases.count, 0)
        XCTAssertGreaterThan(plan.functionalTests.count, 0)
        XCTAssertGreaterThan(plan.uiTests.count, 0)
        XCTAssertGreaterThan(plan.journeyTests.count, 0)
    }

    func testDefectCatalog_LearnsDefectsAndGeneratesRegressionTests() {
        let catalog = DefectCatalog.shared
        let defects = catalog.allDefects

        XCTAssertGreaterThan(defects.count, 0)

        let regressionSuite = catalog.generateRegressionSuite()
        XCTAssertEqual(regressionSuite.count, defects.count)
        XCTAssertTrue(regressionSuite.allSatisfy { $0.category == .regression })
    }

    func testAIQualityAnalyzer_IdentifiesCoverageGapsAndUnexecutableTests() {
        let analyzer = AIQualityAnalyzer()
        let screens = ScreenRegistry.shared.allScreens
        let journeys = ScreenRegistry.shared.allJourneys
        let defects = DefectCatalog.shared.allDefects

        let report = analyzer.analyzeQuality(screens: screens, journeys: journeys, existingTests: [], defects: defects)

        XCTAssertGreaterThan(report.coverageGaps.count, 0)
        XCTAssertGreaterThan(report.unexecutableTests.count, 0)
        // Ensure unexecutable tests are explicitly listed with reasons
        XCTAssertTrue(report.unexecutableTests.contains { $0.reason.contains("sensor") })
    }
}
