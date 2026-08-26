import Foundation
import Alamofire
import XCTest

/// Transport-neutral response consumed by `ApiManager`.
internal struct ApiTransportResponse {
    /// Raw response body, when one was received.
    let data: Data?

    /// HTTP metadata, when the server returned an HTTP response.
    let response: HTTPURLResponse?

    /// Underlying transport failure, when the request did not complete normally.
    let error: Error?

    /// Indicates that the transport classified the failure as a timeout.
    let isTimeout: Bool

    /// Creates a transport response for deterministic production and test adapters.
    ///
    /// - Parameters:
    ///   - data: Raw response data.
    ///   - response: HTTP response metadata.
    ///   - error: Underlying transport error.
    ///   - isTimeout: Whether the transport error represents a timeout.
    internal init(
        data: Data?,
        response: HTTPURLResponse?,
        error: Error?,
        isTimeout: Bool = false
    ) {
        self.data = data
        self.response = response
        self.error = error
        self.isTimeout = isTimeout
    }
}

/// Injectable boundary between `ApiManager` and a concrete networking library.
internal protocol ApiRequestTransport {
    /// Executes a request and reports one transport response.
    ///
    /// - Parameters:
    ///   - request: Fully configured URL request.
    ///   - completion: Callback invoked when the transport finishes.
    func execute(_ request: URLRequest, completion: @escaping (ApiTransportResponse) -> Void)
}

/// Alamofire-backed production transport.
private final class AlamofireApiRequestTransport: ApiRequestTransport {
    /// Executes the request away from the main queue so synchronous XCTest waiting cannot deadlock it.
    ///
    /// - Parameters:
    ///   - request: Fully configured URL request.
    ///   - completion: Callback invoked with normalized transport fields.
    func execute(_ request: URLRequest, completion: @escaping (ApiTransportResponse) -> Void) {
        AF.request(request).response(queue: .global(qos: .userInitiated)) { response in
            let urlError = response.error?.underlyingError as? URLError
            completion(ApiTransportResponse(
                data: response.data,
                response: response.response,
                error: response.error,
                isTimeout: urlError?.code == .timedOut
            ))
        }
    }
}

/// Thread-safe single-response storage used across the transport and XCTest wait boundary.
private final class ApiTransportResponseBox {
    /// Lock protecting response storage.
    private let lock = NSLock()

    /// First response accepted from the transport.
    private var response: ApiTransportResponse?

    /// Stores the first response and ignores duplicate transport callbacks.
    ///
    /// - Parameter response: Response to store.
    /// - Returns: `true` only when the response was accepted.
    func storeIfEmpty(_ response: ApiTransportResponse) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard self.response == nil else { return false }
        self.response = response
        return true
    }

    /// Returns the stored response without changing it.
    ///
    /// - Returns: The first transport response, or `nil` before completion.
    func load() -> ApiTransportResponse? {
        lock.lock()
        defer { lock.unlock() }
        return response
    }
}

// MARK: - ApiManager

/// Manager for handling HTTP API requests in UI tests.
///
/// This class provides a convenient wrapper around Alamofire for making HTTP requests
/// during UI testing. It integrates with the XCEasy framework's logging and step system.
///
/// ## Dependency Injection
///
/// ApiManager uses `TestExpectationFactory` for creating and waiting on expectations.
/// By default, it uses the test case itself as the factory, but this can be customized.
///
/// ```swift
/// // Default usage
/// let apiManager = ApiManager(baseURL: "https://api.example.com")
///
/// // Custom expectation factory (for testing)
/// let apiManager = ApiManager(
///     baseURL: "https://api.example.com",
///     expectationFactory: customFactory
/// )
/// ```
public class ApiManager {

    // MARK: - Properties

    /// The base URL for the API.
    private var baseURL: String

    /// The expectation factory for handling asynchronous operations.
    private let expectationFactory: TestExpectationFactory

    /// Request executor hidden behind an injectable transport boundary.
    private let transport: ApiRequestTransport

    // MARK: - Initialization

    /// Initializes the ApiManager with a base URL.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for the API.
    ///   - expectationFactory: The expectation factory for async operations.
    ///                        Defaults to a internal default implementation.
    public init(
        baseURL: String,
        expectationFactory: TestExpectationFactory = DefaultExpectationFactory()
    ) {
        self.baseURL = baseURL
        self.expectationFactory = expectationFactory
        self.transport = AlamofireApiRequestTransport()
    }

