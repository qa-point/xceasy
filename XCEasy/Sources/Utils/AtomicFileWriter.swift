import Foundation

internal enum AtomicFileWriter {
    /// Persists data atomically after creating the destination directory.
    ///
    /// - Parameters:
    ///   - data: Complete bytes to persist.
    ///   - url: Final file URL; its parent directories may not exist yet.
    /// - Throws: A directory-creation or atomic-write error.
    static func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }
}
