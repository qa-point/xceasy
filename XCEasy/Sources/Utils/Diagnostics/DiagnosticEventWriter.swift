import Foundation

internal final class DiagnosticEventWriter {
    private let url: URL
    private let encoder: JSONEncoder
    private let lock = NSLock()

    /// Creates an execution event stream with deterministic JSON encoding.
    ///
    /// - Parameters:
    ///   - testId: Unique execution identifier used in the filename.
    ///   - directory: Directory that owns the JSONL stream.
    /// - Throws: A filesystem error when the directory or stream cannot be created.
    init(testId: String, directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appendingPathComponent("\(testId)_events.jsonl")
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
    }

    /// Appends exactly one JSON object and newline under an exclusive writer lock.
    ///
    /// - Parameter event: Canonical event to encode.
    /// - Throws: An encoding or file-handle error.
    func append(_ event: DiagnosticEvent) throws {
        var data = try encoder.encode(event)
        data.append(0x0A)
        lock.lock()
        defer { lock.unlock() }
        let handle = try FileHandle(forWritingTo: url)
        defer { handle.closeFile() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    /// Returns the immutable URL of this execution's event stream.
    ///
    /// - Returns: JSONL event file URL.
    func fileURL() -> URL { url }
}
