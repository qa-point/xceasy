import XCTest
import Foundation

public class Device: XCEasyApp {
    private static let shared = Device()
    private let device = XCUIDevice.shared

    /// Taps on the specified screen position
    /// - Parameters:
    ///  - position: The screen position to tap
    public static func tap(at position: ScreenPosition) {
        let stepTitle = LocalizationManager.shared.string(
            forKey: "screen_tap_title",
            arguments: ["\(position.description)"]
        )
        operationStep(code: "device.tap", title: stepTitle, target: position.description) {
            guard let app = shared.app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot tap coordinates because the test context has no app"
                ))
                return
            }
            XCEasyTestLogger.shared.log("Start performing tap on screen with position")
            app.coordinate(withNormalizedOffset: position.offset).tap()
            XCEasyTestLogger.shared.log("End performing tap on screen with position")
        }
    }

    /// Swipes from the start position to the end position on the screen.
    ///
    /// - Parameters:
    ///  - startPosition: The starting screen position for the swipe.
    ///  - endPosition: The ending screen position for the swipe.
    public static func swipe(from startPosition: ScreenPosition, to endPosition: ScreenPosition) {
        let stepTitle = LocalizationManager.shared.string(
            forKey: "screen_swipe_title",
            arguments: ["\(startPosition.description)", "\(endPosition.description)"]
        )
        operationStep(code: "device.swipe", title: stepTitle, target: "\(startPosition.description)->\(endPosition.description)") {
            guard let app = shared.app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot swipe coordinates because the test context has no app"
                ))
                return
            }
            XCEasyTestLogger.shared.log("Get start coordinates")
            let start = app.coordinate(withNormalizedOffset: startPosition.offset)
            XCEasyTestLogger.shared.log("Get end coordinates")
            let end = app.coordinate(withNormalizedOffset: endPosition.offset)
            XCEasyTestLogger.shared.log("Start performing swipe")
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0.05)
            XCEasyTestLogger.shared.log("End performing swipe")
        }
    }

    /// Presses the specified screen position for a given duration.
    ///
    /// - Parameters:
    ///  - position: The screen position to press.
    ///  - duration: The duration to press the screen position.
    public static func press(at position: ScreenPosition, duration: Double) {
        let stepTitle = LocalizationManager.shared.string(
            forKey: "screen_press_title",
            arguments: ["\(position.description)", "\(duration)"]
        )
        operationStep(code: "device.press", title: stepTitle, target: position.description) {
            guard let app = shared.app else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "context.application_unavailable",
                    safeDescription: "Cannot press coordinates because the test context has no app"
                ))
                return
            }
            XCEasyTestLogger.shared.log("Start performing press")
            app.coordinate(withNormalizedOffset: position.offset).press(forDuration: duration)
            XCEasyTestLogger.shared.log("End performing press")
        }
    }

    /// Gets the value from the clipboard
    ///
    /// - Returns: The value from the clipboard
    @discardableResult
    public static func getClipboardValue() -> String {
        var clipboardValue: String = ""
        let stepTitle = LocalizationManager.shared.string(forKey: "get_clipboard_value")

        operationStep(code: "device.clipboard.read", title: stepTitle) {
            XCEasyTestLogger.shared.log("Try to get value from clipboard")
            clipboardValue = UIPasteboard.general.string ?? ""
            XCEasyTestLogger.shared.log("Return value")
        }
        return clipboardValue
    }

    /// Waits for the specified number of seconds
    ///
    /// - Parameters:
    ///  - seconds: The number of seconds to wait
    public static func wait(seconds: TimeInterval) {
        let stepTitle = LocalizationManager.shared.string(
            forKey: "wait_for_seconds",
            arguments: ["\(seconds)"]
        )
        operationStep(code: "device.wait", title: stepTitle) {
            XCEasyTestLogger.shared.log("Start waiting")
            Thread.sleep(forTimeInterval: seconds)
            XCEasyTestLogger.shared.log("End waiting")
        }
    }

    /// Sets the device orientation
    ///
    /// - Parameters:
    ///  - orientation: The orientation to set
    public static func setOrientation(_ orientation: DeviceOrientation) {
        let stepTitle = LocalizationManager.shared.string(
            forKey: "set_orientation",
            arguments: ["\(orientation.properties.name)"]
        )
        operationStep(code: "device.orientation.set", title: stepTitle, target: orientation.properties.name) {
            shared.device.orientation = orientation.properties.key
            XCEasyTestLogger.shared.log("Orientation changed")
        }
    }
}
