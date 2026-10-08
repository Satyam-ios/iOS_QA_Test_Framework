import Foundation

/// Defines the execution environments for applications using CompanyiOSKit.
public enum AppEnvironment: String, Sendable, CaseIterable {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"
    case testing = "Testing"

    /// Default base URL configuration for each environment.
    public var defaultBaseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://dev-api.company.com/v1")!
        case .staging:
            return URL(string: "https://staging-api.company.com/v1")!
        case .production:
            return URL(string: "https://api.company.com/v1")!
        case .testing:
            return URL(string: "https://test-api.company.com/v1")!
        }
    }

    /// Whether verbose debug logs should be emitted in this environment.
    public var isLoggingEnabled: Bool {
        switch self {
        case .development, .staging, .testing:
            return true
        case .production:
            return false
        }
    }
}
