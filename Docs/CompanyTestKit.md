# CompanyTestKit Documentation

`CompanyTestKit` provides standardized, reusable testing infrastructure, automated journey execution, test generation, and defect learning across Apple applications.

---

## 1. Modules & Components

* **Journey & Screen Testing:**
  * `ScreenDefinition` & `UIElementDescriptor`: Models screens, reachable routes, accessibility identifiers, UI controls, and API dependencies.
  * `UserJourney` & `JourneyStep`: Models end-to-end multi-screen user workflows.
  * `JourneyRunner`: Executes multi-screen journeys step-by-step with state and timing validation.
* **Discovery & Minimal Integration:**
  * `ScreenRegistry`: Central catalog managing discovered and registered screens and user journeys.
  * `CompanyTestDiscovery.register(...)`: Lightweight 1-line integration API for developers.
  * `AccessibilityValidator`: Validates unique accessibility identifiers and VoiceOver accessibility labels on all controls.
* **Automated Test Generation:**
  * `TestGenerationEngine`: Automatically synthesizes functional, API, UI, platform lifecycle, and journey test scenarios.
* **AI Quality Intelligence:**
  * `AIQualityAnalyzer`: Detects coverage gaps, uncovered journeys, missing negative/boundary tests, and explicitly tags unexecutable hardware tests.
* **Defect Learning Catalog:**
  * `DefectCatalog`: Converts verified production bugs into permanent, reusable regression test patterns.
* **Developer In-App Dashboard:**
  * `InAppTestCenterView`: Full-featured SwiftUI dashboard for inspecting screens, journeys, generated tests, and running the quality gate inside the app.
* **Mocks, Fixtures & Helpers:**
  * `MockAPIClient`: Actor-isolated mock for API requests.
  * `MockTokenManager`: In-memory token management actor.
  * `MockKeychainManager`: In-memory isolated Keychain wrapper.
  * `MockNetworkMonitor`: Controllable reachability simulator.
  * `AsyncTestHelpers`: Deterministic condition waiter (`waitUntil`) eliminating flaky sleep delays.
  * `QualityGateEvaluator`: Automated release gate decision engine (`RELEASE READY` vs `RELEASE BLOCKED`).

---

## 2. Usage Examples

### 2.1 One-Line Screen Registration
```swift
import CompanyTestKit

// In your ViewController or SwiftUI View setup:
CompanyTestDiscovery.register(
    ScreenDefinition(
        id: "screen_profile",
        name: "User Profile",
        route: "/profile",
        elements: [
            UIElementDescriptor(id: "field_name", type: .textField, accessibilityLabel: "Name"),
            UIElementDescriptor(id: "btn_save", type: .button, accessibilityLabel: "Save")
        ],
        apiDependencies: ["/api/v1/profile/save"]
    )
)
```

### 2.2 In-App Test Center Integration
Present the developer test center in a debug menu or developer settings sheet:

```swift
import SwiftUI
import CompanyTestKit

struct DeveloperSettingsView: View {
    var body: some View {
        InAppTestCenterView()
    }
}
```

### 2.3 Executing End-to-End User Journeys
```swift
import XCTest
import CompanyTestKit

final class JourneyTests: XCTestCase {
    func testStandardFlow() async {
        let runner = JourneyRunner(screens: ScreenRegistry.shared.allScreens)
        let journey = ScreenRegistry.shared.allJourneys.first!

        let result = await runner.execute(journey: journey)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.executedSteps, journey.steps.count)
    }
}
```