    /// Creates an API manager with a deterministic transport for framework tests.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL prepended to every route.
    ///   - expectationFactory: Factory controlling synchronous XCTest waits.
    ///   - transport: Request executor, normally a test fake.
    internal init(
        baseURL: String,
        expectationFactory: TestExpectationFactory,
        transport: ApiRequestTransport
    ) {
        self.baseURL = baseURL
        self.expectationFactory = expectationFactory
        self.transport = transport
    }

    // MARK: - Private Methods

    /// Creates a URL by appending the route to the base URL.
    ///
    /// - Parameter route: The route to append to the base URL.
    /// - Returns: A URL object if the URL is valid, otherwise nil.
    private func createURL(route: String) -> URL? {
        let urlString = "\(baseURL)\(route)"
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }

    /// Sends a network request with the specified parameters.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - httpMethod: The HTTP method to use (default is GET).
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    ///   - timeout: The timeout for the request (default is 30 seconds).
    ///   - completion: A closure to call when the request completes with a Result.
    private func sendRequest(
        route: String,
        httpMethod: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = XCEasyConfig.requestTimeout,
        completion: @escaping (ApiResult) -> Void
    ) {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "api_manager_send_request", arguments: [httpMethod.rawValue])

        operationStep(code: "api.request", title: stepTitle, target: httpMethod.rawValue) {
            guard let url = createURL(route: route) else {
                completion(.failure(.invalidURL))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.rawValue
            request.httpBody = body
            request.timeoutInterval = timeout

            if let headers = headers {
                for (key, value) in headers {
                    request.addValue(value, forHTTPHeaderField: key)
                }
            }

            let expectation = expectationFactory.makeExpectation(description: "Request")

            XCEasyTestLogger.shared.log("URL: \(url)", level: .debug)
            XCEasyTestLogger.shared.log("Method: \(httpMethod.rawValue)", level: .debug)
            XCEasyTestLogger.shared.log("Header count: \(headers?.count ?? 0)", level: .debug)
            XCEasyTestLogger.shared.log("Body bytes: \(body?.count ?? 0)", level: .debug)

            let responseBox = ApiTransportResponseBox()
            transport.execute(request) { response in
                if responseBox.storeIfEmpty(response) {
                    expectation.fulfill()
                }
            }

            guard expectationFactory.waitForExpectations(timeout: timeout) else {
                completion(.failure(.timeout))
                return
            }

            guard let response = responseBox.load() else {
                completion(.failure(.noData))
                return
            }
            completion(Self.apiResult(from: response))
        }
    }

    /// Converts transport fields into the stable public `ApiResult` contract.
    ///
    /// - Parameter response: Transport-neutral response fields.
    /// - Returns: A success for 2xx responses with data, otherwise a typed API error.
    private static func apiResult(from response: ApiTransportResponse) -> ApiResult {
        if let data = response.data {
            guard let httpResponse = response.response else {
                return .failure(.invalidResponse)
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                return .failure(.http(statusCode: httpResponse.statusCode))
            }
            return .success(ApiResponse(data: data, response: httpResponse))
        }

        if response.isTimeout {
            return .failure(.timeout)
        }
        if let error = response.error {
            return .failure(.network(error))
        }
        return .failure(.noData)
    }

    /// Handles an error by logging it and optionally failing the test.
    ///
    /// - Parameters:
    ///   - error: The API error to handle.
    ///   - soft: Whether to fail the test or not (default is false).
    private func handleError(_ error: ApiError, soft: Bool = false) {
        let logText = LocalizationManager.shared
            .string(forKey: "api_manager_send_request_error", arguments: [error.description])
        XCEasyTestLogger.shared.log(logText, level: .error)
        if !soft { XCTFail(logText) }
    }

    // MARK: - GET Request

    /// Sends a GET request to the specified route.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - soft: Whether to fail the test on error (default is false).
    ///   - completion: A closure to call when the request completes with a Result.
    public func get(
        route: String,
        headers: [String: String]? = nil,
        soft: Bool = false,
        completion: @escaping (ApiResult) -> Void
    ) {
        sendRequest(route: route, httpMethod: .get, headers: headers) { result in
            if case .failure(let error) = result {
                self.handleError(error, soft: soft)
            }
            completion(result)
        }
    }

