import Foundation
import CompanyiOSKit

/// Controllable mock for network connectivity state.
public final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _isConnected: Bool
    private var _isCellular: Bool
    private var _isExpensive: Bool

    public var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }

    public var isCellular: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCellular
    }

    public var isExpensive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isExpensive
    }

    public init(isConnected: Bool = true, isCellular: Bool = false, isExpensive: Bool = false) {
        self._isConnected = isConnected
        self._isCellular = isCellular
        self._isExpensive = isExpensive
    }

    public func setConnected(_ connected: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self._isConnected = connected
    }

    public func setCellular(_ cellular: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self._isCellular = cellular
    }

    public func setExpensive(_ expensive: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self._isExpensive = expensive
    }
}

/// Controllable in-memory storage mock.
public actor MockStorage: StorageProtocol {
    private var storage: [String: Data] = [:]
    private var shouldThrowError: Bool = false

    public init() {}

    public func setShouldThrowError(_ value: Bool) {
        self.shouldThrowError = value
    }

    public func save<T: Encodable & Sendable>(_ value: T, forKey key: String) throws {
        if shouldThrowError {
            throw AppError.storage(reason: "Simulated storage failure")
        }
        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }

    public func read<T: Decodable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        if shouldThrowError {
            throw AppError.storage(reason: "Simulated storage failure")
        }
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }
}
