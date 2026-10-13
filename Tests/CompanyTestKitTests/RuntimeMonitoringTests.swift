import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class RuntimeMonitoringTests: XCTestCase {

    override func setUp() {
        super.setUp()
        RuntimeTelemetryStore.shared.clear()
        NetworkTelemetryObserver.shared.clear()
        RuntimeErrorTracker.shared.reset()
        TestExecutionStore.shared.clear()
        DefectCatalog.shared.reset()
    }

    // MARK: - 1. Runtime Telemetry Store Tests

    func testRuntimeTelemetryStore_RecordsAndFiltersEvents() {
        let store = RuntimeTelemetryStore(maxCapacity: 10)

        store.record(
            category: .crash,
            severity: .critical,
            title: "Simulated Crash",
            details: "SIGSEGV at 0x0"
        )
        store.record(
            category: .networkFailure,
            severity: .high,
            title: "Network 500",
            details: "Internal server error"
        )

        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.events(matching: .crash).count, 1)
        XCTAssertEqual(store.events(matching: .networkFailure).count, 1)
        XCTAssertEqual(store.events(atLeast: .critical).count, 1)
    }

    func testRuntimeTelemetryStore_EnforcesCapacityLimit() {
        let store = RuntimeTelemetryStore(maxCapacity: 5)
        for i in 1...10 {
            store.record(category: .unhandledError, severity: .medium, title: "Error \(i)", details: "Details")
        }

        XCTAssertEqual(store.count, 5)
        XCTAssertEqual(store.allEvents.first?.title, "Error 10")
    }

    // MARK: - 2. Crash Monitor Tests

    func testCrashMonitor_RecordsDiagnosticException() {
        let monitor = CrashMonitor.shared
        monitor.recordDiagnosticException(name: "NSInvalidArgumentException", reason: "Index out of bounds")

        let crashes = RuntimeTelemetryStore.shared.events(matching: .crash)
        XCTAssertFalse(crashes.isEmpty)
        XCTAssertTrue(crashes.first?.title.contains("NSInvalidArgumentException") == true)
        XCTAssertTrue(crashes.first?.details.contains("Index out of bounds") == true)
    }

    // MARK: - 3. Runtime Error Tracker & Loop Detection

    func testRuntimeErrorTracker_DetectsRepeatedFailureLoop() {
        let tracker = RuntimeErrorTracker(loopThresholdCount: 3, loopThresholdWindow: 5.0)

        enum SampleTestError: Error, LocalizedError {
            case networkTimeout
            var errorDescription: String? { "The connection timed out." }
        }

        // Trigger 3 identical errors rapidly
        tracker.record(error: SampleTestError.networkTimeout, source: "CheckoutViewModel.swift", line: 42)
        tracker.record(error: SampleTestError.networkTimeout, source: "CheckoutViewModel.swift", line: 42)
        tracker.record(error: SampleTestError.networkTimeout, source: "CheckoutViewModel.swift", line: 42)

        let loopEvents = RuntimeTelemetryStore.shared.events(matching: .repeatedFailurePattern)
        XCTAssertFalse(loopEvents.isEmpty, "Should detect repeated retry loop after 3 identical rapid errors")
        XCTAssertTrue(loopEvents.first?.title.contains("Suspicious Failure Loop Detected") == true)
    }

    // MARK: - 4. Network Telemetry & Contract Validation

    func testNetworkTelemetryObserver_DistinguishesClientDefectFromBackendOutage() {
        let observer = NetworkTelemetryObserver.shared

        // Record Client Defect (HTTP 400)
        observer.record(
            endpoint: "/api/v1/user",
            method: "POST",
            statusCode: 400,
            duration: 0.12
        )

        // Record Backend Outage (HTTP 503)
        observer.record(
            endpoint: "/api/v1/feed",
            method: "GET",
            statusCode: 503,
            duration: 0.45
        )

        let events = observer.events
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.failureOrigin, .clientDefect)
        XCTAssertEqual(events.last?.failureOrigin, .backendOutage)

        let storeFailures = RuntimeTelemetryStore.shared.events(matching: .networkFailure)
        XCTAssertEqual(storeFailures.count, 2)
    }

    func testNetworkTelemetryObserver_RecordsContractViolation() {
        let observer = NetworkTelemetryObserver.shared
        struct MissingFieldError: Error, LocalizedError {
            var errorDescription: String? { "Key 'userId' not found." }
        }

        observer.recordContractViolation(
            endpoint: "/api/v1/profile",
            targetType: "UserProfileResponse",
            decodingError: MissingFieldError()
        )

        let violations = RuntimeTelemetryStore.shared.events(matching: .contractViolation)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations.first?.title.contains("UserProfileResponse") == true)
    }

    // MARK: - 5. Memory Performance Monitor

    func testMemoryPerformanceMonitor_HandlesMemoryWarning() {
        let monitor = MemoryPerformanceMonitor.shared
        monitor.handleMemoryWarning()

        XCTAssertEqual(monitor.totalWarningsCount, 1)
        let memoryEvents = RuntimeTelemetryStore.shared.events(matching: .memoryWarning)
        XCTAssertFalse(memoryEvents.isEmpty)
        XCTAssertTrue(memoryEvents.first?.title.contains("Memory Warning") == true)
    }

    // MARK: - 6. Main Thread Hang Watchdog

    func testMainThreadHangWatchdog_RecordsStalls() {
        let watchdog = MainThreadHangWatchdog.shared
        watchdog.recordStall(duration: 0.65, source: "UserProfileViewController.swift:L99")

        let hangEvents = RuntimeTelemetryStore.shared.events(matching: .mainThreadHang)
        XCTAssertFalse(hangEvents.isEmpty)
        XCTAssertEqual(hangEvents.first?.severity, .critical)
        XCTAssertTrue(hangEvents.first?.details.contains("0.65") == true)
    }

    // MARK: - 7. Maintainability Scoring Engine

    func testMaintainabilityScoringEngine_CalculatesScoreAndGrade() {
        let engine = MaintainabilityScoringEngine()

        let staticFindings = [
            StaticCodeFinding(ruleId: "UNSAFE_FORCE_UNWRAP", message: "Force unwrap", severity: .high, sourceFile: "App.swift", sourceLine: 10, codeSnippet: "val!", recommendation: "guard"),
            StaticCodeFinding(ruleId: "MAIN_THREAD_DEADLOCK", message: "DispatchQueue sync", severity: .critical, sourceFile: "App.swift", sourceLine: 20, codeSnippet: "sync", recommendation: "async")
        ]

        let securityFindings = [
            SecurityFinding(category: .credentialLeak, severity: .critical, sourceFile: "Keys.swift", sourceLine: 5, evidence: "sk_live_123", recommendation: "Secure storage")
        ]

        let report = engine.evaluateProject(
            targetName: "TestApp",
            scannedFileCount: 5,
            staticFindings: staticFindings,
            securityFindings: securityFindings
        )

        // Deductions: Force Unwrap (-5) + Deadlock (-10) + Security (-15) = 30 points deducted. Score: 70
        XCTAssertEqual(report.finalScore, 70)
        XCTAssertEqual(report.grade, .needsAttention)
        XCTAssertEqual(report.deductions.count, 3)
    }

    // MARK: - 8. Senior Project Auditor (10 Sections)

    func testSeniorProjectAuditor_ProducesComprehensive10SectionReport() {
        let auditor = SeniorProjectAuditor()
        let report = auditor.auditProject(
            screens: ScreenRegistry.shared.allScreens,
            journeys: ScreenRegistry.shared.allJourneys,
            executedTests: [],
            defects: DefectCatalog.shared.allDefects
        )

        XCTAssertFalse(report.appName.isEmpty)
        XCTAssertEqual(report.supportedPlatforms, ["iOS 15.0+", "macOS 12.0+"])
        XCTAssertEqual(report.categoryStatuses.count, 9)
        XCTAssertNotNil(report.categoryStatuses["Static Code Analysis"])
        XCTAssertNotNil(report.categoryStatuses["Runtime Monitoring"])
        XCTAssertNotNil(report.categoryStatuses["Security & Privacy"])
        XCTAssertNotNil(report.categoryStatuses["Overall Quality Gate"])

        // Screen-by-Screen audit reports
        XCTAssertEqual(report.screenAudits.count, ScreenRegistry.shared.allScreens.count)

        // Senior Developer Quality Metrics
        XCTAssertGreaterThan(report.overallQualityPercentage, 0.0)
        XCTAssertFalse(report.overallQualityGrade.isEmpty)
        XCTAssertEqual(report.pillarScores.count, 6)
        XCTAssertEqual(report.openDefectsCount, 0) // Zero defects by default

        // Maintainability report
        XCTAssertGreaterThanOrEqual(report.maintainability.finalScore, 0)
        XCTAssertLessThanOrEqual(report.maintainability.finalScore, 100)
    }

    func testSeniorScreenQualityInspector_GeneratesFull5PillarAuditAndUnitTests() {
        let screen = ScreenDefinition(
            id: "screen_appliance_details",
            name: "Appliance Scan Details",
            route: "/appliances/scan_details",
            elements: [
                UIElementDescriptor(id: "btn_pair", type: .button, accessibilityIdentifier: "pair_btn", accessibilityLabel: "Connect & Pair"),
                UIElementDescriptor(id: "lbl_battery", type: .label, accessibilityIdentifier: "battery_lbl", accessibilityLabel: "Battery Level")
            ],
            apiDependencies: ["/api/v1/hardware/connect"],
            sourceFile: "HardwareViewController.swift",
            viewClassName: "AppliaceScanDetailsViewController"
        )

        let inspector = SeniorScreenQualityInspector()
        let audit = inspector.inspect(screen: screen)

        XCTAssertEqual(audit.screenId, "screen_appliance_details")
        XCTAssertEqual(audit.viewClassName, "AppliaceScanDetailsViewController")
        XCTAssertGreaterThanOrEqual(audit.overallScore, 90.0)
        XCTAssertTrue(audit.overallGrade.contains("A"))

        // Verify 5 Pillars
        XCTAssertEqual(audit.securityChecks.count, 4)
        XCTAssertEqual(audit.memoryChecks.count, 4)
        XCTAssertEqual(audit.errorHandlingChecks.count, 5)
        XCTAssertEqual(audit.concurrencyChecks.count, 3)

        // Verify 7 Unit Tests for senior iOS developer
        XCTAssertEqual(audit.unitTestCases.count, 7)
        let testCategories = audit.unitTestCases.map { $0.category }
        XCTAssertTrue(testCategories.contains("Memory & Leaks"))
        XCTAssertTrue(testCategories.contains("Concurrency & Threading"))
        XCTAssertTrue(testCategories.contains("View Lifecycle"))
        XCTAssertTrue(testCategories.contains("Dependency Injection"))

        // Assert code snippet exists for memory retain cycles
        let memoryTest = audit.unitTestCases.first { $0.category == "Memory & Leaks" }
        XCTAssertNotNil(memoryTest)
        XCTAssertTrue(memoryTest?.codeSnippet.contains("weak var weakSut") == true)
        XCTAssertTrue(memoryTest?.assertions.first?.contains("XCTAssertNil(weakSut") == true)
    }

    // MARK: - 9. Test Execution Store

    func testTestExecutionStore_TruthfulTestOutcomes() {
        let store = TestExecutionStore.shared
        XCTAssertFalse(store.hasExecutedTests)

        let result = TestCaseResult(name: "Test_Authentication_Flow", suite: "AuthTests", category: .unit, status: .passed, duration: 0.02)
        store.recordResult(result)

        XCTAssertTrue(store.hasExecutedTests)
        XCTAssertEqual(store.allResults.count, 1)
        XCTAssertEqual(store.allResults.first?.name, "Test_Authentication_Flow")
    }

    // MARK: - 10. InAppTestCenterView Loader & UX Tests

    func testInAppTestCenterView_InstantiatesWithLoaderAndSections() {
        let view = InAppTestCenterView()
        XCTAssertNotNil(view)

        // Verify active audit sections
        let sections = InAppTestCenterView.ActiveAuditSection.allCases
        XCTAssertEqual(sections.count, 7)
        XCTAssertTrue(sections.contains(.defects))
        XCTAssertTrue(sections.contains(.screens))
        XCTAssertTrue(sections.contains(.antiHacking))
        XCTAssertTrue(sections.contains(.architecture))
    }
}

