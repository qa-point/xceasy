import Foundation
import XCTest

internal struct XCEasyPerformanceSample: Codable, Equatable {
    let operationKey: String
    let durationMilliseconds: Int64
    let outcome: String
    let phasesMilliseconds: [String: Int64]
    let budgetMilliseconds: Int64?
    let budgetPolicy: String
}

internal struct XCEasyPerformanceMetric: Codable, Equatable {
    let operationKey: String
    let count: Int
    let minimumMilliseconds: Int64
    let maximumMilliseconds: Int64
    let meanMilliseconds: Double
    let medianMilliseconds: Int64
    let p90Milliseconds: Int64
    let p95Milliseconds: Int64
    let p99Milliseconds: Int64
}

internal struct XCEasyPerformanceFinding: Codable, Equatable {
    let operationKey: String
    let reasonCode: String
    let observedMilliseconds: Int64
    let budgetMilliseconds: Int64
    let policy: String
    let dominantPhase: String?
    let suggestedAction: String
}

internal struct XCEasyPerformanceSummary: Codable, Equatable {
    let schemaVersion: String
    let testId: String
    let executionId: String
    let metrics: [XCEasyPerformanceMetric]
    let findings: [XCEasyPerformanceFinding]
}

internal enum XCEasyPerformanceAggregator {
    /// Aggregates per-operation metrics and budget findings for one execution.
    ///
    /// - Parameters:
    ///   - testId: Stable test-case identifier.
    ///   - executionId: Unique attempt identifier.
    ///   - samples: Completed operation timing samples.
    /// - Returns: Deterministically ordered metrics and findings.
    static func makeSummary(
        testId: String,
        executionId: String,
        samples: [XCEasyPerformanceSample]
    ) -> XCEasyPerformanceSummary {
        let grouped = Dictionary(grouping: samples, by: \.operationKey)
        let metrics = grouped.keys.sorted().compactMap { key -> XCEasyPerformanceMetric? in
            guard let group = grouped[key], !group.isEmpty else { return nil }
            let values = group.map(\.durationMilliseconds).sorted()
            let mean = Double(values.reduce(0, +)) / Double(values.count)
            return XCEasyPerformanceMetric(
                operationKey: key,
                count: values.count,
                minimumMilliseconds: values[0],
                maximumMilliseconds: values[values.count - 1],
                meanMilliseconds: mean,
                medianMilliseconds: percentile(0.50, values: values),
                p90Milliseconds: percentile(0.90, values: values),
                p95Milliseconds: percentile(0.95, values: values),
                p99Milliseconds: percentile(0.99, values: values)
            )
        }
        let findings = samples.compactMap { sample -> XCEasyPerformanceFinding? in
            guard let budget = sample.budgetMilliseconds,
                  sample.durationMilliseconds > budget else { return nil }
            let dominant = sample.phasesMilliseconds.max { lhs, rhs in lhs.value < rhs.value }?.key
            return XCEasyPerformanceFinding(
                operationKey: sample.operationKey,
                reasonCode: "performance.budget_exceeded",
                observedMilliseconds: sample.durationMilliseconds,
                budgetMilliseconds: budget,
                policy: sample.budgetPolicy,
                dominantPhase: dominant,
                suggestedAction: suggestion(for: dominant)
            )
        }
        return XCEasyPerformanceSummary(
            schemaVersion: "1.0.0",
            testId: testId,
            executionId: executionId,
            metrics: metrics,
            findings: findings
        )
    }

    /// Selects a nearest-rank percentile from sorted values.
    ///
    /// - Parameters:
    ///   - percentile: Fractional percentile such as `0.95`.
    ///   - values: Nonempty ascending duration values.
    /// - Returns: Nearest-rank duration.
    private static func percentile(_ percentile: Double, values: [Int64]) -> Int64 {
        let rank = max(1, Int(ceil(percentile * Double(values.count))))
        return values[min(values.count - 1, rank - 1)]
    }

    /// Maps a dominant timing phase to a conservative optimization suggestion.
    ///
    /// - Parameter dominantPhase: Longest recorded phase, if phase evidence exists.
    /// - Returns: Human-readable next diagnostic action without changing timeouts automatically.
    private static func suggestion(for dominantPhase: String?) -> String {
        switch dominantPhase {
        case "resolve", "wait_exists", "wait_hittable":
            return "Inspect application readiness and locator stability before changing the timeout."
        case "serialization", "artifact_write":
            return "Reduce success-artifact volume or serialization frequency."
        case "network":
            return "Inspect backend latency and independent requests that can use bounded parallelism."
        default:
            return "Inspect the cited operation span and compare it with a compatible baseline."
        }
    }
}

/// Builds optional operation performance evidence using the current execution policy.
///
/// - Parameters:
///   - operationKey: Stable semantic operation code.
///   - durationMilliseconds: Total measured duration.
///   - phasesMilliseconds: Optional named phase breakdown.
/// - Returns: Evidence with effective budget, or `nil` when collection is disabled.
internal func diagnosticPerformanceEvidence(
    operationKey: String,
    durationMilliseconds: Int64,
    phasesMilliseconds: [String: Int64]? = nil
) -> DiagnosticPerformanceEvidence? {
    let configuration = XCEasyConfig.performance
    guard configuration.level != .off else { return nil }
    let budget = configuration.budgetMilliseconds(for: operationKey)
    return DiagnosticPerformanceEvidence(
        operationKey: operationKey,
        phasesMilliseconds: phasesMilliseconds ?? ["total": durationMilliseconds],
        budgetMilliseconds: budget,
        budgetStatus: budget.map { durationMilliseconds > $0 ? "exceeded" : "within_budget" }
    )
}

/// Applies observe, warning, or XCTest-failure behavior to an exceeded budget.
///
/// - Parameters:
///   - operationKey: Stable semantic operation code.
///   - durationMilliseconds: Observed duration.
///   - parentOperationId: Optional operation that owns the budget event.
internal func enforcePerformanceBudget(
    operationKey: String,
    durationMilliseconds: Int64,
    parentOperationId: String? = nil
) {
    let configuration = XCEasyConfig.performance
    guard configuration.level != .off,
          let budget = configuration.budgetMilliseconds(for: operationKey),
          durationMilliseconds > budget else { return }
    let message = "Performance budget exceeded for \(operationKey): \(durationMilliseconds) ms > \(budget) ms"
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "performance.budget_exceeded",
        level: configuration.budgetPolicy == .fail ? "error" : "warning",
        testId: XCEasyTestContext.shared.testId,
        operationCode: operationKey,
        operationId: UUID().uuidString.lowercased(),
        parentOperationId: parentOperationId,
        statusCode: configuration.budgetPolicy == .fail ? "failed" : "warning",
        reasonCode: "performance.budget_exceeded",
        durationMilliseconds: durationMilliseconds,
        title: message
    ))
    switch configuration.budgetPolicy {
    case .observe:
        break
    case .warn:
        XCEasyTestLogger.shared.log(message, level: .warning)
    case .fail:
        XCTFail(message)
    }
}
