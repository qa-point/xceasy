import Foundation
import XCTest
@testable import XCEasy

final class AllureResultsValidatorTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-allure-validator-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testValidResultContainerAndAttachmentsPassValidation() throws {
        try writeJSON([
            "uuid": "test-1",
            "testCaseId": String(repeating: "a", count: 64),
            "historyId": String(repeating: "b", count: 64),
            "fullName": "Suite/testMethod",
            "name": "testMethod",
            "status": "passed",
            "stage": "finished",
            "start": 100,
            "stop": 120,
            "attachments": [["name": "events", "source": "test-1-events.jsonl", "type": "application/x-ndjson"]]
        ], named: "test-1-result.json")
        try writeJSON([
            "uuid": "container-1",
            "children": ["test-1"],
            "befores": [["name": "Setup", "attachments": [["source": "setup.log"]]]],
            "afters": [["name": "Teardown"]]
        ], named: "container-1-container.json")
        try writeJSON(["name": "XCEasy"], named: "executor.json")
        try writeJSON([], named: "categories.json")
        try Data("{}\n".utf8).write(to: directory.appendingPathComponent("test-1-events.jsonl"))
        try Data("setup".utf8).write(to: directory.appendingPathComponent("setup.log"))

        let summary = AllureResultsValidator().validate(directory: directory)

        XCTAssertTrue(summary.isValid, "\(summary.issues)")
        XCTAssertEqual(summary.resultCount, 1)
        XCTAssertEqual(summary.containerCount, 1)
        XCTAssertEqual(summary.attachmentCount, 2)
    }

    func testMissingAttachmentAndContainerLinkHaveStableIssueCodes() throws {
        try writeJSON([
            "uuid": "test-1",
            "testCaseId": String(repeating: "a", count: 64),
            "historyId": String(repeating: "b", count: 64),
            "fullName": "Suite/testMethod",
            "name": "testMethod",
            "status": "passed",
            "stage": "finished",
            "start": 100,
            "stop": 120,
            "attachments": [["source": "missing.log"]]
        ], named: "test-1-result.json")
        try writeJSON(["name": "XCEasy"], named: "executor.json")
        try writeJSON([], named: "categories.json")

        let summary = AllureResultsValidator().validate(directory: directory)
        let codes = Set(summary.issues.map(\.code))

        XCTAssertTrue(codes.contains("attachment_file_missing"))
        XCTAssertTrue(codes.contains("result_container_unlinked"))
    }

    func testMalformedResultIsReportedWithoutCrashing() throws {
        try Data("not-json".utf8).write(to: directory.appendingPathComponent("broken-result.json"))
        try writeJSON(["name": "XCEasy"], named: "executor.json")
        try writeJSON([], named: "categories.json")

        let summary = AllureResultsValidator().validate(directory: directory)

        XCTAssertEqual(summary.issues.first?.code, "json_invalid")
    }

    func testMissingStableIdentityHasExplicitIssue() throws {
        try writeJSON([
            "uuid": "test-1", "fullName": "Suite/testMethod", "name": "testMethod",
            "status": "passed", "stage": "finished", "start": 1, "stop": 2
        ], named: "test-1-result.json")
        try writeJSON(["uuid": "container", "children": ["test-1"]], named: "container-container.json")
        try writeJSON(["name": "XCEasy"], named: "executor.json")
        try writeJSON([], named: "categories.json")

        let codes = Set(AllureResultsValidator().validate(directory: directory).issues.map(\.code))

        XCTAssertTrue(codes.contains("required_field_missing"))
    }

    private func writeJSON(_ object: Any, named name: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try data.write(to: directory.appendingPathComponent(name))
    }
}
