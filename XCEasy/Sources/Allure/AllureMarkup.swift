import XCTest

// MARK: - Public Allure API

/// Adds a test case Allure ID.
/// - Parameter value: Unique test identifier.
public func id(_ value: String) {
    labels(type: .id, values: [value])
}

/// Adds an epic label to categorize related features.
/// - Parameter value: Epic name.
public func epic(_ value: String) {
    labels(type: .epic, values: [value])
}

/// Adds a feature label.
/// - Parameter value: Feature name.
public func feature(_ value: String) {
    labels(type: .feature, values: [value])
}

/// Adds a story label.
/// - Parameter value: Story name.
public func story(_ value: String) {
    labels(type: .story, values: [value])
}

/// Adds a suite label.
/// - Parameter value: Suite name.
public func suite(_ value: String) {
    labels(type: .suite, values: [value])
}

/// Adds an owner label.
/// - Parameter value: Owner name.
public func owner(_ value: String) {
    labels(type: .owner, values: [value])
}

/// Adds a lead label to the current test.
/// - Parameter value: Project lead name.
public func lead(_ value: String) {
    label("lead", value)
}

/// Adds a severity label.
/// - Parameter value: Severity state.
public func severity(_ value: SeverityState) {
    labels(type: .severity, values: [value.rawValue])
}

/// Adds a custom label.
/// - Parameters:
///   - name: Label name.
///   - value: Label value.
public func label(_ name: String, _ value: String) {
    XCTContext.runActivity(named: "allure.label.\(name):\(value)") { _ in }
    XCEasyTestContext.shared.addLabel(Label(name: name, value: value))
}

/// Adds multiple tags.
/// - Parameter tags: Tag values.
public func tag(_ tags: String...) {
    labels(type: .tag, values: tags)
}

/// Adds a standard Allure link to the current test.
/// - Parameters:
///   - name: Readable link name.
///   - url: Link URL.
///   - type: Allure link type; defaults to `custom`.
public func link(name: String? = nil, url: String, type: String = "custom") {
    XCEasyTestContext.shared.addLink(AllureLinkRecord(
        name: name ?? url,
        url: SensitiveDataRedactor.redact(url),
        type: type
    ))
}

/// Adds a standard issue link.
/// - Parameter value: Issue key or value expanded through the `issue` link pattern.
public func issue(_ value: String) {
    typedLink(type: "issue", value: value)
}

/// Adds a TMS link.
/// - Parameter value: TMS issue key.
public func tms(_ value: String) {
    typedLink(type: "tms", value: value)
}

/// Adds a description to the test.
/// - Parameter value: Description text.
public func description(_ value: String) {
    XCTContext.runActivity(named: "allure.description:\(value)", block: { _ in })
    XCEasyTestContext.shared.description = value
}

/// Marks the current Allure result as flaky.
public func flaky() {
    updateStatusDetails { $0.flaky = true }
}

/// Marks the current Allure result as muted.
public func muted() {
    updateStatusDetails { $0.muted = true }
}

/// Sets the display name for the test.
/// - Parameter name: Display name.
public func displayName(_ name: String) {
    XCTContext.runActivity(named: "allure.name:\(name)", block: { _ in })
    XCEasyTestContext.shared.displayName = name
}

/// Adds a history-aware Allure parameter to the current test execution.
///
/// - Parameters:
///   - name: Stable parameter name.
///   - value: Value redacted before it reaches any report sink.
///   - excluded: Whether the parameter is excluded from `historyId`.
///   - mode: Allure display mode. `masked` and `hidden` never persist the raw value.
///
/// ```swift
/// parameter("account", value: "test-user", excluded: true, mode: .masked)
/// ```
public func parameter(
    _ name: String,
    value: String,
    excluded: Bool = false,
    mode: AllureParameterMode = .default
) {
    guard var result = XCEasyTestContext.shared.testResult else {
        recordFrameworkFailure(XCEasyFrameworkError(
            code: "allure.test_context_unavailable",
            safeDescription: "Cannot add Allure parameter before a test result is started"
        ))
        return
    }
    let redactedValue: String
    if mode == .default {
        redactedValue = SensitiveDataRedactor.redact(value)
    } else {
        redactedValue = "<redacted:parameter length=\(value.count)>"
    }
    var parameters = result.parameters ?? []
    parameters.removeAll { $0.name == name }
    parameters.append(Parameter(
        name: SensitiveDataRedactor.redact(name),
        value: redactedValue,
        excluded: excluded,
        mode: mode.rawValue
    ))
    result.parameters = parameters
    XCEasyTestContext.shared.testResult = result
}

