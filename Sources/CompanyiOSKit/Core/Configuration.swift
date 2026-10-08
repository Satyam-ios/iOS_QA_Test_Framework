import Foundation

/// Centralized configuration specification for host applications.
public struct AppConfiguration: Sendable {
    public let environment: AppEnvironment
    public let apiBaseURL: URL
    public let requestTimeoutInterval: TimeInterval
    public let maxRetryAttempts: Int
    public let retryBackoffFactor: Double
    public let isDebugMode: Bool

    public init(
        environment: AppEnvironment = .production,
        apiBaseURL: URL? = nil,
        requestTimeoutInterval: TimeInterval = 30.0,
        maxRetryAttempts: Int = 3,
        retryBackoffFactor: Double = 2.0,
        isDebugMode: Bool = false
    ) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL ?? environment.defaultBaseURL
        self.requestTimeoutInterval = requestTimeoutInterval
        self.maxRetryAttempts = maxRetryAttempts
        self.retryBackoffFactor = retryBackoffFactor
        self.isDebugMode = isDebugMode
    }

    /// Default production configuration.
    public static let standard = AppConfiguration()

    /// Configuration pre-configured for automated tests.
    public static let test = AppConfiguration(
        environment: .testing,
        requestTimeoutInterval: 5.0,
        maxRetryAttempts: 1,
        retryBackoffFactor: 0.1,
        isDebugMode: true
    )
}

/// Thread-safe configuration manager providing injectable configuration state.
public actor ConfigurationManager {
    public static let shared = ConfigurationManager()

    private var currentConfig: AppConfiguration

    public init(initialConfiguration: AppConfiguration = .standard) {
        self.currentConfig = initialConfiguration
    }

    public func getConfiguration() -> AppConfiguration {
        return currentConfig
    }

    public func updateConfiguration(_ configuration: AppConfiguration) {
        self.currentConfig = configuration
    }
}
