import Foundation
import XCTest

/// Deferred failure information to record after nested steps are fully finalized.
internal struct DeferredFailure {
    let message: String
}

// MARK: - XCEasyTestContext

/// Execution-scoped test context backed by thread-local ownership and task-local propagation.
internal class XCEasyTestContext: TestContextProviding {

    // MARK: - Properties

    /// Shared instance of the test context.
    static let shared = XCEasyTestContext()

    private let threadState = ThreadLocal<XCEasyExecutionState>()

    /// Returns task-propagated state, thread-owned state, or creates an isolated fallback.
    private var state: XCEasyExecutionState {
        if let taskState = XCEasyTaskExecutionScope.state { return taskState }
        if let existing = threadState.value { return existing }
        let created = XCEasyExecutionState()
        threadState.value = created
        return created
    }

    // MARK: - TestContextProviding Properties

    /// The test ID for the current thread.
    var testId: String? {
        get { state.read(\.testId) }
        set { state.update { $0.testId = newValue } }
    }

    /// The XCUIApplication instance for the current thread.
    var app: XCUIApplication? {
        get { state.read(\.app) }
        set { state.update { $0.app = newValue } }
    }

    /// The display name for the current thread.
    var displayName: String? {
        get { state.read(\.displayName) }
        set { state.update { $0.displayName = newValue } }
    }

    /// The TestResult for the current thread.
    var testResult: TestResult? {
        get { state.read(\.testResult) }
        set { state.update { $0.testResult = newValue } }
    }

    /// The labels for the current thread.
    var labels: [Label] {
        get { state.read(\.labels) }
        set { state.update { $0.labels = newValue } }
    }

    /// The links for the current thread.
    var links: [AllureLinkRecord] {
        get { state.read(\.links) }
        set { state.update { $0.links = newValue } }
    }

    /// The description for the current thread.
    var description: String? {
        get { state.read(\.resultDescription) }
        set { state.update { $0.resultDescription = newValue } }
    }

    /// The test suite for the current thread.
    var testSuite: String? {
        get { state.read(\.testSuite) }
        set { state.update { $0.testSuite = newValue } }
    }

    /// The step stack for the current thread.
    var stepStack: [StepResult] {
        get { state.read(\.stepStack) }
        set { state.update { $0.stepStack = newValue } }
    }

    /// Active step execution depth for the current thread.
    var activeStepDepth: Int {
        get { state.read(\.activeStepDepth) }
        set { state.update { $0.activeStepDepth = newValue } }
    }

    /// The screenshot attachment for the current thread.
    var screenshot: ScreenshotAttachment? {
        get { state.read(\.screenshot) }
        set { state.update { $0.screenshot = newValue } }
    }

    /// Deferred failures for the current thread.
    var deferredFailures: [DeferredFailure] {
        get { state.read(\.deferredFailures) }
        set { state.update { $0.deferredFailures = newValue } }
    }

    var executionId: String? {
        get { state.read(\.executionId) }
        set { state.update { $0.executionId = newValue } }
    }

    /// Canonical scenario name used to keep parameterized variants under one Allure test case.
    var canonicalIdentityFullName: String? {
        get { state.read(\.canonicalIdentityFullName) }
        set { state.update { $0.canonicalIdentityFullName = newValue } }
    }

    var lifecycleState: XCEasyTestLifecycleState {
        state.read { $0.lifecycle.state }
    }

    /// Creates fresh state for one test while preserving the enclosing suite identity.
    ///
    /// - Parameters:
    ///   - testId: Stable test-case identity.
    ///   - executionId: Unique attempt identity.
    func beginExecution(testId: String, executionId: String) {
        let suite = state.read(\.testSuite)
        let fresh = XCEasyExecutionState()
        fresh.update {
            $0.testSuite = suite
            $0.testId = testId
            $0.executionId = executionId
        }
        threadState.value = fresh
    }

    /// Propagates the current execution state through structured async work.
    ///
    /// - Parameter operation: Async operation that may resume on another thread.
    /// - Returns: Value returned by `operation`.
    /// - Throws: Rethrows any error produced by `operation`.
    func withCurrentExecution<T>(_ operation: () async throws -> T) async rethrows -> T {
        let capturedState = state
        do {
            let value = try await XCEasyTaskExecutionScope.$state.withValue(
                capturedState,
                operation: operation
            )
            threadState.value = capturedState
            return value
        } catch {
            threadState.value = capturedState
            throw error
        }
    }

    /// Attaches a configuration snapshot to the current execution state.
    ///
    /// - Parameter configuration: Lock-protected configuration captured at setup.
    func setExecutionConfiguration(_ configuration: XCEasyExecutionConfigurationState?) {
        state.update { $0.configuration = configuration }
    }

