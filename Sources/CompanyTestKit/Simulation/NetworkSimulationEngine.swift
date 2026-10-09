import Foundation
import CompanyiOSKit

/// Configuration specifying network fault injection scenarios.
public struct NetworkFaultScenario: Codable, Sendable, Equatable {
    public var simulatedLatency: TimeInterval
    public var failureRate: Double // 0.0 to 1.0
    public var simulatedStatusCode: Int?
    public var isSimulatingOffline: Bool
    public var dropPackets: Bool

    public init(
        simulatedLatency: TimeInterval = 0.0,
        failureRate: Double = 0.0,
        simulatedStatusCode: Int? = nil,
        isSimulatingOffline: Bool = false,
        dropPackets: Bool = false
    ) {
        self.simulatedLatency = simulatedLatency
        self.failureRate = failureRate
        self.simulatedStatusCode = simulatedStatusCode
        self.isSimulatingOffline = isSimulatingOffline
        self.dropPackets = dropPackets
    }

    public static let standard = NetworkFaultScenario()
    public static let highLatency = NetworkFaultScenario(simulatedLatency: 2.5)
    public static let offline = NetworkFaultScenario(isSimulatingOffline: true)
    public static let server500 = NetworkFaultScenario(simulatedStatusCode: 500)
    public static let flaky = NetworkFaultScenario(failureRate: 0.5, simulatedStatusCode: 503)
}

/// Network fault injection engine for simulating poor connectivity, timeouts, and server errors.
public final class NetworkSimulationEngine: @unchecked Sendable {
    public static let shared = NetworkSimulationEngine()

    private let lock = NSLock()
    private var activeScenario: NetworkFaultScenario = .standard
    private var simulatedRequestCount: Int = 0
    private var simulatedFailureCount: Int = 0

    private init() {}

    /// Activates a fault injection scenario.
    public func setScenario(_ scenario: NetworkFaultScenario) {
        lock.lock()
        defer { lock.unlock() }
        activeScenario = scenario
    }

    /// Resets all network simulation faults to normal operating mode.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        activeScenario = .standard
        simulatedRequestCount = 0
        simulatedFailureCount = 0
    }

    public var currentScenario: NetworkFaultScenario {
        lock.lock()
        defer { lock.unlock() }
        return activeScenario
    }

    private func recordAttempt() -> NetworkFaultScenario {
        lock.lock()
        defer { lock.unlock() }
        simulatedRequestCount += 1
        return activeScenario
    }

    private func recordFailure() {
        lock.lock()
        defer { lock.unlock() }
        simulatedFailureCount += 1
    }

    /// Simulates fault processing for an outgoing request.
    /// Returns normally if no fault triggered, or throws NetworkError if a fault is configured.
    public func processRequest() async throws {
        let scenario = recordAttempt()

        // 1. Offline Mode Simulation
        if scenario.isSimulatingOffline {
            recordFailure()
            throw NetworkError.offline
        }

        // 2. Simulated Latency
        if scenario.simulatedLatency > 0 {
            try? await Task.sleep(nanoseconds: UInt64(scenario.simulatedLatency * 1_000_000_000))
        }

        // 3. Simulated Packet Drop / Timeout
        if scenario.dropPackets {
            recordFailure()
            throw NetworkError.timedOut
        }

        // 4. Simulated HTTP Status Errors
        if let code = scenario.simulatedStatusCode {
            recordFailure()
            throw NetworkError.serverError(statusCode: code, message: "Simulated \(code) fault")
        }

        // 5. Flaky Failure Rate
        if scenario.failureRate > 0 && Double.random(in: 0...1) < scenario.failureRate {
            recordFailure()
            throw NetworkError.serverError(statusCode: 503, message: "Simulated intermittent 503 fault")
        }
    }

    /// Metrics on simulated faults.
    public var metrics: (totalRequests: Int, failures: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (simulatedRequestCount, simulatedFailureCount)
    }
}
