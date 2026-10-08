import Foundation

/**
 # PROJECT TEST CENTER & COMPANYTESTKIT DEVELOPER GUIDE
 
 Welcome to the **CompanyiOSKit + CompanyTestKit** quality automation ecosystem.
 This guide explains how to integrate, configure, and operate the framework across any iOS project
 (Swift, SwiftUI, UIKit, and Objective-C) targeting iOS 15.0 and above.
 
 ---
 
 ## 1. ARCHITECTURAL OVERVIEW
 
 The ecosystem is organized into three decoupled layers:
 
 ```text
                      Host iOS Application
                                │
                                ▼
                        CompanyiOSKit
               (Production Reusable Infrastructure)
                 • Core / AppLifecycle / Config
                 • Networking / Auth / Keychain
                 • Validation / Logging / Storage
                 • Permissions / Analytics / Flags
                 • Objective-C Compatibility Bridge
                                │
                                ▼
                        CompanyTestKit
               (AI-Assisted QA Automation Engine)
                 • CompanyTestCenter (1-Line Facade)
                 • Screen & Journey Discovery Engine
                 • Automated Test Generation Engine
                 • End-to-End Journey Runner
                 • Defect Catalog & Regression Suite
                 • AI Quality Analyzer & Gap Hunter
                 • In-App Interactive Test Center UI
                                │
                                ▼
                      ProjectTestCenter CLI
               (Continuous Integration Quality Gate)
                 • Zero-config terminal runner
                 • Quality gate evaluation
                 • QA handoff artifact generation
 ```
 
 ---
 
 ## 2. MINIMAL DEVELOPER INTEGRATION (ONE LINE)
 
 The framework is designed for **instant adoption with zero configuration**.
 
 ### For SwiftUI Applications:
 ```swift
 import SwiftUI
 import CompanyTestKit
 
 @main
 struct MyApp: App {
     init() {
         // One-line integration starts discovery and logging:
         CompanyTestCenter.start()
     }
 
     var body: some Scene {
         WindowGroup {
             ContentView()
         }
     }
 }
 ```
 
 ### For UIKit Applications (AppDelegate):
 ```swift
 import UIKit
 import CompanyTestKit
 
 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
     func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
         // One-line start:
         CompanyTestCenter.start()
         return true
     }
 }
 ```
 
 ### For Objective-C Applications:
 ```objc
 @import CompanyTestKit;
 
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     // One-line Objective-C integration:
     [CompanyTestCenterObjc start];
     return YES;
 }
 ```
 
 ---
 
 ## 3. IN-APP TEST CENTER PRESENTATION
 
 Developers and QA testers can inspect screens, execute journeys, view generated tests, and check the release gate directly on physical devices or simulators.
 
 ### Presenting via SwiftUI:
 ```swift
 import SwiftUI
 import CompanyTestKit
 
 struct SettingsView: View {
     @State private var showTestCenter = false
 
     var body: some View {
         Button("Open QA Test Center") {
             showTestCenter = true
         }
         .inAppTestCenter(isPresented: $showTestCenter)
     }
 }
 ```
 
 ### Presenting via UIKit:
 ```swift
 import UIKit
 import CompanyTestKit
 
 @objc func openTestCenterTapped() {
     CompanyTestCenter.present(from: self)
 }
 ```
 
 ---
 
 ## 4. OPTIONAL CUSTOM SCREEN & JOURNEY REGISTRATION
 
 While out-of-the-box discovery provides baseline coverage automatically, developers can register custom screens and multi-step user journeys to capture complex application-specific flows.
 
 ### Registering a Custom Screen:
 ```swift
 CompanyTestCenter.register(
     id: "screen_checkout",
     name: "Checkout Screen",
     route: "/checkout",
     elements: [
         UIElementDescriptor(id: "field_card_number", type: .textField, accessibilityIdentifier: "card_input", accessibilityLabel: "Card Number"),
         UIElementDescriptor(id: "btn_pay", type: .button, accessibilityIdentifier: "pay_now_btn", accessibilityLabel: "Pay Now")
     ],
     apiDependencies: ["/api/v1/payments/charge"],
     availableStates: [.normal, .loading, .error(message: "Payment declined")]
 )
 ```
 
 ### Registering an End-to-End User Journey:
 ```swift
 let checkoutJourney = UserJourney(
     id: "journey_purchase",
     name: "Product Checkout Journey",
     description: "Navigate from Cart to Payment and confirmation",
     initialRoute: "/cart",
     steps: [
         JourneyStep(stepNumber: 1, screenId: "screen_cart", actionName: "Tap Checkout", targetElementId: "btn_checkout", expectedRoute: "/checkout"),
         JourneyStep(stepNumber: 2, screenId: "screen_checkout", actionName: "Enter Payment", targetElementId: "field_card_number", inputValue: "4111222233334444"),
         JourneyStep(stepNumber: 3, screenId: "screen_checkout", actionName: "Submit Payment", targetElementId: "btn_pay", expectedRoute: "/order_confirmed", apiCallTriggered: "/api/v1/payments/charge")
     ]
 )
 CompanyTestCenter.register(journey: checkoutJourney)
 ```
 
 ---
 
 ## 5. DEFECT CATALOGING & REGRESSION INVARIANTS
 
 When a bug is fixed in production, preserve it in the regression catalog so it is never re-introduced:
 
 ```swift
 CompanyTestCenter.record(defect: DefectRecord(
     id: "BUG-1092",
     title: "Card input crashed on whitespace paste",
     affectedScreen: "screen_checkout",
     rootCause: "Unsanitized clipboard string caused fatal index out of bounds",
     regressionPattern: "Input sanitization must strip non-digit characters without exception",
     riskLevel: .high,
     reproductionSteps: ["Copy formatted card string", "Paste into card field", "Assert no crash"],
     verifiedFixed: true
 ))
 ```
 
 ---
 
 ## 6. TEST EXECUTION TRUTHFULNESS & PRINCIPLES
 
 The framework adheres strictly to **absolute testing truth**:
 
 1. **No Fabricated Results**: Tests only report `PASSED` when their assertions actually run and succeed.
 2. **Unexecutable Hardware Tests**: Tests requiring physical external hardware (e.g., Bluetooth IoT pairing, biometric sensors, APNS push receipts) are explicitly marked `BLOCKED` or `NOT EXECUTED` with clear diagnostic reasons, rather than falsely mocked as passing.
 3. **Regression Safety**: Every recorded defect generates an invariant test case executed on every release candidate.
 
 ---
 
 ## 7. TERMINAL & CI COMMAND LINE INTERFACE (ProjectTestCenter)
 
 The bundled executable target `ProjectTestCenter` allows automated pipeline validation:
 
 ```bash
 # Run full combined quality workflow (Discover -> Generate -> Execute -> Analyze -> Gate):
 swift run ProjectTestCenter quality
 
 # Run individual phases:
 swift run ProjectTestCenter discover      # List registered screens and journeys
 swift run ProjectTestCenter generate      # Generate full test scenario matrix
 swift run ProjectTestCenter test          # Run user journey steps asynchronously
 swift run ProjectTestCenter regression    # Run defect regression invariants
 swift run ProjectTestCenter report        # Produce QA handoff markdown report
 swift run ProjectTestCenter gate          # Evaluate release quality gate (exit code 0/1)
 ```
 */
public enum ProjectTestCenterDeveloperGuide {
    /// Returns the complete developer documentation as a formatted markdown string.
    public static var documentationOverview: String {
        return """
        # CompanyiOSKit & CompanyTestKit Quick Reference
        - Minimal Onboarding: CompanyTestCenter.start()
        - Screens & Journeys: ScreenRegistry.shared
        - Defect Catalog: DefectCatalog.shared
        - Test Synthesis: TestGenerationEngine()
        - AI Quality Evaluation: AIQualityAnalyzer()
        - Command Line Runner: swift run ProjectTestCenter quality
        """
    }
}
