import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class CoreAndPersistenceTests: XCTestCase {

    struct CacheableUser: Codable, Equatable, Sendable {
        let name: String
        let age: Int
    }

    func testMemoryCache_WhenValueSaved_ReturnsValue() async throws {
        let cache = MemoryCache()
        let user = CacheableUser(name: "Satyam", age: 30)

        try await cache.save(user, forKey: "current_user")
        let loaded = try await cache.read(CacheableUser.self, forKey: "current_user")

        XCTAssertEqual(loaded, user)
    }

    func testMemoryCache_WhenExpired_ReturnsNil() async throws {
        // TTL of 0.05 seconds
        let cache = MemoryCache(defaultTTL: 0.05)
        let user = CacheableUser(name: "Temporary", age: 20)

        try await cache.save(user, forKey: "temp_user")
        try await Task.sleep(nanoseconds: 60_000_000) // 0.06s

        let loaded = try await cache.read(CacheableUser.self, forKey: "temp_user")
        XCTAssertNil(loaded)
    }

    func testFeatureFlagManager_WhenOverridden_ReflectsNewValue() async {
        let flag = FeatureFlag(key: "experimental_calling_codec", defaultValue: false)
        let manager = FeatureFlagManager()

        let defaultVal = await manager.isEnabled(flag)
        XCTAssertFalse(defaultVal)

        await manager.setOverride(flag, isEnabled: true)
        let overriddenVal = await manager.isEnabled(flag)
        XCTAssertTrue(overriddenVal)

        await manager.clearOverride(flag)
        let clearedVal = await manager.isEnabled(flag)
        XCTAssertFalse(clearedVal)
    }

    private actor LifecycleStateBox {
        var state: AppLifecycleState = .inactive
        func setState(_ s: AppLifecycleState) { state = s }
        func getState() -> AppLifecycleState { state }
    }

    func testAppLifecycleCoordinator_WhenTransitionOccurs_NotifiesListeners() async throws {
        let coordinator = AppLifecycleCoordinator(initialState: .active)
        let box = LifecycleStateBox()

        let id = await coordinator.addObserver { state in
            Task { await box.setState(state) }
        }

        await coordinator.transition(to: .background)

        try await AsyncTestHelpers.waitUntil(timeout: 1.0) {
            await box.getState() == .background
        }

        let current = await coordinator.currentState
        XCTAssertEqual(current, .background)
        await coordinator.removeObserver(id: id)
    }

    func testErrorMapper_WhenURLErrorTimedOut_MapsToTimeoutAppError() {
        let mapper = ErrorMapper.shared
        let urlError = URLError(.timedOut)

        let appError = mapper.mapToAppError(urlError)
        XCTAssertEqual(appError, .timeout)
        XCTAssertTrue(appError.isRetryable)

        let userFacing = mapper.mapToUserFacingError(appError)
        XCTAssertEqual(userFacing.title, "Request Timed Out")
        XCTAssertTrue(userFacing.isRetryable)
    }
}
