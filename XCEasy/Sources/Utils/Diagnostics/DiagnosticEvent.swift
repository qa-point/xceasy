import Foundation

internal struct DiagnosticSource: Codable, Equatable {
    let file: String
    let line: Int
    let function: String?

    /// Creates a privacy-safe source location without exposing machine-specific paths.
    ///
    /// - Parameters:
    ///   - file: Source path; only its final component is retained.
    ///   - line: Source line normalized to a nonnegative value.
    ///   - function: Optional function name redacted before storage.
    init(file: String, line: Int, function: String?) {
        self.file = URL(fileURLWithPath: file).lastPathComponent
        self.line = max(0, line)
        self.function = function.map(SensitiveDataRedactor.redact)
    }
}

internal struct DiagnosticPrivacy: Codable, Equatable {
    let redacted: Bool
    let ruleset: String

    static let standard = DiagnosticPrivacy(redacted: true, ruleset: "default-v1")
}

internal struct DiagnosticAttachmentReference: Codable, Equatable {
    let id: String
    let path: String
    let mimeType: String
    let kind: String
    let truncated: Bool
}

internal struct DiagnosticPerformanceEvidence: Codable, Equatable {
    let operationKey: String
    let phasesMilliseconds: [String: Int64]
    let budgetMilliseconds: Int64?
    let budgetStatus: String?
}

internal struct DiagnosticEvent: Codable, Equatable {
    static let schemaVersion = "1.0.0"

    let schemaVersion: String
    let timestamp: String
    let monotonicNanoseconds: UInt64
    let event: String
    let level: String
    let testId: String?
    let executionId: String?
    let runId: String?
    let deviceId: String?
    let shardIndex: Int?
    let attempt: Int?
    let processId: Int32
    let threadId: String
    let operationCode: String?
    let operationId: String?
    let parentOperationId: String?
    let statusCode: String?
    let reasonCode: String?
    let durationMilliseconds: Int64?
    let target: String?
    let title: String?
    let selector: XCEasyLocatorDescriptor?
    let queryEvidence: XCEasyQueryEvidence?
    let collectionEvidence: XCEasyCollectionEvidence?
    let source: DiagnosticSource?
    let privacy: DiagnosticPrivacy
    let attachments: [DiagnosticAttachmentReference]?
    let performance: DiagnosticPerformanceEvidence?

    /// Creates a versioned, privacy-safe canonical diagnostic event.
    ///
    /// Environment and execution defaults are captured at initialization, while dynamic text
    /// is redacted before it reaches any sink.
    ///
    /// - Parameters:
    ///   - event: Stable lowercase-dot event name.
    ///   - level: Canonical severity such as `info`, `warning`, or `error`.
    ///   - testId: Stable test-case identifier.
    ///   - executionId: Unique test-attempt identifier.
    ///   - runId: Optional coordinator run identifier.
    ///   - deviceId: Optional simulator or device identifier.
    ///   - shardIndex: Optional zero-based worker shard index.
    ///   - attempt: Optional execution or recovery attempt number.
    ///   - processId: Runner process identifier.
    ///   - threadId: Thread correlation identifier.
    ///   - operationCode: Stable semantic operation code.
    ///   - operationId: Unique operation identifier.
    ///   - parentOperationId: Owning operation identifier for nested work.
    ///   - statusCode: Stable operation status.
    ///   - reasonCode: Stable outcome or failure reason.
    ///   - durationMilliseconds: Measured operation duration.
    ///   - target: Human-readable target redacted before storage.
    ///   - title: Human-readable title redacted before storage.
    ///   - selector: Privacy-safe immutable locator descriptor.
    ///   - queryEvidence: Bounded UI observation evidence.
    ///   - collectionEvidence: Bounded component-collection selection or polling evidence.
    ///   - source: Call-site source metadata.
    ///   - privacy: Redaction policy applied to the event.
    ///   - attachments: Evidence artifacts linked to the event.
    ///   - performance: Timing phases and budget evidence.
    ///   - date: Wall-clock timestamp, injectable for deterministic tests.
    ///   - monotonicNanoseconds: Monotonic timestamp, injectable for deterministic tests.
    init(
        event: String,
        level: String = "info",
        testId: String? = nil,
        executionId: String? = XCEasyTestContext.shared.executionId,
        runId: String? = ProcessInfo.processInfo.environment["XC_EASY_RUN_ID"],
        deviceId: String? = ProcessInfo.processInfo.environment["XC_EASY_DEVICE_ID"],
        shardIndex: Int? = ProcessInfo.processInfo.environment["XC_EASY_SHARD_INDEX"].flatMap(Int.init),
        attempt: Int? = ProcessInfo.processInfo.environment["XC_EASY_ATTEMPT"].flatMap(Int.init),
        processId: Int32 = ProcessInfo.processInfo.processIdentifier,
        threadId: String = String(describing: ObjectIdentifier(Thread.current)),
        operationCode: String? = nil,
        operationId: String? = nil,
        parentOperationId: String? = nil,
        statusCode: String? = nil,
        reasonCode: String? = nil,
        durationMilliseconds: Int64? = nil,
        target: String? = nil,
        title: String? = nil,
        selector: XCEasyLocatorDescriptor? = nil,
        queryEvidence: XCEasyQueryEvidence? = nil,
        collectionEvidence: XCEasyCollectionEvidence? = nil,
        source: DiagnosticSource? = nil,
        privacy: DiagnosticPrivacy = .standard,
        attachments: [DiagnosticAttachmentReference]? = nil,
        performance: DiagnosticPerformanceEvidence? = nil,
        date: Date = Date(),
        monotonicNanoseconds: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) {
        self.schemaVersion = Self.schemaVersion
        self.timestamp = ISO8601DateFormatter.xceasy.string(from: date)
        self.monotonicNanoseconds = monotonicNanoseconds
        self.event = event
        self.level = level
        self.testId = testId
        self.executionId = executionId
        self.runId = runId
        self.deviceId = deviceId
        self.shardIndex = shardIndex
        self.attempt = attempt
        self.processId = processId
        self.threadId = threadId
        self.operationCode = operationCode
        self.operationId = operationId
        self.parentOperationId = parentOperationId
        self.statusCode = statusCode
        self.reasonCode = reasonCode
        self.durationMilliseconds = durationMilliseconds
        self.target = target.map(SensitiveDataRedactor.redact)
        self.title = title.map(SensitiveDataRedactor.redact)
        self.selector = selector
        self.queryEvidence = queryEvidence
        self.collectionEvidence = collectionEvidence
        self.source = source
        self.privacy = privacy
        self.attachments = attachments
        self.performance = performance
    }
}

private extension ISO8601DateFormatter {
    static let xceasy: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
