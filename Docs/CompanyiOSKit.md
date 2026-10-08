# CompanyiOSKit Documentation

`CompanyiOSKit` is an application-independent, production-grade iOS framework providing foundational architecture for mobile engineering ecosystems. It is strictly decoupled from domain-specific applications (Calling, IoT, E-Learning, Enterprise, etc.) and is built with **Swift 6 strict concurrency** (`Sendable` compliance, actors, and structured concurrency).

---

## 1. Architecture Overview

`CompanyiOSKit` is structured into modular layers adhering to protocol-oriented design and clean architecture:

* **Core:** Application lifecycle observation, centralized configuration, environment flags, and global constants.
* **Networking:** Async/await HTTP client abstraction with configurable retry policies, reachability monitoring, and typed response decoding.
* **Authentication:** Token lifecycle management, secure Keychain persistence, and session state coordination.
* **Security:** Cryptographic-grade Keychain wrapper, memory protection, and automated log sanitization.
* **Persistence:** Abstract storage contracts with in-memory TTL caching and atomic disk persistence.
* **Validation:** Reusable RFC-compliant input validators (email, phone, password complexity).
* **Logging:** Structured logging layer with OSLog integration and sensitive data redaction.
* **Error Handling:** Unified domain error model (`AppError`) and localized presentation mappers.
* **Permissions:** Decoupled authorization wrappers for iOS system permissions.
* **UI:** VoiceOver-accessible SwiftUI primitives (`LoadingIndicatorView`, `EmptyStateView`, `ErrorBannerView`, `PrimaryActionButton`).
* **Utilities:** ISO8601 date formatting, string masking, and collection helpers.
* **Analytics:** Fan-out event dispatcher contract.
* **FeatureFlags:** Actor-backed local and remote feature flag evaluation.

---

## 2. Installation & Integration

In your `Package.swift`:

```swift
dependencies: [
    .package(path: "../iOS_QA_Framework") // or remote Git URL
],
targets: [
    .target(
        name: "YourAppFeature",
        dependencies: [
            .product(name: "CompanyiOSKit", package: "iOS_QA_Framework")
        ]
    )
]
```

---

## 3. Core Modules & Usage Examples

### 3.1 Networking (`APIClient`)

```swift
import CompanyiOSKit

let client = APIClient(
    baseURL: URL(string: "https://api.yourcompany.com/v1")!,
    tokenManager: TokenManager()
)

struct UserProfile: Codable, Sendable {
    let id: String
    let name: String
}

let request = APIRequest(path: "/users/me", method: .get)
let response: APIResponse<UserProfile> = try await client.execute(request)
print("Loaded user: \(response.value.name)")
```

### 3.2 Security & Log Redaction (`SensitiveDataRedactor`)

```swift
import CompanyiOSKit

let logger = AppLogger.shared
// Automatically masks Bearer tokens, API keys, passwords, and secrets
logger.info("Connecting with Authorization: Bearer abc123secretTokenValue")
// Output in OSLog: Connecting with Authorization: Bearer [REDACTED_TOKEN]
```

### 3.3 Validation (`EmailValidator`, `PasswordValidator`)

```swift
import CompanyiOSKit

let emailResult = EmailValidator.shared.validate("test@company.com")
if emailResult.isValid {
    // Proceed
}

let passwordValidator = PasswordValidator.standard
let passResult = passwordValidator.validate("SecureP@ss1!")
```

### 3.4 Session & Token Management (`SessionManager`)

```swift
import CompanyiOSKit

let session = SessionManager.shared
await session.setAuthenticated(userId: "usr_12345")

// On user logout, session purges tokens from secure Keychain
try await session.logout()
```

---

## 4. Extension Guidelines

1. **Maintain Zero Domain Coupling:** Never introduce calling-, device-, or IoT-specific models into `CompanyiOSKit`.
2. **Swift 6 Strict Concurrency:** Every public type must be `Sendable` or an `actor`.
3. **Protocol First:** Always expose protocols (`APIClientProtocol`, `StorageProtocol`, `LoggerProtocol`) so host applications and tests can supply mocks.
