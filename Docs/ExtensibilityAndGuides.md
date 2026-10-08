# Extensibility & Developer Guide

This guide details standard operational procedures for extending `CompanyiOSKit`, `CompanyTestKit`, and `ProjectTestCenter`.

---

## 1. How to Add a New Reusable Module

1. **Verify Generality:** Ensure the capability is domain-agnostic (e.g., Image Caching, Biometric Auth, Deep Link Router). Domain-specific features (e.g. CallKit for CallingApp, BLE Protocol for IoTApp) must remain in the host application.
2. **Define Protocol Contract:** Create a `Protocol` conforming to `Sendable`.
3. **Implement Concrete Service:** Create an implementation adhering to Swift 6 strict concurrency (`actor` or `final class: Sendable`).
4. **Export Publicly in `CompanyiOSKit`:** Place in `Sources/CompanyiOSKit/<ModuleName>/`.
5. **Create Test Mock in `CompanyTestKit`:** Implement a controllable mock in `Sources/CompanyTestKit/Mocks/`.
6. **Add Unit Tests:** Implement comprehensive behavioral test cases in `Tests/CompanyiOSKitTests/`.

---

## 2. How to Add a New Test Type

1. Add the new test category to `TestCategory` enum in `CompanyTestKit/TestReporting/TestResultModels.swift` (e.g., `.snapshot`, `.fuzzing`).
2. Implement the helper harness in `CompanyTestKit/Helpers/`.
3. Integrate test target execution into `ProjectTestCenter`.

---

## 3. How to Add a New Reporter

1. Create a type conforming to a reporting interface (e.g., `JUnitXMLReporter`, `SonarQubeReporter`).
2. Accept `QualityReport` as input.
3. Serialize `QualityReport.testResults` to the target format.
4. Write output to disk or stream to CI stdout.

---

## 4. How to Add a New Analyzer

1. Create an analyzer class in `ProjectTestCenter/Analyzers/` (e.g., `SwiftLintAnalyzer`, `SecurityScanAnalyzer`).
2. Define diagnostic rules with severity (`Critical`, `High`, `Medium`, `Low`).
3. Connect analyzer output to `QualityGateEvaluator.evaluate()`.

---

## 5. How to Add AI Support

1. **Failure Root-Cause Classification:** Connect failed test logs and stack traces to an LLM prompt to hypothesize root causes into one of:
   - `BUG`
   - `TEST_ISSUE`
   - `ENVIRONMENT_ISSUE`
   - `DATA_ISSUE`
   - `FLAKY_TEST`
2. **Verification Rule:** Every AI output must be tagged with a confidence tier:
   - `Verified`
   - `Evidence-based finding`
   - `Probable`
   - `Needs verification`
3. **AI Rule Integrity:** Never allow AI to mutate production code without test verification or fabricate test passes.

---

## 6. How to Run the Complete Quality Pipeline

Execute the end-to-end pipeline:

```bash
# 1. Select Xcode toolchain
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# 2. Run static analysis & project discovery
xcrun swift run ProjectTestCenter analyze

# 3. Compile and execute full test matrix
xcrun swift test

# 4. Evaluate release quality gate
xcrun swift run ProjectTestCenter gate
```
