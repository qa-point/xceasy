# Device interaction

English · [Русский](../../ru/guide/10_DEVICE_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)

`Device` controls the device and the whole screen. It does not query accessibility elements and knows no application identifier. Use `find(...).tap()`/`swipe(...)` for a specific button or list because a locator produces more precise logs and diagnostics. Use `Device` for orientation, clipboard access, and gestures in a fixed screen area.

## Available operations

| API | Behavior | Diagnostic operation code |
|---|---|---|
| `Device.tap(at:)` | Taps a normalized screen position. | `device.tap` |
| `Device.swipe(from:to:)` | Drags between two whole-screen positions. | `device.swipe` |
| `Device.press(at:duration:)` | Holds a position for a duration. | `device.press` |
| `Device.setOrientation(_:)` | Changes device orientation. | `device.orientation.set` |
| `Device.getClipboardValue()` | Returns the clipboard string or `""`. | `device.clipboard.read` |
| `Device.wait(seconds:)` | Performs a fixed delay. | `device.wait` |

Positions: `.center`, `.leftCenter`, `.rightCenter`, `.topCenter`, `.bottomCenter`, `.leftTop`, `.leftBottom`, `.rightTop`, `.rightBottom`. They are predefined points near the center or an edge, not element coordinates.

Orientations: `.portrait`, `.portraitUpsideDown`, `.landscapeLeft`, `.landscapeRight`, `.faceUp`, `.faceDown`, `.unknown`. UI tests normally need the first four; the remaining values mirror the complete `XCUIDevice.Orientation` set.

## Test example

```swift
final class DeviceTests: BaseTestCase {
    func testScreenAndClipboardOperations() {
        Device.setOrientation(.landscapeLeft)
        Device.tap(at: .center)
        Device.swipe(from: .rightCenter, to: .leftCenter)
        Device.press(at: .rightTop, duration: 1.5)

        let copiedText = Device.getClipboardValue()
        assertNotEmpty(actual: copiedText)

        Device.setOrientation(.portrait)
    }
}
```

Allure receives sequential steps such as `Set orientation [Landscape Left]`, `Tap screen [center]`, `Swipe screen [right] → [left]`, `Press screen...`, and `Get clipboard value`. JSONL contains the stable codes from the table and durations; clipboard contents are not included in the step title.

## When `wait` is acceptable

```swift
Device.wait(seconds: 1)
```

This call is reported too, but a fixed delay always consumes the whole duration and depends on environment speed. Prefer `waitForDisplayed`, `waitForEnabled`, or an assertion with a timeout for observable UI state. Use `Device.wait` only when no accessibility state can represent the condition and a surrounding user `step` explains the reason.
