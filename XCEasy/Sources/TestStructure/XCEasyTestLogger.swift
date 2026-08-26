import Foundation
import XCTest
import CryptoKit

// MARK: - XCEasyTestLogger

/// Internal test logger for the XCEasy framework.
///
/// Provides methods for logging test events with support for
/// different log levels and delimiters.
internal class XCEasyTestLogger {

    // MARK: - Properties

    /// Shared instance of the test logger.
    static let shared = XCEasyTestLogger()

    /// Dictionary of loggers indexed by test ID.
    private var loggers: [String: XCEasyLogger] = [:]

    /// Canonical per-test JSONL writers indexed by test ID.
    private var eventWriters: [String: DiagnosticEventWriter] = [:]

    /// Per-execution performance recorders indexed by execution ID.
    private var performanceRecorders: [String: XCEasyPerformanceRecorder] = [:]

    /// Per-execution artifact registries used to build self-contained diagnostic bundles.
    private var artifactRegistries: [String: DiagnosticArtifactRegistry] = [:]

    /// Resolved output directories indexed by execution ID.
    private var artifactDirectories: [String: URL] = [:]

    /// Concurrent dispatch queue for thread-safe logger access.
    private let queue = DispatchQueue(
        label: "com.qa-point.xceasy.testlogger",
        attributes: .concurrent
    )

    // MARK: - Delimiters

    /// Enumeration representing log delimiters.
    enum Delimeters: String {
        case asterisk = "********************************************************************************"
        case line = "────────────────────────────────────────────────────────────────────────────────"
        case doubleLine = "════════════════════════════════════════════════════════════════════════════════"
    }

    // MARK: - Public Methods

    /// Starts the test logger for a specific test ID.
    /// - Parameters:
    ///   - id: Unique execution identifier used for per-attempt files.
    ///   - testId: Optional stable test-case identifier used in performance summaries.
    ///   - logDir: Optional directory for log file storage.
    func start(id: String, testId: String? = nil, logDir: URL? = nil) {
        let logger = XCEasyLogger(testId: id, logDir: logDir)
        let directory = logDir
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let writer: DiagnosticEventWriter?
        do {
            writer = try DiagnosticEventWriter(testId: id, directory: directory)
        } catch {
            writer = nil
            logger.log("diagnostic_event_writer_start_failed reason=\(error.localizedDescription)", level: .error)
        }
        let recorder = XCEasyPerformanceRecorder(
            testId: testId ?? id,
            executionId: id,
            directory: directory
        )
        let registry = DiagnosticArtifactRegistry(executionId: id, directory: directory)
        queue.sync(flags: .barrier) {
            self.loggers[id] = logger
            self.eventWriters[id] = writer
            self.performanceRecorders[id] = recorder
            self.artifactRegistries[id] = registry
            self.artifactDirectories[id] = directory
        }
    }

    /// Persists one redacted canonical event and mirrors a compact readable line
    /// into the ordinary per-test log.
    func event(_ event: DiagnosticEvent, loggerId: String? = nil) {
        let id = loggerId ?? currentLoggerId
        guard let id else { return }
        do {
            try queue.sync { try eventWriters[id]?.append(event) }
        } catch {
            log("diagnostic_event_write_failed reason=\(error.localizedDescription)", level: .error, loggerId: id)
        }
        queue.sync { performanceRecorders[id]?.record(event) }
        let duration = event.durationMilliseconds.map { " duration_ms=\($0)" } ?? ""
        let target = event.target.map { " target=\($0)" } ?? ""
        let reason = event.reasonCode.map { " reason=\($0)" } ?? ""
        let selector = event.selector.map { " selector_fingerprint=\($0.fingerprint)" } ?? ""
        let query = event.queryEvidence.map {
            " expected=\($0.expectedState) initial=\($0.initialState) final=\($0.finalState) candidates=\($0.candidateCount) attempts=\($0.attempts) evidence=\($0.evidenceLevel) candidate_collection=\($0.candidateCollection)"
        } ?? ""
        let collection = event.collectionEvidence.map {
            let expected = $0.expectedCount.map { " expected_count=\($0)" } ?? ""
            let actual = $0.actualCount.map { " actual_count=\($0)" } ?? ""
            let displayed = $0.displayedCount.map { " displayed_count=\($0)" } ?? ""
            let failed = $0.failedIndices.map { " failed_indices=\($0)" } ?? ""
            return " collection_expectation=\($0.expectation) matched=\($0.matched) attempts=\($0.attempts)\(expected)\(actual)\(displayed)\(failed)"
        } ?? ""
        let title = event.title.map { " — \($0)" } ?? ""
        log(
            "\(event.event) code=\(event.operationCode ?? "unknown") status=\(event.statusCode ?? "unknown")\(reason)\(duration)\(target)\(selector)\(query)\(collection)\(title)",
            loggerId: id
        )
    }

