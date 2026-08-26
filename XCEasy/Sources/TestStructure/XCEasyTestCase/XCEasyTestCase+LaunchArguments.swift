import Foundation

// MARK: - Launch Configuration

extension XCEasyTestCase {

    // MARK: - Internal Methods

    /// Sets launch arguments from LaunchArgumentsManager to the application.
    internal func setLaunchArguments() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "set_launch_arguments_title")
        step(stepTitle) {
            guard let app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot configure launch arguments because the test context has no app"
                ))
                return
            }
            let args = LaunchArgumentsManager.values
            XCEasyTestLogger.shared.log("Launch Arguments: \(args)")
            let currentArgs = app.launchArguments
            app.launchArguments = currentArgs + args
        }
    }

    /// Sets launch environment variables from LaunchEnvironmentManager to the application.
    internal func setLaunchEnvironment() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "set_launch_environment_title")
        step(stepTitle) {
            guard let app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot configure launch environment because the test context has no app"
                ))
                return
            }
            let vars = LaunchEnvironmentManager.values
            XCEasyTestLogger.shared.log("Launch Environment: \(vars)")
            let currentEnv = app.launchEnvironment
            app.launchEnvironment = currentEnv.merging(vars) { _, new in new }
        }
    }
}
