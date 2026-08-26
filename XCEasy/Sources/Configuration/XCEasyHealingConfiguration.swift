import Foundation

/// Controls evidence-backed selector healing proposals.
/// XCEasy never mutates source code or changes assertions automatically.
public struct XCEasyHealingConfiguration: Codable, Equatable, Sendable {
    public enum Mode: String, Codable, CaseIterable, Sendable {
        case observe
        case suggest
    }

    public var mode: Mode
    public var minimumConfidence: Double
    public var minimumScoreGap: Double

    /// Creates a controlled selector-healing policy.
    ///
    /// Values outside `0...1` are clamped before use.
    ///
    /// - Parameters:
    ///   - mode: Whether XCEasy only observes candidates or emits reviewable suggestions.
    ///   - minimumConfidence: Minimum score required for the leading candidate.
    ///   - minimumScoreGap: Minimum difference between the best and second-best candidates.
    ///
    /// ```swift
    /// XCEasyConfig.healing = XCEasyHealingConfiguration(
    ///     mode: .suggest,
    ///     minimumConfidence: 0.85,
    ///     minimumScoreGap: 0.2
    /// )
    /// ```
    public init(
        mode: Mode = .observe,
        minimumConfidence: Double = 0.75,
        minimumScoreGap: Double = 0.12
    ) {
        self.mode = mode
        self.minimumConfidence = min(1, max(0, minimumConfidence))
        self.minimumScoreGap = min(1, max(0, minimumScoreGap))
    }
}
