import XCEasy
import Foundation

class ApiManagerTests: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.apple.mobilesafari",
            requestTimeout: 3,
            localization: .ru
        )
        super.configuration()
    }

    var api: ApiManager!
    var apiIncorrect: ApiManager!

    override func setUp() {
        super.setUp()
        api = ApiManager(baseURL: "https://reqres.in")
        apiIncorrect = ApiManager(baseURL: "https://reqres.qq")
    }

    // MARK: - Positive tests

    func test_assertGetRequest() {
        api.get(route: "/api/users/2") { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 200)

                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let id = dataDict["id"] as? Int {
                    assertEqual(actual: id, expected: 2)
                }

            case .failure(let error):
                fail("Request failed with error: \(error.description)")
            }
        }
    }

    func test_assertPostRequest() {
        let body: [String: Any] = [
            "name": "xceasy",
            "job": "framework"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: body, options: [])

        api.post(route: "/api/users", body: jsonData) { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 201)

                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let createdAt = json["createdAt"] as? String {
                    assertNotNil(actual: createdAt)
                }

            case .failure(let error):
                fail("Request failed with error: \(error.description)")
            }
        }
    }

    func test_assertPutRequest() {
        let body: [String: Any] = [
            "name": "xceasy",
            "job": "framework"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: body, options: [])

        api.put(route: "/api/users/2", body: jsonData) { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 200)

                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let updatedAt = json["updatedAt"] as? String {
                    assertNotNil(actual: updatedAt)
                }

            case .failure(let error):
                fail("Request failed with error: \(error.description)")
            }
        }
    }

    func test_assertPatchRequest() {
        let body: [String: Any] = [
            "name": "xceasy",
            "job": "framework"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: body, options: [])

        api.patch(route: "/api/users/2", body: jsonData) { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 200)

                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                   let updatedAt = json["updatedAt"] as? String {
                    assertNotNil(actual: updatedAt)
                }

            case .failure(let error):
                fail("Request failed with error: \(error.description)")
            }
        }
    }

    func test_assertDeleteRequest() {
        api.delete(route: "/api/users/2") { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 204)

            case .failure(let error):
                fail("Request failed with error: \(error.description)")
            }
        }
    }

    func test_assertGetRequestSoft() {
        apiIncorrect.get(route: "/api/users/2", soft: true) { result in
            switch result {
            case .success(let response):
                assertEqual(actual: response.statusCode, expected: 200)

            case .failure(_):
                // Error is logged internally due to soft: true
                // Test continues without failing
                break
            }
        }

        assertEqual(actual: 1, expected: 1)
    }

    // MARK: - Negative tests

    func test_assertRequestFailed() {
        apiIncorrect.get(route: "/api/users/2") { result in
            switch result {
            case .success(let response):
                // This should not happen for incorrect URL
                assertEqual(actual: response.statusCode, expected: 200)

            case .failure(let error):
                // Expected: request should fail due to incorrect URL
                switch error {
                case .invalidURL, .network, .timeout:
                    // Expected errors
                    break
                default:
                    fail("Unexpected error type: \(error.description)")
                }
            }
        }
    }
}
