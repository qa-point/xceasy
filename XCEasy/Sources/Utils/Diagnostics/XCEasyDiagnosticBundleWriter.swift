import CryptoKit
import Foundation

internal struct XCEasyDiagnosticManifest: Codable, Equatable {
    struct Git: Codable, Equatable {
        let commit: String?
        let dirty: Bool?
    }

    let schemaVersion: String
    let testId: String
    let executionId: String
    let runId: String?
    let deviceId: String?
    let attempt: Int
    let frameworkVersion: String
    let locale: String
    let timezone: String
    let git: Git
    let artifacts: [DiagnosticArtifactRecord]
}

internal struct XCEasyDiagnosticSummary: Codable, Equatable {
    let schemaVersion: String
    let testId: String
    let executionId: String
    let status: String
    let failureCategory: String
    let failureFingerprint: String?
    let primaryFailure: String?
    let evidencePaths: [String]
}

internal struct XCEasyDiagnosticBundleWriter {
    let directory: URL
    let registry: DiagnosticArtifactRegistry

    /// Finalizes a self-contained diagnostic summary, reproduction, and integrity manifest.
    ///
    /// - Parameters:
    ///   - testResult: Final Allure result and attachment graph.
    ///   - eventFileURL: Canonical execution event stream, when available.
    ///   - logFileURL: Immutable readable log snapshot, when available.
    /// - Returns: Allure attachment metadata for the generated bundle entry points.
    /// - Throws: A read, encoding, hashing, or atomic-write error.
    func write(
        testResult: TestResult,
        eventFileURL: URL?,
        logFileURL: URL?
    ) throws -> [Attachment] {
        try registerIfPresent(eventFileURL, kind: "diagnostic_events", mimeType: "application/x-ndjson")
        try registerIfPresent(logFileURL, kind: "log", mimeType: "text/plain")
        for attachment in testResult.attachments ?? [] {
            guard let source = attachment.source else { continue }
            // The readable logger remains open until result persistence ends.
            // XCEasyTestLogger registers an immutable log snapshot instead.
            if source.hasSuffix("_xceasy_log.log") { continue }
            let url = directory.appendingPathComponent(source)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            try registry.registerExisting(
                url: url,
                kind: artifactKind(mimeType: attachment.type),
                mimeType: attachment.type ?? "application/octet-stream"
            )
        }

        let executionId = testResult.uuid ?? "unknown-execution"
        let testId = testResult.testCaseId ?? "unknown-test"
        let status = testResult.status?.rawValue ?? "unknown"
        let safeFailure = testResult.statusDetails?.message.map(SensitiveDataRedactor.redact)
        let fingerprint = safeFailure.map {
            Self.digest("\(testResult.fullName ?? "unknown")|\(status)|\(Self.normalizeFailure($0))")
        }
        let summary = XCEasyDiagnosticSummary(
            schemaVersion: "1.0.0",
            testId: testId,
            executionId: executionId,
            status: status,
            failureCategory: Self.failureCategory(status: status, message: safeFailure),
            failureFingerprint: fingerprint,
            primaryFailure: safeFailure,
            evidencePaths: registry.records().map(\.path)
        )
        let summaryName = "\(executionId)_diagnostic-summary.json"
        try writeJSON(summary, filename: summaryName)
        try registry.registerExisting(
            url: directory.appendingPathComponent(summaryName),
            kind: "diagnostic_summary",
            mimeType: "application/json"
        )

        let reproductionName = "\(executionId)_reproduction.md"
        let reproduction = Self.reproductionMarkdown(testResult: testResult, summary: summary)
        try AtomicFileWriter.write(Data(reproduction.utf8), to: directory.appendingPathComponent(reproductionName))
        try registry.registerExisting(
            url: directory.appendingPathComponent(reproductionName),
            kind: "reproduction",
            mimeType: "text/markdown"
        )

        let manifest = XCEasyDiagnosticManifest(
            schemaVersion: "1.0.0",
            testId: testId,
            executionId: executionId,
            runId: ProcessInfo.processInfo.environment["XC_EASY_RUN_ID"],
            deviceId: ProcessInfo.processInfo.environment["XC_EASY_DEVICE_ID"],
            attempt: ProcessInfo.processInfo.environment["XC_EASY_ATTEMPT"].flatMap(Int.init) ?? 1,
            frameworkVersion: "0.1.1",
            locale: XCEasyConfig.localization.rawValue,
            timezone: TimeZone.current.identifier,
            git: .init(
                commit: ProcessInfo.processInfo.environment["GIT_COMMIT"],
                dirty: ProcessInfo.processInfo.environment["GIT_DIRTY"].map {
                    ["1", "true", "yes"].contains($0.lowercased())
                }
            ),
            artifacts: registry.records()
        )
        let manifestName = "\(executionId)_diagnostic-manifest.json"
        try writeJSON(manifest, filename: manifestName)

        return [
            Attachment(name: "XCEasy Diagnostic Manifest.json", source: manifestName, type: "application/json"),
            Attachment(name: "XCEasy Diagnostic Summary.json", source: summaryName, type: "application/json"),
            Attachment(name: "XCEasy Reproduction.md", source: reproductionName, type: "text/markdown")
        ]
    }

