import Foundation

/// Controls performance collection and optional budget findings.
public struct XCEasyPerformanceConfiguration: Codable, Equatable, Sendable {
    public enum Level: String, Codable, CaseIterable, Sendable {
        case off
        case basic
        case detailed
    }

    public enum BudgetPolicy: String, Codable, CaseIterable, Sendable {
        case observe
        case warn
        case fail
    }

    public var level: Level
    public var defaultBudgetMilliseconds: Int64?
    public var operationBudgetsMilliseconds: [String: Int64]
    public var budgetPolicy: BudgetPolicy

    /// Creates a performance collection and budget policy.
    ///
    /// An operation-specific budget takes precedence over the default budget.
    ///
    /// - Parameters:
    ///   - level: Amount of timing evidence to collect.
    ///   - defaultBudgetMilliseconds: Fallback budget for operations without an override.
    ///   - operationBudgetsMilliseconds: Budgets keyed by canonical operation code.
    ///   - budgetPolicy: How a budget violation affects the test.
    ///
    /// ```swift
    /// XCEasyConfig.performance = XCEasyPerformanceConfiguration(
    ///     level: .detailed,
    ///     defaultBudgetMilliseconds: 2_000,
    ///     operationBudgetsMilliseconds: ["ui.tap": 1_000],
    ///     budgetPolicy: .warn
    /// )
    /// ```
    public init(
        level: Level = .basic,
        defaultBudgetMilliseconds: Int64? = nil,
        operationBudgetsMilliseconds: [String: Int64] = [:],
        budgetPolicy: BudgetPolicy = .observe
    ) {
        self.level = level
        self.defaultBudgetMilliseconds = defaultBudgetMilliseconds
        self.operationBudgetsMilliseconds = operationBudgetsMilliseconds
        self.budgetPolicy = budgetPolicy
    }

    /// Resolves the effective budget for a canonical operation.
    ///
    /// - Parameter operationKey: Canonical operation code, such as `ui.tap`.
    /// - Returns: The operation override, the default budget, or `nil` when no budget is set.
    public func budgetMilliseconds(for operationKey: String) -> Int64? {
        operationBudgetsMilliseconds[operationKey] ?? defaultBudgetMilliseconds
    }
}
