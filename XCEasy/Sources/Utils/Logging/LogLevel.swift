import Foundation
import os.log

/// Enum representing different log levels.
enum LogLevel {
    case info, warning, error, debug, def

    /// Properties associated with each log level.
    var properties: LogLevelItem {
        switch self {
        case .info:
            return LogLevelItem(label: "INFO", color: "\u{001B}[92m", osLogType: .info)
        case .warning:
            return LogLevelItem(label: "WARNING", color: "\u{001B}[93m", osLogType: .error)
        case .error:
            return LogLevelItem(label: "ERROR", color: "\u{001B}[91m", osLogType: .fault)
        case .debug:
            return LogLevelItem(label: "DEBUG", color: "\u{001B}[94m", osLogType: .debug)
        case .def:
            return LogLevelItem(label: "DEFAULT", color: "", osLogType: .default)
        }
    }
}

/// Struct representing log level items with associated properties.
struct LogLevelItem {
    let label: String
    let color: String
    let osLogType: OSLogType
    let resetColor: String = "\u{001B}[0m"
}
