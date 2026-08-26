import Foundation
import XCTest
@testable import XCEasy

final class DiagnosticsTests: XCTestCase {
    func testSensitiveDataRulesetCompilationFailsClosedForInvalidPattern() {
        XCTAssertTrue(SensitiveDataRedactor.compilePatterns(["token"]).isValid)
        let invalid = SensitiveDataRedactor.compilePatterns(["["])
        XCTAssertFalse(invalid.isValid)
        XCTAssertTrue(invalid.expressions.isEmpty)
    }

    func testRedactorRemovesCommonSecretsCaseInsensitively() {
        let source = "Authorization: Bearer abc.def password=hunter2 api_key=xyz"
        let redacted = SensitiveDataRedactor.redact(source)

        XCTAssertFalse(redacted.contains("abc.def"))
        XCTAssertFalse(redacted.contains("hunter2"))
        XCTAssertFalse(redacted.contains("xyz"))
        XCTAssertTrue(redacted.contains("<redacted>"))
    }

    func testRedactorCoversBearerAndKeyValueVariantsWithoutChangingSafeText() {
        let canaries = [
            "authorization=Bearer upper.canary",
            "BEARER standalone-canary",
            "passwd: password-canary",
            "TOKEN=token-canary",
            "secret: secret-canary",
            "api-key=api-canary",
            "api_key: underscore-canary"
        ]

        for canary in canaries {
            let redacted = SensitiveDataRedactor.redact(canary)
            XCTAssertTrue(redacted.contains("<redacted>"), canary)
            XCTAssertFalse(redacted.contains("canary"), canary)
        }
        XCTAssertEqual(SensitiveDataRedactor.redact("safe diagnostic text"), "safe diagnostic text")
    }

    func testDiagnosticEventRedactsPresentationFieldsAndKeepsCanonicalCodes() {
        let event = DiagnosticEvent(
            event: "operation.finished",
            operationCode: "ui.type_text",
            statusCode: "passed",
            target: "password=secret",
            title: "Authorization: token",
            date: Date(timeIntervalSince1970: 0),
            monotonicNanoseconds: 42
        )

        XCTAssertEqual(event.operationCode, "ui.type_text")
        XCTAssertEqual(event.statusCode, "passed")
        XCTAssertEqual(event.monotonicNanoseconds, 42)
        XCTAssertFalse(event.target?.contains("secret") == true)
        XCTAssertFalse(event.title?.contains("token") == true)
    }

