import Foundation

/// Class responsible for logging messages to a file and optionally to the console.
internal class XCEasyLogger {
    private var logFilePath: String?
    private var logDirectory: URL?
    private var fileHandle: FileHandle?
    private let fileLock = NSLock()
    private var testId: String
    private var osLogger: OSLogger

    /// Initializes the XCEasyLogger with a given test ID.
    /// - Parameter testId: The test ID.
    init(testId: String, logDir: URL? = nil) {
        self.testId = testId
        logDirectory = logDir ?? FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        osLogger = OSLogger(subsystem: "com.qa-point.xceasy.log", category: "Log-\(testId)")
        createLogFile()
    }

    // MARK: - Private

    /// Creates a log file for the current test session.
    private func createLogFile() {
        guard let logDirectory = logDirectory else { return }
        let frameworkName = LogFormatter.getFrameworkName().lowercased()
        let fileName = "\(testId)_\(frameworkName)_log.log"
        let resolvedLogFilePath = logDirectory.appendingPathComponent(fileName).path
        logFilePath = resolvedLogFilePath

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: resolvedLogFilePath) {
            if fileManager.createFile(atPath: resolvedLogFilePath, contents: nil, attributes: nil) {
                fileHandle = FileHandle(forWritingAtPath: resolvedLogFilePath)
                if fileHandle == nil {
                    log("Failed to open log file at: \(resolvedLogFilePath)", level: .error)
                }
                log("Log file created: \(resolvedLogFilePath)", level: .debug)
            } else {
                log("Failed to create log file at: \(resolvedLogFilePath)", level: .error)
            }
        } else {
            fileHandle = FileHandle(forWritingAtPath: resolvedLogFilePath)
            if fileHandle == nil {
                log("Failed to open existing log file at: \(resolvedLogFilePath)", level: .error)
            } else {
                log("Existing log file opened: \(resolvedLogFilePath)", level: .debug)
            }
        }
    }

    /// Writes a message to the log file.
    /// - Parameter message: The message to write.
    private func writeToFile(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        fileLock.lock()
        defer { fileLock.unlock() }
        guard let fileHandle else { return }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
    }

    // MARK: - Public

    /// Logs a message with a specified log level and optionally prints it to the console.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level.
    ///   - printLog: Whether to print the log to the console.
    func log(
        _ message: String,
        level: LogLevel = .info,
        printLog: Bool = XCEasyConfig.printLogToConsole
    ) {
        let safeMessage = SensitiveDataRedactor.redact(message)
        let logMessage = LogFormatter.formatMessage(safeMessage)
        if printLog {
            osLogger.log(logMessage, level: level)
        }
        // Persistent artifacts intentionally contain no ANSI control sequences.
        writeToFile(logMessage + String.newLine)
    }

    /// Closes the log file handle.
    func close() {
        fileLock.lock()
        defer { fileLock.unlock() }
        fileHandle?.closeFile()
        fileHandle = nil
    }

    /// Returns current log file URL if available.
    func getLogFileURL() -> URL? {
        guard let logFilePath else { return nil }
        return URL(fileURLWithPath: logFilePath)
    }
}
