import Foundation
import CompanyiOSKit

/// Central coordinator initializing and managing all runtime monitoring instruments.
public final class RuntimeMonitoringEngine: @unchecked Sendable {
    public static let shared = RuntimeMonitoringEngine()

    private let lock = NSLock()
    private var isStarted = false

    private init() {}

    /// Starts all configured runtime monitoring services.
    public func start(configuration: TestCenterConfiguration) {
        lock.lock()
        defer { lock.unlock() }

        guard !isStarted else { return }
        isStarted = true

        // 1. Crash and exception handling
        CrashMonitor.shared.startMonitoring()

        // 2. Memory monitoring and warning observation
        MemoryPerformanceMonitor.shared.startMonitoring()

        // 3. Main thread hang watchdog
        MainThreadHangWatchdog.shared.startWatchdog()

        // 4. Runtime screen navigation observer
        RuntimeScreenObserver.shared.startObserving()

        // 5. Lifecycle event logging
        AppLogger.shared.info("[RuntimeMonitoringEngine] All runtime monitors (Crash, Memory, HangWatchdog, Network, Navigation) initialized successfully.")
    }

    /// Stops all runtime monitoring services.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard isStarted else { return }
        isStarted = false

        MemoryPerformanceMonitor.shared.stopMonitoring()
        MainThreadHangWatchdog.shared.stopWatchdog()
        RuntimeScreenObserver.shared.stopObserving()
    }

    public var isMonitoringActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isStarted
    }
}
