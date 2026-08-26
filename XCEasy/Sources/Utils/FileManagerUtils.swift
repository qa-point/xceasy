import Foundation

// MARK: - FileManagerUtils

/// Utility class for file management operations.
///
/// Provides methods for creating directories, finding project roots,
/// and saving test results.
class FileManagerUtils {

    // MARK: - Properties

    /// Shared instance of the file manager utility.
    static let shared = FileManagerUtils()

    // MARK: - Initialization

    /// Creates the shared filesystem facade.
    private init() {}

    // MARK: - Public Methods

    /// Creates a directory for storing test results.
    ///
    /// - Parameter url: The URL of the directory for storing test results.
    func createDirectory(at url: URL) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(atPath: url.path)
        }

        try fileManager.createDirectory(
            atPath: url.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    /// Finds the root directory of the project.
    ///
    /// - Returns: The URL of the project's root directory.
    func findProjectRoot() -> URL {
        var currentPath = FileManager.default.currentDirectoryPath
        while currentPath != "/" {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: currentPath)
                if contents.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }) {
                    return URL(fileURLWithPath: currentPath)
                }
            } catch {
                return fallbackDirectory()
            }
            currentPath = (currentPath as NSString).deletingLastPathComponent
        }
        return fallbackDirectory()
    }

    /// Resolves a writable runner-local fallback without relying on a workspace path.
    ///
    /// - Returns: User cache directory when available, otherwise the process temporary directory.
    private func fallbackDirectory() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
    }

    /// Saves the TestResult object to a file.
    ///
    /// - Parameters:
    ///   - testResult: The TestResult object to save.
    ///   - directory: The directory where the file should be saved.
    func saveTestResult(_ testResult: TestResult, to directory: URL) throws {
        let fileName = "\(testResult.uuid ?? "unknown")-result.json"
        let fileURL = directory.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(testResult)
        try AtomicFileWriter.write(data, to: fileURL)
    }

    /// Saves Allure executor metadata to executor.json.
    func saveExecutor(_ executor: Executor, to directory: URL) throws {
        let fileURL = directory.appendingPathComponent("executor.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(executor)
        try AtomicFileWriter.write(data, to: fileURL)
    }

    /// Saves Allure environment properties file.
    func saveEnvironmentProperties(_ properties: [String: String], to directory: URL) throws {
        let fileURL = directory.appendingPathComponent("environment.properties")
        let content = properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: String.newLine)
        let data = content.data(using: .utf8) ?? Data()
        try AtomicFileWriter.write(data, to: fileURL)
    }

    /// Saves Allure test result container (`*-container.json`).
    func saveTestResultContainer(_ container: TestResultContainer, to directory: URL) throws {
        let fileName = "\(container.uuid ?? UUID().uuidString)-container.json"
        let fileURL = directory.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(container)
        try AtomicFileWriter.write(data, to: fileURL)
    }

    /// Saves default Allure categories to categories.json.
    func saveCategories(_ categories: [AllureCategory], to directory: URL) throws {
        let fileURL = directory.appendingPathComponent("categories.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(categories)
        try AtomicFileWriter.write(data, to: fileURL)
    }

    /// Resolves the Allure output directory before the test bundle starts.
    ///
    /// - Returns: URL of the default report directory.
    func getDefaultReportDirectory() -> URL {
        resolveReportDirectory(
            environment: ProcessInfo.processInfo.environment,
            currentDirectory: findProjectRoot()
        )
    }

    /// Resolves the runner-local Allure output from environment and a known base directory.
    ///
    /// - Parameters:
    ///   - environment: Process environment containing optional `XC_EASY_REPORT_DIR`.
    ///   - currentDirectory: Base used for relative configured paths and the default directory.
    /// - Returns: Standardized absolute output URL; shell substitutions are rejected.
    func resolveReportDirectory(
        environment: [String: String],
        currentDirectory: URL
    ) -> URL {
        if let configuredPath = environment["XC_EASY_REPORT_DIR"],
           !configuredPath.isEmpty,
           !configuredPath.contains("$(") {
            let expanded = NSString(string: configuredPath).expandingTildeInPath
            if NSString(string: expanded).isAbsolutePath {
                return URL(fileURLWithPath: expanded).standardizedFileURL
            }
            return currentDirectory.appendingPathComponent(expanded).standardizedFileURL
        }
        return currentDirectory.appendingPathComponent("allure-results").standardizedFileURL
    }
}
