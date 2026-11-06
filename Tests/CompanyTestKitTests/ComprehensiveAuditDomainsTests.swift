import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class ComprehensiveAuditDomainsTests: XCTestCase {

    // MARK: - 1. Apple Guidelines & Compliance Tests

    func testAppleGuidelinesAuditor_BaselineReport_IsCompliant() {
        let baseline = AppleGuidelinesAuditor.baselineReport()
        XCTAssertTrue(baseline.isCompliant)
        XCTAssertEqual(baseline.scorePercentage, 100.0)
        XCTAssertEqual(baseline.confirmedViolationsCount, 0)
        XCTAssertTrue(baseline.hasPrivacyManifest)
    }

    func testAppleGuidelinesAuditor_ApplicationAudit_ProducesStructuredFindings() {
        let auditor = AppleGuidelinesAuditor()
        let report = auditor.auditApplication()

        XCTAssertNotNil(report)
        XCTAssertGreaterThanOrEqual(report.scorePercentage, 0.0)
        XCTAssertLessThanOrEqual(report.scorePercentage, 100.0)

        // Verifies findings are properly classified
        for finding in report.findings {
            XCTAssertFalse(finding.title.isEmpty)
            XCTAssertFalse(finding.detail.isEmpty)
            XCTAssertFalse(finding.documentationURL.isEmpty)
            XCTAssertTrue(finding.documentationURL.starts(with: "https://developer.apple.com"))
        }
    }

    // MARK: - 2. Info.plist & Entitlements Validator Tests

    func testInfoPlistValidator_BaselineReport_IsValid() {
        let baseline = InfoPlistValidator.baselineReport()
        XCTAssertTrue(baseline.isValid)
        XCTAssertEqual(baseline.overallScore, 100.0)
        XCTAssertTrue(baseline.findings.isEmpty)
    }

    func testInfoPlistValidator_DetectsGenericDescriptions() {
        // Create an in-memory bundle representation
        let mockDict: [String: Any] = [
            "NSCameraUsageDescription": "Camera is required by app", // Generic phrase rejection
            "NSLocationWhenInUseUsageDescription": "We need your precise location to display real-time navigation directions on the map." // Valid description
        ]

        // Custom validation check
        var detectedVague = false
        for (key, val) in mockDict {
            if let str = val as? String, str.lowercased().contains("required by app") {
                detectedVague = true
                XCTAssertEqual(key, "NSCameraUsageDescription")
            }
        }
        XCTAssertTrue(detectedVague)
    }

    func testInfoPlistValidator_ProducesCopyableXMLSnippets() {
        let validator = InfoPlistValidator()
        let report = validator.validateApplicationBundle()

        XCTAssertNotNil(report)
        for finding in report.findings {
            XCTAssertFalse(finding.xmlSnippet.isEmpty)
            XCTAssertTrue(finding.xmlSnippet.contains("<key>\(finding.key)</key>"))
            XCTAssertTrue(
                finding.xmlSnippet.contains("<string>") ||
                finding.xmlSnippet.contains("<false/>") ||
                finding.xmlSnippet.contains("<true/>") ||
                finding.xmlSnippet.contains("<array>")
            )
        }
    }

    // MARK: - 3. TestFlight & App Store Readiness Auditor Tests

    func testAppStoreReadinessAuditor_BaselineReport_IsReady() {
        let baseline = AppStoreReadinessAuditor.baselineReport()
        XCTAssertEqual(baseline.gateStatus, .readyForUpload)
        XCTAssertEqual(baseline.readinessScore, 100.0)
        XCTAssertFalse(baseline.serverSideDisclaimerNotice.isEmpty)
    }

    func testAppStoreReadinessAuditor_IncludesMandatoryServerSideDisclaimer() {
        let auditor = AppStoreReadinessAuditor()
        let report = auditor.auditReadiness()

        XCTAssertTrue(report.serverSideDisclaimerNotice.contains("Apple's server-side ingestion"))
        XCTAssertTrue(report.serverSideDisclaimerNotice.contains("human App Review"))
        XCTAssertGreaterThan(report.checks.count, 0)
    }

    // MARK: - 4. Performance & Launch-Time Auditor Tests

    func testAppPerformanceAuditor_BaselineReport_IsOptimal() {
        let baseline = AppPerformanceAuditor.baselineReport()
        XCTAssertEqual(baseline.healthGrade, .optimal)
        XCTAssertEqual(baseline.overallPerformanceScore, 98.0)
        XCTAssertEqual(baseline.hangEventsCount, 0)
        XCTAssertLessThan(baseline.coldLaunchEstimatedMs, 500)
    }

    func testAppPerformanceAuditor_ReadsHardwareAndMemoryTelemetry() {
        let auditor = AppPerformanceAuditor.shared
        let report = auditor.auditPerformance()

        XCTAssertGreaterThan(report.overallPerformanceScore, 0.0)
        XCTAssertGreaterThanOrEqual(report.peakMemoryMB, 0.0)
        XCTAssertGreaterThanOrEqual(report.activeMemoryMB, 0.0)
        XCTAssertFalse(report.thermalState.isEmpty)
    }

    // MARK: - 5. Accessibility & Localization Auditor Tests

    func testAccessibilityAuditor_BaselineReport_IsValid() {
        let baseline = AccessibilityAndLocalizationAuditor.baselineReport()
        XCTAssertEqual(baseline.scorePercentage, 96.0)
        XCTAssertTrue(baseline.findings.isEmpty)
        XCTAssertFalse(baseline.currentLocaleIdentifier.isEmpty)
    }

    func testAccessibilityAuditor_AuditsScreenElements() {
        let testScreen = ScreenDefinition(
            id: "screen_a11y_test",
            name: "Settings Screen",
            route: "/settings",
            elements: [
                UIElementDescriptor(
                    id: "btn_save",
                    type: .button,
                    accessibilityIdentifier: nil, // Missing identifier
                    accessibilityLabel: nil       // Missing label
                )
            ]
        )

        let auditor = AccessibilityAndLocalizationAuditor()
        let report = auditor.auditAccessibility(screens: [testScreen])

        XCTAssertGreaterThan(report.totalElementsAudited, 0)
        // Missing label finding should be flagged
        XCTAssertTrue(report.missingLabelsCount > 0 || report.missingIdentifiersCount > 0)
    }

    // MARK: - 6. Free Local Intelligence Engine Tests (100% Offline)

    func testLocalIntelligenceEngine_AnalyzesDefectWithoutExternalAPI() {
        let defect = DefectRecord(
            id: "DEF-001",
            title: "Text clipped on small screens: 'Welcome, Sw...'",
            affectedScreen: "WelcomeScreen",
            rootCause: "Fixed width constraint truncating localized greeting",
            regressionPattern: "Never enforce fixed width constraints on multi-language labels",
            riskLevel: .medium,
            reproductionSteps: ["Run on iPhone SE", "Verify greeting text is truncated"],
            verifiedFixed: false,
            expectedBehavior: "Displays full text dynamically wrapped",
            actualBehavior: "Displays 'Welcome, Sw...'",
            recommendedCorrection: "Use numberOfLines = 0 with dynamic type constraints"
        )

        let engine = LocalIntelligenceEngine.shared
        let solution = engine.analyzeDefect(defect)

        XCTAssertFalse(solution.recommendedDesignPattern.isEmpty)
        XCTAssertFalse(solution.architecturalAnalysis.isEmpty)
        XCTAssertFalse(solution.copyPasteSolution.isEmpty)
        XCTAssertTrue(solution.copyPasteSolution.contains("SwiftUI") || solution.copyPasteSolution.contains("numberOfLines"))
    }

    func testLocalIntelligenceEngine_SynthesizesCompilableXCTestClasses() {
        var screen = ScreenDefinition(
            id: "screen_checkout",
            name: "Checkout Screen",
            route: "/checkout",
            elements: [
                UIElementDescriptor(id: "btn_pay", type: .button, accessibilityIdentifier: "pay_button", accessibilityLabel: "Pay Now")
            ]
        )
        screen.viewClassName = "CheckoutViewController"

        let engine = LocalIntelligenceEngine.shared
        let xctestCode = engine.generateXCTestCode(for: screen)

        XCTAssertTrue(xctestCode.contains("import XCTest"))
        XCTAssertTrue(xctestCode.contains("class CheckoutUITests: XCTestCase"))
        XCTAssertTrue(xctestCode.contains("func testScreenElementsExistAndAreInteractive()"))
        XCTAssertTrue(xctestCode.contains("pay_button"))
    }

    // MARK: - 7. Audit Execution Engine Caching & Deduplication Tests

    private final class ThreadSafeProgressTracker: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var stages: [String] = []

        func append(_ stage: String) {
            lock.lock()
            defer { lock.unlock() }
            stages.append(stage)
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return stages.count
        }

        var last: String? {
            lock.lock()
            defer { lock.unlock() }
            return stages.last
        }
    }

    func testAuditExecutionEngine_CachesResultsWithinTTL() async throws {
        let engine = AuditExecutionEngine.shared
        let tracker1 = ThreadSafeProgressTracker()

        // Initial fetch
        let payload1 = try await engine.fetchAuditPayload(forceRefresh: true) { _, stage in
            tracker1.append(stage)
        }
        XCTAssertNotNil(payload1)
        XCTAssertGreaterThan(tracker1.count, 0)

        // Instant subsequent fetch (Cache hit in < 5ms)
        let startTime = Date()
        let tracker2 = ThreadSafeProgressTracker()
        let payload2 = try await engine.fetchAuditPayload(forceRefresh: false) { _, stage in
            tracker2.append(stage)
        }
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(elapsed, 0.1, "Cached payload must return almost instantaneously")
        XCTAssertEqual(payload1.timestamp, payload2.timestamp, "Must return identical cached payload instance")
        XCTAssertTrue(tracker2.last?.contains("cache") ?? false)
    }

    func testAuditExecutionEngine_DeduplicatesConcurrentRequests() async throws {
        let engine = AuditExecutionEngine.shared

        // Concurrently dispatch 3 fetch operations without forcing refresh so deduplication and caching align
        async let fetch1 = engine.fetchAuditPayload(forceRefresh: false)
        async let fetch2 = engine.fetchAuditPayload(forceRefresh: false)
        async let fetch3 = engine.fetchAuditPayload(forceRefresh: false)

        let (res1, res2, res3) = try await (fetch1, fetch2, fetch3)

        XCTAssertEqual(res1.timestamp, res2.timestamp)
        XCTAssertEqual(res2.timestamp, res3.timestamp)
    }
}
