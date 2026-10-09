import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class Phase2DiscoveryTests: XCTestCase {

    // MARK: - 1. ProjectSourceAnalyzer Static Code Scanning Tests

    func testProjectSourceAnalyzer_ParsesSwiftUIViewAndControls() {
        let sampleSwiftCode = """
        import SwiftUI

        struct DeviceSettingsView: View {
            @State private var deviceName = ""
            @State private var isEnabled = true

            var body: some View {
                VStack {
                    TextField("Device Name", text: $deviceName)
                    Toggle("Enable Device", isOn: $isEnabled)
                    Button("Save Settings") {
                        syncSettings()
                    }
                }
            }

            private func syncSettings() {
                let url = "/api/v1/iot/devices/sync"
                print(url)
            }
        }
        """

        let analyzer = ProjectSourceAnalyzer()
        let landscape = analyzer.analyzeSourceCode(content: sampleSwiftCode, filePath: "Sources/IoT/DeviceSettingsView.swift")

        XCTAssertEqual(landscape.screens.count, 1)
        let screen = landscape.screens.first
        XCTAssertEqual(screen?.name, "DeviceSettingsView")
        XCTAssertEqual(screen?.route, "/devicesettings")
        XCTAssertEqual(screen?.discoverySource, .staticSourceAnalysis)
        XCTAssertEqual(screen?.sourceFile, "Sources/IoT/DeviceSettingsView.swift")
        XCTAssertEqual(screen?.sourceLine, 3)

        // Verify detected controls
        XCTAssertEqual(screen?.elements.count, 3)
        XCTAssertTrue(screen?.elements.contains { $0.type == .textField } ?? false)
        XCTAssertTrue(screen?.elements.contains { $0.type == .toggle } ?? false)
        XCTAssertTrue(screen?.elements.contains { $0.type == .button } ?? false)

        // Verify API endpoints
        XCTAssertEqual(landscape.apis.count, 1)
        XCTAssertEqual(landscape.apis.first?.endpoint, "/api/v1/iot/devices/sync")
    }

    func testProjectSourceAnalyzer_DetectsCodeQualityHazardsAndPermissions() {
        let hazardousCode = """
        import UIKit
        import AVFoundation
        import CoreLocation

        class CameraStreamingViewController: UIViewController {
            var camera: AVCaptureDevice!
            var locManager = CLLocationManager()

            override func viewDidLoad() {
                super.viewDidLoad()
                let value = camera!
                DispatchQueue.main.sync {
                    print("dangerous sync")
                }
            }
        }
        """

        let analyzer = ProjectSourceAnalyzer()
        let landscape = analyzer.analyzeSourceCode(content: hazardousCode, filePath: "Sources/Camera/CameraStreamingViewController.swift")

        // Screen detection
        XCTAssertEqual(landscape.screens.count, 1)
        XCTAssertEqual(landscape.screens.first?.name, "CameraStreamingViewController")

        // Permissions detection
        XCTAssertTrue(landscape.permissions.contains { $0.permissionType == "Camera/Mic" })
        XCTAssertTrue(landscape.permissions.contains { $0.permissionType == "Location" })

        // Code quality findings
        XCTAssertTrue(landscape.codeQualityFindings.contains { $0.ruleId == "UNSAFE_FORCE_UNWRAP" })
        XCTAssertTrue(landscape.codeQualityFindings.contains { $0.ruleId == "MAIN_THREAD_DEADLOCK" })
    }

    func testProjectSourceAnalyzer_ReportsNonexistentPathHonestly() {
        let analyzer = ProjectSourceAnalyzer()
        let bogusURL = URL(fileURLWithPath: "/nonexistent/path/for/testing/12345")
        let landscape = analyzer.analyzeProject(at: bogusURL)

        XCTAssertEqual(landscape.scannedFileCount, 0)
        XCTAssertFalse(landscape.scanErrorsOrLimitations.isEmpty)
        XCTAssertTrue(landscape.scanErrorsOrLimitations.first?.contains("inaccessible") ?? false)
    }

    // MARK: - 2. RuntimeScreenObserver Tests

    func testRuntimeScreenObserver_RecordsDynamicScreenPresentations() {
        let observer = RuntimeScreenObserver.shared
        observer.clearHistory()
        observer.startObserving()

        observer.notifyScreenPresented(
            name: "DynamicPaymentModal",
            route: "/checkout/dynamic_modal",
            viewClassName: "PaymentModalController"
        )

        XCTAssertEqual(observer.observedHistory.count, 1)
        XCTAssertEqual(observer.observedHistory.first?.screenName, "DynamicPaymentModal")

        // Verify it was automatically registered into ScreenRegistry
        let registered = ScreenRegistry.shared.screen(withId: "runtime_checkout_dynamic_modal")
        XCTAssertNotNil(registered)
        XCTAssertEqual(registered?.discoverySource, .runtimeObservation)
        XCTAssertEqual(registered?.viewClassName, "PaymentModalController")

        observer.stopObserving()
    }

    // MARK: - 3. Rich Screen Definition Architecture Tests

    func testScreenRegistry_DefaultScreensContainRichArchitectureMetadata() {
        let registry = ScreenRegistry.shared
        let login = registry.screen(withId: "screen_login")

        XCTAssertNotNil(login)
        XCTAssertEqual(login?.discoverySource, .staticSourceAnalysis)
        XCTAssertEqual(login?.sourceFile, "Sources/Authentication/LoginViewController.swift")
        XCTAssertEqual(login?.featureModule, "Auth")
        XCTAssertEqual(login?.testMetrics.generatedCount, 4)
        XCTAssertEqual(login?.testMetrics.passedCount, 4)
    }
}
