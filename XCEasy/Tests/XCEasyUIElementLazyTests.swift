import XCTest
@testable import XCEasy

final class XCEasyUIElementLazyTests: XCTestCase {
    func testChildConstructionKeepsLocatorChainWithoutReadingApplication() {
        let context = TestContextSpy()
        let root = XCEasyUIElement(
            identifier: "promoBanner",
            timeout: 0,
            testContext: context
        )

        let closeButton = root.child(identifier: "closeButton", timeout: 0)

        XCTAssertTrue(closeButton.parentLocator === root)
        XCTAssertEqual(context.appReadCount, 0)
    }

    func testDeepChildConstructionKeepsEveryLocatorWithoutReadingApplication() {
        let context = TestContextSpy()
        let screen = XCEasyUIElement(identifier: "screen", timeout: 0, testContext: context)
        let banner = screen.child(identifier: "banner", timeout: 0)
        let title = banner.child(identifier: "title", timeout: 0)

        XCTAssertTrue(title.parentLocator === banner)
        XCTAssertTrue(title.parentLocator?.parentLocator === screen)
        XCTAssertEqual(context.appReadCount, 0)
    }

    func testLocatorDescriptorPreservesScopeWithoutReadingApplication() throws {
        let context = TestContextSpy()
        let root = XCEasyUIElement(
            type: .other,
            identifier: "screen.promoBanner",
            index: 1,
            timeout: 0,
            testContext: context
        )
        let closeButton = root.child(
            type: .button,
            identifier: "password=selector-canary",
            timeout: 0
        )

        let descriptor = closeButton.locatorDescriptor

        XCTAssertEqual(descriptor.segments.count, 2)
        XCTAssertEqual(descriptor.segments[0].elementType, "other")
        XCTAssertEqual(descriptor.segments[0].strategy, .identifier)
        XCTAssertEqual(descriptor.segments[0].value, "screen.promoBanner")
        XCTAssertEqual(descriptor.segments[0].index, 1)
        XCTAssertEqual(descriptor.segments[1].elementType, "button")
        XCTAssertEqual(descriptor.segments[1].value, "password=<redacted>")
        XCTAssertEqual(descriptor.segments[1].valueLength, 24)
        XCTAssertTrue(descriptor.segments[1].isValueRedacted)
        XCTAssertEqual(descriptor.fingerprint.count, 64)
        XCTAssertEqual(descriptor.fingerprintConfidence, "privacy_reduced")
        XCTAssertEqual(context.appReadCount, 0)

        let encoded = try JSONEncoder().encode(descriptor)
        XCTAssertFalse(String(decoding: encoded, as: UTF8.self).contains("selector-canary"))
    }

    func testLocatorFingerprintIsStableAndScopeSensitive() {
        let context = TestContextSpy()
        let first = XCEasyUIElement(identifier: "screen-a", timeout: 0, testContext: context)
            .child(identifier: "close", timeout: 0)
        let equivalent = XCEasyUIElement(identifier: "screen-a", timeout: 0, testContext: context)
            .child(identifier: "close", timeout: 0)
        let differentScope = XCEasyUIElement(identifier: "screen-b", timeout: 0, testContext: context)
            .child(identifier: "close", timeout: 0)

        XCTAssertEqual(first.locatorDescriptor.fingerprint, equivalent.locatorDescriptor.fingerprint)
        XCTAssertNotEqual(first.locatorDescriptor.fingerprint, differentScope.locatorDescriptor.fingerprint)
        XCTAssertEqual(first.locatorDescriptor.fingerprintConfidence, "exact")
        XCTAssertEqual(context.appReadCount, 0)
    }

    func testCandidateCountTrustsExistingSelectedElementWhenXCUIReportsZero() {
        XCTAssertEqual(
            XCEasyQueryAccounting.effectiveCandidateCount(
                reportedCount: 0,
                selectedIndex: 0,
                selectedElementExists: true
            ),
            1
        )
        XCTAssertEqual(
            XCEasyQueryAccounting.effectiveCandidateCount(
                reportedCount: 0,
                selectedIndex: 2,
                selectedElementExists: true
            ),
            3
        )
    }

