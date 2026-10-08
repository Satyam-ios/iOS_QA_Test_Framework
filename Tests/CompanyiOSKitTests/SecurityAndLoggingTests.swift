import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class SecurityAndLoggingTests: XCTestCase {

    func testSensitiveDataRedactor_WhenBearerTokenPresent_MasksToken() {
        let redactor = SensitiveDataRedactor.shared
        let rawLog = "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xyz.secret"
        let sanitized = redactor.redact(rawLog)

        XCTAssertFalse(sanitized.contains("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))
        XCTAssertTrue(sanitized.contains("Bearer [REDACTED_TOKEN]"))
    }

    func testSensitiveDataRedactor_WhenApiKeyInJSON_MasksValue() {
        let redactor = SensitiveDataRedactor.shared
        let rawJSON = "{\"apiKey\": \"super_secret_key_12345\", \"name\": \"john\"}"
        let sanitized = redactor.redact(rawJSON)

        XCTAssertFalse(sanitized.contains("super_secret_key_12345"))
        XCTAssertTrue(sanitized.contains("\"apiKey\": \"[REDACTED]\""))
    }

    func testMockKeychainManager_WhenSavingAndReading_MaintainsData() throws {
        let keychain = MockKeychainManager()
        let secretData = "SuperSecretPassword".data(using: .utf8)!

        try keychain.save(key: "account_secret", data: secretData)
        let retrieved = try keychain.readData(key: "account_secret")

        XCTAssertEqual(retrieved, secretData)

        try keychain.delete(key: "account_secret")
        let afterDelete = try keychain.readData(key: "account_secret")
        XCTAssertNil(afterDelete)
    }

    func testTestLogCollector_WhenLogsEmitted_CapturesAndFiltersByLevel() {
        let collector = TestLogCollector(minimumLogLevel: .warning)

        collector.info("Normal information message")
        collector.warning("Potential warning encountered")
        collector.error("Critical failure detected")

        XCTAssertEqual(collector.capturedRecords.count, 2)
        XCTAssertFalse(collector.containsMessage(matching: "Normal information message"))
        XCTAssertTrue(collector.containsMessage(matching: "Potential warning encountered"))
        XCTAssertTrue(collector.containsMessage(matching: "Critical failure detected"))
    }
}
