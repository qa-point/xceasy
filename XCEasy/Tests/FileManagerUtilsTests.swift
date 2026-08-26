import XCTest
@testable import XCEasy

final class FileManagerUtilsTests: XCTestCase {
    func testDefaultReportDirectoryUsesAllureResults() {
        let root = URL(fileURLWithPath: "/tmp/project")

        let result = FileManagerUtils.shared.resolveReportDirectory(
            environment: [:],
            currentDirectory: root
        )

        XCTAssertEqual(result.path, "/tmp/project/allure-results")
    }

    func testAbsoluteEnvironmentReportDirectoryWins() {
        let result = FileManagerUtils.shared.resolveReportDirectory(
            environment: ["XC_EASY_REPORT_DIR": "/tmp/custom-allure"],
            currentDirectory: URL(fileURLWithPath: "/tmp/project")
        )

        XCTAssertEqual(result.path, "/tmp/custom-allure")
    }

    func testRelativeEnvironmentReportDirectoryIsResolvedAgainstProjectRoot() {
        let result = FileManagerUtils.shared.resolveReportDirectory(
            environment: ["XC_EASY_REPORT_DIR": "artifacts/allure-results"],
            currentDirectory: URL(fileURLWithPath: "/tmp/project")
        )

        XCTAssertEqual(result.path, "/tmp/project/artifacts/allure-results")
    }

    func testUnexpandedXcodeVariableFallsBackSafely() {
        let result = FileManagerUtils.shared.resolveReportDirectory(
            environment: ["XC_EASY_REPORT_DIR": "$(PROJECT_DIR)/allure-results"],
            currentDirectory: URL(fileURLWithPath: "/tmp/project")
        )

        XCTAssertEqual(result.path, "/tmp/project/allure-results")
    }
}