/// Executes a step within the test.
/// - Parameters:
///   - name: Step name.
///   - file: Call-site file captured in canonical diagnostics.
///   - line: Call-site line captured in canonical diagnostics.
///   - function: Call-site function captured in canonical diagnostics.
///   - block: Step body.
/// - Returns: The result of the step block.
/// - Throws: Rethrows an error from `block` after finalizing failed step evidence.
///
/// ```swift
/// try step("Submit profile") {
///     try profileForm.submit()
/// }
/// ```
@discardableResult
public func step<T>(
    _ name: String,
    file: StaticString = #fileID,
    line: UInt = #line,
    function: StaticString = #function,
    block: () throws -> T
) rethrows -> T {
    try executeXCEasyStep(
        name,
        metadata: .test,
        file: file,
        line: line,
        function: function,
        block: block
    )
}

/// Executes an async throwing step while propagating execution context across thread hops.
///
/// - Parameters:
///   - name: Human-readable step name.
///   - file: Call-site file captured in canonical diagnostics.
///   - line: Call-site line captured in canonical diagnostics.
///   - function: Call-site function captured in canonical diagnostics.
///   - block: Async work whose value and error are preserved.
/// - Returns: Value returned by `block`.
/// - Throws: Rethrows an error after the failed step hierarchy is finalized.
///
/// ```swift
/// try await step("Load profile") {
///     try await profileService.load()
/// }
/// ```
@available(iOS 15.0, *)
@discardableResult
public func step<T>(
    _ name: String,
    file: StaticString = #fileID,
    line: UInt = #line,
    function: StaticString = #function,
    block: () async throws -> T
) async rethrows -> T {
    try await executeXCEasyStep(
        name,
        metadata: .test,
        file: file,
        line: line,
        function: function,
        block: block
    )
}

// MARK: - Shared Step Execution

/// Structured context attached to a step without changing its Allure nesting semantics.
internal struct XCEasyStepMetadata {
    let operationCode: String
    let target: String?
    let selector: XCEasyLocatorDescriptor?

    /// Metadata for a regular test step.
    static let test = XCEasyStepMetadata(
        operationCode: "test.step",
        target: nil,
        selector: nil
    )

    /// Creates metadata for work owned by a reusable UI component.
    ///
    /// - Parameters:
    ///   - componentName: Stable semantic component name.
    ///   - element: Immutable component locator.
    /// - Returns: Component metadata for canonical diagnostics and performance telemetry.
    static func component(
        name componentName: String,
        element: XCEasyUIElement
    ) -> XCEasyStepMetadata {
        XCEasyStepMetadata(
            operationCode: "component.step",
            target: componentName,
            selector: element.locatorDescriptor
        )
    }
}

/// Executes synchronous work through the shared Allure step lifecycle.
///
/// - Parameters:
///   - name: Complete human-readable step name.
///   - metadata: Structured owner and locator context.
///   - file: Call-site file captured in canonical diagnostics.
///   - line: Call-site line captured in canonical diagnostics.
///   - function: Call-site function captured in canonical diagnostics.
///   - block: Step body whose value and error are preserved.
/// - Returns: Value returned by `block`.
/// - Throws: Rethrows an error after finalizing the failed hierarchy.
@discardableResult
internal func executeXCEasyStep<T>(
    _ name: String,
    metadata: XCEasyStepMetadata,
    file: StaticString,
    line: UInt,
    function: StaticString,
    block: () throws -> T
) rethrows -> T {
    finalizeOrphanedStepsBeforeStartingNewRootStep()
    XCEasyTestContext.shared.incrementActiveStepDepth()

    let startTime = Int64(Date().timeIntervalSince1970 * 1000)
    let monotonicStart = DispatchTime.now().uptimeNanoseconds
    let operationId = UUID().uuidString.lowercased()
    var stepResult = StepResult(name: name, status: .passed, stage: .running, start: startTime)
    let source = DiagnosticSource(file: "\(file)", line: Int(line), function: "\(function)")

    emitStepStarted(
        name: name,
        metadata: metadata,
        operationId: operationId,
        source: source,
        monotonicStart: monotonicStart
    )
    XCEasyTestContext.shared.pushStep(stepResult)
    let softFailureVersionAtStart = XCEasyTestContext.shared.softAssertionFailureVersion
    XCEasyTestLogger.shared.log("Step pushed: \(name)")

    defer {
        finalizeStep(
            name: name,
            metadata: metadata,
            operationId: operationId,
            source: source,
            startTime: startTime,
            stepResult: &stepResult
        )
    }

    do {
        XCEasyTestLogger.shared.startLogBlock("Starting STEP: '\(name)'")
        XCEasyTestLogger.shared.log("step_started title=\(name)")
        let result = try block()
        if XCEasyTestContext.shared.softAssertionFailureVersion > softFailureVersionAtStart {
            stepResult.status = .failed
            stepResult.statusDetails = StatusDetails(
                message: "One or more soft assertions failed",
                trace: nil
            )
        } else {
            stepResult.status = .passed
        }
        stepResult.stage = .finished
        return result
    } catch {
        stepResult.status = .failed
        stepResult.stage = .finished
        stepResult.statusDetails = StatusDetails(
            message: "Step failed with error: \(error.localizedDescription)",
            trace: "\(error)"
        )
        persistFailedStepHierarchy(name, error)
        recordFailureOrDefer("Error in: \(name): \(error)")
        throw error
    }
}

