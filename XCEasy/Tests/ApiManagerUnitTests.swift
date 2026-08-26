import Foundation
import XCTest
@testable import XCEasy

final class ApiManagerUnitTests: XCTestCase {
    func testCallbackMethodsCreateExpectedRequestsAndReturnSuccess() throws {
        let transport = StubApiRequestTransport(responses: Array(
            repeating: response(statusCode: 200, data: Data("ok".utf8)),
            count: 5
        ))
        let manager = makeManager(transport: transport)
        let body = Data("body".utf8)
        var results: [ApiResult] = []

        manager.get(route: "/get", headers: ["X-Test": "get"]) { results.append($0) }
        manager.post(route: "/post", body: body) { results.append($0) }
        manager.put(route: "/put", body: body) { results.append($0) }
        manager.delete(route: "/delete") { results.append($0) }
        manager.patch(route: "/patch", body: body) { results.append($0) }

        XCTAssertEqual(results.count, 5)
        XCTAssertTrue(results.allSatisfy {
            guard case .success(let response) = $0 else { return false }
            return response.statusCode == 200 && response.data == Data("ok".utf8)
        })
        XCTAssertEqual(transport.requests.map(\.httpMethod), ["GET", "POST", "PUT", "DELETE", "PATCH"])
        XCTAssertEqual(transport.requests.map { $0.url?.path }, ["/get", "/post", "/put", "/delete", "/patch"])
        XCTAssertEqual(transport.requests[0].value(forHTTPHeaderField: "X-Test"), "get")
        XCTAssertEqual(transport.requests[1].httpBody, body)
        XCTAssertEqual(transport.requests[2].httpBody, body)
        XCTAssertNil(transport.requests[3].httpBody)
        XCTAssertEqual(transport.requests[4].httpBody, body)
        XCTAssertEqual(
            transport.requests.map(\.timeoutInterval),
            Array(repeating: XCEasyConfig.requestTimeout, count: 5)
        )
    }

    func testRequestsUseConfiguredRequestTimeout() {
        let originalTimeout = XCEasyConfig.requestTimeout
        defer { XCEasyConfig.requestTimeout = originalTimeout }
        XCEasyConfig.requestTimeout = 7
        let transport = StubApiRequestTransport(responses: [
            response(statusCode: 200, data: Data("ok".utf8))
        ])
        let manager = makeManager(transport: transport)

        manager.get(route: "/configured-timeout") { _ in }

        XCTAssertEqual(transport.requests.first?.timeoutInterval, 7)
    }

    func testCallbackClassifiesEveryFailureWithoutRealNetwork() throws {
        let underlying = NSError(domain: "ApiManagerUnitTests", code: 1)
        let responses = [
            response(statusCode: 503, data: Data()),
            ApiTransportResponse(data: Data(), response: nil, error: nil),
            ApiTransportResponse(data: nil, response: nil, error: nil, isTimeout: true),
            ApiTransportResponse(data: nil, response: nil, error: underlying),
            ApiTransportResponse(data: nil, response: nil, error: nil)
        ]
        let transport = StubApiRequestTransport(responses: responses)
        let manager = makeManager(transport: transport)
        var errors: [ApiError] = []

        for route in ["/http", "/invalid-response", "/timeout", "/network", "/no-data"] {
            manager.get(route: route, soft: true) { result in
                if case .failure(let error) = result { errors.append(error) }
            }
        }

        XCTAssertEqual(errors.count, 5)
        guard case .http(statusCode: 503) = errors[0] else { return XCTFail("Expected HTTP error") }
        guard case .invalidResponse = errors[1] else { return XCTFail("Expected invalid response") }
        guard case .timeout = errors[2] else { return XCTFail("Expected timeout") }
        guard case .network(let error) = errors[3] else { return XCTFail("Expected network error") }
        XCTAssertEqual((error as NSError).domain, underlying.domain)
        guard case .noData = errors[4] else { return XCTFail("Expected no-data error") }
    }

