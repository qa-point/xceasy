import XCTest
@testable import XCEasy

final class XCEasyPerformanceSummaryTests: XCTestCase {
    func testSummaryCalculatesPercentilesAndBudgetFinding() {
        let samples = [10, 20, 30, 40, 100].map { value in
            XCEasyPerformanceSample(
                operationKey: "ui.tap",
                durationMilliseconds: Int64(value),
                outcome: "passed",
                phasesMilliseconds: ["resolve": Int64(value - 1), "interaction": 1],
                budgetMilliseconds: 50,
                budgetPolicy: "warn"
            )
        }

        let summary = XCEasyPerformanceAggregator.makeSummary(
            testId: "test",
            executionId: "execution",
            samples: samples
        )

        XCTAssertEqual(summary.metrics.first?.medianMilliseconds, 30)
        XCTAssertEqual(summary.metrics.first?.p90Milliseconds, 100)
        XCTAssertEqual(summary.findings.count, 1)
        XCTAssertEqual(summary.findings.first?.dominantPhase, "resolve")
        XCTAssertEqual(summary.findings.first?.reasonCode, "performance.budget_exceeded")
    }

    func testDisabledPerformanceLevelProducesNoEvidence() {
        let original = XCEasyConfig.performance
        defer { XCEasyConfig.performance = original }
        XCEasyConfig.performance = XCEasyPerformanceConfiguration(level: .off)

        XCTAssertNil(diagnosticPerformanceEvidence(
            operationKey: "ui.tap",
            durationMilliseconds: 10
        ))
    }

    func testExactOperationBudgetOverridesDefaultBudget() {
        let configuration = XCEasyPerformanceConfiguration(
            defaultBudgetMilliseconds: 1_000,
            operationBudgetsMilliseconds: ["ui.tap": 100]
        )

        XCTAssertEqual(configuration.budgetMilliseconds(for: "ui.tap"), 100)
        XCTAssertEqual(configuration.budgetMilliseconds(for: "ui.swipe"), 1_000)
    }
}