/// Executes asynchronous work through the shared task-propagated Allure step lifecycle.
///
/// - Parameters:
///   - name: Complete human-readable step name.
///   - metadata: Structured owner and locator context.
///   - file: Call-site file captured in canonical diagnostics.
///   - line: Call-site line captured in canonical diagnostics.
///   - function: Call-site function captured in canonical diagnostics.
///   - block: Async step body whose value and error are preserved.
/// - Returns: Value returned by `block`.
/// - Throws: Rethrows an error after finalizing the failed hierarchy.
@available(iOS 15.0, *)
@discardableResult
internal func executeXCEasyStep<T>(
    _ name: String,
    metadata: XCEasyStepMetadata,
    file: StaticString,
    line: UInt,
    function: StaticString,
    block: () async throws -> T
) async rethrows -> T {
    try await XCEasyTestContext.shared.withCurrentExecution {
        finalizeOrphanedStepsBeforeStartingNewRootStep()
        XCEasyTestContext.shared.incrementActiveStepDepth()

        let startTime = Int64(Date().timeIntervalSince1970 * 1000)
        let monotonicStart = DispatchTime.now().uptimeNanoseconds
        let operationId = UUID().uuidString.lowercased()
        var stepResult = StepResult(name: name, status: .passed, stage: .running, start: startTime)
        let source = DiagnosticSource(file: "\(file)", line: Int(line), function: "\(function)")

        emitStepStarted(
            name: name,
            metadata: metadata,
            operationId: operationId,
            source: source,
            monotonicStart: monotonicStart
        )
        XCEasyTestContext.shared.pushStep(stepResult)
        let softFailureVersionAtStart = XCEasyTestContext.shared.softAssertionFailureVersion
        XCEasyTestLogger.shared.log("Step pushed: \(name)")

        defer {
            finalizeStep(
                name: name,
                metadata: metadata,
                operationId: operationId,
                source: source,
                startTime: startTime,
                stepResult: &stepResult
            )
        }

        do {
            XCEasyTestLogger.shared.startLogBlock("Starting STEP: '\(name)'")
            XCEasyTestLogger.shared.log("step_started title=\(name)")
            let result = try await block()
            if XCEasyTestContext.shared.softAssertionFailureVersion > softFailureVersionAtStart {
                stepResult.status = .failed
                stepResult.statusDetails = StatusDetails(
                    message: "One or more soft assertions failed",
                    trace: nil
                )
            } else {
                stepResult.status = .passed
            }
            stepResult.stage = .finished
            return result
        } catch {
            stepResult.status = .failed
            stepResult.stage = .finished
            stepResult.statusDetails = StatusDetails(
                message: "Async step failed with error: \(error.localizedDescription)",
                trace: "\(error)"
            )
            persistFailedStepHierarchy(name, error)
            recordFailureOrDefer("Error in async step \(name): \(error)")
            throw error
        }
    }
}

/// Emits canonical evidence when a shared step begins.
///
/// - Parameters:
///   - name: Human-readable step name.
///   - metadata: Structured step owner metadata.
///   - operationId: Unique step operation identifier.
///   - source: Privacy-safe call-site metadata.
///   - monotonicStart: Monotonic start timestamp.
private func emitStepStarted(
    name: String,
    metadata: XCEasyStepMetadata,
    operationId: String,
    source: DiagnosticSource,
    monotonicStart: UInt64
) {
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "step.started",
        testId: XCEasyTestContext.shared.testId,
        operationCode: metadata.operationCode,
        operationId: operationId,
        statusCode: "running",
        target: metadata.target,
        title: name,
        selector: metadata.selector,
        source: source,
        monotonicNanoseconds: monotonicStart
    ))
}

