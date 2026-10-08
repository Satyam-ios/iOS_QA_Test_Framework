import Foundation

/// Policy controlling whether and when a failed network request should be retried.
public protocol RetryPolicy: Sendable {
    func evaluate(attempt: Int, error: Error) -> (shouldRetry: Bool, delay: TimeInterval)
}

/// Exponential backoff retry policy with jitter and max attempt bounds.
public struct ExponentialBackoffRetryPolicy: RetryPolicy, Sendable {
    public let maxAttempts: Int
    public let initialDelay: TimeInterval
    public let multiplier: Double
    public let maxDelay: TimeInterval

    public init(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        multiplier: Double = 2.0,
        maxDelay: TimeInterval = 10.0
    ) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.multiplier = multiplier
        self.maxDelay = maxDelay
    }

    public func evaluate(attempt: Int, error: Error) -> (shouldRetry: Bool, delay: TimeInterval) {
        guard attempt < maxAttempts else {
            return (false, 0)
        }

        // Only retry network errors marked as retryable
        if let netError = error as? NetworkError, !netError.isRetryable {
            return (false, 0)
        }

        let calculatedDelay = initialDelay * pow(multiplier, Double(attempt))
        let cappedDelay = min(calculatedDelay, maxDelay)
        return (true, cappedDelay)
    }
}
