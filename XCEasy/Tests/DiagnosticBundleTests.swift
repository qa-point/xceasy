import Foundation
import XCTest
@testable import XCEasy

final class DiagnosticBundleTests: XCTestCase {
    func testBundleIndexesArtifactsAndProducesStableFailureFingerprint() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let events = directory.appendingPathComponent("execution_events.jsonl")
        try AtomicFileWriter.write(Data("{}\n".utf8), to: events)
        let log = directory.appendingPathComponent("execution.log")
        try AtomicFileWriter.write(Data("safe log".utf8), to: log)
        let registry = DiagnosticArtifactRegistry(executionId: "execution", directory: directory)
        let writer = XCEasyDiagnosticBundleWriter(directory: directory, registry: registry)
        let result = TestResult(
            uuid: "execution",
            historyId: "history",
            testCaseId: "test-id",
            fullName: "Module/Test/test()",
            testCaseName: "test()",
            name: "test",
            status: .failed,
            stage: .finished,
            statusDetails: StatusDetails(message: "Expected 42 but got 17", trace: nil),
            start: 1,
            stop: 2
        )

        let attachments = try writer.write(testResult: result, eventFileURL: events, logFileURL: log)

        XCTAssertEqual(attachments.count, 3)
        XCTAssertEqual(
            attachments.map(\.name),
            [
                "XCEasy Diagnostic Manifest.json",
                "XCEasy Diagnostic Summary.json",
                "XCEasy Reproduction.md"
            ]
        )
        let summaryData = try Data(contentsOf: directory.appendingPathComponent("execution_diagnostic-summary.json"))
        let summary = try JSONDecoder().decode(XCEasyDiagnosticSummary.self, from: summaryData)
        XCTAssertEqual(summary.failureCategory, "product")
        XCTAssertEqual(summary.failureFingerprint?.count, 64)
        let manifestData = try Data(contentsOf: directory.appendingPathComponent("execution_diagnostic-manifest.json"))
        let manifest = try JSONDecoder().decode(XCEasyDiagnosticManifest.self, from: manifestData)
        XCTAssertTrue(manifest.artifacts.contains { $0.path == "execution_events.jsonl" })
        XCTAssertTrue(manifest.artifacts.allSatisfy { $0.sha256.count == 64 })
    }

    func testRegistryTruncatesTextBeforePersistence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-registry-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let registry = DiagnosticArtifactRegistry(executionId: "execution", directory: directory)

        let reference = try registry.write(
            data: Data("0123456789".utf8),
            extension: "txt",
            kind: "ui_snapshot",
            mimeType: "text/plain",
            producerEventId: "event",
            byteLimit: 4
        )

        XCTAssertTrue(reference.truncated)
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent(reference.path)).count, 4)
        XCTAssertEqual(registry.records().first?.producerEventId, "event")
    }
}