    /// Prints a message to the test console log and log file.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level (default is .def).
    ///   - loggerId: Optional logger ID (uses current test ID if not provided).
    func log(_ message: String, level: LogLevel = .def, loggerId: String? = nil) {
        let safeMessage = SensitiveDataRedactor.redact(message)
        let id = loggerId ?? currentLoggerId
        guard let loggerId = id else {
            // Fallback: print to console without file logging
            if XCEasyConfig.printLogToConsole {
                print("[XCEasy] No logger ID available: \(safeMessage)")
            }
            return
        }

        queue.sync {
            loggers[loggerId]?.log(String.tab + safeMessage, level: level)
        }
    }

    /// Starts a log block with a delimiter.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - delimeter: The delimiter to use (default is .line).
    func startLogBlock(_ message: String, delimeter: Delimeters = .line) {
        guard let currentLoggerId = currentLoggerId else { return }
        queue.sync {
            loggers[currentLoggerId]?.log(delimeter.rawValue)
            loggers[currentLoggerId]?.log(message)
        }
    }

    /// Ends a log block with a delimiter.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - delimeter: The delimiter to use (default is .line).
    func endLogBlock(_ message: String, delimeter: Delimeters = .line) {
        guard let currentLoggerId = currentLoggerId else { return }
        queue.sync {
            loggers[currentLoggerId]?.log(message)
            loggers[currentLoggerId]?.log(delimeter.rawValue)
        }
    }

    /// Logs a message block with delimiters.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level (default is .info).
    ///   - topDelimeter: The top delimiter (default is .line).
    ///   - bottomDelimeter: The bottom delimiter (default is .line).
    func logBlock(
        _ message: String,
        level: LogLevel = .info,
        topDelimeter: Delimeters = .line,
        bottomDelimeter: Delimeters = .line
    ) {
        guard let currentLoggerId = currentLoggerId else { return }
        queue.sync {
            loggers[currentLoggerId]?.log(topDelimeter.rawValue, level: level)
            loggers[currentLoggerId]?.log(message, level: level)
            loggers[currentLoggerId]?.log(bottomDelimeter.rawValue, level: level)
        }
    }

    /// Logs a delimiter line.
    /// - Parameters:
    ///   - level: The log level (default is .info).
    ///   - delimeter: The delimiter to use (default is .line).
    func logDelimeter(level: LogLevel = .info, delimeter: Delimeters = .line) {
        guard let currentLoggerId = currentLoggerId else { return }
        queue.sync {
            loggers[currentLoggerId]?.log(delimeter.rawValue, level: level)
        }
    }

    /// Stops the test logger for a specific test ID.
    /// - Parameter id: The unique test identifier.
    func end(id: String) {
        queue.sync(flags: .barrier) {
            self.loggers[id]?.close()
            self.loggers.removeValue(forKey: id)
            self.eventWriters.removeValue(forKey: id)
            self.performanceRecorders.removeValue(forKey: id)
            self.artifactRegistries.removeValue(forKey: id)
            self.artifactDirectories.removeValue(forKey: id)
        }
    }

    /// Returns current test log file URL if available.
    func currentLogFileURL() -> URL? {
        guard let currentLoggerId = currentLoggerId else { return nil }
        return queue.sync {
            loggers[currentLoggerId]?.getLogFileURL()
        }
    }

    /// Returns the canonical JSONL event stream for the current execution.
    ///
    /// - Returns: Event file URL, or `nil` before logger initialization.
    func currentEventFileURL() -> URL? {
        guard let currentLoggerId = currentLoggerId else { return nil }
        return queue.sync { eventWriters[currentLoggerId]?.fileURL() }
    }

    /// Writes the current execution's aggregated performance summary.
    ///
    /// - Returns: Allure attachment metadata, or `nil` when no execution is active.
    /// - Throws: A filesystem or encoding error from the performance recorder.
    func writeCurrentPerformanceSummary() throws -> Attachment? {
        guard let currentLoggerId else { return nil }
        return try queue.sync {
            try performanceRecorders[currentLoggerId]?.writeSummary()
        }
    }

