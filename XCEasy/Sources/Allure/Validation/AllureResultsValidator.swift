import Foundation

internal struct AllureValidationIssue: Equatable {
    let code: String
    let file: String?
    let detail: String
}

internal struct AllureValidationSummary: Equatable {
    let resultCount: Int
    let containerCount: Int
    let attachmentCount: Int
    let issues: [AllureValidationIssue]

    var isValid: Bool { issues.isEmpty }
}

/// Validates the subset of the Allure 2 result contract emitted by XCEasy.
internal struct AllureResultsValidator {
    private let fileManager: FileManager

    /// Creates a validator with an injectable filesystem dependency.
    ///
    /// - Parameter fileManager: Filesystem used to enumerate results and verify attachments.
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Validates result, container, identity, timeline, attachment, and service-file contracts.
    ///
    /// - Parameter directory: Exported `allure-results` directory.
    /// - Returns: Counts plus every detected contract issue; validation does not stop early.
    func validate(directory: URL) -> AllureValidationSummary {
        let files: [URL]
        do {
            files = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return AllureValidationSummary(
                resultCount: 0,
                containerCount: 0,
                attachmentCount: 0,
                issues: [.init(
                    code: "directory_unreadable",
                    file: nil,
                    detail: "\(directory.path): \(error.localizedDescription)"
                )]
            )
        }

        let resultFiles = files.filter { $0.lastPathComponent.hasSuffix("-result.json") }
        let containerFiles = files.filter { $0.lastPathComponent.hasSuffix("-container.json") }
        var issues: [AllureValidationIssue] = []
        var resultIDs = Set<String>()
        var attachmentCount = 0

        if resultFiles.isEmpty {
            issues.append(.init(code: "result_missing", file: nil, detail: "No *-result.json files"))
        }

        for file in resultFiles {
            guard let object = jsonObject(at: file, issues: &issues) else { continue }
            if let resultID = requireString("uuid", in: object, file: file, issues: &issues) {
                resultIDs.insert(resultID)
            }
            _ = requireString("fullName", in: object, file: file, issues: &issues)
            _ = requireString("name", in: object, file: file, issues: &issues)
            _ = requireString("status", in: object, file: file, issues: &issues)
            validateIdentity(object, file: file, issues: &issues)
            if object["stage"] as? String != "finished" {
                issues.append(.init(code: "stage_not_finished", file: file.lastPathComponent, detail: "stage must be finished"))
            }
            validateTimeline(object, file: file, issues: &issues)
            attachmentCount += validateAttachments(in: object, directory: directory, file: file, issues: &issues)
        }

        var containerChildren = Set<String>()
        for file in containerFiles {
            guard let object = jsonObject(at: file, issues: &issues) else { continue }
            _ = requireString("uuid", in: object, file: file, issues: &issues)
            guard let children = object["children"] as? [String], !children.isEmpty else {
                issues.append(.init(code: "container_children_missing", file: file.lastPathComponent, detail: "children must not be empty"))
                continue
            }
            containerChildren.formUnion(children)
            attachmentCount += validateAttachments(in: object, directory: directory, file: file, issues: &issues)
        }

        for resultID in resultIDs where !containerChildren.contains(resultID) {
            issues.append(.init(code: "result_container_unlinked", file: nil, detail: resultID))
        }
        for child in containerChildren where !resultIDs.contains(child) {
            issues.append(.init(code: "container_child_missing", file: nil, detail: child))
        }

        validateServiceFile(named: "executor.json", in: files, issues: &issues)
        validateServiceFile(named: "categories.json", in: files, issues: &issues)

        return AllureValidationSummary(
            resultCount: resultFiles.count,
            containerCount: containerFiles.count,
            attachmentCount: attachmentCount,
            issues: issues
        )
    }

