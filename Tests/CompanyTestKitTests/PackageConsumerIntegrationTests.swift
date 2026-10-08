import XCTest
import CompanyiOSKit
import CompanyTestKit

/// Integration tests simulating an external consuming iOS application importing `CompanyTestKit`.
/// Verifies that all required symbols are publicly visible, accessible, and functional.
final class PackageConsumerIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ScreenRegistry.shared.reset()
    }

    // MARK: - 1. One-Line Onboarding Facade Tests

    func testConsumer_OneLineStart_InitializesSuccessfully() {
        // Simulates host app calling CompanyTestCenter.start() in App.init() or AppDelegate
        let center = CompanyTestCenter.start()
        XCTAssertTrue(center.isRunning, "CompanyTestCenter must be marked running after start()")
        XCTAssertTrue(CompanyTestCenter.shared.isRunning)
    }

    // MARK: - 2. Symbol Visibility Regression Guard Tests

    func testConsumer_CanAccessCoreTypes_WithoutScopeErrors() async {
        // Verifies the exact 5 symbols reported in the compiler error report are completely in scope:
        // 1. ScreenRegistry
        let screenRegistry = ScreenRegistry.shared
        XCTAssertFalse(screenRegistry.allScreens.isEmpty, "ScreenRegistry must expose discovered screens")

        // 2. TestGenerationEngine
        let engine = TestGenerationEngine()
        let plan = engine.generateTests(for: screenRegistry.allScreens, journeys: screenRegistry.allJourneys)
        XCTAssertGreaterThan(plan.testCases.count, 0, "TestGenerationEngine must generate test cases")

        // 3. JourneyRunner
        let runner = JourneyRunner(screens: screenRegistry.allScreens)
        if let firstJourney = screenRegistry.allJourneys.first {
            let result = await runner.execute(journey: firstJourney)
            XCTAssertTrue(result.isSuccessful, "JourneyRunner should execute valid baseline journey")
        }

        // 4. DefectCatalog
        let catalog = DefectCatalog.shared
        XCTAssertFalse(catalog.allDefects.isEmpty, "DefectCatalog must expose registered defects")

        // 5. AIQualityAnalyzer
        let analyzer = AIQualityAnalyzer()
        let analysis = analyzer.analyzeQuality(screens: screenRegistry.allScreens, journeys: screenRegistry.allJourneys)
        XCTAssertGreaterThan(analysis.overallConfidenceScore, 0.0, "AIQualityAnalyzer should compute confidence score")
    }

    // MARK: - 3. Custom Screen & Journey Registration Tests

    func testConsumer_CanRegisterCustomScreensAndJourneys() {
        let customScreenId = "screen_checkout_v2"
        CompanyTestCenter.register(
            id: customScreenId,
            name: "Checkout Screen V2",
            route: "/checkout/v2",
            elements: [
                UIElementDescriptor(id: "btn_place_order", type: .button, accessibilityIdentifier: "place_order_btn")
            ],
            apiDependencies: ["/api/v2/orders"]
        )

        let retrievedScreen = ScreenRegistry.shared.screen(withId: customScreenId)
        XCTAssertNotNil(retrievedScreen, "ScreenRegistry must contain newly registered custom screen")
        XCTAssertEqual(retrievedScreen?.name, "Checkout Screen V2")
        XCTAssertEqual(retrievedScreen?.elements.count, 1)

        let customJourney = UserJourney(
            id: "journey_custom_order",
            name: "Order Placement Flow",
            initialRoute: "/checkout/v2",
            steps: [
                JourneyStep(
                    stepNumber: 1,
                    screenId: customScreenId,
                    actionName: "Tap Place Order",
                    targetElementId: "btn_place_order",
                    expectedRoute: "/order_complete"
                )
            ]
        )
        CompanyTestCenter.register(journey: customJourney)

        let foundJourney = ScreenRegistry.shared.allJourneys.first(where: { $0.id == "journey_custom_order" })
        XCTAssertNotNil(foundJourney, "ScreenRegistry must contain newly registered custom journey")
    }

    // MARK: - 4. Defect Cataloging & Regression Suite Tests

    func testConsumer_CanRecordDefect_AndSynthesizeRegressionScenario() {
        let defect = DefectRecord(
            id: "DEFECT-CONSUMER-01",
            title: "Memory spike when scrolling catalog",
            affectedScreen: "screen_home",
            rootCause: "Uncached thumbnails retained in memory",
            regressionPattern: "Image cache must evict on memory warning",
            riskLevel: .medium,
            reproductionSteps: ["Scroll 100 rows", "Assert memory < 100MB"],
            verifiedFixed: true
        )

        CompanyTestCenter.record(defect: defect)

        let regressionCases = CompanyTestCenter.runRegressionSuite()
        let matchingRegression = regressionCases.first(where: { $0.id.contains("DEFECT-CONSUMER-01") })
        XCTAssertNotNil(matchingRegression, "DefectCatalog must generate an invariant regression test case for recorded defect")
    }

    // MARK: - 5. Quality Gate Evaluation Tests

    func testConsumer_QualityGateEvaluator_ReflectsTruthfulResults() {
        let passingResult = TestCaseResult(
            id: "TC-01",
            name: "testAuthSuccess",
            suite: "AuthSuite",
            category: .unit,
            status: .passed,
            duration: 0.05
        )

        let reportPass = CompanyTestCenter.evaluateQualityGate(results: [passingResult])
        XCTAssertEqual(reportPass.releaseStatus, .releaseReady)
        XCTAssertEqual(reportPass.passRatePercentage, 100.0)
        XCTAssertTrue(reportPass.blockingReasons.isEmpty)

        let failingResult = TestCaseResult(
            id: "TC-02",
            name: "testPaymentDecline",
            suite: "PaymentSuite",
            category: .api,
            status: .failed,
            duration: 0.12,
            failureReason: "Gateway timeout"
        )

        let reportFail = CompanyTestCenter.evaluateQualityGate(results: [passingResult, failingResult])
        XCTAssertEqual(reportFail.releaseStatus, .releaseBlocked)
        XCTAssertEqual(reportFail.failedTests, 1)
        XCTAssertFalse(reportFail.blockingReasons.isEmpty)
    }

    // MARK: - 6. AI Quality & Unexecutable Tests Verification

    func testConsumer_AIQualityAnalyzer_IdentifiesUnexecutableTestsWithoutFabrication() {
        let analysis = CompanyTestCenter.analyzeQuality()

        // Verify unexecutable hardware tests are acknowledged truthfully rather than faked
        XCTAssertFalse(analysis.unexecutableTests.isEmpty, "Analyzer should identify physical hardware/APNS requirements")
        let hardwareTest = analysis.unexecutableTests.first
        XCTAssertNotNil(hardwareTest?.reason, "Unexecutable test must provide specific factual reason")
    }

    // MARK: - 7. Objective-C Bridge Compatibility

    func testConsumer_ObjcBridge_FunctionsCorrectly() {
        CompanyTestCenterObjc.start()
        CompanyTestCenterObjc.registerScreen(
            id: "screen_objc",
            name: "Objective-C Sample Screen",
            route: "/objc"
        )

        let screen = ScreenRegistry.shared.screen(withId: "screen_objc")
        XCTAssertNotNil(screen, "Screen registered via Objective-C bridge must be present in registry")
        XCTAssertEqual(screen?.name, "Objective-C Sample Screen")
    }
}
