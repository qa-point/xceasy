import Foundation

/// Utility for taking screenshots during test execution
public class ScreenshotUtils {

    /// Takes screenshot of current screen state
    ///
    /// - Parameters:
    ///   - name: Screenshot name
    ///   - testId: Current test ID
    /// - Returns: ScreenshotAttachment object or nil if failed
    internal static func takeScreenshot(name: String, testId: String) -> ScreenshotAttachment? {
        guard let app = XCEasyTestContext.shared.app else {
            XCEasyTestLogger.shared.log("Cannot take screenshot - app is not initialized", level: .error)
            return nil
        }

        let window = app.windows.firstMatch
        guard canCaptureScreenshot(
            isApplicationRunning: app.state == .runningForeground,
            windowExists: window.exists
        ) else {
            XCEasyTestLogger.shared.log(
                "Cannot take screenshot - application window is unavailable",
                level: .debug
            )
            return nil
        }

        let screenshot = window.screenshot()
        let imageData = screenshot.pngRepresentation

        let filename = "\(testId)_\(Int64(Date().timeIntervalSince1970 * 1000)).png"

        return ScreenshotAttachment(
            name: name,
            filename: filename,
            data: imageData,
            type: .png
        )
    }

    /// Determines whether requesting an XCUI screenshot is safe.
    ///
    /// XCTest records a new issue when `screenshot()` is called for a missing window. During
    /// launch failures that issue would recursively trigger failure evidence collection.
    ///
    /// - Parameters:
    ///   - isApplicationRunning: Whether the application is currently in the foreground.
    ///   - windowExists: Whether the current accessibility tree contains an application window.
    /// - Returns: `true` only when both prerequisites are satisfied.
    internal static func canCaptureScreenshot(
        isApplicationRunning: Bool,
        windowExists: Bool
    ) -> Bool {
        isApplicationRunning && windowExists
    }

    /// Saves screenshot to file system
    ///
    /// - Parameters:
    ///   - screenshot: Screenshot to save
    ///   - directory: Directory to save screenshot
    /// - Returns: Attachment object for Allure report
    internal static func saveScreenshot(
        _ screenshot: ScreenshotAttachment,
        to directory: URL,
        filenameSuffix: String = ""
    ) throws -> Attachment {
        let source = filename(
            screenshot.filename,
            appendingSuffix: filenameSuffix
        )
        let fileURL = directory.appendingPathComponent(source)
        try AtomicFileWriter.write(screenshot.data, to: fileURL)

        return Attachment(
            name: screenshot.name,
            source: source,
            type: screenshot.type.rawValue
        )
    }

    /// Produces a distinct Allure source while preserving the original file extension.
    /// Allure uses `source` as an attachment identity, so repeated placements must not share it.
    internal static func filename(_ filename: String, appendingSuffix suffix: String) -> String {
        guard !suffix.isEmpty else { return filename }

        let fileURL = URL(fileURLWithPath: filename)
        let fileExtension = fileURL.pathExtension
        let baseName = fileURL.deletingPathExtension().lastPathComponent

        guard !fileExtension.isEmpty else { return "\(baseName)\(suffix)" }
        return "\(baseName)\(suffix).\(fileExtension)"
    }

    /// Attaches screenshot to test result
    internal static func attachToTest(_ testResult: inout TestResult, allureAttachment: Attachment) {
        var testAttachments = testResult.attachments ?? []
        testAttachments.append(allureAttachment)
        testResult.attachments = testAttachments
        XCEasyTestLogger.shared.log("Screenshot attached to test result: \(allureAttachment.name ?? "unknown")")
    }

    /// Attaches an Allure attachment to the last failed step in the hierarchy.
    @discardableResult
    internal static func attachAttachmentToLastFailedStep(
        _ testResult: inout TestResult,
        allureAttachment: Attachment
    ) -> Bool {
        guard let steps = testResult.steps, !steps.isEmpty else {
            XCEasyTestLogger.shared.log("No steps found to attach screenshot", level: .debug)
            return false
        }

        let modifiedSteps = StepUtils.attachToLastFailedStep(steps: steps, attachment: allureAttachment)
        testResult.steps = modifiedSteps

        let hadFailedStep = StepUtils.findLastFailedStep(in: steps) != nil

        if hadFailedStep {
            XCEasyTestLogger.shared.log("Attachment added to last failed step: \(allureAttachment.name ?? "unknown")")
        } else {
            XCEasyTestLogger.shared.log("No failed step found for attachment", level: .debug)
        }

        return hadFailedStep
    }

    /// Attaches an Allure attachment to the deepest step as a fallback.
    internal static func attachAttachmentToDeepestStepAsFallback(
        _ testResult: inout TestResult,
        allureAttachment: Attachment
    ) {
        guard let steps = testResult.steps, !steps.isEmpty else {
            return
        }

        let modifiedSteps = StepUtils.attachToDeepestStep(steps: steps, attachment: allureAttachment)
        testResult.steps = modifiedSteps
        XCEasyTestLogger.shared.log("Attachment added to deepest step as fallback: \(allureAttachment.name ?? "unknown")")
    }
}
