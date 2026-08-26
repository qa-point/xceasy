import XCTest
@testable import XCEasy

final class XCEasyConfigTests: XCTestCase {
    override func tearDown() {
        XCEasyConfig.endExecution()
        XCEasyConfig.findTimeout = 10
        XCEasyConfig.actionPolicy = .hittable
        XCEasyConfig.uiQueryEvidenceLevel = .basic
        XCEasyConfig.uiQueryAmbiguityPolicy = .strict
        XCEasyConfig.visibilityPolicy = .onScreen
        XCEasyConfig.performance = XCEasyPerformanceConfiguration()
        XCEasyConfig.healing = XCEasyHealingConfiguration()
        XCEasyConfig.diagnosticSnapshotByteLimit = 64 * 1024
        super.tearDown()
    }

    func testHealingDefaultsToObserveAndIsExecutionScoped() {
        XCTAssertEqual(XCEasyConfig.healing.mode, .observe)
        XCEasyConfig.beginExecution()
        XCEasyConfig.healing = XCEasyHealingConfiguration(mode: .suggest)
        XCTAssertEqual(XCEasyConfig.healing.mode, .suggest)
        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.healing.mode, .observe)
    }

    func testExecutionChangesDoNotMutateDefaults() {
        XCEasyConfig.findTimeout = 12
        XCEasyConfig.beginExecution()
        XCEasyConfig.findTimeout = 3

        XCTAssertEqual(XCEasyConfig.findTimeout, 3)

        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.findTimeout, 12)
    }

    func testExecutionStartsWithCurrentDefaults() {
        XCEasyConfig.findTimeout = 7

        XCEasyConfig.beginExecution()

        XCTAssertEqual(XCEasyConfig.findTimeout, 7)
    }

    func testQueryEvidenceLevelDefaultsToBasic() {
        XCTAssertEqual(XCEasyConfig.uiQueryEvidenceLevel, .basic)
    }

    func testActionPolicyDefaultsToHittableAndIsExecutionScoped() {
        XCTAssertEqual(XCEasyConfig.actionPolicy, .hittable)

        XCEasyConfig.beginExecution()
        XCEasyConfig.actionPolicy = .displayed
        XCTAssertEqual(XCEasyConfig.actionPolicy, .displayed)

        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.actionPolicy, .hittable)
    }

    func testApplyUpdatesActionPolicy() {
        XCEasyConfig.apply(actionPolicy: .displayed)

        XCTAssertEqual(XCEasyConfig.actionPolicy, .displayed)
    }

    func testQueryEvidenceLevelIsExecutionScoped() {
        XCEasyConfig.uiQueryEvidenceLevel = .detailed
        XCEasyConfig.beginExecution()
        XCEasyConfig.uiQueryEvidenceLevel = .off

        XCTAssertEqual(XCEasyConfig.uiQueryEvidenceLevel, .off)

        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.uiQueryEvidenceLevel, .detailed)
    }

    func testApplyUpdatesQueryEvidenceLevel() {
        XCEasyConfig.apply(uiQueryEvidenceLevel: .detailed)

        XCTAssertEqual(XCEasyConfig.uiQueryEvidenceLevel, .detailed)
    }

    func testAmbiguityPolicyDefaultsToStrictAndIsExecutionScoped() {
        XCTAssertEqual(XCEasyConfig.uiQueryAmbiguityPolicy, .strict)

        XCEasyConfig.beginExecution()
        XCEasyConfig.uiQueryAmbiguityPolicy = .permissive
        XCTAssertEqual(XCEasyConfig.uiQueryAmbiguityPolicy, .permissive)

        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.uiQueryAmbiguityPolicy, .strict)
    }

    func testApplyUpdatesPerformanceAndSnapshotConfiguration() {
        let performance = XCEasyPerformanceConfiguration(
            level: .detailed,
            defaultBudgetMilliseconds: 500,
            budgetPolicy: .warn
        )

        XCEasyConfig.apply(
            performance: performance,
            diagnosticSnapshotByteLimit: 2048
        )

        XCTAssertEqual(XCEasyConfig.performance, performance)
        XCTAssertEqual(XCEasyConfig.diagnosticSnapshotByteLimit, 2048)
    }

    func testVisibilityPolicyDefaultsToOnScreenAndIsExecutionScoped() {
        XCTAssertEqual(XCEasyConfig.visibilityPolicy, .onScreen)

        XCEasyConfig.beginExecution()
        XCEasyConfig.apply(visibilityPolicy: .nonEmptyFrame)
        XCTAssertEqual(XCEasyConfig.visibilityPolicy, .nonEmptyFrame)

        XCEasyConfig.endExecution()
        XCTAssertEqual(XCEasyConfig.visibilityPolicy, .onScreen)
    }
}
