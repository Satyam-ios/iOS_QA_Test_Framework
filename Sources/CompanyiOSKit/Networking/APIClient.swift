import Foundation

/// Primary abstraction for executing HTTP requests against remote APIs.
public protocol APIClientProtocol: Sendable {
    func execute<T: Decodable & Sendable>(_ request: APIRequest) async throws -> APIResponse<T>
    func executeRaw(_ request: APIRequest) async throws -> (Data, HTTPURLResponse)
}

/// Standard async/await API Client implementation.
public final class APIClient: APIClientProtocol, Sendable {
    public let baseURL: URL
    private let session: URLSession
    private let tokenManager: (any TokenManaging)?
    private let retryPolicy: any RetryPolicy
    private let logger: any LoggerProtocol
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenManager: (any TokenManaging)? = nil,
        retryPolicy: any RetryPolicy = ExponentialBackoffRetryPolicy(),
        logger: any LoggerProtocol = AppLogger.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenManager = tokenManager
        self.retryPolicy = retryPolicy
        self.logger = logger
        self.decoder = decoder
    }

    public func execute<T: Decodable & Sendable>(_ request: APIRequest) async throws -> APIResponse<T> {
        let (data, response) = try await executeWithRetry(request: request, attempt: 0)

        do {
            let decoded = try decoder.decode(T.self, from: data)
            var responseHeaders: [String: String] = [:]
            for (k, v) in response.allHeaderFields {
                responseHeaders["\(k)"] = "\(v)"
            }
            return APIResponse(
                value: decoded,
                statusCode: response.statusCode,
                headers: responseHeaders,
                rawData: data
            )
        } catch let decodeError {
            logger.error("Failed to decode response: \(decodeError)")
            throw NetworkError.decodingFailed(reason: decodeError.localizedDescription)
        }
    }

    public func executeRaw(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        return try await executeWithRetry(request: request, attempt: 0)
    }

    private func executeWithRetry(request: APIRequest, attempt: Int) async throws -> (Data, HTTPURLResponse) {
        do {
            let urlRequest = try await buildURLRequest(from: request)
            logger.debug("Executing \(request.method.rawValue) \(urlRequest.url?.absoluteString ?? "") (attempt \(attempt + 1))")

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(reason: "Non-HTTP response received.")
            }

            try evaluateHTTPStatus(httpResponse, data: data)
            return (data, httpResponse)
        } catch {
            let (shouldRetry, delay) = retryPolicy.evaluate(attempt: attempt, error: error)
            if shouldRetry && delay > 0 {
                logger.warning("Request failed, retrying in \(delay)s. Error: \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }
            throw error
        }
    }

    private func buildURLRequest(from request: APIRequest) async throws -> URLRequest {
        guard let url = request.url(relativeTo: baseURL) else {
            throw NetworkError.invalidURL(request.path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        if let timeout = request.timeoutInterval {
            urlRequest.timeoutInterval = timeout
        }

        // Apply headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Apply auth header if required
        if request.requiresAuthentication, let tokenManager = tokenManager {
            if let accessToken = try await tokenManager.getAccessToken() {
                urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: AppConstants.HTTPHeader.authorization)
            }
        }

        return urlRequest
    }

    private func evaluateHTTPStatus(_ response: HTTPURLResponse, data: Data) throws {
        let code = response.statusCode
        switch code {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.clientError(statusCode: code, message: message)
        case 500...599:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: code, message: message)
        default:
            throw NetworkError.unknown(reason: "HTTP \(code)")
        }
    }
}
