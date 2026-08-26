import Foundation

// MARK: - ApiError

/// Enumeration representing API error types.
///
/// This enum provides structured error handling for API operations,
/// allowing callers to handle different error scenarios appropriately.
public enum ApiError: Error, CustomStringConvertible {

    /// The URL is invalid or malformed.
    case invalidURL

    /// The request timed out.
    case timeout

    /// No data was received from the server.
    case noData

    /// Invalid response type from the server.
    case invalidResponse

    /// A network error occurred.
    case network(Error)

    /// An HTTP error with the specified status code occurred.
    case http(statusCode: Int)

    /// An unknown error occurred.
    case unknown(Error)

    // MARK: - CustomStringConvertible

    /// A textual representation of the error.
    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .timeout:
            return "Request timed out"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response type from server"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .http(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - ApiResponse

/// Structure representing a successful API response.
///
/// This struct encapsulates all components of an HTTP response,
/// providing a convenient way to access response data.
public struct ApiResponse {

    /// The response data.
    public let data: Data

    /// The HTTP URL response containing status code and headers.
    public let response: HTTPURLResponse

    /// The HTTP status code.
    public var statusCode: Int {
        return response.statusCode
    }

    /// The response headers.
    public var headers: [AnyHashable: Any] {
        return response.allHeaderFields
    }

    /// Creates a new API response.
    ///
    /// - Parameters:
    ///   - data: The response data.
    ///   - response: The HTTP URL response.
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}

// MARK: - ApiResult

/// Type alias for API result using Swift's Result type.
///
/// This provides a consistent way to handle success and failure
/// cases across all API methods.
public typealias ApiResult = Result<ApiResponse, ApiError>
