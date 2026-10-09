import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class Phase3SecurityAndSimulationTests: XCTestCase {

    // MARK: - 1. Security Audit Engine Tests

    func testSecurityAuditEngine_DetectsHardcodedSecretsAndInsecureStorage() {
        let vulnerableSource = """
        import Foundation

        class AuthHelper {
            let secret_key = "mock_secret_vault_token_abcdef12345678"

            func saveToken(token: String) {
                UserDefaults.standard.set(token, forKey: "authToken_password_secret")
            }

            func fetchInsecure() {
                let url = "http://api.insecurebackend.com/v1/data"
                print(url)
            }
        }
        """

        let engine = SecurityAuditEngine()
        let findings = engine.auditSourceCode(content: vulnerableSource, filePath: "Sources/Auth/AuthHelper.swift")

        XCTAssertFalse(findings.isEmpty)

        // Verify Credential Leak finding
        let secretFinding = findings.first { $0.category == .credentialLeak }
        XCTAssertNotNil(secretFinding)
        XCTAssertEqual(secretFinding?.severity, .critical)

        // Verify Insecure Storage finding
        let storageFinding = findings.first { $0.category == .insecureStorage }
        XCTAssertNotNil(storageFinding)
        XCTAssertEqual(storageFinding?.severity, .critical)
        XCTAssertTrue(storageFinding?.recommendation.contains("KeychainManager") ?? false)

        // Verify Insecure Transport finding
        let transportFinding = findings.first { $0.category == .insecureTransport }
        XCTAssertNotNil(transportFinding)
        XCTAssertEqual(transportFinding?.severity, .high)

        let report = SecurityAuditReport(scannedFilesCount: 1, findings: findings)
        XCTAssertFalse(report.isPassing)
        XCTAssertEqual(report.criticalCount, 2)
        XCTAssertEqual(report.highCount, 1)
    }

    // MARK: - 2. Apple Compliance Checker Tests

    func testAppleComplianceChecker_FlagsMissingInfoPlistDescriptionsAndPlaceholders() {
        let checker = AppleComplianceChecker()
        let testCode = """
        import UIKit
        import AVFoundation

        class ScannerView: UIViewController {
            var device: AVCaptureDevice?
            let titleLabel = "Lorem ipsum dolor sit amet"
        }
        """

        let issues = checker.auditSourceCode(content: testCode, filePath: "Sources/ScannerView.swift")

        // Guideline 2.1 placeholder text
        XCTAssertTrue(issues.contains { $0.guideline.contains("2.1") })

        // Check Guideline 5.1.1 Info.plist enforcement
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ComplianceTest_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sampleSwiftPath = tempDir.appendingPathComponent("Test.swift")
        try? testCode.write(to: sampleSwiftPath, atomically: true, encoding: .utf8)

        // Missing NSCameraUsageDescription in Info.plist dictionary
        let emptyInfoPlist: [String: Any] = [:]
        let report = checker.auditProject(directoryURL: tempDir, infoPlistDictionary: emptyInfoPlist)

        XCTAssertTrue(report.issues.contains { $0.guideline.contains("5.1.1") })
        XCTAssertFalse(report.hasPrivacyManifest)
        XCTAssertEqual(report.status, .nonCompliant)
    }

    // MARK: - 3. Network Simulation Engine Tests

    func testNetworkSimulationEngine_SimulatesOfflineModeAndHTTPStatus() async {
        let engine = NetworkSimulationEngine.shared
        defer { engine.reset() }

        // Test Offline Mode
        engine.setScenario(.offline)
        do {
            try await engine.processRequest()
            XCTFail("Offline scenario should throw NetworkError.offline")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.offline)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Test HTTP 500
        engine.setScenario(.server500)
        do {
            try await engine.processRequest()
            XCTFail("Server 500 scenario should throw NetworkError.serverError(statusCode: 500)")
        } catch let error as NetworkError {
            if case .serverError(let code, _) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected serverError(500), got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(engine.metrics.failures, 2)
    }

    // MARK: - 4. Runtime Diagnostics Monitor Tests

    func testRuntimeDiagnosticsMonitor_CapturesSnapshotAndHonestViability() {
        let monitor = RuntimeDiagnosticsMonitor.shared
        let snapshot = monitor.captureSnapshot()

        // Diagnostics metrics
        XCTAssertGreaterThanOrEqual(snapshot.memoryUsageMegabytes, 0.0)

        // Evaluate hardware viability
        let bleViability = monitor.evaluateHardwareViability(for: .physicalBLEPeripheral)
        if monitor.isSimulator {
            XCTAssertFalse(bleViability.isViable)
            if case .unexecutable(let reason) = bleViability {
                XCTAssertTrue(reason.contains("simulator"))
            }
        } else {
            XCTAssertTrue(bleViability.isViable)
        }
    }
}
