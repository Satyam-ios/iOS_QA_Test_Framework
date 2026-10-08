# iOS QA Framework & Engineering Ecosystem

A production-grade, application-agnostic iOS engineering, QA automation, and project quality framework built with **Swift 6 Strict Concurrency**.

---

## Products & Packages

* **`CompanyiOSKit`**: Reusable core engineering ecosystem (Core, Networking, Authentication, Security, Persistence, Validation, Logging, ErrorHandling, Permissions, UI, Utilities, Analytics, FeatureFlags).
* **`CompanyTestKit`**: Reusable testing framework (Mocks, Fixtures, AsyncTestHelpers, Assertions, TestLogCollector, TestReporting).
* **`ProjectTestCenter`**: Developer CLI / Quality Gate Orchestrator.

---

## Quickstart

```bash
# Set Developer Directory
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Build Framework
xcrun swift build

# Run All Tests (39 passing unit & integration tests)
xcrun swift test

# Run Project Test Center Quality Gate
xcrun swift run ProjectTestCenter gate
```

---

## Documentation

Detailed architectural and procedural documentation is available in the [`Docs/`](file:///Users/satyam/Documents/iOS_QA_Framework/Docs) directory:
* [`Docs/CompanyiOSKit.md`](file:///Users/satyam/Documents/iOS_QA_Framework/Docs/CompanyiOSKit.md)
* [`Docs/CompanyTestKit.md`](file:///Users/satyam/Documents/iOS_QA_Framework/Docs/CompanyTestKit.md)
* [`Docs/ProjectTestCenter.md`](file:///Users/satyam/Documents/iOS_QA_Framework/Docs/ProjectTestCenter.md)
* [`Docs/ExtensibilityAndGuides.md`](file:///Users/satyam/Documents/iOS_QA_Framework/Docs/ExtensibilityAndGuides.md)
