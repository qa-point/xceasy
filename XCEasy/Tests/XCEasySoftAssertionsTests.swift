import XCTest
@testable import XCEasy

final class XCEasySoftAssertionsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let context = XCEasyTestContext.shared
        context.stepStack = []
        context.activeStepDepth = 0
        _ = context.consumeDeferredFailures()
        var result = context.testResult ?? TestResult(uuid: "soft-assertion-tests")
        result.steps = []
        context.testResult = result
    }

    func testRegularValueAssertionsContinueInsideSoftlyAndFailOwningSteps() throws {
        var reachedLastAssertion = false

        XCTExpectFailure("Softly intentionally reports one aggregate XCTest issue") {
            softly("Home state") {
                assertEqual(actual: "Actual", expected: "Expected")
                assertTrue(expression: false, label: "avatar is displayed")
                reachedLastAssertion = true
            }
        }

        XCTAssertTrue(reachedLastAssertion)
        let group = try XCTUnwrap(XCEasyTestContext.shared.testResult?.steps?.last)
        XCTAssertEqual(group.name, "Home state")
        XCTAssertEqual(group.status, .failed)
        XCTAssertEqual(group.steps?.count, 2)
        XCTAssertTrue(group.steps?.allSatisfy { $0.status == .failed } == true)
        XCTAssertEqual(XCEasyTestContext.shared.activeStepDepth, 0)
        XCTAssertTrue(XCEasyTestContext.shared.stepStack.isEmpty)
    }

    func testComponentCollectionAssertionsUseTransparentSoftContext() {
        let collection = XCEasyComponentCollection<SoftIndexedComponent>(snapshotProvider: { _ in
            XCEasyCollectionSnapshot(count: 1, displayedIndices: [0], isContextAvailable: true)
        })
        var reachedEnd = false

        XCTExpectFailure("Collection mismatches are aggregated by softly") {
            softly("Cards") {
                collection.assertCount(2, timeout: 0)
                collection.assertIsEmpty(timeout: 0)
                reachedEnd = true
            }
        }

        XCTAssertTrue(reachedEnd)
    }

    func testUIElementAssertionsUseTransparentSoftContext() {
        let element = XCEasyUIElement(
            identifier: "missingElement",
            timeout: 0,
            testContext: SoftElementTestContext()
        )
        var reachedEnd = false

        XCTExpectFailure("UI mismatches are aggregated by softly") {
            softly("UI state") {
                element.assertExists(timeout: 0)
                element.assertIsDisplayed(timeout: 0)
                reachedEnd = true
            }
        }

        XCTAssertTrue(reachedEnd)
    }

    func testSuccessfulSoftlyBlockPreservesRegularAssertionSyntax() {
        softly("Successful group") {
            assertTrue(expression: true, label: "truth")
            assertEqual(actual: 2 + 2, expected: 4)
            assertNotNil(actual: "value")
        }
    }

    func testCollectorRedactsSensitiveValuesAndBoundsDetails() throws {
        let collector = XCEasySoftAssertionCollector(maximumRecordedFailures: 2)

        for index in 0..<5 {
            collector.record(XCEasySoftAssertionFailure(
                label: SensitiveDataRedactor.redact("token=secret-\(index)"),
                expected: "safe",
                actual: SensitiveDataRedactor.redact("token=secret-\(index)"),
                file: "SecretsTests.swift",
                line: UInt(index + 1)
            ))
        }

        let summary = try XCTUnwrap(collector.failureSummary(title: "Secrets"))
        XCTAssertFalse(summary.contains("secret-0"))
        XCTAssertTrue(summary.contains("5 assertion(s) failed"))
        XCTAssertTrue(summary.contains("3 additional failure(s) omitted"))
    }

    @available(iOS 15.0, *)
    func testAsyncSoftlyPreservesExecutionAcrossSuspension() async {
        var reachedAssertion = false

        await softly("Async state") {
            await Task.yield()
            assertEqual(actual: 1, expected: 1)
            reachedAssertion = true
        }

        XCTAssertTrue(reachedAssertion)
    }
}

private struct SoftIndexedComponent: XCEasyIndexedComponent {
    static let collection = XCEasyUIElement(identifier: "card", timeout: 0)
    let position: XCEasyComponentPosition
    let componentName: String

    init(position: XCEasyComponentPosition, componentName: String?) {
        self.position = position
        self.componentName = componentName ?? Self.defaultComponentName(for: position)
    }

    var element: XCEasyUIElement { Self.collection.element(at: position) }
}

private final class SoftElementTestContext: TestContextProviding {
    var testId: String?
    var app: XCUIApplication?
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
    func clearApp() { app = nil }
    func setApp() { app = XCUIApplication() }
    func pushStep(_ step: StepResult) { stepStack.append(step) }
    func popStep() -> StepResult? { stepStack.popLast() }
}
