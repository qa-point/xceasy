import Foundation
import os.log

/// Class responsible for logging messages using the OSLog framework.
internal class OSLogger {
    private var osLogConfig: OSLog

    /// Initializes the OSLogger with a given subsystem and category.
    /// - Parameters:
    ///   - subsystem: The subsystem identifier.
    ///   - category: The category identifier.
    init(subsystem: String, category: String) {
        self.osLogConfig = OSLog(subsystem: subsystem, category: category)
    }

    /// Logs a message with a specified log level.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level.
    func log(_ message: String, level: LogLevel = .info) {
        let logMessage = LogFormatter.formatMessage(message)
        os_log("%{public}@", log: osLogConfig, type: level.properties.osLogType, logMessage)
    }

    /// Emits an informational message through the configured OSLog category.
    ///
    /// - Parameter message: Human-readable text formatted by ``LogFormatter``.
    func info(_ message: String) {
        let logMessage = LogFormatter.formatMessage(message)
        os_log("%{public}@", log: osLogConfig, type: .info, logMessage)
    }

    /// Emits an error message through the configured OSLog category.
    ///
    /// - Parameter message: Human-readable text formatted by ``LogFormatter``.
    func error(_ message: String) {
        let logMessage = LogFormatter.formatMessage(message)
        os_log("%{public}@", log: osLogConfig, type: .error, logMessage)
    }

    /// Emits a debug message through the configured OSLog category.
    ///
    /// - Parameter message: Human-readable text formatted by ``LogFormatter``.
    func debug(_ message: String) {
        let logMessage = LogFormatter.formatMessage(message)
        os_log("%{public}@", log: osLogConfig, type: .debug, logMessage)
    }
}
