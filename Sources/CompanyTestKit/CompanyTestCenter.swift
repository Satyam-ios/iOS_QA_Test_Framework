import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
import CompanyiOSKit

/// Configuration options for initializing CompanyTestCenter.
public struct TestCenterConfiguration: Sendable {
    public var enableInAppHUD: Bool
    public var autoDiscoverScreens: Bool
    public var autoRunSmokeTests: Bool
    public var logLevel: LogLevel
    public var shakeGestureEnabled: Bool

    public init(
        enableInAppHUD: Bool = true,
        autoDiscoverScreens: Bool = true,
        autoRunSmokeTests: Bool = false,
        logLevel: LogLevel = .info,
        shakeGestureEnabled: Bool = true
    ) {
        self.enableInAppHUD = enableInAppHUD
        self.autoDiscoverScreens = autoDiscoverScreens
        self.autoRunSmokeTests = autoRunSmokeTests
        self.logLevel = logLevel
        self.shakeGestureEnabled = shakeGestureEnabled
    }

    public static let `default` = TestCenterConfiguration()
}

/// Unified entry facade for the iOS Engineering + QA Automation ecosystem.
///
/// Provides a zero-configuration one-line onboarding point for host applications:
/// ```swift
/// import CompanyTestKit
///
/// // In AppDelegate, App.init(), or SceneDelegate:
/// CompanyTestCenter.start()
/// ```
public final class CompanyTestCenter: @unchecked Sendable {
    public static let shared = CompanyTestCenter()

    private let lock = NSLock()
    private var isStarted = false
    private var configuration: TestCenterConfiguration = .default

    private init() {}

    // MARK: - One-Line Developer Integration

    /// Starts the Test Center engine with zero required configuration.
    ///
    /// - Parameter configuration: Optional custom configuration. Defaults to `.default`.
    @discardableResult
    public static func start(configuration: TestCenterConfiguration = .default) -> CompanyTestCenter {
        shared.start(configuration: configuration)
        return shared
    }

    public func start(configuration: TestCenterConfiguration = .default) {
        lock.lock()
        defer { lock.unlock() }

        self.configuration = configuration
        guard !isStarted else { return }
        isStarted = true

        // 1. Configure logging
        AppLogger.shared.log("🚀 [CompanyTestCenter] Starting QA Automation Engine (v\(CompanyTestKitInfo.version))...", level: configuration.logLevel)

        // 2. Ensure baseline screen landscape is populated if enabled
        if configuration.autoDiscoverScreens {
            _ = ScreenRegistry.shared.allScreens
            _ = ScreenRegistry.shared.allJourneys
            _ = DefectCatalog.shared.allDefects
        }

        AppLogger.shared.log("✅ [CompanyTestCenter] Ready. \(ScreenRegistry.shared.allScreens.count) screen(s), \(ScreenRegistry.shared.allJourneys.count) journey(s) registered.", level: configuration.logLevel)
    }

    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isStarted
    }

    // MARK: - Optional Developer Customization APIs

    /// Registers a custom application screen into the discovery engine.
    public static func register(screen: ScreenDefinition) {
        ScreenRegistry.shared.register(screen)
    }

    /// Convenience registration for a custom screen.
    public static func register(
        id: String,
        name: String,
        route: String,
        elements: [UIElementDescriptor] = [],
        apiDependencies: [String] = [],
        availableStates: [ScreenStateKind] = [.normal],
        supportedActions: [UserActionDescriptor] = []
    ) {
        let screen = ScreenDefinition(
            id: id,
            name: name,
            route: route,
            elements: elements,
            apiDependencies: apiDependencies,
            availableStates: availableStates,
            supportedActions: supportedActions
        )
        ScreenRegistry.shared.register(screen)
    }

    /// Registers a multi-screen user journey.
    public static func register(journey: UserJourney) {
        ScreenRegistry.shared.registerJourney(journey)
    }

    /// Records a defect into the regression learning catalog.
    public static func record(defect: DefectRecord) {
        DefectCatalog.shared.recordDefect(defect)
    }

    // MARK: - Engine Operations

    /// Generates a complete automated test plan for all registered screens and journeys.
    public static func generateTestPlan() -> GeneratedTestPlan {
        let engine = TestGenerationEngine()
        return engine.generateTests(
            for: ScreenRegistry.shared.allScreens,
            journeys: ScreenRegistry.shared.allJourneys
        )
    }

    /// Executes all registered user journeys and returns execution results.
    public static func runJourneyTests() async -> [JourneyExecutionResult] {
        let runner = JourneyRunner(screens: ScreenRegistry.shared.allScreens)
        var results: [JourneyExecutionResult] = []
        for journey in ScreenRegistry.shared.allJourneys {
            let res = await runner.execute(journey: journey)
            results.append(res)
        }
        return results
    }

    /// Executes the defect regression suite and returns test cases.
    public static func runRegressionSuite() -> [GeneratedTestCase] {
        return DefectCatalog.shared.generateRegressionSuite()
    }

    /// Evaluates current test results against the release quality gate.
    public static func evaluateQualityGate(results: [TestCaseResult] = [], projectName: String = "iOS_QA_Framework") -> QualityReport {
        let evaluator = QualityGateEvaluator()
        return evaluator.evaluate(results: results, projectName: projectName)
    }

    /// Runs AI quality analysis to detect coverage gaps, architectural risks, and unexecutable tests.
    public static func analyzeQuality(existingTests: [TestCaseResult] = []) -> AIAnalysisReport {
        let analyzer = AIQualityAnalyzer()
        return analyzer.analyzeQuality(
            screens: ScreenRegistry.shared.allScreens,
            journeys: ScreenRegistry.shared.allJourneys,
            existingTests: existingTests,
            defects: DefectCatalog.shared.allDefects
        )
    }

    // MARK: - UI Presentation Helpers

    #if canImport(UIKit) && !os(watchOS)
    /// Presents the in-app Test Center dashboard modally from the provided view controller or top-most controller.
    @MainActor
    public static func present(from presenter: UIViewController? = nil) {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        let rootVC = presenter ?? keyWindow.rootViewController
        guard let presentingVC = rootVC else { return }

        var topVC = presentingVC
        while let next = topVC.presentedViewController {
            topVC = next
        }

        let hostingController = UIHostingController(rootView: InAppTestCenterView())
        hostingController.modalPresentationStyle = .pageSheet
        topVC.present(hostingController, animated: true)
    }
    #endif
}

// MARK: - Objective-C Bridge

#if canImport(ObjectiveC)
@objc(CompanyTestCenterObjc)
public final class CompanyTestCenterObjc: NSObject {
    @objc public static func start() {
        CompanyTestCenter.start()
    }

    @objc public static func registerScreen(id: String, name: String, route: String) {
        CompanyTestCenter.register(id: id, name: name, route: route)
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    @objc public static func presentFromViewController(_ viewController: UIViewController?) {
        CompanyTestCenter.present(from: viewController)
    }
    #endif
}
#endif

// MARK: - SwiftUI Extension

#if canImport(SwiftUI)
public extension View {
    /// Attaches the in-app Test Center presentation sheet to any SwiftUI View.
    func inAppTestCenter(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            InAppTestCenterView()
        }
    }
}
#endif
