import Foundation

/// Presentation model representing an error to an end-user.
public struct UserFacingError: Sendable, Equatable {
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let isRetryable: Bool

    public init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        isRetryable: Bool = false
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.isRetryable = isRetryable
    }
}

/// Mapper converting raw errors into user-facing models and canonical AppErrors.
public struct ErrorMapper: Sendable {
    public static let shared = ErrorMapper()

    public init() {}

    /// Converts an arbitrary Error into a strongly-typed AppError.
    public func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            case .notConnectedToInternet, .networkConnectionLost:
                return .network(reason: "No internet connection.", statusCode: nil, isRetryable: true)
            default:
                return .network(reason: urlError.localizedDescription, statusCode: nil, isRetryable: true)
            }
        }

        if let decodingError = error as? DecodingError {
            return .decodingFailed(reason: decodingError.localizedDescription)
        }

        return .unknown(reason: error.localizedDescription)
    }

    /// Converts an AppError into user-friendly presentation copy.
    public func mapToUserFacingError(_ error: AppError) -> UserFacingError {
        switch error {
        case .network(_, _, let retryable):
            return UserFacingError(
                title: "Connection Issue",
                message: "Please check your internet connection and try again.",
                actionTitle: retryable ? "Retry" : nil,
                isRetryable: retryable
            )
        case .unauthorized:
            return UserFacingError(
                title: "Session Expired",
                message: "Please log in again to continue.",
                actionTitle: "Log In",
                isRetryable: false
            )
        case .forbidden:
            return UserFacingError(
                title: "Access Denied",
                message: "You do not have permission to perform this action.",
                actionTitle: nil,
                isRetryable: false
            )
        case .notFound:
            return UserFacingError(
                title: "Not Found",
                message: "The requested item could not be found.",
                actionTitle: nil,
                isRetryable: false
            )
        case .validationFailed(let field, let reason):
            return UserFacingError(
                title: "Invalid \(field.capitalized)",
                message: reason,
                actionTitle: "Fix Input",
                isRetryable: false
            )
        case .timeout:
            return UserFacingError(
                title: "Request Timed Out",
                message: "The server took too long to respond. Please try again.",
                actionTitle: "Retry",
                isRetryable: true
            )
        case .permissionDenied(let permission):
            return UserFacingError(
                title: "Permission Required",
                message: "Please enable access to \(permission) in Settings.",
                actionTitle: "Settings",
                isRetryable: false
            )
        case .storage, .decodingFailed, .unknown, .cancelled:
            return UserFacingError(
                title: "Something Went Wrong",
                message: "An unexpected error occurred. Please try again later.",
                actionTitle: "Dismiss",
                isRetryable: false
            )
        }
    }
}