    func testInvalidURLAndWaitTimeoutCompleteExactlyOnce() {
        let invalidTransport = StubApiRequestTransport(responses: [])
        let invalidManager = ApiManager(
            baseURL: "%",
            expectationFactory: DefaultExpectationFactory(),
            transport: invalidTransport
        )
        var invalidResults: [ApiResult] = []
        invalidManager.get(route: "%", soft: true) { invalidResults.append($0) }

        XCTAssertEqual(invalidResults.count, 1)
        XCTAssertTrue(invalidTransport.requests.isEmpty)
        guard case .failure(.invalidURL) = invalidResults[0] else {
            return XCTFail("Expected invalid URL")
        }

        let duplicateTransport = DuplicateApiRequestTransport(response: response(statusCode: 200, data: Data()))
        let timeoutManager = ApiManager(
            baseURL: "https://example.test",
            expectationFactory: ForcedTimeoutExpectationFactory(),
            transport: duplicateTransport
        )
        var timeoutResults: [ApiResult] = []
        timeoutManager.get(route: "/slow", soft: true) { timeoutResults.append($0) }

        XCTAssertEqual(timeoutResults.count, 1)
        guard case .failure(.timeout) = timeoutResults[0] else {
            return XCTFail("Expected wait timeout")
        }
    }

    func testCompletedWaitWithoutTransportResponseReturnsNoData() {
        let manager = ApiManager(
            baseURL: "https://example.test",
            expectationFactory: CompletedWithoutResponseExpectationFactory(),
            transport: SilentApiRequestTransport()
        )
        var result: ApiResult?

        manager.get(route: "/missing", soft: true) { result = $0 }

        guard case .failure(.noData) = result else {
            return XCTFail("Expected no-data error")
        }
    }

    @available(iOS 15.0, *)
    func testAsyncMethodsReturnSuccessAndThrowTypedFailure() async throws {
        let responses = (200...204).map { response(statusCode: $0, data: Data("\($0)".utf8)) }
        let transport = StubApiRequestTransport(responses: responses + [response(statusCode: 401, data: Data())])
        let manager = makeManager(transport: transport)

        let getResponse = try await manager.get(route: "/get")
        let postResponse = try await manager.post(route: "/post")
        let putResponse = try await manager.put(route: "/put")
        let deleteResponse = try await manager.delete(route: "/delete")
        let patchResponse = try await manager.patch(route: "/patch")
        XCTAssertEqual(getResponse.statusCode, 200)
        XCTAssertEqual(postResponse.statusCode, 201)
        XCTAssertEqual(putResponse.statusCode, 202)
        XCTAssertEqual(deleteResponse.statusCode, 203)
        XCTAssertEqual(patchResponse.statusCode, 204)

        do {
            _ = try await manager.get(route: "/unauthorized")
            XCTFail("Expected typed HTTP error")
        } catch ApiError.http(let statusCode) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeManager(transport: ApiRequestTransport) -> ApiManager {
        ApiManager(
            baseURL: "https://example.test",
            expectationFactory: DefaultExpectationFactory(),
            transport: transport
        )
    }

    private func response(statusCode: Int, data: Data?) -> ApiTransportResponse {
        let url = URL(string: "https://example.test")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return ApiTransportResponse(data: data, response: httpResponse, error: nil)
    }
}

private final class StubApiRequestTransport: ApiRequestTransport {
    private(set) var requests: [URLRequest] = []
    private var responses: [ApiTransportResponse]

    init(responses: [ApiTransportResponse]) {
        self.responses = responses
    }

    func execute(_ request: URLRequest, completion: @escaping (ApiTransportResponse) -> Void) {
        requests.append(request)
        guard !responses.isEmpty else { return }
        completion(responses.removeFirst())
    }
}

private final class DuplicateApiRequestTransport: ApiRequestTransport {
    private let response: ApiTransportResponse

    init(response: ApiTransportResponse) {
        self.response = response
    }

    func execute(_ request: URLRequest, completion: @escaping (ApiTransportResponse) -> Void) {
        completion(response)
        completion(response)
    }
}

private final class SilentApiRequestTransport: ApiRequestTransport {
    func execute(_ request: URLRequest, completion: @escaping (ApiTransportResponse) -> Void) {}
}

private final class ForcedTimeoutExpectationFactory: TestExpectationFactory {
    func makeExpectation(description: String) -> XCTestExpectation {
        XCTestExpectation(description: description)
    }

    func waitForExpectations(timeout: TimeInterval) -> Bool { false }
}

private final class CompletedWithoutResponseExpectationFactory: TestExpectationFactory {
    func makeExpectation(description: String) -> XCTestExpectation {
        XCTestExpectation(description: description)
    }

    func waitForExpectations(timeout: TimeInterval) -> Bool { true }
}
