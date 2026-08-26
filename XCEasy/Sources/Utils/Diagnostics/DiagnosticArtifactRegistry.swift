import CryptoKit
import Foundation

internal struct DiagnosticArtifactRecord: Codable, Equatable {
    let id: String
    let path: String
    let kind: String
    let mimeType: String
    let bytes: Int
    let sha256: String
    let producerEventId: String?
    let truncated: Bool
    let privacy: DiagnosticPrivacy
}

internal final class DiagnosticArtifactRegistry {
    private let executionId: String
    private let directory: URL
    private let lock = NSLock()
    private var recordsByPath: [String: DiagnosticArtifactRecord] = [:]

    /// Creates an execution-scoped, synchronized artifact index.
    ///
    /// - Parameters:
    ///   - executionId: Unique test-attempt identifier used in generated filenames.
    ///   - directory: Directory that owns both artifacts and their manifest.
    init(executionId: String, directory: URL) {
        self.executionId = executionId
        self.directory = directory
    }

    /// Writes an artifact atomically and registers its integrity metadata.
    ///
    /// - Parameters:
    ///   - data: Artifact bytes before optional truncation.
    ///   - fileExtension: Filename extension without a leading period.
    ///   - kind: Stable artifact category consumed by diagnostic tools.
    ///   - mimeType: MIME type written to the manifest and Allure reference.
    ///   - producerEventId: Canonical event that produced the artifact.
    ///   - byteLimit: Optional maximum persisted byte count.
    /// - Returns: Reference suitable for a canonical diagnostic event.
    /// - Throws: A filesystem error while persisting the artifact.
    func write(
        data: Data,
        extension fileExtension: String,
        kind: String,
        mimeType: String,
        producerEventId: String?,
        byteLimit: Int? = nil
    ) throws -> DiagnosticAttachmentReference {
        let normalizedLimit = byteLimit.map { max(0, $0) }
        let truncated = normalizedLimit.map { data.count > $0 } ?? false
        let persistedData = normalizedLimit.map { Data(data.prefix($0)) } ?? data
        let id = UUID().uuidString.lowercased()
        let filename = "\(executionId)_\(id).\(fileExtension)"
        let url = directory.appendingPathComponent(filename)
        try AtomicFileWriter.write(persistedData, to: url)
        register(
            path: filename,
            data: persistedData,
            kind: kind,
            mimeType: mimeType,
            producerEventId: producerEventId,
            truncated: truncated,
            id: id
        )
        return DiagnosticAttachmentReference(
            id: id,
            path: filename,
            mimeType: mimeType,
            kind: kind,
            truncated: truncated
        )
    }

    /// Adds an existing persisted file to the integrity manifest.
    ///
    /// - Parameters:
    ///   - url: Existing artifact URL.
    ///   - kind: Stable artifact category.
    ///   - mimeType: Artifact MIME type.
    ///   - producerEventId: Optional canonical event that produced the file.
    /// - Throws: An error when the file cannot be read.
    func registerExisting(
        url: URL,
        kind: String,
        mimeType: String,
        producerEventId: String? = nil
    ) throws {
        let data = try Data(contentsOf: url)
        register(
            path: url.lastPathComponent,
            data: data,
            kind: kind,
            mimeType: mimeType,
            producerEventId: producerEventId,
            truncated: false,
            id: UUID().uuidString.lowercased()
        )
    }

    /// Returns a deterministic snapshot of registered artifacts.
    ///
    /// - Returns: Records sorted by relative artifact path.
    func records() -> [DiagnosticArtifactRecord] {
        lock.lock()
        defer { lock.unlock() }
        return recordsByPath.values.sorted { $0.path < $1.path }
    }

    /// Hashes and indexes artifact metadata under the registry lock.
    ///
    /// - Parameters:
    ///   - path: Artifact path relative to the bundle directory.
    ///   - data: Exact persisted bytes used for size and digest calculation.
    ///   - kind: Stable artifact category.
    ///   - mimeType: Artifact MIME type.
    ///   - producerEventId: Optional producing event identifier.
    ///   - truncated: Whether a configured byte limit shortened the content.
    ///   - id: Unique artifact identifier.
    private func register(
        path: String,
        data: Data,
        kind: String,
        mimeType: String,
        producerEventId: String?,
        truncated: Bool,
        id: String
    ) {
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let record = DiagnosticArtifactRecord(
            id: id,
            path: path,
            kind: kind,
            mimeType: mimeType,
            bytes: data.count,
            sha256: digest,
            producerEventId: producerEventId,
            truncated: truncated,
            privacy: .standard
        )
        lock.lock()
        recordsByPath[path] = record
        lock.unlock()
    }
}
