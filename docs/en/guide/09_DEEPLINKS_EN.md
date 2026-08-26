# Deep links

English · [Русский](../../ru/guide/09_DEEPLINKS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


A separate route model is unnecessary. `Deeplink.open(_:, name:)` accepts a path without a scheme, prefixes `XCEasyConfig.deeplinkSchema`, and opens the URL through `XCUIDevice`.

## Configuration

The scheme is the URL part before `://`. It must start with a letter and may contain letters, digits, `+`, `-`, and `.`. Supply only the scheme name:

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(localization: .en, deeplinkSchema: "myapp")
        super.configuration()
    }
}
```

The application itself must register the scheme. XCEasy does not add URL Types to the app target.

## Basic example

```swift
final class SettingsTests: BaseTestCase {
    func testOpenPrivacySettingsByDeeplink() {
        Deeplink.open(
            "/settings/privacy",
            name: "Privacy settings"
        )

        find(identifier: "privacySettingsScreen").assertIsDisplayed()
    }
}
```

The `myapp` scheme is already configured in `BaseTestCase.configuration()`, so this call opens `myapp://settings/privacy`. The leading `/` is optional. Allure receives an `Open deeplink [Privacy settings]` step; canonical diagnostics record `deeplink.open`, `target = "Privacy settings"`, and its duration. The screen assertion is the next separate step.

## Paths, queries, and readable names

```swift
final class DeeplinkTests: BaseTestCase {
    func testRoutes() {
        Deeplink.open("catalog")
        find(identifier: "catalogScreen").assertIsDisplayed()

        Deeplink.open("/product/42?source=ui-test", name: "Test product details")
        find(identifier: "productScreen").assertIsDisplayed()

        Deeplink.open("settings/notifications", name: "Notification settings")
        find(identifier: "notificationSettingsScreen").assertIsDisplayed()
    }
}
```

Leading slashes are removed, so `catalog` and `/catalog` produce the same URL. A complete `https://...` or `myapp://...` URL is rejected: the API accepts only a route so configuration controls the scheme. An empty/invalid scheme, empty path, or `://` in the path records failure `deeplink.invalid_url`.

`name` does not affect the URL. When `name == nil`, the path becomes the title; avoid that form for sensitive query values.

```text
Open deeplink [Test product details]            deeplink.open   passed   93 ms
Assert [productScreen] is displayed             assert.visible  passed
```

XCEasy does not prove that the app handled the route; the following UI assertion does. Separate steps show whether the deep link was dispatched and whether the expected screen opened.
