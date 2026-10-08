import XCTest
@testable import CompanyiOSKit
@testable import CompanyTestKit

final class NetworkingTests: XCTestCase {

    struct EchoPayload: Codable, Equatable, Sendable {
        let status: String
        let message: String
    }

    func testAPIRequest_WhenJSONBodyProvided_SerializesDataAndSetsHeader() throws {
        let payload = EchoPayload(status: "ok", message: "pong")
        let request = try APIRequest.json(path: "/echo", body: payload)

        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.headers[AppConstants.HTTPHeader.contentType], AppConstants.ContentType.json)
        XCTAssertNotNil(request.body)
    }

    func testAPIRequest_WhenQueryParametersProvided_ConstructsValidURL() {
        let baseURL = URL(string: "https://api.company.com/v1")!
        let request = APIRequest(
            path: "search",
            queryParameters: ["query": "antigravity", "limit": "10"]
        )

        let resolvedURL = request.url(relativeTo: baseURL)
        XCTAssertNotNil(resolvedURL)
        XCTAssertTrue(resolvedURL?.absoluteString.contains("query=antigravity") == true)
        XCTAssertTrue(resolvedURL?.absoluteString.contains("limit=10") == true)
    }

    func testMockAPIClient_WhenStubbedSuccess_DecodesExpectedPayload() async throws {
        let mockClient = MockAPIClient()
        let expected = EchoPayload(status: "success", message: "hello world")
        try await mockClient.stubJSON(path: "/status", value: expected)

        let request = APIRequest(path: "/status")
        let response: APIResponse<EchoPayload> = try await mockClient.execute(request)

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.value, expected)
        let executed = await mockClient.executedRequests
        XCTAssertEqual(executed.count, 1)
    }

    func testMockAPIClient_WhenStubbed401_ThrowsUnauthorized() async {
        let mockClient = MockAPIClient()
        await mockClient.stub(path: "/protected", statusCode: 401)

        let request = APIRequest(path: "/protected")
        do {
            let _: APIResponse<EchoPayload> = try await mockClient.execute(request)
            XCTFail("Expected 401 unauthorized error to be thrown")
        } catch let netError as NetworkError {
            XCTAssertEqual(netError, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockAPIClient_WhenStubbed500_ThrowsServerError() async {
        let mockClient = MockAPIClient()
        await mockClient.stub(path: "/broken", statusCode: 503)

        let request = APIRequest(path: "/broken")
        do {
            let _: APIResponse<EchoPayload> = try await mockClient.execute(request)
            XCTFail("Expected 503 server error to be thrown")
        } catch let netError as NetworkError {
            if case .serverError(let code, _) = netError {
                XCTAssertEqual(code, 503)
                XCTAssertTrue(netError.isRetryable)
            } else {
                XCTFail("Expected serverError case")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRetryPolicy_When500ServerError_RecommendsRetryWithBackoff() {
        let policy = ExponentialBackoffRetryPolicy(maxAttempts: 3, initialDelay: 1.0, multiplier: 2.0)
        let serverError = NetworkError.serverError(statusCode: 500, message: "Internal Error")

        let (shouldRetry1, delay1) = policy.evaluate(attempt: 0, error: serverError)
        XCTAssertTrue(shouldRetry1)
        XCTAssertEqual(delay1, 1.0)

        let (shouldRetry2, delay2) = policy.evaluate(attempt: 1, error: serverError)
        XCTAssertTrue(shouldRetry2)
        XCTAssertEqual(delay2, 2.0)

        let (shouldRetryMax, _) = policy.evaluate(attempt: 3, error: serverError)
        XCTAssertFalse(shouldRetryMax)
    }

    func testRetryPolicy_WhenNonRetryableError_RefusesRetry() {
        let policy = ExponentialBackoffRetryPolicy()
        let clientError = NetworkError.unauthorized

        let (shouldRetry, _) = policy.evaluate(attempt: 0, error: clientError)
        XCTAssertFalse(shouldRetry)
    }
}