    /// Reads one JSON file and requires an object at its root.
    ///
    /// - Parameters:
    ///   - file: JSON file to decode.
    ///   - issues: Accumulator receiving a stable issue code on failure.
    /// - Returns: Decoded object, or `nil` after recording the failure.
    private func jsonObject(
        at file: URL,
        issues: inout [AllureValidationIssue]
    ) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: file)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                issues.append(.init(code: "json_root_invalid", file: file.lastPathComponent, detail: "Expected object"))
                return nil
            }
            return object
        } catch {
            issues.append(.init(code: "json_invalid", file: file.lastPathComponent, detail: error.localizedDescription))
            return nil
        }
    }

    /// Extracts a required non-empty string field from an Allure object.
    ///
    /// - Parameters:
    ///   - key: Required JSON key.
    ///   - object: Decoded Allure object.
    ///   - file: Source file used in diagnostics.
    ///   - issues: Accumulator receiving missing-field issues.
    /// - Returns: The field value, or `nil` when it is absent or empty.
    private func requireString(
        _ key: String,
        in object: [String: Any],
        file: URL,
        issues: inout [AllureValidationIssue]
    ) -> String? {
        guard let value = object[key] as? String, !value.isEmpty else {
            issues.append(.init(code: "required_field_missing", file: file.lastPathComponent, detail: key))
            return nil
        }
        return value
    }

    /// Ensures the result stop timestamp is not earlier than its start timestamp.
    ///
    /// - Parameters:
    ///   - object: Decoded result object.
    ///   - file: Source result file.
    ///   - issues: Accumulator receiving timeline issues.
    private func validateTimeline(
        _ object: [String: Any],
        file: URL,
        issues: inout [AllureValidationIssue]
    ) {
        guard let start = object["start"] as? NSNumber,
              let stop = object["stop"] as? NSNumber,
              stop.int64Value >= start.int64Value else {
            issues.append(.init(code: "timeline_invalid", file: file.lastPathComponent, detail: "stop must be >= start"))
            return
        }
    }

    /// Verifies that Allure identity fields contain lowercase SHA-256 values.
    ///
    /// - Parameters:
    ///   - object: Decoded result object.
    ///   - file: Source result file.
    ///   - issues: Accumulator receiving identity issues.
    private func validateIdentity(
        _ object: [String: Any],
        file: URL,
        issues: inout [AllureValidationIssue]
    ) {
        for key in ["testCaseId", "historyId"] {
            guard let value = requireString(key, in: object, file: file, issues: &issues) else { continue }
            if value.range(of: "^[a-f0-9]{64}$", options: .regularExpression) == nil {
                issues.append(.init(
                    code: "identity_invalid",
                    file: file.lastPathComponent,
                    detail: "\(key) must be a lowercase SHA-256 value"
                ))
            }
        }
    }

    /// Verifies attachment sources recursively and counts every attachment reference.
    ///
    /// - Parameters:
    ///   - object: Result, container, fixture, or step object.
    ///   - directory: Directory expected to contain attachment files.
    ///   - file: Source JSON file used in diagnostics.
    ///   - issues: Accumulator receiving attachment issues.
    /// - Returns: Number of attachment references discovered in the object tree.
    private func validateAttachments(
        in object: [String: Any],
        directory: URL,
        file: URL,
        issues: inout [AllureValidationIssue]
    ) -> Int {
        var attachments = object["attachments"] as? [[String: Any]] ?? []
        for key in ["steps", "befores", "afters"] {
            for child in object[key] as? [[String: Any]] ?? [] {
                attachments.append(contentsOf: collectAttachments(from: child))
            }
        }
        for attachment in attachments {
            guard let source = attachment["source"] as? String, !source.isEmpty else {
                issues.append(.init(code: "attachment_source_missing", file: file.lastPathComponent, detail: "Attachment has no source"))
                continue
            }
            if !fileManager.fileExists(atPath: directory.appendingPathComponent(source).path) {
                issues.append(.init(code: "attachment_file_missing", file: file.lastPathComponent, detail: source))
            }
        }
        return attachments.count
    }

    /// Flattens attachment references from a nested Allure step tree.
    ///
    /// - Parameter object: Step-like JSON object.
    /// - Returns: Attachments owned by the object and all descendant steps.
    private func collectAttachments(from object: [String: Any]) -> [[String: Any]] {
        var result = object["attachments"] as? [[String: Any]] ?? []
        for step in object["steps"] as? [[String: Any]] ?? [] {
            result.append(contentsOf: collectAttachments(from: step))
        }
        return result
    }

    /// Requires a named Allure service file containing syntactically valid JSON.
    ///
    /// - Parameters:
    ///   - name: Expected service filename.
    ///   - files: Files enumerated from the result directory.
    ///   - issues: Accumulator receiving missing or malformed file issues.
    private func validateServiceFile(
        named name: String,
        in files: [URL],
        issues: inout [AllureValidationIssue]
    ) {
        guard let file = files.first(where: { $0.lastPathComponent == name }) else {
            issues.append(.init(code: "service_file_missing", file: name, detail: name))
            return
        }
        do {
            _ = try JSONSerialization.jsonObject(with: Data(contentsOf: file))
        } catch {
            issues.append(.init(code: "service_file_invalid", file: name, detail: error.localizedDescription))
        }
    }
}
