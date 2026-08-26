import XCEasy

class FindXCEasyUIElementTests: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.apple.mobilesafari",
            findTimeout: 2
        )
        XCEasyAllureConfig.apply(linkPatterns: [
            "issue": "https://myjira.com/{}",
            "tms": "https://mytms.com/{}"
        ])
        super.configuration()
    }

    // MARK: - Positive tests

    func test_findViaIdentifier() {
        let element = find(identifier: "TabBarItemTitle")
        assertTrue(
            expression: element.isExists(),
            label: "Element with identifier 'TabBarItemTitle' exists"
        )
    }

    func test_findViaIdentifierWithType() {
        let element = find(type: .button, identifier: "TabBarItemTitle")
        assertTrue(
            expression: element.isExists(),
            label: "Element type .button with identifier 'TabBarItemTitle' exists"
        )
    }

    func test_findViaNSPredicateFormat() {
        let element = find(format: "identifier LIKE 'TabBarItemTitle'")
        assertTrue(
            expression: element.isExists(),
            label: "Element NSPredicate \"identifier LIKE 'TabBarItemTitle'\" exists"
        )
    }

    func test_findViaNSPredicateFormatWithType() {
        let element = find(type: .button, format: "identifier LIKE 'TabBarItemTitle'")
        assertTrue(
            expression: element.isExists(),
            label: "Element type .button NSPredicate \"identifier LIKE 'TabBarItemTitle'\" exists"
        )
    }

    func test_findViaIdentifierWithIndex() {
        let element = find(identifier: "favoritesItemIdentifierContent", index: 0)
        element.assertExists()
        assertEqual(
            actual: element.getLabel(),
            expected: "Apple"
        )
    }

    func test_findViaText() {
        let element = find(text: "Apple")
        assertTrue(
            expression: element.isExists(),
            label: "Element with label 'Apple' exists"
        )
    }

    // MARK: - Negative tests

    func test_findViaIdentifierFailed() {
        let element = find(identifier: "failedID")
        assertTrue(
            expression: element.isExists(),
            label: "Element with identifier 'failedID' exists"
        )
    }

    func test_findViaIdentifierWithTypeFailed() {
        let element = find(type: .button, identifier: "failedID")
        assertTrue(
            expression: element.isExists(),
            label: "Element type .button with identifier 'failedID' exists"
        )
    }

    func test_findViaNSPredicateFormatFailed() {
        let element = find(format: "identifier LIKE 'failedID'")
        assertTrue(
            expression: element.isExists(),
            label: "Element NSPredicate \"identifier LIKE 'failedID'\" exists"
        )
    }

    func test_findViaNSPredicateFormatWithTypeFailed() {
        let element = find(type: .button, format: "identifier LIKE 'failedID'")
        assertTrue(
            expression: element.isExists(),
            label: "Element type .button NSPredicate \"identifier LIKE 'failedID'\" exists"
        )
    }
}
