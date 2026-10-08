import Foundation
import Network

/// Protocol for querying network connectivity status.
public protocol NetworkMonitoring: Sendable {
    var isConnected: Bool { get }
    var isCellular: Bool { get }
    var isExpensive: Bool { get }
}

/// System network reachability monitor wrapping Apple's Network framework.
public final class NetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    public static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.company.ioskit.networkmonitor")
    private let lock = NSLock()

    private var _isConnected: Bool = true
    private var _isCellular: Bool = false
    private var _isExpensive: Bool = false

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

    public init() {
        self.monitor = NWPathMonitor()
        self.monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.lock.lock()
            self._isConnected = path.status == .satisfied
            self._isCellular = path.usesInterfaceType(.cellular)
            self._isExpensive = path.isExpensive
            self.lock.unlock()
        }
        self.monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