    /// Registers an optional existing file only when it is present on disk.
    ///
    /// - Parameters:
    ///   - url: Optional artifact URL.
    ///   - kind: Stable manifest category.
    ///   - mimeType: Artifact MIME type.
    /// - Throws: An error when an existing file cannot be read.
    private func registerIfPresent(_ url: URL?, kind: String, mimeType: String) throws {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return }
        try registry.registerExisting(url: url, kind: kind, mimeType: mimeType)
    }

    /// Encodes a model as deterministic, human-readable JSON and writes it atomically.
    ///
    /// - Parameters:
    ///   - value: Encodable diagnostic model.
    ///   - filename: Bundle-relative output filename.
    /// - Throws: An encoding or filesystem error.
    private func writeJSON<T: Encodable>(_ value: T, filename: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try AtomicFileWriter.write(
            try encoder.encode(value),
            to: directory.appendingPathComponent(filename)
        )
    }

    /// Maps a MIME type to a stable diagnostic artifact category.
    ///
    /// - Parameter mimeType: Optional Allure attachment MIME type.
    /// - Returns: Stable manifest category, defaulting to `attachment`.
    private func artifactKind(mimeType: String?) -> String {
        switch mimeType {
        case "image/png", "image/jpeg": return "screenshot"
        case "application/x-ndjson": return "diagnostic_events"
        case "application/json": return "json"
        case "text/plain": return "log"
        default: return "attachment"
        }
    }

    /// Classifies a failure conservatively from status and privacy-safe evidence.
    ///
    /// - Parameters:
    ///   - status: Final Allure status.
    ///   - message: Optional redacted primary failure.
    /// - Returns: Stable product, infrastructure, framework, passed, or unknown category.
    private static func failureCategory(status: String, message: String?) -> String {
        guard status != "passed" else { return "passed" }
        let value = message?.lowercased() ?? ""
        if value.contains("assert") || value.contains("expected") { return "product" }
        if value.contains("timeout") || value.contains("simulator") { return "infrastructure" }
        if value.contains("framework") || value.contains("context.application") { return "framework" }
        return "unknown"
    }

    /// Removes volatile UUID and numeric values before failure fingerprinting.
    ///
    /// - Parameter value: Redacted failure message.
    /// - Returns: Cross-run comparable failure text.
    private static func normalizeFailure(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}"#, with: "<uuid>", options: .regularExpression)
            .replacingOccurrences(of: #"\b\d+(?:\.\d+)?\b"#, with: "<number>", options: .regularExpression)
    }

    /// Produces a lowercase SHA-256 failure fingerprint.
    ///
    /// - Parameter value: Canonical fingerprint input.
    /// - Returns: A 64-character hexadecimal digest.
    private static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Renders a concise evidence-oriented reproduction handoff.
    ///
    /// - Parameters:
    ///   - testResult: Final test identity and status details.
    ///   - summary: Canonical diagnostic summary.
    /// - Returns: Markdown that directs humans and AI to cited artifacts.
    private static func reproductionMarkdown(
        testResult: TestResult,
        summary: XCEasyDiagnosticSummary
    ) -> String {
        let failure = summary.primaryFailure ?? "No primary failure was recorded."
        return """
        # XCEasy reproduction summary

        - Test: `\(SensitiveDataRedactor.redact(testResult.fullName ?? "unknown"))`
        - Test ID: `\(summary.testId)`
        - Execution ID: `\(summary.executionId)`
        - Status: `\(summary.status)`
        - Failure category: `\(summary.failureCategory)`
        - Failure fingerprint: `\(summary.failureFingerprint ?? "none")`

        ## Primary evidence

        \(failure)

        Inspect the diagnostic manifest and referenced event/attachment IDs before proposing a change.
        """
    }
}
