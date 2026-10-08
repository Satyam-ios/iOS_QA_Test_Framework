# CompanyTestKit Documentation

`CompanyTestKit` provides standardized, reusable testing infrastructure for unit, API, integration, and UI test automation across Apple applications.

---

## 1. Modules & Components

* **Mocks:**
  * `MockAPIClient`: Actor-isolated HTTP client mock allowing path stubbing, HTTP status simulation (401, 403, 404, 500), and executed request inspection.
  * `MockTokenManager`: In-memory token management actor for testing authentication lifecycle without persistence.
  * `MockKeychainManager`: In-memory secret storage avoiding macOS Keychain prompts or sandbox restrictions.
  * `MockNetworkMonitor`: Controllable connectivity simulator (online, offline, cellular, expensive).
  * `MockStorage`: In-memory storage mock supporting synthetic failure injection (`shouldThrowError`).
* **Fixtures:**
  * `TestDataFactory`: Factory methods generating deterministic test models (`TestUser`, `AuthToken`, credentials).
* **Helpers:**
  * `AsyncTestHelpers`: Deterministic condition waiter (`waitUntil(timeout:pollingInterval:condition:)`) to eliminate flaky `sleep` calls.
* **Assertions:**
  * `CustomAssertions`: Result and error assertions.
* **Logging:**
  * `TestLogCollector`: In-memory log sink for asserting on emitted logs and testing sensitive data masking.
* **Reporting & Quality Gate:**
  * `QualityGateEvaluator`: Evaluates test arrays and decides release readiness (`RELEASE READY` vs `RELEASE BLOCKED`).

---

## 2. Usage Examples

### 2.1 Testing an API Service with `MockAPIClient`

```swift
import XCTest
import CompanyiOSKit
import CompanyTestKit

final class UserServiceTests: XCTestCase {
    func testFetchProfile_Success() async throws {
        let mockClient = MockAPIClient()
        let expectedUser = TestUser(id: "1", name: "Alice", email: "alice@company.com")
        
        try await mockClient.stubJSON(path: "/profile", value: expectedUser)
        
        let response: APIResponse<TestUser> = try await mockClient.execute(APIRequest(path: "/profile"))
        XCTAssertEqual(response.value, expectedUser)
    }
}
```

### 2.2 Eliminating Flakiness with `AsyncTestHelpers`

```swift
import XCTest
import CompanyTestKit

final class StateMachineTests: XCTestCase {
    func testStateTransition() async throws {
        let machine = StateCoordinator()
        machine.triggerEvent()
        
        // Deterministically waits until condition evaluates to true or times out
        try await AsyncTestHelpers.waitUntil(timeout: 1.0, message: "State failed to reach ready") {
            await machine.currentState == .ready
        }
    }
}
```

### 2.3 Simulating Offline Scenarios

```swift
let networkMonitor = MockNetworkMonitor(isConnected: false)
XCTAssertFalse(networkMonitor.isConnected)
```
