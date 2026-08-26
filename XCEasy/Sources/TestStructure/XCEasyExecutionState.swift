import Foundation
import XCTest

/// Lock-protected mutable state owned by exactly one XCTest execution.
///
/// A reference state lets structured child tasks retain the same execution identity when Swift
/// concurrency resumes them on another thread. Every mutable field is accessed through the lock.
internal final class XCEasyExecutionState: @unchecked Sendable {
    private let lock = NSRecursiveLock()

    var testId: String?
    var app: XCUIApplication?
    var displayName: String?
    var testResult: TestResult?
    var labels: [Label] = []
    var links: [AllureLinkRecord] = []
    var resultDescription: String?
    var testSuite: String?
    var stepStack: [StepResult] = []
    var activeStepDepth = 0
    var screenshot: ScreenshotAttachment?
    var deferredFailures: [DeferredFailure] = []
    var executionId: String?
    var canonicalIdentityFullName: String?
    var lifecycle = XCEasyTestLifecycleMachine()
    var terminalEventClaimed = false
    var configuration: XCEasyExecutionConfigurationState?
    var softAssertionScopes: [XCEasySoftAssertionCollector] = []
    var softAssertionFailureVersion = 0

    /// Reads one field while holding the execution-state lock.
    ///
    /// - Parameter body: Projection that returns an immutable value.
    /// - Returns: Value produced by `body`.
    func read<T>(_ body: (XCEasyExecutionState) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(self)
    }

    /// Mutates one or more fields while holding the execution-state lock.
    ///
    /// - Parameter body: Mutation to apply atomically.
    func update(_ body: (XCEasyExecutionState) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body(self)
    }

    /// Mutates state and returns a value from the same critical section.
    ///
    /// - Parameter body: Atomic mutation and result calculation.
    /// - Returns: Value produced by `body`.
    func update<T>(_ body: (XCEasyExecutionState) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(self)
    }

    /// Clears per-test fields while preserving the current suite association.
    func clearTestData() {
        update { state in
            state.testId = nil
            state.displayName = nil
            state.testResult = nil
            state.labels = []
            state.links = []
            state.resultDescription = nil
            state.stepStack = []
            state.activeStepDepth = 0
            state.screenshot = nil
            state.deferredFailures = []
            state.executionId = nil
            state.canonicalIdentityFullName = nil
            state.lifecycle = XCEasyTestLifecycleMachine()
            state.terminalEventClaimed = false
            state.configuration = nil
            state.softAssertionScopes = []
            state.softAssertionFailureVersion = 0
        }
    }
}

/// Structured-concurrency carrier for one execution state.
internal enum XCEasyTaskExecutionScope {
    @TaskLocal static var state: XCEasyExecutionState?
}
