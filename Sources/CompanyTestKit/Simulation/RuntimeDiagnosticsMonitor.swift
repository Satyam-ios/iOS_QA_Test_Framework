import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Specific hardware capability required to execute a test case.
public enum HardwareRequirement: String, Codable, Sendable {
    case physicalBLEPeripheral = "Physical BLE Peripheral"
    case cameraHardware = "Physical Camera Sensor"
    case physicalNFC = "Physical NFC Reader"
    case biometricsSensor = "Biometric Sensor"
    case cellularModem = "Cellular Radio Hardware"
}

/// Result of evaluating whether a hardware test can realistically execute.
public enum HardwareViabilityResult: Sendable, Equatable {
    case viable
    case unexecutable(reason: String)

    public var isViable: Bool {
        switch self {
        case .viable: return true
        case .unexecutable: return false
        }
    }
}

/// Runtime snapshot of memory usage and thread responsiveness.
public struct DiagnosticsSnapshot: Codable, Sendable, Equatable {
    public let memoryUsageBytes: UInt64
    public let memoryUsageMegabytes: Double
    public let isRunningInSimulator: Bool
    public let timestamp: Date

    public init(
        memoryUsageBytes: UInt64,
        memoryUsageMegabytes: Double,
        isRunningInSimulator: Bool,
        timestamp: Date = Date()
    ) {
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryUsageMegabytes = memoryUsageMegabytes
        self.isRunningInSimulator = isRunningInSimulator
        self.timestamp = timestamp
    }
}

/// Real-time diagnostics monitor capturing performance, memory consumption, and honest hardware availability.
public final class RuntimeDiagnosticsMonitor: @unchecked Sendable {
    public static let shared = RuntimeDiagnosticsMonitor()

    private let lock = NSLock()
    private var peakMemoryBytes: UInt64 = 0

    private init() {}

    /// Indicates whether the runtime execution environment is an Apple simulator.
    public var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Evaluates if an automated test requiring physical hardware can honestly execute.
    public func evaluateHardwareViability(for requirement: HardwareRequirement) -> HardwareViabilityResult {
        if isSimulator {
            switch requirement {
            case .physicalBLEPeripheral:
                return .unexecutable(
                    reason: "Physical BLE IoT device unavailable in simulator environment. Test honestly classified as 'Not Executed' to prevent false negatives."
                )
            case .physicalNFC:
                return .unexecutable(
                    reason: "CoreNFC physical reader unavailable in simulator environment."
                )
            case .cellularModem:
                return .unexecutable(
                    reason: "Cellular radio telephony unavailable in simulator environment."
                )
            case .cameraHardware, .biometricsSensor:
                // Camera and FaceID can have partial mock support in simulator, but sensor is absent
                return .viable
            }
        }

        return .viable
    }

    /// Captures the current memory footprint of the host application process.
    public func captureSnapshot() -> DiagnosticsSnapshot {
        lock.lock()
        defer { lock.unlock() }

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

        if memoryBytes > peakMemoryBytes {
            peakMemoryBytes = memoryBytes
        }

        let mb = Double(memoryBytes) / (1024.0 * 1024.0)
        return DiagnosticsSnapshot(
            memoryUsageBytes: memoryBytes,
            memoryUsageMegabytes: mb,
            isRunningInSimulator: isSimulator
        )
    }

    /// Peak memory footprint observed during the current session in megabytes.
    public var peakMemoryMegabytes: Double {
        lock.lock()
        defer { lock.unlock() }
        return Double(peakMemoryBytes) / (1024.0 * 1024.0)
    }
}
