import XCTest
import Foundation

// MARK: - XCEasyTestCase

/// Base test case class for XCEasy framework.
///
/// Provides common setup and teardown functionality for UI tests,
/// including configuration, launch arguments, and application lifecycle management.
open class XCEasyTestCase: XCEasyApp {

    // MARK: - Configuration Methods

    /// Configures the test case with XCEasy and Allure settings.
    open func configuration() {
        defer {
            XCEasyTestLogger.shared.logDelimeter(delimeter: .asterisk)
        }
        XCEasyTestLogger.shared.startLogBlock(
            "Test Configuration",
            delimeter: .asterisk
        )
        XCEasyConfig.logConfig()
        XCEasyAllureConfig.logConfig()
    }

    // MARK: - Lifecycle Methods

    /// Called before each test method.
    open func beforeTest() {
        defer {
            XCEasyTestLogger.shared.logDelimeter(delimeter: .asterisk)
        }
        XCEasyTestLogger.shared.startLogBlock(
            "Before Test",
            delimeter: .asterisk
        )
    }

    /// Called after each test method.
    open func afterTest() {
        defer {
            XCEasyTestLogger.shared.logDelimeter(delimeter: .asterisk)
        }
        XCEasyTestLogger.shared.startLogBlock(
            "After Test",
            delimeter: .asterisk
        )
    }

    // MARK: - XCTestCase Overrides

    /// Invokes XCTest's class-level setup hook.
    ///
    /// Override only when suite-wide initialization is unavoidable; per-test state belongs in
    /// ``configuration()`` or ``beforeTest()`` so parallel executions remain isolated.
    open override class func setUp() {
        super.setUp()
    }

    /// Creates the execution-scoped configuration, application, setup step, and lifecycle state.
    ///
    /// - Throws: An error propagated by an overriding XCTest setup implementation.
    open override func setUpWithError() throws {
        XCEasyConfig.beginExecution()
        LaunchArgumentsManager.beginExecution()
        LaunchEnvironmentManager.beginExecution()
        _ = XCEasyTestContext.shared.transitionLifecycle(to: .settingUp)
        step("Setup") {
            configuration()
            XCEasyTestContext.shared.setApp()
            continueAfterFailure = false
            setLaunchArguments()
            setLaunchEnvironment()
            launchApplication()
            beforeTest()
        }
        _ = XCEasyTestContext.shared.transitionLifecycle(to: .running)
    }

    /// Runs user teardown, terminates the application, and releases execution-scoped state.
    ///
    /// - Throws: An error propagated by an overriding XCTest teardown implementation.
    open override func tearDownWithError() throws {
        defer {
            LaunchEnvironmentManager.endExecution()
            LaunchArgumentsManager.endExecution()
            XCEasyConfig.endExecution()
        }
        _ = XCEasyTestContext.shared.transitionLifecycle(to: .tearingDown)
        step("Teardown") {
            afterTest()
            closeApplication()
            XCEasyTestContext.shared.clearApp()
        }
    }
}