    func testDiagnosticEventCarriesExecutionCorrelationMetadata() throws {
        let event = DiagnosticEvent(
            event: "operation.finished",
            runId: "run-123",
            deviceId: "device-456",
            shardIndex: 2,
            attempt: 3,
            date: Date(timeIntervalSince1970: 0),
            monotonicNanoseconds: 42
        )

        XCTAssertEqual(event.schemaVersion, "1.0.0")
        XCTAssertEqual(event.runId, "run-123")
        XCTAssertEqual(event.deviceId, "device-456")
        XCTAssertEqual(event.shardIndex, 2)
        XCTAssertEqual(event.attempt, 3)

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
        )
        XCTAssertEqual(object["runId"] as? String, "run-123")
        XCTAssertEqual(object["deviceId"] as? String, "device-456")
        XCTAssertEqual(object["shardIndex"] as? Int, 2)
        XCTAssertEqual(object["attempt"] as? Int, 3)
    }

    func testQueryEvidenceIsStructuredCorrelatedAndRedacted() throws {
        let descriptor = XCEasyLocatorDescriptor(segments: [
            XCEasyLocatorDescriptor.Segment(
                type: .button,
                identifier: "password=selector-canary",
                predicate: nil,
                text: nil,
                index: nil
            )
        ])
        let candidate = XCEasyQueryEvidence.Candidate(
            relationship: "alternative",
            elementType: "button",
            identifier: "token=candidate-canary",
            label: "Authorization: label-canary",
            value: "password=value-canary",
            frame: CGRect(x: 1, y: 2, width: 3, height: 4),
            isEnabled: true,
            isSelected: false,
            isHittable: true
        )
        let evidence = XCEasyQueryEvidence(
            expectedState: "absent",
            initialState: "visible",
            finalState: "absent",
            evidenceLevel: "basic",
            candidateCollection: "bounded",
            matched: true,
            reasonCode: "query.element_absent",
            attempts: 3,
            elapsedMilliseconds: 125,
            candidateCount: 0,
            selectedIndex: nil,
            failedSegmentIndex: 0,
            ancestorState: nil,
            candidates: [candidate],
            observations: [
                XCEasyQueryEvidence.Observation(
                    attempt: 1,
                    elapsedMilliseconds: 0,
                    state: "visible",
                    exists: true,
                    isHittable: true
                ),
                XCEasyQueryEvidence.Observation(
                    attempt: 3,
                    elapsedMilliseconds: 125,
                    state: "absent",
                    exists: false,
                    isHittable: false
                )
            ]
        )
        let event = DiagnosticEvent(
            event: "ui.query.resolved",
            testId: "test-id",
            operationCode: "ui.query",
            operationId: "query-id",
            parentOperationId: "assert-id",
            statusCode: "passed",
            reasonCode: evidence.reasonCode,
            selector: descriptor,
            queryEvidence: evidence,
            date: Date(timeIntervalSince1970: 0),
            monotonicNanoseconds: 42
        )

        let data = try JSONEncoder().encode(event)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains("\"schemaVersion\":\"1.0.0\""))
        XCTAssertTrue(json.contains("\"evidenceLevel\":\"basic\""))
        XCTAssertTrue(json.contains("\"candidateCollection\":\"bounded\""))
        XCTAssertTrue(json.contains("\"parentOperationId\":\"assert-id\""))
        XCTAssertTrue(json.contains("\"reasonCode\":\"query.element_absent\""))
        XCTAssertTrue(json.contains(descriptor.fingerprint))
        XCTAssertFalse(json.contains("selector-canary"))
        XCTAssertFalse(json.contains("candidate-canary"))
        XCTAssertFalse(json.contains("label-canary"))
        XCTAssertFalse(json.contains("value-canary"))
    }

    func testCollectionEvidenceEncodesBoundedCurrentStateAndSymbolicSelection() throws {
        let descriptor = XCEasyUIElement(identifier: "product.card", timeout: 0)
            .element(at: .last)
            .locatorDescriptor
        let evidence = XCEasyCollectionEvidence(
            expectation: "all_displayed",
            expectedCount: nil,
            actualCount: 3,
            matched: false,
            attempts: 2,
            elapsedMilliseconds: 125,
            selectedPosition: nil,
            selectedIndex: nil,
            selectedIndices: nil,
            displayedCount: 2,
            failedIndices: [1],
            isContextAvailable: true,
            observations: [
                .init(
                    attempt: 2,
                    elapsedMilliseconds: 125,
                    count: 3,
                    displayedCount: 2,
                    failedIndices: [1],
                    isContextAvailable: true
                )
            ]
        )
        let event = DiagnosticEvent(
            event: "ui.collection.finished",
            operationCode: "component.collection.wait_all_displayed",
            operationId: "collection-id",
            statusCode: "not_matched",
            reasonCode: "collection.state_not_matched",
            durationMilliseconds: 125,
            selector: descriptor,
            collectionEvidence: evidence,
            date: Date(timeIntervalSince1970: 0),
            monotonicNanoseconds: 42
        )

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
        )
        let selector = try XCTUnwrap(object["selector"] as? [String: Any])
        let segments = try XCTUnwrap(selector["segments"] as? [[String: Any]])
        let encodedEvidence = try XCTUnwrap(object["collectionEvidence"] as? [String: Any])

        XCTAssertEqual(segments.first?["selection"] as? String, "last")
        XCTAssertEqual(encodedEvidence["actualCount"] as? Int, 3)
        XCTAssertEqual(encodedEvidence["displayedCount"] as? Int, 2)
        XCTAssertEqual(encodedEvidence["failedIndices"] as? [Int], [1])
        XCTAssertEqual(encodedEvidence["matched"] as? Bool, false)
    }

    func testWriterProducesOneDecodableJSONLObjectPerLine() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-diagnostics-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let writer = try DiagnosticEventWriter(testId: "test-id", directory: directory)
        try writer.append(DiagnosticEvent(event: "first", date: Date(timeIntervalSince1970: 0), monotonicNanoseconds: 1))
        try writer.append(DiagnosticEvent(event: "second", date: Date(timeIntervalSince1970: 1), monotonicNanoseconds: 2))

        let contents = try String(contentsOf: writer.fileURL(), encoding: .utf8)
        let lines = contents.split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(DiagnosticEvent.self, from: Data(lines[0].utf8)).event, "first")
        XCTAssertEqual(try decoder.decode(DiagnosticEvent.self, from: Data(lines[1].utf8)).event, "second")
    }

    func testPersistentLogRedactsSecretsAndContainsNoANSISequences() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-log-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let logger = XCEasyLogger(testId: "redaction", logDir: directory)
        logger.log("Authorization: Bearer canary.secret password=hunter2", printLog: false)
        logger.close()

        let url = try XCTUnwrap(logger.getLogFileURL())
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(contents.contains("canary.secret"))
        XCTAssertFalse(contents.contains("hunter2"))
        XCTAssertFalse(contents.contains("\u{001B}["))
        XCTAssertTrue(contents.contains("<redacted>"))
    }

    func testTwentyConcurrentDiagnosticContextsDoNotMixEvents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-diagnostics-concurrency-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let contextCount = 20
        let eventCount = 25
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "xceasy.diagnostics.stress", attributes: .concurrent)
        let failureLock = NSLock()
        var failures: [Error] = []

        for contextIndex in 0..<contextCount {
            group.enter()
            queue.async {
                defer { group.leave() }
                let testID = "test-\(contextIndex)"
                do {
                    let writer = try DiagnosticEventWriter(testId: testID, directory: directory)
                    for eventIndex in 0..<eventCount {
                        try writer.append(DiagnosticEvent(
                            event: "stress.event",
                            testId: testID,
                            operationId: "operation-\(eventIndex)",
                            date: Date(timeIntervalSince1970: TimeInterval(eventIndex)),
                            monotonicNanoseconds: UInt64(eventIndex)
                        ))
                    }
                } catch {
                    failureLock.lock()
                    failures.append(error)
                    failureLock.unlock()
                }
            }
        }
        group.wait()

        XCTAssertTrue(failures.isEmpty)
        let decoder = JSONDecoder()
        for contextIndex in 0..<contextCount {
            let testID = "test-\(contextIndex)"
            let url = directory.appendingPathComponent("\(testID)_events.jsonl")
            let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
            XCTAssertEqual(lines.count, eventCount)
            for line in lines {
                let event = try decoder.decode(DiagnosticEvent.self, from: Data(line.utf8))
                XCTAssertEqual(event.testId, testID)
            }
        }
    }
}