    /// Initializes lifecycle bookkeeping for a new isolated test execution.
    ///
    /// - Parameter executionId: Unique identifier for this test attempt.
    func resetLifecycle(executionId: String) {
        state.update {
            $0.executionId = executionId
            $0.lifecycle = XCEasyTestLifecycleMachine()
            $0.terminalEventClaimed = false
        }
    }

    /// Attempts a lifecycle transition and records structured evidence when it is rejected.
    ///
    /// - Parameter state: Requested next lifecycle state.
    /// - Returns: `true` when the transition was accepted; otherwise `false`.
    @discardableResult
    func transitionLifecycle(to state: XCEasyTestLifecycleState) -> Bool {
        do {
            try self.state.update { executionState in
                try executionState.lifecycle.transition(to: state)
            }
            return true
        } catch {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: "lifecycle.transition_rejected",
                level: "error",
                testId: testId,
                executionId: executionId,
                statusCode: "failed",
                reasonCode: "lifecycle.invalid_transition",
                title: "Invalid lifecycle transition to \(state.rawValue)"
            ))
            return false
        }
    }

    /// Atomically claims responsibility for emitting the execution's terminal event.
    ///
    /// - Returns: `true` for the first claimant on the current thread; later calls return `false`.
    func claimTerminalEvent() -> Bool {
        state.update {
            guard !$0.terminalEventClaimed else { return false }
            $0.terminalEventClaimed = true
            return true
        }
    }

    // MARK: - TestContextProviding Methods

    /// Adds a label to the current thread.
    func addLabel(_ label: Label) {
        state.update { $0.labels.append(label) }
    }

    /// Checks if a label exists for the current thread.
    func isLabelExists(_ name: String) -> Bool {
        return labels.contains { $0.name == name }
    }

    /// Adds a link to the current thread.
    func addLink(_ link: AllureLinkRecord) {
        state.update { $0.links.append(link) }
    }

    /// Clears all stored data for the current thread except app.
    func clearTestStorages() {
        state.clearTestData()
    }

    /// Clears the app instance for the current thread.
    func clearApp() {
        state.update { $0.app = nil }
    }

    /// Sets the XCUIApplication instance for the current thread.
    func setApp() {
        let bundleId = XCEasyConfig.bundleId
        state.update {
            $0.app = bundleId.isEmpty ? XCUIApplication() : XCUIApplication(bundleIdentifier: bundleId)
        }
    }

    /// Pushes a step to the stack.
    func pushStep(_ step: StepResult) {
        state.update { $0.stepStack.append(step) }
    }

    /// Pops the last step from the stack.
    func popStep() -> StepResult? {
        state.update { $0.stepStack.popLast() }
    }

    /// Adds deferred failure that should be recorded after step stack unwinds.
    func addDeferredFailure(_ message: String) {
        state.update { $0.deferredFailures.append(DeferredFailure(message: message)) }
    }

    /// Consumes and clears all deferred failures.
    func consumeDeferredFailures() -> [DeferredFailure] {
        state.update {
            let failures = $0.deferredFailures
            $0.deferredFailures = []
            return failures
        }
    }

    /// Increments active step execution depth.
    func incrementActiveStepDepth() {
        state.update { $0.activeStepDepth += 1 }
    }

    /// Decrements active step execution depth.
    func decrementActiveStepDepth() {
        state.update { $0.activeStepDepth = max(0, $0.activeStepDepth - 1) }
    }

    /// Installs one soft-assertion collector for the current execution scope.
    ///
    /// - Parameter collector: Collector that owns mismatches until its `softly` block ends.
    func pushSoftAssertionScope(_ collector: XCEasySoftAssertionCollector) {
        state.update { $0.softAssertionScopes.append(collector) }
    }

    /// Removes and returns the innermost soft-assertion collector.
    ///
    /// - Returns: Collector removed from the current execution, when one exists.
    @discardableResult
    func popSoftAssertionScope() -> XCEasySoftAssertionCollector? {
        state.update { $0.softAssertionScopes.popLast() }
    }

    /// Records one assertion mismatch in the current soft scope.
    ///
    /// - Parameter failure: Redacted assertion mismatch.
    /// - Returns: `true` when a soft scope accepted the failure; otherwise `false`.
    func recordSoftAssertionFailure(_ failure: XCEasySoftAssertionFailure) -> Bool {
        state.update { executionState in
            guard let collector = executionState.softAssertionScopes.last else { return false }
            collector.record(failure)
            executionState.softAssertionFailureVersion += 1
            return true
        }
    }

    /// Monotonically increasing mismatch counter used to mark enclosing steps as failed.
    var softAssertionFailureVersion: Int {
        state.read(\.softAssertionFailureVersion)
    }
}
