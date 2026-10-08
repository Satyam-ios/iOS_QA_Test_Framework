import Foundation
import CompanyiOSKit

/// In-memory actor mock for APIClientProtocol enabling deterministic network testing under Swift 6 strict concurrency.
public actor MockAPIClient: APIClientProtocol {
    private var stubbedResponses: [String: (Data, HTTPURLResponse)] = [:]
    private var defaultError: Error?
    private var _executedRequests: [APIRequest] = []

    public var executedRequests: [APIRequest] {
        return _executedRequests
    }

    public init() {}

    /// Registers a stubbed response for a specific path.
    public func stub(
        path: String,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        data: Data = Data()
    ) {
        let url = URL(string: "https://mock.test\(path)")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        stubbedResponses[path] = (data, response)
    }

    /// Registers a stubbed JSON response.
    public func stubJSON<T: Encodable>(
        path: String,
        statusCode: Int = 200,
        value: T,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        let data = try encoder.encode(value)
        stub(path: path, statusCode: statusCode, data: data)
    }

    /// Configures the client to fail all requests with the provided error.
    public func setError(_ error: Error?) {
        self.defaultError = error
    }

    public func execute<T: Decodable & Sendable>(_ request: APIRequest) async throws -> APIResponse<T> {
        let (data, response) = try await executeRaw(request)

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
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
        } catch {
            throw NetworkError.decodingFailed(reason: error.localizedDescription)
        }
    }

    public func executeRaw(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        _executedRequests.append(request)

        if let error = defaultError {
            throw error
        }

        if let stub = stubbedResponses[request.path] {
            if stub.1.statusCode == 401 {
                throw NetworkError.unauthorized
            } else if stub.1.statusCode == 403 {
                throw NetworkError.forbidden
            } else if stub.1.statusCode == 404 {
                throw NetworkError.notFound
            } else if stub.1.statusCode >= 500 {
                throw NetworkError.serverError(statusCode: stub.1.statusCode, message: "Stubbed Server Error")
            } else if stub.1.statusCode >= 400 {
                throw NetworkError.clientError(statusCode: stub.1.statusCode, message: "Stubbed Client Error")
            }
            return stub
        }

        throw NetworkError.notFound
    }

    public func reset() {
        stubbedResponses.removeAll()
        defaultError = nil
        _executedRequests.removeAll()
    }
}
