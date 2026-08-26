import XCTest
import os.log

// MARK: - XCEasyTestObserver

/// Test observer that logs events, creates a directory for reports, and handles test lifecycle.
@objc(XCEasyTestObserver)
open class XCEasyTestObserver: NSObject, XCTestObservation {

    // MARK: - Properties

    /// Shared instance of the test observer.
    static var shared: XCEasyTestObserver?

    /// The OS logger instance.
    private var logger: OSLogger

    /// The report directory URL.
    private var reportDir: URL? = nil

    /// The Allure formatter instance.
    private let allureFormatter = AllureFormatter()

    // MARK: - Initialization

    /// Creates and registers the process observer before XCTest begins reporting callbacks.
    ///
    /// Registration is idempotent at the bootstrap level; this initializer owns one observer
    /// instance and its OS-log category.
    override init() {
        logger = OSLogger(
            subsystem: "com.qa-point.xceasy.testobserver.log",
            category: "Log-\(UUID().uuidString)"
        )
        super.init()
        XCEasyTestObserver.shared = self
        // Registration is now handled by XCEasyTestObserverRegistrar via +load method
        XCTestObservationCenter.shared.addTestObserver(self)
        logger.log("* XCEasyTestObserver initialized")
    }
}

// MARK: - XCTestObservation Methods

extension XCEasyTestObserver {

    /// Prepares an empty runner-local Allure directory before the first test starts.
    ///
    /// - Parameter testBundle: XCTest bundle entering execution.
    public func testBundleWillStart(_ testBundle: Bundle) {
        let testBundleId = testBundle.bundleIdentifier ?? "Test Bundle"
        logger.log("* Test Bundle starting: [ \(testBundleId) ]")

        let directory = FileManagerUtils.shared.getDefaultReportDirectory()
        reportDir = directory

        do {
            try FileManagerUtils.shared.createDirectory(at: directory)
            logger.log("* Default test result path: \(directory.path)")
            saveAllureServiceFiles()
        } catch {
            logger.log(
                "* Failed to create reports directory: \(error.localizedDescription)",
                level: .error
            )
        }
    }

    /// Validates final Allure output and unregisters the observer after bundle completion.
    ///
    /// - Parameter testBundle: XCTest bundle that completed execution.
    public func testBundleDidFinish(_ testBundle: Bundle) {
        let testBundleId = testBundle.bundleIdentifier ?? "Test Bundle"
        logger.log("* Test Bundle finished: [ \(testBundleId) ]")
        validateAllureResults()
        XCTestObservationCenter.shared.removeTestObserver(self)
    }

    /// Runs the local Allure contract validator and renders every issue to the OS log.
    private func validateAllureResults() {
        guard let reportDir else {
            logger.log("* Allure validation skipped: report directory is unavailable", level: .error)
            return
        }
        let summary = AllureResultsValidator().validate(directory: reportDir)
        if summary.isValid {
            logger.log(
                "* Allure results valid: results=\(summary.resultCount), containers=\(summary.containerCount), attachments=\(summary.attachmentCount)"
            )
            return
        }
        for issue in summary.issues {
            logger.log(
                "* Allure validation issue code=\(issue.code) file=\(issue.file ?? "none") detail=\(issue.detail)",
                level: .error
            )
        }
    }

    /// Captures the formatted suite name for tests entering an XCTest suite.
    ///
    /// - Parameter testSuite: Suite beginning execution.
    public func testSuiteWillStart(_ testSuite: XCTestSuite) {
        logger.log("* Test Suite starting: [ \(testSuite.name) ]")
        let testSuiteName = allureFormatter.formatTestSuiteName(testSuite: testSuite)
        if testSuiteName != "" {
            XCEasyTestContext.shared.testSuite = testSuiteName
        }
    }

