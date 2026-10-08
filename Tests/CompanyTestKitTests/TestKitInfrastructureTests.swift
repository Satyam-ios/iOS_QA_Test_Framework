import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class TestKitInfrastructureTests: XCTestCase {

    private actor CounterBox {
        var count = 0
        func setCount(_ val: Int) { count = val }
        func getCount() -> Int { count }
    }

    func testAsyncTestHelpers_WhenConditionSucceeds_CompletesWithoutError() async throws {
        let box = CounterBox()
        Task {
            try? await Task.sleep(nanoseconds: 20_000_000)
            await box.setCount(5)
        }

        try await AsyncTestHelpers.waitUntil(timeout: 1.0, message: "Count did not reach 5") {
            await box.getCount() == 5
        }
        let finalCount = await box.getCount()
        XCTAssertEqual(finalCount, 5)
    }

    func testAsyncTestHelpers_WhenConditionNeverMet_ThrowsTimeoutError() async {
        do {
            try await AsyncTestHelpers.waitUntil(timeout: 0.1, pollingInterval: 0.02, message: "Always false") {
                false
            }
            XCTFail("Expected timeout error")
        } catch let AsyncTestHelpers.TimeoutError.timedOut(msg) {
            XCTAssertEqual(msg, "Always false")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testQualityGateEvaluator_WhenAllTestsPass_YieldsReleaseReady() {
        let evaluator = QualityGateEvaluator()
        let results = [
            TestCaseResult(name: "test1", suite: "SuiteA", category: .unit, status: .passed, duration: 0.001),
            TestCaseResult(name: "test2", suite: "SuiteB", category: .api, status: .passed, duration: 0.002)
        ]

        let report = evaluator.evaluate(results: results)
        XCTAssertEqual(report.releaseStatus, .releaseReady)
        XCTAssertEqual(report.passRatePercentage, 100.0)
        XCTAssertTrue(report.blockingReasons.isEmpty)
    }

    func testQualityGateEvaluator_WhenTestFails_YieldsReleaseBlocked() {
        let evaluator = QualityGateEvaluator()
        let results = [
            TestCaseResult(name: "test1", suite: "SuiteA", category: .unit, status: .passed, duration: 0.001),
            TestCaseResult(name: "test2", suite: "SuiteB", category: .api, status: .failed, duration: 0.002, failureReason: "HTTP 500", classification: .bug)
        ]

        let report = evaluator.evaluate(results: results)
        XCTAssertEqual(report.releaseStatus, .releaseBlocked)
        XCTAssertEqual(report.failedTests, 1)
        XCTAssertFalse(report.blockingReasons.isEmpty)
    }

    func testMockNetworkMonitor_TogglesConnectivity() {
        let monitor = MockNetworkMonitor(isConnected: true)
        XCTAssertTrue(monitor.isConnected)

        monitor.setConnected(false)
        XCTAssertFalse(monitor.isConnected)

        monitor.setCellular(true)
        XCTAssertTrue(monitor.isCellular)
    }

    func testMockStorage_WhenShouldThrowError_FailsAsExpected() async {
        let storage = MockStorage()
        await storage.setShouldThrowError(true)

        do {
            try await storage.save("TestValue", forKey: "key")
            XCTFail("Expected simulated storage failure")
        } catch let appError as AppError {
            if case .storage(let reason) = appError {
                XCTAssertEqual(reason, "Simulated storage failure")
            } else {
                XCTFail("Expected storage case")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
