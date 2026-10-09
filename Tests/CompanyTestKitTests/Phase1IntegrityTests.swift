import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class Phase1IntegrityTests: XCTestCase {

    // MARK: - 1. Defect Lifecycle & Invariants Tests

    func testDefectLifecycle_CannotVerify_WithoutRegressionTest() {
        let catalog = DefectCatalog.shared
        let defectId = "DEF-INVARIANT-\(UUID().uuidString.prefix(6))"
        let defect = DefectRecord(
            id: defectId,
            title: "Crash on invalid token format",
            affectedScreen: "Login",
            rootCause: "Unchecked unwrap in parseToken",
            regressionPattern: "TokenFormatCrash",
            riskLevel: .critical,
            reproductionSteps: ["Launch", "Enter invalid token", "Submit"],
            verifiedFixed: false,
            status: .new,
            severity: .critical,
            category: .crash
        )
        catalog.recordDefect(defect)

        // Attempt to mark as verified without passing test - should fail invariant
        let verifyWithoutProof = catalog.updateStatus(of: defectId, to: .verified, verifiedByTestId: nil)
        XCTAssertFalse(verifyWithoutProof, "Defect cannot transition to verified without a verifying test ID")

        // Should successfully transition through triage -> fixInProgress -> fixedPendingVerification
        XCTAssertTrue(catalog.updateStatus(of: defectId, to: .triaged))
        XCTAssertTrue(catalog.updateStatus(of: defectId, to: .fixInProgress))
        XCTAssertTrue(catalog.updateStatus(of: defectId, to: .fixedPendingVerification))

        // Now verify with proof
        XCTAssertTrue(catalog.updateStatus(of: defectId, to: .verified, verifiedByTestId: "TEST_TOKEN_FORMAT_PASS"))
        let updated = catalog.findDefect(id: defectId)
        XCTAssertEqual(updated?.status, .verified)
        XCTAssertEqual(updated?.linkedRegressionTestId, "TEST_TOKEN_FORMAT_PASS")
    }

    // MARK: - 2. Three-Tier Quality Gate & Contradiction Resolution Tests

    func testQualityGateEvaluator_WhenCriticalDefectOpen_BlocksReleaseReadiness_EvenIfTestsPass() {
        let passingResult = TestCaseResult(
            id: "TC-1",
            name: "testHappyPath",
            suite: "CheckoutTests",
            category: .unit,
            status: .passed,
            duration: 0.05
        )

        let openCriticalDefect = DefectRecord(
            id: "DEF-CRIT-99",
            title: "Payment token exposed in log",
            affectedScreen: "Checkout",
            rootCause: "Plaintext print in TokenManager",
            regressionPattern: "TokenLeakPattern",
            riskLevel: .critical,
            status: .new,
            severity: .critical,
            category: .security
        )

        let evaluation = QualityGateEvaluator.evaluateComprehensive(
            results: [passingResult],
            defects: [openCriticalDefect]
        )

        // All test suite cases passed (Technical Quality passes)
        XCTAssertEqual(evaluation.technicalQuality.passRate, 100.0)
        XCTAssertEqual(evaluation.technicalQuality.failedCount, 0)
        XCTAssertTrue(evaluation.technicalQuality.isTechnicallyPassing)

        // But Release Readiness MUST be BLOCKED due to open critical defect!
        XCTAssertEqual(evaluation.releaseReadiness.status, .releaseBlocked)
        XCTAssertFalse(evaluation.releaseReadiness.blockingReasons.isEmpty)

        // QA Handoff is also blocked
        XCTAssertEqual(evaluation.qaHandoff.status, .blockedForQA)
        XCTAssertFalse(evaluation.qaHandoff.blockingReasons.isEmpty)
    }

    func testQualityGateEvaluator_WhenLowDefectsAccepted_PermitsQAHandoffWithCaveats() {
        let passingResult = TestCaseResult(
            id: "TC-2",
            name: "testSettingsLayout",
            suite: "SettingsTests",
            category: .ui,
            status: .passed,
            duration: 0.1
        )

        let minorDefect = DefectRecord(
            id: "DEF-MIN-01",
            title: "Minor label padding offset",
            affectedScreen: "Settings",
            rootCause: "Padding 12pt instead of 16pt",
            regressionPattern: "PaddingDiscrepancy",
            riskLevel: .low,
            status: .acceptedRisk,
            severity: .low,
            category: .ui
        )

        let evaluation = QualityGateEvaluator.evaluateComprehensive(
            results: [passingResult],
            defects: [minorDefect]
        )

        XCTAssertEqual(evaluation.qaHandoff.status, .approvedWithCaveats)
        XCTAssertEqual(evaluation.releaseReadiness.status, .releaseReady)
    }

    // MARK: - 3. Test Generation & Safe Bulk Deletion Tests

    func testSafeBulkDeletion_PreservesRegressionSuite() {
        let engine = TestGenerationEngine()
        let screens = ScreenRegistry.shared.allScreens
        let plan = engine.generateTests(for: screens)

        // Inject regression test
        let regressionCase = GeneratedTestCase(
            id: "REG-DEF-01",
            title: "Regression_LoginCrashOnEmptyPassword",
            category: .regression,
            screenId: "screen_login",
            intent: "Ensure no crash on empty password submission",
            precondition: "Login screen loaded",
            steps: ["Tap login with empty password"],
            expectedOutcome: "Validation error without crash",
            isExecutable: true,
            executionStatus: .readyToExecute
        )

        var planWithRegression = plan
        planWithRegression.testCases.append(regressionCase)

        XCTAssertEqual(planWithRegression.regressionTests.count, 1)

        // Execute bulk delete with scope = .all, preserving regression tests
        let result = engine.deleteTestCases(from: planWithRegression, inScope: .all, preserveRegressionCases: true)

        XCTAssertEqual(result.preservedRegressionCount, 1)
        XCTAssertEqual(result.updatedPlan.testCases.count, 1)
        XCTAssertEqual(result.updatedPlan.testCases.first?.id, "REG-DEF-01")
        XCTAssertEqual(result.deletedCount, plan.testCases.count)
    }

    func testSafeBulkDeletion_ByScreen_DeletesOnlyTargetScreen() {
        let engine = TestGenerationEngine()
        let screens = ScreenRegistry.shared.allScreens
        let plan = engine.generateTests(for: screens)

        guard let firstScreen = screens.first else {
            XCTFail("Expected at least one screen in registry")
            return
        }

        let targetScreenId = firstScreen.id
        let screenCountBefore = plan.testCases.filter { $0.screenId == targetScreenId }.count
        XCTAssertGreaterThan(screenCountBefore, 0)

        let result = engine.deleteTestCases(from: plan, inScope: .byScreen(targetScreenId))

        XCTAssertEqual(result.deletedCount, screenCountBefore)
        XCTAssertEqual(result.updatedPlan.testCases.filter { $0.screenId == targetScreenId }.count, 0)
        XCTAssertGreaterThan(result.updatedPlan.testCases.count, 0)
    }
}
