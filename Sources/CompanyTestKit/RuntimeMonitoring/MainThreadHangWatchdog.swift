import Foundation
import CompanyiOSKit

/// Background watchdog monitoring main-thread runloop responsiveness and detecting UI hangs.
public final class MainThreadHangWatchdog: @unchecked Sendable {
    public static let shared = MainThreadHangWatchdog()

    private let lock = NSLock()
    private var isRunning = false
    private var pingThread: Thread?
    private let stallThreshold: TimeInterval
    private let hangThreshold: TimeInterval

    public init(stallThreshold: TimeInterval = 0.25, hangThreshold: TimeInterval = 0.5) {
        self.stallThreshold = stallThreshold
        self.hangThreshold = hangThreshold
    }

    /// Starts watchdog monitoring on a low-priority background thread.
    public func startWatchdog() {
        lock.lock()
        defer { lock.unlock() }

        guard !isRunning else { return }
        isRunning = true

        let thread = Thread { [weak self] in
            self?.runWatchdogLoop()
        }
        thread.name = "com.company.testcenter.hang_watchdog"
        thread.qualityOfService = .utility
        pingThread = thread
        thread.start()
    }

    /// Stops watchdog monitoring.
    public func stopWatchdog() {
        lock.lock()
        defer { lock.unlock() }

        isRunning = false
        pingThread?.cancel()
        pingThread = nil
    }

    private func runWatchdogLoop() {
        while true {
            lock.lock()
            let active = isRunning
            lock.unlock()
            if !active || Thread.current.isCancelled { break }

            let semaphore = DispatchSemaphore(value: 0)
            let pingStart = Date()

            DispatchQueue.main.async {
                semaphore.signal()
            }

            // Wait for main thread to respond within stall threshold
            let stallWait = semaphore.wait(timeout: .now() + stallThreshold)
            if stallWait == .timedOut {
                // Main thread is stalled! Wait up to hang threshold
                let hangWait = semaphore.wait(timeout: .now() + (hangThreshold - stallThreshold))
                let duration = Date().timeIntervalSince(pingStart)

                if hangWait == .timedOut {
                    // Critical hang (> 500ms)
                    RuntimeTelemetryStore.shared.record(
                        category: .mainThreadHang,
                        severity: .critical,
                        title: "Main Thread Hang Detected (\(String(format: "%.0f", duration * 1000))ms)",
                        details: "Main thread was blocked for \(String(format: "%.2f", duration)) seconds, violating UI responsiveness guidelines. Potential synchronous file I/O, heavy JSON parsing, or lock contention.",
                        sourceLocation: "MainRunLoop",
                        contextMetadata: ["blockedDurationMs": String(format: "%.0f", duration * 1000)]
                    )
                    // Wait for main thread to finally finish before next probe
                    semaphore.wait()
                } else {
                    // Minor stall (250ms - 500ms)
                    RuntimeTelemetryStore.shared.record(
                        category: .mainThreadHang,
                        severity: .medium,
                        title: "Main Thread Stall (\(String(format: "%.0f", duration * 1000))ms)",
                        details: "Main thread delayed by \(String(format: "%.0f", duration * 1000))ms. Frames were likely dropped.",
                        sourceLocation: "MainRunLoop",
                        contextMetadata: ["stallDurationMs": String(format: "%.0f", duration * 1000)]
                    )
                }
            }

            // Sleep 500ms between probes to conserve CPU
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    /// Manually records a known main-thread stall (e.g. from test harnesses or instruments).
    public func recordStall(duration: TimeInterval, source: String? = nil) {
        let severity: DefectSeverity = duration >= hangThreshold ? .critical : .high
        RuntimeTelemetryStore.shared.record(
            category: .mainThreadHang,
            severity: severity,
            title: "Recorded Main-Thread Stall (\(String(format: "%.0f", duration * 1000))ms)",
            details: "UI thread blocked for \(String(format: "%.2f", duration))s.",
            sourceLocation: source ?? "MainRunLoop",
            contextMetadata: ["duration": String(format: "%.3fs", duration)]
        )
    }
}