    // MARK: - POST Request

    /// Sends a POST request to the specified route.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    ///   - soft: Whether to fail the test on error (default is false).
    ///   - completion: A closure to call when the request completes with a Result.
    public func post(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        soft: Bool = false,
        completion: @escaping (ApiResult) -> Void
    ) {
        sendRequest(route: route, httpMethod: .post, headers: headers, body: body) { result in
            if case .failure(let error) = result {
                self.handleError(error, soft: soft)
            }
            completion(result)
        }
    }

    // MARK: - PUT Request

    /// Sends a PUT request to the specified route.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    ///   - soft: Whether to fail the test on error (default is false).
    ///   - completion: A closure to call when the request completes with a Result.
    public func put(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        soft: Bool = false,
        completion: @escaping (ApiResult) -> Void
    ) {
        sendRequest(route: route, httpMethod: .put, headers: headers, body: body) { result in
            if case .failure(let error) = result {
                self.handleError(error, soft: soft)
            }
            completion(result)
        }
    }

    // MARK: - DELETE Request

    /// Sends a DELETE request to the specified route.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - soft: Whether to fail the test on error (default is false).
    ///   - completion: A closure to call when the request completes with a Result.
    public func delete(
        route: String,
        headers: [String: String]? = nil,
        soft: Bool = false,
        completion: @escaping (ApiResult) -> Void
    ) {
        sendRequest(route: route, httpMethod: .delete, headers: headers) { result in
            if case .failure(let error) = result {
                self.handleError(error, soft: soft)
            }
            completion(result)
        }
    }

    // MARK: - PATCH Request

    /// Sends a PATCH request to the specified route.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    ///   - soft: Whether to fail the test on error (default is false).
    ///   - completion: A closure to call when the request completes with a Result.
    public func patch(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        soft: Bool = false,
        completion: @escaping (ApiResult) -> Void
    ) {
        sendRequest(route: route, httpMethod: .patch, headers: headers, body: body) { result in
            if case .failure(let error) = result {
                self.handleError(error, soft: soft)
            }
            completion(result)
        }
    }

    // MARK: - Async/Await Methods (iOS 15+)

    /// Sends a GET request to the specified route with async/await support.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    /// - Returns: An `ApiResponse` if the request succeeds.
    /// - Throws: An `ApiError` if the request fails.
    @available(iOS 15.0, *)
    public func get(
        route: String,
        headers: [String: String]? = nil
    ) async throws -> ApiResponse {
        return try await withCheckedThrowingContinuation { continuation in
            get(route: route, headers: headers, soft: true) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Sends a POST request to the specified route with async/await support.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    /// - Returns: An `ApiResponse` if the request succeeds.
    /// - Throws: An `ApiError` if the request fails.
    @available(iOS 15.0, *)
    public func post(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> ApiResponse {
        return try await withCheckedThrowingContinuation { continuation in
            post(route: route, headers: headers, body: body, soft: true) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Sends a PUT request to the specified route with async/await support.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    /// - Returns: An `ApiResponse` if the request succeeds.
    /// - Throws: An `ApiError` if the request fails.
    @available(iOS 15.0, *)
    public func put(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> ApiResponse {
        return try await withCheckedThrowingContinuation { continuation in
            put(route: route, headers: headers, body: body, soft: true) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Sends a DELETE request to the specified route with async/await support.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    /// - Returns: An `ApiResponse` if the request succeeds.
    /// - Throws: An `ApiError` if the request fails.
    @available(iOS 15.0, *)
    public func delete(
        route: String,
        headers: [String: String]? = nil
    ) async throws -> ApiResponse {
        return try await withCheckedThrowingContinuation { continuation in
            delete(route: route, headers: headers, soft: true) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Sends a PATCH request to the specified route with async/await support.
    ///
    /// - Parameters:
    ///   - route: The route to append to the base URL.
    ///   - headers: The HTTP headers to include in the request (default is nil).
    ///   - body: The body data to include in the request (default is nil).
    /// - Returns: An `ApiResponse` if the request succeeds.
    /// - Throws: An `ApiError` if the request fails.
    @available(iOS 15.0, *)
    public func patch(
        route: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> ApiResponse {
        return try await withCheckedThrowingContinuation { continuation in
            patch(route: route, headers: headers, body: body, soft: true) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