/// Finalizes one shared step and attaches it to its current Allure parent.
///
/// - Parameters:
///   - name: Human-readable step name.
///   - metadata: Structured step owner metadata.
///   - operationId: Unique step operation identifier.
///   - source: Privacy-safe call-site metadata.
///   - startTime: Wall-clock start timestamp in milliseconds.
///   - stepResult: Mutable Allure step result finalized in place.
private func finalizeStep(
    name: String,
    metadata: XCEasyStepMetadata,
    operationId: String,
    source: DiagnosticSource,
    startTime: Int64,
    stepResult: inout StepResult
) {
    stepResult.stop = Int64(Date().timeIntervalSince1970 * 1000)
    let duration = max(0, (stepResult.stop ?? startTime) - startTime)

    if var currentStep = XCEasyTestContext.shared.popStep() {
        currentStep.stop = stepResult.stop
        currentStep.status = stepResult.status
        currentStep.stage = stepResult.stage ?? .finished
        currentStep.statusDetails = stepResult.statusDetails

        if var parentStep = XCEasyTestContext.shared.popStep() {
            parentStep.steps = (parentStep.steps ?? []) + [currentStep]
            XCEasyTestContext.shared.pushStep(parentStep)
        } else if var testResult = XCEasyTestContext.shared.testResult {
            testResult.steps = (testResult.steps ?? []) + [currentStep]
            XCEasyTestContext.shared.testResult = testResult
        }
    }

    XCEasyTestLogger.shared.log(
        "step_finished status=\(stepResult.status?.rawValue ?? "unknown") duration_ms=\(duration) title=\(name)"
    )
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "step.finished",
        level: stepResult.status == .failed ? "error" : "info",
        testId: XCEasyTestContext.shared.testId,
        operationCode: metadata.operationCode,
        operationId: operationId,
        statusCode: stepResult.status?.rawValue ?? "unknown",
        reasonCode: stepResult.status == .failed
            ? (stepResult.statusDetails?.message == "One or more soft assertions failed"
                ? "step.soft_assertion_failed"
                : "step.thrown_error")
            : "step.completed",
        durationMilliseconds: duration,
        target: metadata.target,
        title: name,
        selector: metadata.selector,
        source: source,
        performance: diagnosticPerformanceEvidence(
            operationKey: metadata.operationCode,
            durationMilliseconds: duration
        )
    ))
    enforcePerformanceBudget(
        operationKey: metadata.operationCode,
        durationMilliseconds: duration,
        parentOperationId: operationId
    )
    XCEasyTestLogger.shared.endLogBlock("Finished STEP: '\(name)' in \(duration) ms")
    XCEasyTestContext.shared.decrementActiveStepDepth()
    flushDeferredFailuresIfNeeded()
}

// MARK: - Private

/// Recursively saves the hierarchy of failed steps, adding detailed error information to the deepest step.
/// - Parameters:
///   - stepName: The name of the step that failed.
///   - error: The error that occurred.
private func persistFailedStepHierarchy(_ stepName: String, _ error: any Error) {
    var failedSteps: [StepResult] = []

    while let step = XCEasyTestContext.shared.popStep() {
        var modifiedStep = step
        modifiedStep.status = .failed
        modifiedStep.stage = .finished
        modifiedStep.start = modifiedStep.start ?? Int64(Date().timeIntervalSince1970 * 1000)
        modifiedStep.stop = modifiedStep.stop ?? modifiedStep.start
        failedSteps.append(modifiedStep)
    }

    var rootStep: StepResult?
    for step in failedSteps {
        guard let currentStep = rootStep else {
            rootStep = step
            continue
        }

        var newStep = step
        let start = [newStep.start, currentStep.start].compactMap { $0 }.min()
        let stop = [newStep.stop, currentStep.stop].compactMap { $0 }.max()
        newStep.start = start ?? newStep.start
        newStep.stop = stop ?? newStep.stop
        newStep.steps = (newStep.steps ?? []) + [currentStep]
        rootStep = newStep
    }

    if var root = rootStep {
        updateDeepestStep(in: &root, stepName: stepName, error: error)
        if var testResult = XCEasyTestContext.shared.testResult {
            testResult.steps = (testResult.steps ?? []) + [root]
            XCEasyTestContext.shared.testResult = testResult
        }
    }
}

