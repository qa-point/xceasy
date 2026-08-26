import Foundation

/// Class responsible for formatting log messages.
internal class LogFormatter {

    /// Retrieves the framework name from the bundle.
    /// - Returns: The framework name.
    static func getFrameworkName() -> String {
        let bundle = Bundle(for: LogFormatter.self)
        if let frameworkName = bundle.infoDictionary?["CFBundleName"] as? String {
            return frameworkName
        } else {
            return "Unknown"
        }
    }

    /// Formats the current date as a timestamp string.
    /// - Parameter date: The date to format.
    /// - Returns: The formatted timestamp string.
    static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return formatter.string(from: date)
    }

    /// Formats a log message with a timestamp and framework name.
    /// - Parameter message: The message to format.
    /// - Returns: The formatted log message.
    static func formatMessage(_ message: String) -> String {
        let timestamp = formatTimestamp(Date())
        let frameworkName = getFrameworkName()
        let logMessage = "[ \(timestamp) ] [ \(frameworkName) ]  \(message)"
        return logMessage
    }

    /// Formats a log message with color based on the log level.
    /// - Parameters:
    ///   - message: The message to format.
    ///   - level: The log level.
    /// - Returns: The formatted log message with color.
    static func formatColorMessage(_ message: String, level: LogLevel) -> String {
        let timestampLabel = "[ \(formatTimestamp(Date())) ]"
        let frameworkLabel = "[ \(getFrameworkName()) ]"
        let logMessage = "\(timestampLabel) \(frameworkLabel) \(message)"
        return "\(level.properties.color)\(logMessage)\(level.properties.resetColor)"
    }
}
