import XCTest
@testable import XCEasy

final class DeeplinkTests: XCTestCase {
    func testURLBuilderAcceptsPathWithOrWithoutLeadingSlash() {
        XCTAssertEqual(
            Deeplink.makeURL(path: "/settings/privacy", scheme: "myapp")?.absoluteString,
            "myapp://settings/privacy"
        )
        XCTAssertEqual(
            Deeplink.makeURL(path: "profile/42?source=test", scheme: "myapp")?.absoluteString,
            "myapp://profile/42?source=test"
        )
    }

    func testURLBuilderRejectsEmptyAndMalformedInput() {
        XCTAssertNil(Deeplink.makeURL(path: "", scheme: "myapp"))
        XCTAssertNil(Deeplink.makeURL(path: "/", scheme: "myapp"))
        XCTAssertNil(Deeplink.makeURL(path: "/settings", scheme: "my app"))
        XCTAssertNil(Deeplink.makeURL(path: "https://example.com", scheme: "myapp"))
    }
}
