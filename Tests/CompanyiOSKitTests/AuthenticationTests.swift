import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class AuthenticationTests: XCTestCase {

    func testAuthToken_WhenExpirationInFuture_IsNotExpired() {
        let token = TestDataFactory.makeAuthToken(expiresIn: 3600)
        XCTAssertFalse(token.isExpired)
    }

    func testAuthToken_WhenExpirationInPast_IsExpired() {
        let token = TestDataFactory.makeExpiredAuthToken()
        XCTAssertTrue(token.isExpired)
    }

    func testMockTokenManager_WhenTokenSaved_RetrievesTokensSuccessfully() async throws {
        let tokenManager = MockTokenManager()
        let token = TestDataFactory.makeAuthToken()

        await tokenManager.saveTokens(token)

        let accessToken = await tokenManager.getAccessToken()
        let refreshToken = await tokenManager.getRefreshToken()
        let isValid = await tokenManager.isAccessTokenValid()

        XCTAssertEqual(accessToken, token.accessToken)
        XCTAssertEqual(refreshToken, token.refreshToken)
        XCTAssertTrue(isValid)
    }

    func testMockTokenManager_WhenCleared_ReturnsNil() async throws {
        let tokenManager = MockTokenManager(initialToken: TestDataFactory.makeAuthToken())
        await tokenManager.clearTokens()

        let accessToken = await tokenManager.getAccessToken()
        let isValid = await tokenManager.isAccessTokenValid()

        XCTAssertNil(accessToken)
        XCTAssertFalse(isValid)
    }

    func testSessionManager_WhenUserLogsIn_TransitionsToAuthenticated() async {
        let tokenManager = MockTokenManager()
        let sessionManager = SessionManager(tokenManager: tokenManager)

        let initial = await sessionManager.currentState
        XCTAssertEqual(initial, .unauthenticated)

        await sessionManager.setAuthenticated(userId: "user_qa_999")
        let authenticated = await sessionManager.currentState
        XCTAssertEqual(authenticated, .authenticated(userId: "user_qa_999"))
        XCTAssertTrue(authenticated.isAuthenticated)
    }

    func testSessionManager_WhenLogoutCalled_PurgesTokensAndTransitions() async throws {
        let initialToken = TestDataFactory.makeAuthToken()
        let tokenManager = MockTokenManager(initialToken: initialToken)
        let sessionManager = SessionManager(tokenManager: tokenManager)

        await sessionManager.setAuthenticated(userId: "user_1")
        try await sessionManager.logout()

        let state = await sessionManager.currentState
        let tokenRemaining = await tokenManager.getAccessToken()

        XCTAssertEqual(state, .unauthenticated)
        XCTAssertNil(tokenRemaining)
    }

    private actor EventCounter {
        var count = 0
        func increment() { count += 1 }
        func getCount() -> Int { count }
    }

    func testSessionManager_WhenStateChanges_NotifiesObservers() async throws {
        let tokenManager = MockTokenManager()
        let sessionManager = SessionManager(tokenManager: tokenManager)

        let counter = EventCounter()

        let observerId = await sessionManager.addObserver { _ in
            Task { await counter.increment() }
        }

        await sessionManager.setAuthenticated(userId: "user_async")

        try await AsyncTestHelpers.waitUntil(timeout: 2.0) {
            await counter.getCount() >= 2
        }

        await sessionManager.removeObserver(id: observerId)
    }
}
