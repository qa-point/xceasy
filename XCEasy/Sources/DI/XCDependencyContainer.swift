import Foundation

// MARK: - XCDependencyContainer

/// Container for managing framework dependencies.
///
/// This class provides a centralized way to access all dependencies
/// used throughout the XCEasy framework. It is designed to be thread-safe
/// and support parallel test execution across multiple devices.
///
/// ## Thread Safety
///
/// - `testContext`: Uses thread-local storage to ensure each test thread
///   has its own isolated context. This allows parallel test execution
///   without interference between tests.
/// - `localizationManager`: Shared across all threads (localization is global).
/// - `config`: Configuration is static and global, accessed directly via `XCEasyConfig`.
///
/// ## Usage
///
/// ```swift
/// // Access test context
/// let context = XCDependencyContainer.shared.testContext
///
/// // Access configuration directly (it's static)
/// let timeout = XCEasyConfig.findTimeout
///
/// // Override test context for testing
/// XCDependencyContainer.shared.testContext = CustomTestContext()
/// ```
public class XCDependencyContainer {

    // MARK: - Properties

    /// Shared instance of the dependency container.
    public static let shared = XCDependencyContainer()

    /// Thread-local storage for test context.
    /// Each thread gets its own isolated context instance.
    private let testContextStorage = ThreadLocal<TestContextProviding>()

    /// The localization manager.
    /// Shared across all threads as localization is global.
    public var localizationManager: LocalizationManaging = LocalizationManager.shared

    /// The test context provider.
    ///
    /// This property uses thread-local storage to ensure each test thread
    /// has its own isolated context. When getting or setting this property:
    /// - If a thread-local value exists, it is returned
    /// - Otherwise, the default shared context is used
    public var testContext: TestContextProviding {
        get {
            return testContextStorage.value ?? XCEasyTestContext.shared
        }
        set {
            testContextStorage.value = newValue
        }
    }

    // MARK: - Initialization

    /// Private initializer to prevent direct instantiation.
    ///
    /// Use `shared` to access the dependency container.
    private init() {}

    // MARK: - Public Methods

    /// Resets the thread-local test context to the default implementation.
    ///
    /// This method should be called between tests to ensure clean state.
    /// Note: This only resets the test context for the current thread.
    public func reset() {
        testContextStorage.value = nil
    }

    /// Resets all dependencies to their default implementations.
    ///
    /// This method resets the thread-local test context and can be used
    /// to restore default state after custom dependency injection.
    ///
    /// - Parameter resetLocalization: Whether to reset localization (default: false).
    public func resetAll(resetLocalization: Bool = false) {
        testContextStorage.value = nil

        if resetLocalization {
            localizationManager = LocalizationManager.shared
        }
    }
}