    /// Clears suite-scoped context after an XCTest suite finishes.
    ///
    /// - Parameter testSuite: Suite that completed execution.
    public func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        logger.log("* Test Suite finished: [ \(testSuite.name) ]")
        XCEasyTestContext.shared.testSuite = nil
    }

    /// Creates stable test identity and isolated per-attempt result, log, and event storage.
    ///
    /// - Parameter testCase: XCTest case beginning execution.
    public func testCaseWillStart(_ testCase: XCTestCase) {
        let executionId = UUID().uuidString.lowercased()
        let fullName = allureFormatter.formatTestCasePath(testCase: testCase)
        let metadata = XCEasyStaticMetadataResolver.resolve(testCase: testCase)
        let canonicalFullName = allureFormatter.canonicalIdentityPath(
            fullName: fullName,
            scenario: metadata.canonicalScenario
        )
        let identity = AllureIdentity.make(fullName: canonicalFullName, parameters: metadata.parameters)
        XCEasyTestContext.shared.beginExecution(testId: identity.testCaseId, executionId: executionId)
        XCEasyTestContext.shared.canonicalIdentityFullName = canonicalFullName
        XCEasyTestLogger.shared.start(id: executionId, testId: identity.testCaseId, logDir: reportDir)
        XCEasyTestLogger.shared.log(
            "* Test starting: \(fullName)",
            level: .debug
        )
        XCEasyTestContext.shared.testResult = TestResult(
            uuid: executionId,
            historyId: identity.historyId,
            testCaseId: identity.testCaseId,
            fullName: fullName,
            testCaseName: allureFormatter.formatTestCaseName(testCase: testCase),
            stage: .running,
            description: testCase.description,
            start: Int64(Date().timeIntervalSince1970 * 1000),
        )
        XCEasyTestContext.shared.testResult?.parameters = metadata.parameters
        addStandardAllureLabels(testCase: testCase)
        addExecutionLabelsFromEnvironment()
        applyStaticMetadata(metadata)
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "test.started",
            testId: identity.testCaseId,
            executionId: executionId,
            operationCode: "test.lifecycle",
            operationId: executionId,
            statusCode: "running",
            title: fullName
        ))
    }

    /// Applies compile-time metadata before XCTest invokes `setUp`.
    ///
    /// - Parameter metadata: Merged class, method, marker, and parameterized-case metadata.
    private func applyStaticMetadata(_ metadata: XCEasyResolvedMetadata) {
        XCEasyTestContext.shared.displayName = metadata.displayName
        XCEasyTestContext.shared.description = metadata.resultDescription
        metadata.labels.forEach(XCEasyTestContext.shared.addLabel)
        metadata.links.forEach(XCEasyTestContext.shared.addLink)
        guard var result = XCEasyTestContext.shared.testResult else { return }
        var details = result.statusDetails ?? StatusDetails()
        if metadata.flaky { details.flaky = true }
        if metadata.muted { details.muted = true }
        result.statusDetails = details
        XCEasyTestContext.shared.testResult = result
        for marker in metadata.markers {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: "test.marker.applied",
                testId: XCEasyTestContext.shared.testId,
                executionId: XCEasyTestContext.shared.executionId,
                operationCode: "test.selection.metadata",
                statusCode: "passed",
                title: marker
            ))
        }
    }

    /// Adds deterministic framework, host, thread, package, class, and method labels.
    ///
    /// - Parameter testCase: Test case from which names are derived.
    private func addStandardAllureLabels(testCase: XCTestCase) {
        let fullName = allureFormatter.formatTestCasePath(testCase: testCase)
        let components = fullName.split(separator: "/").map(String.init)
        let testClass = components.dropLast().last ?? "UnknownTestClass"
        let testMethod = components.last ?? allureFormatter.formatTestCaseName(testCase: testCase)
        let values = [
            Label(name: "framework", value: "XCEasy"),
            Label(name: "language", value: "swift"),
            Label(name: "host", value: ProcessInfo.processInfo.hostName),
            Label(name: "thread", value: String(describing: ObjectIdentifier(Thread.current))),
            Label(name: "package", value: components.first ?? "XCEasy"),
            Label(name: "testClass", value: testClass),
            Label(name: "testMethod", value: testMethod)
        ]
        values.forEach(XCEasyTestContext.shared.addLabel)
    }

    /// Adds optional run, device, shard, and attempt labels supplied by the coordinator.
    private func addExecutionLabelsFromEnvironment() {
        let environment = ProcessInfo.processInfo.environment
        [
            ("xceasy.run_id", environment["XC_EASY_RUN_ID"]),
            ("xceasy.device_id", environment["XC_EASY_DEVICE_ID"]),
            ("xceasy.device_type", environment["XC_EASY_DEVICE_TYPE"]),
            ("xceasy.shard_index", environment["XC_EASY_SHARD_INDEX"]),
            ("xceasy.attempt", environment["XC_EASY_ATTEMPT"]),
        ].forEach { name, value in
            guard let value, !value.isEmpty else { return }
            XCEasyTestContext.shared.addLabel(Label(name: name, value: value))
        }
    }

    /// Finalizes one test exactly once and persists its Allure and diagnostic artifacts.
    ///
    /// - Parameter testCase: XCTest case that completed execution.
    public func testCaseDidFinish(_ testCase: XCTestCase) {
        guard let executionId = XCEasyTestContext.shared.executionId else { return }

        XCEasyTestLogger.shared.log(
            "* Test finished: \(allureFormatter.formatTestCasePath(testCase: testCase))",
            level: .debug
        )
        // Persist the terminal lifecycle event before performance and integrity
        // artifacts are finalized so their hashes describe an immutable stream.
        finishLifecycleAndEmitTerminalEvent(testCase)

        if var testResult = XCEasyTestContext.shared.testResult {
            if !XCEasyTestContext.shared.isLabelExists("suite") {
                let suiteLabel = Label(name: "suite", value: String(XCEasyTestContext.shared.testSuite ?? "DefaultSuite"))
                XCEasyTestContext.shared.addLabel(suiteLabel)
            }

            testResult.status = Status.fromTestRun(testCase.testRun)
            testResult.labels = XCEasyTestContext.shared.labels
            testResult.links = XCEasyTestContext.shared.links
            testResult.name = XCEasyTestContext.shared.displayName ?? allureFormatter.formatTestCaseName(testCase: testCase)
            testResult.description = XCEasyTestContext.shared.description ?? nil
            testResult.stop = Int64(Date().timeIntervalSince1970 * 1000)
            testResult.stage = .finished
            if let fullName = XCEasyTestContext.shared.canonicalIdentityFullName ?? testResult.fullName {
                let identity = AllureIdentity.make(
                    fullName: fullName,
                    parameters: testResult.parameters ?? []
                )
                testResult.testCaseId = identity.testCaseId
                testResult.historyId = identity.historyId
            }

            finalizeUnfinishedStepsIfNeeded(&testResult)

            let originalSteps = testResult.steps ?? []
            let setupFixture = findStep(named: "Setup", in: originalSteps)
            let teardownFixture = findStep(named: "Teardown", in: originalSteps)
            testResult.steps = removeFixtureStepsFromTestBody(originalSteps)

            attachFailureScreenshotToTestAndFailedStep(&testResult)
            attachLogFileToTestAndFailedStep(&testResult)
            attachDiagnosticEventsToTest(&testResult)
            attachPerformanceSummaryToTest(&testResult)
            attachDiagnosticBundleToTest(&testResult)

            XCEasyTestContext.shared.testResult = testResult
            do {
                guard let reportDir else {
                    throw XCEasyFrameworkError(
                        code: "report.directory_unavailable",
                        safeDescription: "Cannot write Allure result because report directory is unavailable"
                    )
                }
                try FileManagerUtils.shared.saveTestResult(testResult, to: reportDir)
                if let container = buildTestResultContainer(
                    for: testCase,
                    testResult: testResult,
                    setupFixture: setupFixture,
                    teardownFixture: teardownFixture
                ) {
                    try FileManagerUtils.shared.saveTestResultContainer(container, to: reportDir)
                    XCEasyTestLogger.shared.log("* Test result container saved for test: \(allureFormatter.formatTestCasePath(testCase: testCase))")
                }
                XCEasyTestLogger.shared.log("* Test result saved for test: \(allureFormatter.formatTestCasePath(testCase: testCase))")
            } catch {
                XCEasyTestLogger.shared.log(
                    "* Failed to save test result: \(error.localizedDescription)",
                    level: .error
                )
            }
        }

        XCEasyTestLogger.shared.end(id: executionId)
        XCEasyTestContext.shared.clearTestStorages()
    }

    /// Writes and attaches the execution performance summary without hiding test failures.
    ///
    /// - Parameter testResult: In-memory Allure result being finalized.
    private func attachPerformanceSummaryToTest(_ testResult: inout TestResult) {
        do {
            guard let attachment = try XCEasyTestLogger.shared.writeCurrentPerformanceSummary() else { return }
            var attachments = testResult.attachments ?? []
            attachments.append(attachment)
            testResult.attachments = attachments
        } catch {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: "telemetry.error",
                level: "error",
                testId: XCEasyTestContext.shared.testId,
                statusCode: "failed",
                reasonCode: "performance.summary_write_failed",
                title: error.localizedDescription
            ))
        }
    }

    /// Finalizes and attaches the evidence-oriented diagnostic bundle.
    ///
    /// - Parameter testResult: In-memory Allure result being finalized.
    private func attachDiagnosticBundleToTest(_ testResult: inout TestResult) {
        do {
            let attachments = try XCEasyTestLogger.shared.writeCurrentDiagnosticBundle(testResult: testResult)
            testResult.attachments = (testResult.attachments ?? []) + attachments
        } catch {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: "telemetry.error",
                level: "error",
                testId: XCEasyTestContext.shared.testId,
                statusCode: "failed",
                reasonCode: "diagnostic.bundle_write_failed",
                title: error.localizedDescription
            ))
        }
    }

    /// Transitions the context to a terminal state and emits at most one `test.finished` event.
    ///
    /// - Parameter testCase: Completed XCTest case used to derive status and identity.
    private func finishLifecycleAndEmitTerminalEvent(_ testCase: XCTestCase) {
        let context = XCEasyTestContext.shared
        switch context.lifecycleState {
        case .settingUp:
            _ = context.transitionLifecycle(to: .finished)
        case .running:
            _ = context.transitionLifecycle(to: .finished)
        case .tearingDown:
            _ = context.transitionLifecycle(to: .finished)
        case .created:
            _ = context.transitionLifecycle(to: .finished)
        case .finished, .interrupted:
            break
        }
        guard context.claimTerminalEvent() else { return }
        let status = Status.fromTestRun(testCase.testRun)
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "test.finished",
            level: status == .passed ? "info" : "error",
            testId: context.testId,
            executionId: context.executionId,
            operationCode: "test.lifecycle",
            operationId: context.executionId,
            statusCode: status.rawValue,
            reasonCode: context.lifecycleState == .interrupted ? "test.interrupted" : "test.completed",
            title: allureFormatter.formatTestCasePath(testCase: testCase)
        ))
    }

    /// Captures diagnostic evidence and marks the active step when XCTest records an issue.
    ///
    /// - Parameters:
    ///   - testCase: Test case that recorded the issue.
    ///   - issue: XCTest issue containing the failure description and source context.
    public func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) {
        XCEasyTestLogger.shared.log(
            "* Test  \(allureFormatter.formatTestCasePath(testCase: testCase)) recorded issue:",
            level: .debug
        )
        XCEasyTestLogger.shared.log(
            "* \(issue)",
            level: .debug
        )

        takeScreenshotOnFailure(for: testCase, issue: issue)

        if var testResult = XCEasyTestContext.shared.testResult {
            testResult.statusDetails = Self.failureStatusDetails(
                preserving: testResult.statusDetails,
                message: issue.compactDescription,
                trace: issue.detailedDescription ?? nil
            )

            // Finalize interrupted step hierarchy immediately, before Teardown starts,
            // so Teardown remains a separate root step in report.
            finalizeUnfinishedStepsIfNeeded(&testResult)

            XCEasyTestContext.shared.testResult = testResult
        }

        markCurrentRunningStepAsFailed(issue)
    }

    // MARK: - Private Methods

    /// Adds failure text without discarding metadata flags applied before test execution.
    internal static func failureStatusDetails(
        preserving existing: StatusDetails?,
        message: String,
        trace: String?
    ) -> StatusDetails {
        var details = existing ?? StatusDetails()
        details.message = message
        details.trace = trace
        return details
    }

    /// Takes screenshot when test fails.
    private func takeScreenshotOnFailure(for testCase: XCTestCase, issue: XCTIssue) {
        guard let testId = XCEasyTestContext.shared.testId else { return }

        let screenshotName = "Screenshot_\(testId)_\(Int64(Date().timeIntervalSince1970 * 1000))"
        guard let screenshot = ScreenshotUtils.takeScreenshot(name: screenshotName, testId: testId) else {
            XCEasyTestLogger.shared.log("Failed to take screenshot on test failure", level: .error)
            return
        }

        XCEasyTestContext.shared.screenshot = screenshot
        XCEasyTestLogger.shared.log("Failure screenshot saved: \(screenshotName)")
    }

    /// Attaches failure screenshot to test result and the last failed step.
    private func attachFailureScreenshotToTestAndFailedStep(_ testResult: inout TestResult) {
        guard let screenshot = XCEasyTestContext.shared.screenshot, let reportDir = reportDir
            else { return }

        do {
            let stepAttachment = try ScreenshotUtils.saveScreenshot(screenshot, to: reportDir)
            let testAttachment = try ScreenshotUtils.saveScreenshot(
                screenshot,
                to: reportDir,
                filenameSuffix: "-test"
            )
            ScreenshotUtils.attachToTest(&testResult, allureAttachment: testAttachment)
            let attachedToFailedStep = ScreenshotUtils.attachAttachmentToLastFailedStep(
                &testResult,
                allureAttachment: stepAttachment
            )
            if !attachedToFailedStep {
                ScreenshotUtils.attachAttachmentToDeepestStepAsFallback(
                    &testResult,
                    allureAttachment: stepAttachment
                )
                XCEasyTestLogger.shared.log("No failed step found, attached screenshot to deepest step instead")
            }

        } catch {
            XCEasyTestLogger.shared.log("Failed to attach failure screenshot: \(error.localizedDescription)", level: .error)
        }
    }

    /// Attaches current test log file to test result and the last failed step.
    private func attachLogFileToTestAndFailedStep(_ testResult: inout TestResult) {
        guard let logFileURL = XCEasyTestLogger.shared.currentLogFileURL() else {
            XCEasyTestLogger.shared.log("No log file URL found for current test", level: .debug)
            return
        }

        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            XCEasyTestLogger.shared.log("Log file does not exist at path: \(logFileURL.path)", level: .debug)
            return
        }

        let attachment = Attachment(
            name: "Test Log",
            source: logFileURL.lastPathComponent,
            type: "text/plain"
        )

        var testAttachments = testResult.attachments ?? []
        testAttachments.append(attachment)
        testResult.attachments = testAttachments
        XCEasyTestLogger.shared.log("Log attached to test result: \(logFileURL.lastPathComponent)")

        let attachedToFailedStep = ScreenshotUtils.attachAttachmentToLastFailedStep(
            &testResult,
            allureAttachment: attachment
        )
        if !attachedToFailedStep {
            XCEasyTestLogger.shared.log("No failed step found, log remains attached to the test result")
        }
    }

    /// Attaches the canonical machine-readable event stream used by AI tools,
    /// self-healing diagnostics, and performance analysis.
    private func attachDiagnosticEventsToTest(_ testResult: inout TestResult) {
        guard let eventFileURL = XCEasyTestLogger.shared.currentEventFileURL(),
              FileManager.default.fileExists(atPath: eventFileURL.path) else {
            XCEasyTestLogger.shared.log("No diagnostic events file found for current test", level: .debug)
            return
        }
        let attachment = Attachment(
            name: "XCEasy Diagnostic Events.jsonl",
            source: eventFileURL.lastPathComponent,
            type: "application/x-ndjson"
        )
        var attachments = testResult.attachments ?? []
        attachments.append(attachment)
        testResult.attachments = attachments
        XCEasyTestLogger.shared.log("Diagnostic events attached: \(eventFileURL.lastPathComponent)")
    }

    /// Marks the currently running step (top of step stack) as failed.
    private func markCurrentRunningStepAsFailed(_ issue: XCTIssue) {
        var stack = XCEasyTestContext.shared.stepStack
        guard !stack.isEmpty else { return }

        let index = stack.count - 1
        stack[index].status = .failed
        stack[index].stage = .finished
        stack[index].statusDetails = StatusDetails(
            message: issue.compactDescription,
            trace: issue.detailedDescription ?? nil
        )

        XCEasyTestContext.shared.stepStack = stack
    }

    /// Finalizes steps that remained in stack due to abrupt XCTest interruption.
    private func finalizeUnfinishedStepsIfNeeded(_ testResult: inout TestResult) {
        let stack = XCEasyTestContext.shared.stepStack
        guard !stack.isEmpty else { return }

        XCEasyTestLogger.shared.log(
            "Detected \(stack.count) unfinished step(s); finalizing them before saving result",
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

        if let root {
            testResult.steps = (testResult.steps ?? []) + [root]
            XCEasyTestLogger.shared.log(
                "Finalized unfinished root step: '\(root.name ?? "Unknown")'",
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

    /// Saves Allure service files used by report UI.
    private func saveAllureServiceFiles() {
        guard let reportDir else { return }

        do {
            try FileManagerUtils.shared.saveExecutor(buildExecutor(), to: reportDir)
            try FileManagerUtils.shared.saveEnvironmentProperties(buildEnvironmentProperties(), to: reportDir)
            try FileManagerUtils.shared.saveCategories(buildDefaultCategories(), to: reportDir)
            logger.log("* Allure service files saved: executor.json, environment.properties, categories.json")
        } catch {
            logger.log("* Failed to save Allure service files: \(error.localizedDescription)", level: .error)
        }
    }

    /// Builds Allure test result container with fixtures (befores/afters).
    private func buildTestResultContainer(
        for testCase: XCTestCase,
        testResult: TestResult,
        setupFixture: StepResult?,
        teardownFixture: StepResult?
    ) -> TestResultContainer? {
        guard let testUuid = testResult.uuid else { return nil }

        return TestResultContainer(
            uuid: UUID().uuidString,
            name: allureFormatter.formatTestCasePath(testCase: testCase),
            children: [testUuid],
            description: testResult.description,
            descriptionHtml: testResult.descriptionHtml,
            befores: setupFixture.map { [$0] },
            afters: teardownFixture.map { [$0] },
            links: testResult.links,
            start: testResult.start,
            stop: testResult.stop
        )
    }

    /// Removes fixture steps from test body so they are displayed only in container befores/afters.
    private func removeFixtureStepsFromTestBody(_ steps: [StepResult]) -> [StepResult] {
        return steps.filter {
            $0.name != "Setup" && $0.name != "Teardown"
        }
    }

    /// Finds first step by name in hierarchy.
    private func findStep(named stepName: String, in steps: [StepResult]) -> StepResult? {
        for step in steps {
            if step.name == stepName {
                return step
            }
            if let nested = step.steps, let found = findStep(named: stepName, in: nested) {
                return found
            }
        }
        return nil
    }

    /// Builds default executor metadata for Allure.
    private func buildExecutor() -> Executor {
        let processInfo = ProcessInfo.processInfo
        let env = processInfo.environment

        return Executor(
            name: env["CI"] == "true" ? "CI" : "Xcode",
            type: env["CI"] == "true" ? "ci" : "local",
            url: env["CI_JOB_URL"] ?? env["BUILD_URL"],
            buildOrder: Int(env["CI_PIPELINE_IID"] ?? env["BUILD_NUMBER"] ?? ""),
            buildName: env["CI_JOB_NAME"] ?? env["SCHEME_NAME"] ?? "XCEasy Tests",
            buildUrl: env["CI_JOB_URL"] ?? env["BUILD_URL"],
            reportName: "XCEasy Allure Report",
            reportUrl: env["ALLURE_REPORT_URL"]
        )
    }

    /// Builds environment.properties contents for Allure.
    private func buildEnvironmentProperties() -> [String: String] {
        let processInfo = ProcessInfo.processInfo
        let properties: [String: String] = [
            "framework": "XCEasy",
            "framework.bundleId": XCEasyConfig.bundleId,
            "framework.localization": XCEasyConfig.localization.rawValue,
            "framework.findTimeout": String(XCEasyConfig.findTimeout),
            "framework.actionTimeout": String(XCEasyConfig.actionTimeout),
            "framework.assertionTimeout": String(XCEasyConfig.assertionTimeout),
            "framework.requestTimeout": String(XCEasyConfig.requestTimeout),
            "framework.uiQueryEvidenceLevel": XCEasyConfig.uiQueryEvidenceLevel.rawValue,
            "allure.linkTypes": XCEasyAllureConfig.configuredLinkTypes.joined(separator: ","),
            "os.name": processInfo.operatingSystemVersionString,
            "process.arguments": processInfo.arguments.joined(separator: " ")
        ]

        return properties
    }

    /// Builds default categories.json entries for common XCT/UI failures.
    private func buildDefaultCategories() -> [AllureCategory] {
        [
            AllureCategory(
                name: "UI Element Not Found",
                matchedStatuses: [Status.failed.rawValue],
                messageRegex: ".*(No matches found|element.*not found|Failed to get matching snapshot).*",
                traceRegex: nil,
                flaky: false
            ),
            AllureCategory(
                name: "Assertion Failure",
                matchedStatuses: [Status.failed.rawValue],
                messageRegex: ".*(Assertion Failure|XCTFail).*",
                traceRegex: nil,
                flaky: false
            ),
            AllureCategory(
                name: "Broken Test Infrastructure",
                matchedStatuses: [Status.broken.rawValue],
                messageRegex: nil,
                traceRegex: ".*(NSException|fatalError|uncaught exception).*",
                flaky: false
            )
        ]
    }
}
