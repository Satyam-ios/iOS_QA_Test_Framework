# iOS QA Framework & Engineering Ecosystem

A production-grade, application-agnostic iOS engineering, QA automation, and project quality framework built with **Swift 6 Strict Concurrency** supporting **iOS 15+** and **macOS 12+** across **Swift, SwiftUI, and Objective-C**.

---

## 🚀 Release v1.0.1 — Change Verification & Status

**Release Build:** `v1.0.1`  
**Test Matrix:** 57 Automated Tests (100% Passed)  
**Deployment Targets:** iOS 15.0+ | macOS 12.0+  
**Supported Languages:** Swift, SwiftUI, UIKit, Objective-C  

### Components Included & Verified in This Release:

| Component | Status | Key API / Entry Point | Description |
| :--- | :---: | :--- | :--- |
| **`CompanyTestCenter`** | ✅ VERIFIED | `CompanyTestCenter.start()` | **1-Line Developer Integration Facade** for zero-config onboarding |
| **`ScreenRegistry`** | ✅ VERIFIED | `ScreenRegistry.shared` | Application screen & route discovery engine |
| **`TestGenerationEngine`** | ✅ VERIFIED | `TestGenerationEngine()` | Dynamic test scenario synthesizer (functional, UI, regression) |
| **`JourneyRunner`** | ✅ VERIFIED | `JourneyRunner(screens: ...)` | Deterministic end-to-end user journey orchestrator |
| **`DefectCatalog`** | ✅ VERIFIED | `DefectCatalog.shared` | Defect learning catalog preserving bug invariants |
| **`AIQualityAnalyzer`** | ✅ VERIFIED | `AIQualityAnalyzer()` | AI risk evaluator & coverage gap detection |
| **`InAppTestCenterView`** | ✅ VERIFIED | `.inAppTestCenter(isPresented:)` | In-app SwiftUI & UIKit QA dashboard |
| **`CompanyTestKit` Umbrella** | ✅ VERIFIED | `@_exported import CompanyiOSKit` | Single import giving access to both test and production kits |
| **`ObjectiveCBridge`** | ✅ VERIFIED | `CompanyTestCenterObjc.start()` | Full Objective-C interoperability support |
| **`Consumer Guards`** | ✅ VERIFIED | `PackageConsumerIntegrationTests` | Permanent regression test suite preventing symbol scope errors |

---

## Products & Packages

* **`CompanyiOSKit`**: Reusable core engineering ecosystem (Core, Networking, Authentication, Security, Persistence, Validation, Logging, ErrorHandling, Permissions, UI, Utilities, Analytics, FeatureFlags, ObjectiveCBridge).
* **`CompanyTestKit`**: Reusable testing framework & QA engine (CompanyTestCenter, ScreenRegistry, TestGenerationEngine, JourneyRunner, DefectCatalog, AIQualityAnalyzer, InAppTestCenterView, Mocks, Fixtures).
* **`ProjectTestCenter`**: Developer CLI / Quality Gate Orchestrator.

---

## 1-Line Quickstart for Consuming Apps

### Swift / SwiftUI
```swift
import SwiftUI
import CompanyTestKit

@main
struct MyApp: App {
    init() {
        // One-line start initializes discovery, logging, and regression engines:
        CompanyTestCenter.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit (AppDelegate)
```swift
import UIKit
import CompanyTestKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CompanyTestCenter.start()
        return true
    }
}
```

### Objective-C
```objc
@import CompanyTestKit;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CompanyTestCenterObjc start];
    return YES;
}
```

---

## Multi-Language & Platform Support

* **Minimum iOS Deployment:** iOS 15.0+ (also macOS 12.0+)
* **Swift & SwiftUI:** Full native async/await, actor isolation, and accessible SwiftUI views.
* **Objective-C:** Dedicated `@objc` bridge classes (`CompanyObjcAPIClient`, `CompanyObjcKeychainManager`, `CompanyObjcValidator`, `CompanyObjcLogger`, `CompanyObjcSessionManager`, `CompanyTestCenterObjc`).

---

## Verification & Testing

```bash
# Build Framework
xcrun swift build

# Run All 57 Automated Unit, API, Journey, and Consumer Tests
xcrun swift test

# Run Project Test Center Quality Gate Pipeline
xcrun swift run ProjectTestCenter quality
```

---

## Documentation

Detailed architectural and procedural documentation is available:
* [`Sources/CompanyTestKit/ProjectTestCenterDeveloperGuide.swift`](Sources/CompanyTestKit/ProjectTestCenterDeveloperGuide.swift)
* [`Docs/CompanyiOSKit.md`](Docs/CompanyiOSKit.md)
* [`Docs/CompanyTestKit.md`](Docs/CompanyTestKit.md)
* [`Docs/ProjectTestCenter.md`](Docs/ProjectTestCenter.md)
* [`Docs/ExtensibilityAndGuides.md`](Docs/ExtensibilityAndGuides.md)
* [`Docs/PROJECT_QUALITY_REPORT.md`](Docs/PROJECT_QUALITY_REPORT.md)