    /// Captures bounded, redacted UI evidence only when a query fails.
    /// Returned references are embedded into the canonical failure event.
    func captureUIFailureEvidence(producerEventId: String?) -> [DiagnosticAttachmentReference] {
        guard let id = currentLoggerId,
              let registry = queue.sync(execute: { artifactRegistries[id] }),
              let app = XCEasyTestContext.shared.app else {
            return []
        }

        var references: [DiagnosticAttachmentReference] = []
        let window = app.windows.firstMatch
        if ScreenshotUtils.canCaptureScreenshot(
            isApplicationRunning: app.state == .runningForeground,
            windowExists: window.exists
        ) {
            do {
                let screenshot = window.screenshot().pngRepresentation
                let reference = try registry.write(
                    data: screenshot,
                    extension: "png",
                    kind: "ui_screenshot",
                    mimeType: "image/png",
                    producerEventId: producerEventId
                )
                references.append(reference)
                appendCurrentTestAttachment(Attachment(
                    name: "UI failure screenshot",
                    source: reference.path,
                    type: reference.mimeType
                ))
            } catch {
                log("ui_failure_screenshot_write_failed reason=\(error.localizedDescription)", level: .error, loggerId: id)
            }
        } else {
            log("ui_failure_screenshot_skipped reason=application_window_unavailable", level: .debug, loggerId: id)
        }

        do {
            let hierarchy = SensitiveDataRedactor.redact(app.debugDescription)
            let reference = try registry.write(
                data: Data(hierarchy.utf8),
                extension: "txt",
                kind: "ui_hierarchy",
                mimeType: "text/plain",
                producerEventId: producerEventId,
                byteLimit: XCEasyConfig.diagnosticSnapshotByteLimit
            )
            references.append(reference)
            appendCurrentTestAttachment(Attachment(
                name: "Redacted UI hierarchy",
                source: reference.path,
                type: reference.mimeType
            ))
        } catch {
            log("ui_failure_hierarchy_write_failed reason=\(error.localizedDescription)", level: .error, loggerId: id)
        }
        return references
    }

    /// Evaluates selector evidence and stores a review-only healing proposal.
    ///
    /// - Parameters:
    ///   - selector: Failed immutable locator chain.
    ///   - candidates: Bounded candidate evidence collected from the current UI tree.
    ///   - reasonCode: Stable reason explaining why resolution failed.
    ///   - producerEventId: Event that produced the evidence.
    /// - Returns: Registered proposal attachment, or `nil` if no execution exists or writing fails.
    func recordHealingProposal(
        selector: XCEasyLocatorDescriptor,
        candidates: [XCEasyQueryEvidence.Candidate],
        reasonCode: String,
        producerEventId: String?
    ) -> DiagnosticAttachmentReference? {
        guard let id = currentLoggerId,
              let registry = queue.sync(execute: { artifactRegistries[id] }) else { return nil }
        let fingerprintInput = [
            XCEasyTestContext.shared.testId ?? "unknown",
            selector.fingerprint,
            reasonCode
        ].joined(separator: "|")
        let failureFingerprint = SHA256.hash(data: Data(fingerprintInput.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let proposal = XCEasyHealingEngine.evaluate(
            input: XCEasyHealingInput(
                executionId: XCEasyTestContext.shared.executionId ?? id,
                failureFingerprint: failureFingerprint,
                selector: selector,
                candidates: candidates
            ),
            configuration: XCEasyConfig.healing
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let reference = try registry.write(
                data: try encoder.encode(proposal),
                extension: "json",
                kind: "healing_proposal",
                mimeType: "application/json",
                producerEventId: producerEventId
            )
            appendCurrentTestAttachment(Attachment(
                name: "XCEasy selector healing proposal",
                source: reference.path,
                type: reference.mimeType
            ))
            return reference
        } catch {
            log("healing_proposal_write_failed reason=\(error.localizedDescription)", level: .error, loggerId: id)
            return nil
        }
    }

    /// Finalizes the evidence bundle and returns attachments for the Allure result.
    ///
    /// - Parameter testResult: Final test result used to build summary and reproduction artifacts.
    /// - Returns: Attachment metadata for the generated diagnostic artifacts.
    /// - Throws: A filesystem, hashing, or encoding error while finalizing the bundle.
    func writeCurrentDiagnosticBundle(testResult: TestResult) throws -> [Attachment] {
        guard let id = currentLoggerId else { return [] }
        let resources = queue.sync {
            (
                artifactRegistries[id],
                artifactDirectories[id],
                eventWriters[id]?.fileURL(),
                loggers[id]?.getLogFileURL()
            )
        }
        guard let registry = resources.0, let directory = resources.1 else { return [] }
        if let logURL = resources.3, FileManager.default.fileExists(atPath: logURL.path) {
            let logData = try Data(contentsOf: logURL)
            _ = try registry.write(
                data: logData,
                extension: "log",
                kind: "log_snapshot",
                mimeType: "text/plain",
                producerEventId: XCEasyTestContext.shared.executionId
            )
        }
        return try XCEasyDiagnosticBundleWriter(directory: directory, registry: registry).write(
            testResult: testResult,
            eventFileURL: resources.2,
            logFileURL: nil
        )
    }

    /// Adds a generated artifact to the in-memory result without resolving global test state.
    ///
    /// - Parameter attachment: Allure metadata for an already persisted artifact.
    private func appendCurrentTestAttachment(_ attachment: Attachment) {
        guard var result = XCEasyTestContext.shared.testResult else { return }
        result.attachments = (result.attachments ?? []) + [attachment]
        XCEasyTestContext.shared.testResult = result
    }

    // MARK: - Private Properties

    /// Gets the current logger ID from the test context.
    private var currentLoggerId: String? {
        XCEasyTestContext.shared.executionId ?? XCEasyTestContext.shared.testId
    }
}
