import Foundation

internal final class XCEasyPerformanceRecorder {
    private let testId: String
    private let executionId: String
    private let directory: URL
    private let lock = NSLock()
    private var samples: [XCEasyPerformanceSample] = []

    /// Creates synchronized performance storage for one test attempt.
    ///
    /// - Parameters:
    ///   - testId: Stable test-case identifier.
    ///   - executionId: Unique attempt identifier.
    ///   - directory: Artifact output directory.
    init(testId: String, executionId: String, directory: URL) {
        self.testId = testId
        self.executionId = executionId
        self.directory = directory
    }

    /// Extracts a timing sample from a canonical event when performance evidence exists.
    ///
    /// - Parameter event: Completed operation or query event.
    func record(_ event: DiagnosticEvent) {
        guard let duration = event.durationMilliseconds,
              let performance = event.performance else { return }
        let configuration = XCEasyConfig.performance
        let sample = XCEasyPerformanceSample(
            operationKey: performance.operationKey,
            durationMilliseconds: duration,
            outcome: event.statusCode ?? "unknown",
            phasesMilliseconds: performance.phasesMilliseconds,
            budgetMilliseconds: performance.budgetMilliseconds,
            budgetPolicy: configuration.budgetPolicy.rawValue
        )
        lock.lock()
        samples.append(sample)
        lock.unlock()
    }

    /// Aggregates an immutable sample snapshot and persists it atomically.
    ///
    /// - Returns: Allure attachment metadata for the performance summary.
    /// - Throws: An encoding or filesystem error.
    func writeSummary() throws -> Attachment {
        lock.lock()
        let snapshot = samples
        lock.unlock()
        let summary = XCEasyPerformanceAggregator.makeSummary(
            testId: testId,
            executionId: executionId,
            samples: snapshot
        )
        let filename = "\(executionId)_performance-summary.json"
        let url = directory.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try AtomicFileWriter.write(try encoder.encode(summary), to: url)
        return Attachment(name: "XCEasy Performance Summary", source: filename, type: "application/json")
    }
}
