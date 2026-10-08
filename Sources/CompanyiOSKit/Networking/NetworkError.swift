import Foundation

/// Specific network errors encountered during HTTP execution.
public enum NetworkError: LocalizedError, Sendable, Equatable {
    case invalidURL(String)
    case unauthorized
    case forbidden
    case notFound
    case clientError(statusCode: Int, message: String?)
    case serverError(statusCode: Int, message: String?)
    case decodingFailed(reason: String)
    case timedOut
    case offline
    case cancelled
    case unknown(reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .unauthorized:
            return "Unauthorized (HTTP 401). Please check credentials or refresh session."
        case .forbidden:
            return "Forbidden (HTTP 403). Access is denied."
        case .notFound:
            return "Resource not found (HTTP 404)."
        case .clientError(let code, let msg):
            return "Client error (\(code)): \(msg ?? "No message")"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg ?? "No message")"
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        case .timedOut:
            return "The network request timed out."
        case .offline:
            return "The device is currently offline."
        case .cancelled:
            return "The network request was cancelled."
        case .unknown(let reason):
            return "Network error: \(reason)"
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .serverError(let code, _):
            return code >= 500
        case .timedOut, .offline:
            return true
        default:
            return false
        }
    }
}
