import Foundation

/// Asynchronous test utilities to replace arbitrary sleep delays with deterministic conditions.
public enum AsyncTestHelpers {
    public enum TimeoutError: LocalizedError {
        case timedOut(message: String)

        public var errorDescription: String? {
            switch self {
            case .timedOut(let msg):
                return "Async operation timed out: \(msg)"
            }
        }
    }

    /// Asynchronously polls a condition until it evaluates to true or times out.
    public static func waitUntil(
        timeout: TimeInterval = 2.0,
        pollingInterval: TimeInterval = 0.05,
        message: String = "Condition not met before timeout",
        condition: @Sendable () async throws -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if try await condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }

        throw TimeoutError.timedOut(message: message)
    }
}
