import XCTest
@testable import XCEasy

final class AllureMarkupTests: XCTestCase {
    private let context = XCEasyTestContext.shared

    override func setUp() {
        super.setUp()
        context.labels = []
        context.links = []
        context.description = nil
        context.displayName = nil
        context.stepStack = []
        context.activeStepDepth = 0
        var result = context.testResult ?? TestResult(uuid: "markup-tests")
        result.steps = []
        result.parameters = []
        context.testResult = result
        XCEasyAllureConfig.apply(linkPatterns: [
            "issue": "https://jira.example.test/browse/{}",
            "tms": "https://tms.example.test/{}"
        ])
    }

    func testMetadataHelpersPopulateLabelsLinksAndPresentation() {
        id("AUTO-1")
        epic("Checkout")
        feature("Payment")
        story("Card")
        suite("Regression")
        owner("Owner1")
        severity(.critical)
        label("layer", "ui")
        tag("smoke", "ios")
        link(url: "https://example.test/reference")
        issue("PAY-1")
        tms("CASE-1")
        XCEasy.description("Safe description")
        displayName("Card payment")

        XCTAssertEqual(context.labels.count, 10)
        XCTAssertTrue(context.labels.contains { $0.name == LabelType.id.rawValue && $0.value == "AUTO-1" })
        XCTAssertTrue(context.labels.contains { $0.name == LabelType.severity.rawValue && $0.value == "CRITICAL" })
        XCTAssertTrue(context.labels.contains { $0.name == "layer" && $0.value == "ui" })
        XCTAssertEqual(context.links.map(\.url), [
            "https://example.test/reference",
            "https://jira.example.test/browse/PAY-1",
            "https://tms.example.test/CASE-1"
        ])
        XCTAssertEqual(context.description, "Safe description")
        XCTAssertEqual(context.displayName, "Card payment")
    }

    func testParameterReplacesDuplicateAndRedactsEveryDisplayMode() throws {
        parameter("account", value: "password=first", excluded: false)
        parameter("account", value: "password=second", excluded: true, mode: .masked)
        parameter("hidden", value: "token=canary", mode: .hidden)

        let parameters = try XCTUnwrap(context.testResult?.parameters)
        XCTAssertEqual(parameters.count, 2)
        let account = try XCTUnwrap(parameters.first { $0.name == "account" })
        XCTAssertEqual(account.excluded, true)
        XCTAssertEqual(account.mode, AllureParameterMode.masked.rawValue)
        XCTAssertFalse(account.value?.contains("second") == true)
        let hidden = try XCTUnwrap(parameters.first { $0.name == "hidden" })
        XCTAssertEqual(hidden.mode, AllureParameterMode.hidden.rawValue)
        XCTAssertFalse(hidden.value?.contains("canary") == true)
    }

    func testRuntimeMetadataSupportsLeadLinksFlakyAndMuted() throws {
        lead("Lead1")
        link(name: "Build", url: "https://ci.example.test/build/1", type: "build")
        flaky()
        muted()

        XCTAssertTrue(context.labels.contains { $0.name == "lead" && $0.value == "Lead1" })
        XCTAssertEqual(context.links.last?.type, "build")
        XCTAssertEqual(context.testResult?.statusDetails?.flaky, true)
        XCTAssertEqual(context.testResult?.statusDetails?.muted, true)
    }

    func testStepReturnsValueAndPersistsFinishedResult() throws {
        let value = step("Calculate") { 42 }

        XCTAssertEqual(value, 42)
        let recorded = try XCTUnwrap(context.testResult?.steps?.last)
        XCTAssertEqual(recorded.name, "Calculate")
        XCTAssertEqual(recorded.status, .passed)
        XCTAssertEqual(recorded.stage, .finished)
        XCTAssertNotNil(recorded.start)
        XCTAssertNotNil(recorded.stop)
        XCTAssertEqual(context.activeStepDepth, 0)
        XCTAssertTrue(context.stepStack.isEmpty)
    }

    func testNestedStepsPreserveHierarchyAndReturnValue() throws {
        let value = step("Outer") {
            step("Inner") { "result" }
        }

        XCTAssertEqual(value, "result")
        let outer = try XCTUnwrap(context.testResult?.steps?.last)
        XCTAssertEqual(outer.name, "Outer")
        XCTAssertEqual(outer.steps?.map(\.name), ["Inner"])
    }

    func testGivenWhenThenAndCreateCanonicalStepNames() {
        var calls: [String] = []

        given("a user") { calls.append("given") }
        when("the user acts") { calls.append("when") }
        then("the result appears") { calls.append("then") }
        and("the result is stable") { calls.append("and") }

        XCTAssertEqual(calls, ["given", "when", "then", "and"])
        XCTAssertEqual(
            context.testResult?.steps?.compactMap(\.name),
            ["GIVEN: a user", "WHEN: the user acts", "THEN: the result appears", "AND: the result is stable"]
        )
    }

    func testAllureConfigurationResolvesStandardPatternsAndCanLog() {
        XCEasyAllureConfig.apply(linkPatterns: [
            "issue": "https://jira.example.test/browse/{}",
            "tms": "https://tms.example.test/%s"
        ])

        XCTAssertEqual(XCEasyAllureConfig.resolveLink(type: "issue", value: "TEST-ISSUE-001"), "https://jira.example.test/browse/TEST-ISSUE-001")
        XCTAssertEqual(XCEasyAllureConfig.resolveLink(type: "tms", value: "T-1"), "https://tms.example.test/T-1")

        XCEasyAllureConfig.logConfig()
        XCTAssertEqual(context.testResult?.steps?.last?.status, .passed)
    }
}