/// Updates the deepest step with error details.
/// - Parameters:
///   - step: The step to update.
///   - stepName: The name of the step that failed.
///   - error: The error that occurred.
private func updateDeepestStep(in step: inout StepResult, stepName: String, error: any Error) {
    guard !step.steps.isNilOrEmpty else {
        step.statusDetails = StatusDetails(
            message: "Error in: '\(stepName)'",
            trace: "\(error)"
        )
        return
    }

    var steps = step.steps ?? []

    if !steps.isEmpty {
        var lastChild = steps[steps.count - 1]
        updateDeepestStep(in: &lastChild, stepName: stepName, error: error)
        steps[steps.count - 1] = lastChild
    }

    step.steps = steps
}

/// Records all deferred failures once there are no active steps in the current thread.
private func flushDeferredFailuresIfNeeded() {
    guard XCEasyTestContext.shared.activeStepDepth == 0 else { return }

    let failures = XCEasyTestContext.shared.consumeDeferredFailures()
    guard !failures.isEmpty else { return }

    failures.forEach { failure in
        XCTFail(failure.message)
    }
}

/// Records failure immediately if no step is active; otherwise defers until all nested steps are finalized.
private func recordFailureOrDefer(_ message: String) {
    XCEasyTestLogger.shared.log(message, level: .error)

    if XCEasyTestContext.shared.activeStepDepth > 0 {
        XCEasyTestContext.shared.addDeferredFailure(message)
    } else {
        XCTFail(message)
    }
}

/// Finalizes orphaned unfinished steps before starting a new root-level step (e.g. Teardown).
///
/// This handles cases where XCTest aborts current step execution before step `defer` is reached,
/// leaving stale items in `stepStack`. Without this, the next root-level step can accidentally
/// become a child of the failed branch.
private func finalizeOrphanedStepsBeforeStartingNewRootStep() {
    guard XCEasyTestContext.shared.activeStepDepth == 0 else { return }

    let stack = XCEasyTestContext.shared.stepStack
    guard !stack.isEmpty else { return }

    XCEasyTestLogger.shared.log(
        "Detected orphaned unfinished step stack before starting new root step; finalizing stale stack",
        level: .warning
    )

    let now = Int64(Date().timeIntervalSince1970 * 1000)
    var root: StepResult?
    var finalizedStepNames: [String] = []

    for var step in stack.reversed() {
        if step.start == nil { step.start = now }
        if step.stop == nil { step.stop = now }
        if step.stage == nil { step.stage = .finished }
        if step.status == nil || step.status == .passed {
            step.status = .failed
        }

        if let stepName = step.name {
            finalizedStepNames.append(stepName)
        }

        if let currentRoot = root {
            step.steps = (step.steps ?? []) + [currentRoot]
        }
        root = step
    }

    if let root, var testResult = XCEasyTestContext.shared.testResult {
        testResult.steps = (testResult.steps ?? []) + [root]
        XCEasyTestContext.shared.testResult = testResult

        XCEasyTestLogger.shared.log(
            "Finalized orphaned root step: '\(root.name ?? "Unknown")'",
            level: .warning
        )

        finalizedStepNames.forEach { stepName in
            XCEasyTestLogger.shared.endLogBlock("Finished STEP: '\(stepName)'")
        }
    }

    XCEasyTestContext.shared.stepStack = []
    XCEasyTestContext.shared.activeStepDepth = 0
    _ = XCEasyTestContext.shared.consumeDeferredFailures()
}

// MARK: - Internal Implementation

/// Adds multiple labels to the test context.
/// - Parameters:
///   - type: The type of label to add.
///   - values: The values for the label.
internal func labels(type: LabelType, values: [String]) {
    values.forEach { value in
        XCTContext.runActivity(named: "allure.label.\(type.rawValue):\(value)") { _ in }
        XCEasyTestContext.shared.addLabel(Label(name: type.rawValue, value: value))
    }
}

/// Adds a typed Allure link resolved through configured link patterns.
private func typedLink(type: String, value: String) {
    XCEasyTestContext.shared.addLink(AllureLinkRecord(
        name: SensitiveDataRedactor.redact(value),
        url: XCEasyAllureConfig.resolveLink(type: type, value: value),
        type: type
    ))
}

/// Mutates status details while preserving flags set by other metadata sources.
private func updateStatusDetails(_ mutation: (inout StatusDetails) -> Void) {
    guard var result = XCEasyTestContext.shared.testResult else {
        recordFrameworkFailure(XCEasyFrameworkError(
            code: "allure.test_context_unavailable",
            safeDescription: "Cannot update Allure status details before a test result is started"
        ))
        return
    }
    var details = result.statusDetails ?? StatusDetails()
    mutation(&details)
    result.statusDetails = details
    XCEasyTestContext.shared.testResult = result
}
