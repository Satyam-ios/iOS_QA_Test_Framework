import Foundation

/// Strongly-typed response from an API invocation.
public struct APIResponse<T: Sendable>: Sendable {
    public let value: T
    public let statusCode: Int
    public let headers: [String: String]
    public let rawData: Data

    public init(value: T, statusCode: Int, headers: [String: String], rawData: Data) {
        self.value = value
        self.statusCode = statusCode
        self.headers = headers
        self.rawData = rawData
    }

    public var isSuccessful: Bool {
        return statusCode >= 200 && statusCode < 300
    }
}