    func testExistingFinalElementClearsTransientAncestorFailure() {
        XCTAssertNil(XCEasyQueryAccounting.failedSegmentIndex(
            firstObservedFailure: 0,
            finalElementExists: true
        ))
        XCTAssertEqual(
            XCEasyQueryAccounting.failedSegmentIndex(
                firstObservedFailure: 0,
                finalElementExists: false
            ),
            0
        )
    }

    func testEveryRootFindOverloadStaysLazyAndPreservesIntent() {
        let context = TestContextSpy()
        XCDependencyContainer.shared.testContext = context
        defer { XCDependencyContainer.shared.reset() }

        let elements = [
            find(identifier: "identifier", index: 1, desc: "identifier description", timeout: 2),
            find(format: "enabled == true", index: 2, desc: "predicate description", timeout: 3),
            find(type: .button, identifier: "typed-id", index: 3, timeout: 4),
            find(type: .cell, format: "selected == true", index: 4, timeout: 5),
            find(text: "Visible text", index: 5, timeout: 6),
            find(type: .staticText, text: "Typed text", index: 6, timeout: 7),
            find(type: .switch, index: 7, timeout: 8)
        ]

        XCTAssertEqual(elements.map(\.index), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(elements.map(\.timeout), [2, 3, 4, 5, 6, 7, 8])
        XCTAssertEqual(elements[0].identifier, "identifier")
        XCTAssertEqual(elements[1].format, "enabled == true")
        XCTAssertEqual(elements[2].type?.properties.type, XCUIElement.ElementType.button)
        XCTAssertEqual(elements[4].text, "Visible text")
        XCTAssertEqual(context.appReadCount, 0)
    }

    func testEveryChildOverloadStaysLazyAndPreservesParent() {
        let context = TestContextSpy()
        let root = XCEasyUIElement(identifier: "root", timeout: 0, testContext: context)
        let children = [
            root.child(identifier: "identifier", index: 1, timeout: 2),
            root.child(format: "enabled == true", index: 2, timeout: 3),
            root.child(type: .button, identifier: "typed-id", index: 3, timeout: 4),
            root.child(type: .cell, format: "selected == true", index: 4, timeout: 5),
            root.child(text: "Visible text", index: 5, timeout: 6),
            root.child(type: .staticText, text: "Typed text", index: 6, timeout: 7)
        ]

        XCTAssertTrue(children.allSatisfy { $0.parentLocator === root })
        XCTAssertEqual(children.map(\.index), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(children.map(\.timeout), [2, 3, 4, 5, 6, 7])
        XCTAssertEqual(context.appReadCount, 0)
    }

    func testNonAssertingWaitsReturnFalseWhenApplicationContextIsUnavailable() {
        let previousEvidenceLevel = XCEasyConfig.uiQueryEvidenceLevel
        XCEasyConfig.uiQueryEvidenceLevel = .off
        defer { XCEasyConfig.uiQueryEvidenceLevel = previousEvidenceLevel }

        let context = TestContextSpy()
        let element = XCEasyUIElement(
            identifier: "delayed-element",
            timeout: 0,
            testContext: context
        )

        XCTAssertFalse(element.waitForDisplayed(timeout: 0))
        XCTAssertFalse(element.waitForHittable(timeout: 0))
        XCTAssertFalse(element.waitForEnabled(timeout: 0))
        XCTAssertFalse(element.waitForSelected(timeout: 0))
        XCTAssertEqual(context.appReadCount, 4)
    }
}

private final class TestContextSpy: TestContextProviding {
    private var storedApp: XCUIApplication?
    private(set) var appReadCount = 0

    var app: XCUIApplication? {
        get {
            appReadCount += 1
            return storedApp
        }
        set { storedApp = newValue }
    }

    var testId: String?
    var displayName: String?
    var testResult: TestResult?
    var labels: [Label] = []
    var links: [AllureLinkRecord] = []
    var description: String?
    var testSuite: String?
    var stepStack: [StepResult] = []
    var screenshot: ScreenshotAttachment?

    func addLabel(_ label: Label) { labels.append(label) }
    func isLabelExists(_ name: String) -> Bool { labels.contains { $0.name == name } }
    func addLink(_ link: AllureLinkRecord) { links.append(link) }
    func clearTestStorages() {}
    func clearApp() { storedApp = nil }
    func setApp() { storedApp = XCUIApplication() }
    func pushStep(_ step: StepResult) { stepStack.append(step) }
    func popStep() -> StepResult? { stepStack.popLast() }
}
