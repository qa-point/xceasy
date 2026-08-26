import Foundation

internal enum SensitiveDataRedactor {
    private static let patterns = [
        #"(?i)(authorization\s*[:=]\s*)(?:bearer\s+)?([^\s,;]+)"#,
        #"(?i)(bearer\s+)([A-Za-z0-9._~+\-/=]+)"#,
        #"(?i)((?:password|passwd|token|secret|api[_-]?key)\s*[:=]\s*)([^\s,;]+)"#
    ]
    private static let compiledPatterns = compilePatterns(patterns)

    /// Compiles a privacy ruleset and fails closed when any expression is invalid.
    ///
    /// - Parameter patterns: Regular-expression patterns to compile.
    /// - Returns: Compiled expressions and a validity flag for the complete ruleset.
    static func compilePatterns(
        _ patterns: [String]
    ) -> (expressions: [NSRegularExpression], isValid: Bool) {
        var expressions: [NSRegularExpression] = []
        for pattern in patterns {
            do {
                expressions.append(try NSRegularExpression(pattern: pattern))
            } catch {
                return ([], false)
            }
        }
        return (expressions, true)
    }

    /// Redacts recognized credential forms before text reaches a log or report sink.
    ///
    /// The method fails closed when the built-in privacy ruleset cannot be compiled.
    ///
    /// - Parameter value: Potentially sensitive text.
    /// - Returns: Redacted text safe for framework-controlled sinks.
    static func redact(_ value: String) -> String {
        guard compiledPatterns.isValid else { return "<redacted:privacy-ruleset-error>" }
        return compiledPatterns.expressions.reduce(value) { result, regex in
            let range = NSRange(result.startIndex..., in: result)
            return regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1<redacted>")
        }
    }
}
