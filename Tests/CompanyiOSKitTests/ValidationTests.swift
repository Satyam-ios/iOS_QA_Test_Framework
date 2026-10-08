import XCTest
@testable import CompanyiOSKit

final class ValidationTests: XCTestCase {

    // MARK: - EmailValidator Tests

    func testEmailValidator_WhenValidEmail_ReturnsValid() {
        let validator = EmailValidator.shared
        let result = validator.validate("satyam.kumar@vgroup.net")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.failureReason)
    }

    func testEmailValidator_WhenEmptyString_ReturnsInvalid() {
        let validator = EmailValidator.shared
        let result = validator.validate("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failureReason, "Email address cannot be empty.")
    }

    func testEmailValidator_WhenMissingDomain_ReturnsInvalid() {
        let validator = EmailValidator.shared
        let result = validator.validate("user@")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failureReason, "Please enter a valid email address.")
    }

    func testEmailValidator_WhenMissingAtSymbol_ReturnsInvalid() {
        let validator = EmailValidator.shared
        let result = validator.validate("plainaddress.com")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - PhoneValidator Tests

    func testPhoneValidator_WhenStandardInternationalNumber_ReturnsValid() {
        let validator = PhoneValidator.shared
        let result = validator.validate("+1 (555) 019-2834")
        XCTAssertTrue(result.isValid)
    }

    func testPhoneValidator_WhenTooShort_ReturnsInvalid() {
        let validator = PhoneValidator.shared
        let result = validator.validate("12345")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failureReason, "Phone number is too short (minimum 7 digits).")
    }

    func testPhoneValidator_WhenEmpty_ReturnsInvalid() {
        let validator = PhoneValidator.shared
        let result = validator.validate("   ")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failureReason, "Phone number cannot be empty.")
    }

    // MARK: - PasswordValidator Tests

    func testPasswordValidator_WhenStrongPassword_ReturnsValid() {
        let validator = PasswordValidator.standard
        let result = validator.validate("StrongP@ssw0rd!")
        XCTAssertTrue(result.isValid)
    }

    func testPasswordValidator_WhenTooShort_ReturnsInvalid() {
        let validator = PasswordValidator(minLength: 10)
        let result = validator.validate("Short1!")
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failureReason?.contains("at least 10 characters") == true)
    }

    func testPasswordValidator_WhenMissingSpecialChar_ReturnsInvalid() {
        let validator = PasswordValidator.standard
        let result = validator.validate("NoSpecialChar123")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failureReason, "Password must contain at least one special character.")
    }
}
