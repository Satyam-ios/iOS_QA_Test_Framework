import XCTest
@testable import CompanyiOSKit

final class ObjectiveCBridgeTests: XCTestCase {

    func testCompanyObjcValidator_ValidatesInput() {
        XCTAssertTrue(CompanyObjcValidator.validateEmail("john.doe@company.com"))
        XCTAssertFalse(CompanyObjcValidator.validateEmail("invalid-email"))
        XCTAssertNotNil(CompanyObjcValidator.emailValidationError("invalid-email"))

        XCTAssertTrue(CompanyObjcValidator.validatePhone("+15551234567"))
        XCTAssertFalse(CompanyObjcValidator.validatePhone("123"))

        XCTAssertTrue(CompanyObjcValidator.validatePassword("P@ssw0rd123!"))
        XCTAssertFalse(CompanyObjcValidator.validatePassword("weak"))
    }

    func testCompanyObjcKeychainManager_SavesAndReads() throws {
        let keychain = CompanyObjcKeychainManager.shared
        try keychain.save(string: "SecretTokenValue", forKey: "objc_test_key")

        let retrieved = keychain.readString(forKey: "objc_test_key")
        XCTAssertEqual(retrieved, "SecretTokenValue")

        try keychain.delete(key: "objc_test_key")
        let afterDelete = keychain.readString(forKey: "objc_test_key")
        XCTAssertNil(afterDelete)
    }

    func testCompanyObjcLogger_EmitsLogsWithoutCrashing() {
        let logger = CompanyObjcLogger.shared
        logger.logInfo("Testing Obj-C logger integration with Bearer mySecretToken123")
        logger.logWarning("Testing Obj-C warning")
        logger.logError("Testing Obj-C error")
    }

    func testCompanyObjcSessionManager_SetsAuthAndChecks() async {
        let manager = CompanyObjcSessionManager.shared
        manager.setAuthenticated(userId: "objc_user_42")

        let isAuthed: Bool = await withCheckedContinuation { continuation in
            manager.checkAuthentication { authed in
                continuation.resume(returning: authed)
            }
        }
        XCTAssertTrue(isAuthed)
    }
}
