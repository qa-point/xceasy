# Working with API requests

English · [Русский](../../ru/guide/11_API_REQUESTS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)

`ApiManager` is a small HTTP client for preparing or cleaning backend state for a UI test. It is not a specialized API-testing framework: it provides no schema assertions, endpoint models, retry policy, or API-suite generation.

## Configuration

Create the manager with a base URL. A route is appended directly to that string, so use a consistent pair, such as a base without a trailing `/` and a route with a leading `/`. Configure the shared timeout with `XCEasyConfig.requestTimeout`.

```swift
class BaseTestCase: XCEasyTestCase {
    let api = ApiManager(baseURL: "https://staging.example.com")

    override func configuration() {
        XCEasyConfig.apply(requestTimeout: 20)
        super.configuration()
    }
}
```

`headers` is an HTTP-header dictionary. `body` has type `Data?`: serialize `Codable` with `JSONEncoder` or a dictionary with `JSONSerialization`. Only `200..<300` responses with an HTTP response and data are successful.

## Async/await: recommended form

All five methods accept `route` and optional `headers`; methods that support a body also accept `Data?`:

```swift
final class ProfileTests: BaseTestCase {
    func testPreparedPremiumProfile() async throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["plan": "premium"]
        )
        let headers = ["Content-Type": "application/json"]

        let created = try await api.post(route: "/test-data/profile", headers: headers, body: body)
        let loaded = try await api.get(route: "/test-data/profile", headers: headers)
        let replaced = try await api.put(route: "/test-data/profile", headers: headers, body: body)
        let changed = try await api.patch(route: "/test-data/profile", headers: headers, body: body)
        let deleted = try await api.delete(route: "/test-data/profile", headers: headers)

        assertEqual(actual: created.statusCode, expected: 201)
        assertEqual(actual: loaded.statusCode, expected: 200)
        assertEqual(actual: replaced.statusCode, expected: 200)
        assertEqual(actual: changed.statusCode, expected: 200)
        assertEqual(actual: deleted.statusCode, expected: 204)
    }
}
```

Async overloads throw `ApiError`. Use `do/catch` for an expected error; a plain `try` is normally enough for setup because an error terminates the test method.

## Callback API

Callback overloads return `ApiResult` and add a `soft` argument. With `soft: false`, a transport/API error immediately records an XCTest failure; with `true`, the manager only returns `.failure` and the test decides what to do.

```swift
func testCallbackPreparation() {
    api.get(route: "/test-data/profile", soft: true) { result in
        switch result {
        case .success(let response):
            assertEqual(actual: response.statusCode, expected: 200)
        case .failure(let error):
            fail("Could not prepare profile: \(error)")
        }
    }
}
```

The same arguments are available for `post`, `put`, and `patch`; `delete` has no body.

## Responses and errors

`ApiResponse` provides `data`, the original `HTTPURLResponse`, `statusCode`, and `headers`. The test decodes data with `JSONDecoder`.

| `ApiError` | Cause |
|---|---|
| `.invalidURL` | Base URL + route is not an HTTP(S) URL. |
| `.timeout` | No response arrived within `requestTimeout`. |
| `.noData` | The transport returned no data. |
| `.invalidResponse` | Data exists but a valid HTTP response does not. |
| `.network(Error)` | Network/transport failure. |
| `.http(statusCode:)` | HTTP status is outside `200..<300`. |
| `.unknown(Error)` | Reserved public case for an unknown error. |

## Report output

Every request creates a timed step with operation code `api.request` and the HTTP method. The debug log contains the redacted URL, method, header count, and body size, but not header values or the body:

```text
Send API request [POST]                    passed  184 ms
  URL: https://staging.example.com/test-data/profile
  Method: POST
  Header count: 1
  Body bytes: 18
Assert equal [201]                         passed
```

Do not put tokens or personal data in a route or user step name. Send `Authorization` as a header; its value is not emitted by the standard API log.
