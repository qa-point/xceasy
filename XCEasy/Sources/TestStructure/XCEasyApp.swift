import XCTest

// MARK: - XCEasyApp

/// Base class for UI test applications.
///
/// Provides common functionality for launching, closing, and managing the application under test.
open class XCEasyApp: XCTestCase {

    // MARK: - Properties

    /// The XCUIApplication instance for the current test, retrieved from shared context.
    var app: XCUIApplication? { XCEasyTestContext.shared.app }

    // MARK: - Public Methods

    /// Launches the application with the current configuration.
    ///
    /// This method retrieves the application bundle identifier from XCEasyConfig
    /// and launches the application, logging the action.
    public func launchApplication() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "launch_application_title")

        operationStep(code: "app.launch", title: stepTitle) {
            XCEasyTestLogger.shared.log("Launch application")
            guard let app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot launch application because the test context has no app"
                ))
                return
            }
            app.launch()
        }
    }

    /// Terminates the application.
    ///
    /// This method terminates the running application instance and logs the action.
    public func closeApplication() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "close_application_title")

        operationStep(code: "app.terminate", title: stepTitle) {
            XCEasyTestLogger.shared.log("Close application")
            guard let app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot terminate application because the test context has no app"
                ))
                return
            }
            app.terminate()
        }
    }

    /// Reopens the application with a brief delay.
    ///
    /// This method performs a full application restart: closes the app, waits 1 second,
    /// then launches it again with additional delays before and after for stability.
    public func reopenApplication() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "reopen_application_title")

        operationStep(code: "app.reopen", title: stepTitle) {
            closeApplication()
            launchApplication()
        }
    }

    /// Prints the element tree debug description to console.
    ///
    /// Useful for debugging and understanding the current UI hierarchy.
    public func printDebugTree() {
        guard let app else {
            recordFrameworkFailure(XCEasyFrameworkError(
                code: "context.application_unavailable",
                safeDescription: "Cannot print UI tree because the test context has no app"
            ))
            return
        }
        print(app.debugDescription)
    }
}
