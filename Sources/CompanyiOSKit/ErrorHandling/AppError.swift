import Foundation

/// Unified domain error model across the framework.
public enum AppError: LocalizedError, Sendable, Equatable {
    case network(reason: String, statusCode: Int?, isRetryable: Bool)
    case unauthorized(reason: String)
    case forbidden(reason: String)
    case notFound(reason: String)
    case validationFailed(field: String, reason: String)
    case storage(reason: String)
    case permissionDenied(permission: String)
    case cancelled
    case timeout
    case decodingFailed(reason: String)
    case unknown(reason: String)

    public var errorDescription: String? {
        switch self {
        case .network(let reason, let statusCode, _):
            if let code = statusCode {
                return "Network error (\(code)): \(reason)"
            }
            return "Network error: \(reason)"
        case .unauthorized(let reason):
            return "Unauthorized: \(reason)"
        case .forbidden(let reason):
            return "Access forbidden: \(reason)"
        case .notFound(let reason):
            return "Resource not found: \(reason)"
        case .validationFailed(let field, let reason):
            return "Validation failed for '\(field)': \(reason)"
        case .storage(let reason):
            return "Storage error: \(reason)"
        case .permissionDenied(let permission):
            return "Permission denied for \(permission)"
        case .cancelled:
            return "Operation was cancelled."
        case .timeout:
            return "Operation timed out."
        case .decodingFailed(let reason):
            return "Failed to decode response: \(reason)"
        case .unknown(let reason):
            return "An unexpected error occurred: \(reason)"
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .network(_, _, let retryable):
            return retryable
        case .timeout:
            return true
        default:
            return false
        }
    }
}
