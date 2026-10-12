import Foundation
#if canImport(Darwin)
import Darwin
#endif
#if canImport(UIKit)
import UIKit
#endif
import CompanyiOSKit

/// Monitors runtime memory consumption, system memory warnings, and memory spikes.
public final class MemoryPerformanceMonitor: @unchecked Sendable {
    public static let shared = MemoryPerformanceMonitor()

    private let lock = NSLock()
    private var isMonitoring = false
    private var timer: Timer?
    private var baselineMemoryBytes: UInt64 = 0
    private var peakMemoryBytes: UInt64 = 0
    private var memoryWarningCount: Int = 0

    private init() {}

    /// Starts periodic memory observation and notification subscriptions.
    public func startMonitoring(sampleInterval: TimeInterval = 2.0) {
        lock.lock()
        defer { lock.unlock() }

        guard !isMonitoring else { return }
        isMonitoring = true

        baselineMemoryBytes = currentResidentMemoryBytes()
        peakMemoryBytes = baselineMemoryBytes

        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        #endif
    }

    /// Stops memory observation.
    public func stopMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    /// Handles a received system memory warning.
    public func handleMemoryWarning() {
        lock.lock()
        memoryWarningCount += 1
        let currentMB = Double(currentResidentMemoryBytes()) / (1024.0 * 1024.0)
        let count = memoryWarningCount
        lock.unlock()

        RuntimeTelemetryStore.shared.record(
            category: .memoryWarning,
            severity: .critical,
            title: "System Memory Warning Received (#\(count))",
            details: "Host application received OS memory warning at \(String(format: "%.1f", currentMB)) MB resident memory. OS may terminate process if memory is not freed.",
            contextMetadata: ["residentMemoryMB": String(format: "%.1f", currentMB), "warningCount": "\(count)"]
        )
    }

    /// Checks the current memory against baseline and records growth warnings.
    @discardableResult
    public func checkMemoryPressure() -> Double {
        lock.lock()
        defer { lock.unlock() }

        let current = currentResidentMemoryBytes()
        if current > peakMemoryBytes {
            peakMemoryBytes = current
        }

        let growthBytes = current > baselineMemoryBytes ? (current - baselineMemoryBytes) : 0
        let growthMB = Double(growthBytes) / (1024.0 * 1024.0)
        let currentMB = Double(current) / (1024.0 * 1024.0)

        // If memory grew by > 50 MB since start, record a memory growth event
        if growthMB >= 50.0 {
            RuntimeTelemetryStore.shared.record(
                category: .memoryGrowth,
                severity: .high,
                title: "Excessive Memory Growth (+50MB)",
                details: "Process memory expanded by \(String(format: "%.1f", growthMB)) MB to \(String(format: "%.1f", currentMB)) MB. Inspect view controllers and image caches for retain cycles.",
                contextMetadata: ["growthMB": String(format: "%.1f", growthMB), "totalMB": String(format: "%.1f", currentMB)]
            )
        }

        return currentMB
    }

    /// Reads resident memory size in bytes from mach task info.
    public func currentResidentMemoryBytes() -> UInt64 {
        var memoryBytes: UInt64 = 0
        #if canImport(Darwin)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            memoryBytes = UInt64(info.resident_size)
        }
        #endif
        return memoryBytes
    }

    public var peakMemoryMegabytes: Double {
        lock.lock()
        defer { lock.unlock() }
        return Double(peakMemoryBytes) / (1024.0 * 1024.0)
    }

    public var totalWarningsCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return memoryWarningCount
    }
}
