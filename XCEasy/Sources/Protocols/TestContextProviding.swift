import XCTest

// MARK: - TestContextProviding

/// Protocol defining the interface for test context management.
///
/// Conforming types are responsible for providing and managing
/// the test execution context, including the application instance,
/// test identifiers, and Allure-related metadata.
public protocol TestContextProviding {

    // MARK: - Properties

    /// The XCUIApplication instance for the current test.
    var app: XCUIApplication? { get set }

    /// The unique test identifier.
    var testId: String? { get set }

    /// The display name for the test.
    var displayName: String? { get set }

    /// The test result information.
    var testResult: TestResult? { get set }

    /// The list of labels associated with the test.
    var labels: [Label] { get set }

    /// The list of links associated with the test.
    var links: [AllureLinkRecord] { get set }

    /// The description of the test.
    var description: String? { get set }

    /// The test suite name.
    var testSuite: String? { get set }

    /// The stack of step results.
    var stepStack: [StepResult] { get set }

    /// The screenshot attachment for the test.
    var screenshot: ScreenshotAttachment? { get set }

    // MARK: - Methods

    /// Adds a label to the current test context.
    /// - Parameter label: The label to add.
    func addLabel(_ label: Label)

    /// Checks if a label with the specified name exists.
    /// - Parameter name: The name of the label to check.
    /// - Returns: `true` if the label exists, `false` otherwise.
    func isLabelExists(_ name: String) -> Bool

    /// Adds a link to the current test context.
    /// - Parameter link: The link to add.
    func addLink(_ link: AllureLinkRecord)

    /// Clears all test-related storage except the application instance.
    func clearTestStorages()

    /// Clears the application instance.
    func clearApp()

    /// Sets up the application instance based on the current configuration.
    func setApp()

    /// Pushes a step result onto the step stack.
    /// - Parameter step: The step result to push.
    func pushStep(_ step: StepResult)

    /// Pops the last step result from the step stack.
    /// - Returns: The popped step result, or `nil` if the stack is empty.
    func popStep() -> StepResult?
}
