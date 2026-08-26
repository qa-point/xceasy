import XCTest

// MARK: - AllureFormatter

/// Formatter for Allure test report data.
///
/// Provides methods for formatting test case paths, names, and test suite names
/// for Allure reporting.
internal class AllureFormatter {

    // MARK: - Public Methods

    /// Formats the test case path for Allure reporting.
    /// - Parameter testCase: The XCTest instance to format.
    /// - Returns: A formatted string representing the test case path.
    func formatTestCasePath(testCase: XCTestCase) -> String {
        let formattedName = testCase.name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: " ", with: "/")
        return formattedName + "()"
    }

    /// Formats the test case name for Allure reporting.
    /// - Parameter testCase: The XCTest instance to format.
    /// - Returns: A formatted string representing the test case name.
    func formatTestCaseName(testCase: XCTestCase) -> String {
        let formattedName = testCase.name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: " ", with: "/")
            .split(separator: "/")
            .last ?? ""
        return String(formattedName) + "()"
    }

    /// Replaces a generated parameter case method with its canonical scenario for Allure identity.
    ///
    /// - Parameters:
    ///   - fullName: Concrete XCTest full name retained in the result.
    ///   - scenario: Optional source scenario name shared by generated variants.
    /// - Returns: Identity-only full name used for stable `testCaseId` calculation.
    func canonicalIdentityPath(fullName: String, scenario: String?) -> String {
        guard let scenario, let slash = fullName.lastIndex(of: "/") else { return fullName }
        return String(fullName[...slash]) + scenario + "()"
    }

    /// Formats the test suite name for Allure reporting.
    /// - Parameter testSuite: The XCTestSuite instance to format.
    /// - Returns: A formatted string representing the test suite name.
    func formatTestSuiteName(testSuite: XCTestSuite) -> String {
        return testSuite.name.contains(".xctest")
            ? String(testSuite.name.split(separator: ".").first ?? "")
            : ""
    }
}
