import Foundation

/// HTTP methods supported by the API client.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
}

/// Representation of an API request.
public struct APIRequest: Sendable {
    public let path: String
    public let method: HTTPMethod
    public var headers: [String: String]
    public var queryParameters: [String: String]
    public var body: Data?
    public var requiresAuthentication: Bool
    public var timeoutInterval: TimeInterval?

    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        requiresAuthentication: Bool = true,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
        self.requiresAuthentication = requiresAuthentication
        self.timeoutInterval = timeoutInterval
    }

    /// Convenience initializer with an Encodable JSON body.
    public static func json<B: Encodable & Sendable>(
        path: String,
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        body: B,
        requiresAuthentication: Bool = true,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> APIRequest {
        var mergedHeaders = headers
        mergedHeaders[AppConstants.HTTPHeader.contentType] = AppConstants.ContentType.json
        let data = try encoder.encode(body)
        return APIRequest(
            path: path,
            method: method,
            headers: mergedHeaders,
            queryParameters: queryParameters,
            body: data,
            requiresAuthentication: requiresAuthentication
        )
    }

    /// Builds the full URL given a base URL.
    public func url(relativeTo baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            return nil
        }
        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url
    }
}
