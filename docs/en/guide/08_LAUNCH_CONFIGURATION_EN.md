# Launch arguments and environment

English · [Русский](../../ru/guide/08_LAUNCH_CONFIGURATION_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


There is one Manager API and no duplicate global DSL. Configure values before the application launches:

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.yourcompany.app",
            localization: .en
        )

        LaunchArgumentsManager.add("-ui_testing")
        LaunchArgumentsManager.add("-disable_animations")

        LaunchEnvironmentManager.set([
            "IS_UI_TEST": "1",
            "API_BASE_URL": "https://staging.example.com",
            "FEATURE_FLAG_X": "true"
        ])

        super.configuration()
    }
}
```

`XCEasyTestCase` applies these values after `configuration()` and before the automatic `launchApplication()` call.

## Launch arguments

Arguments are an ordered string array in `XCUIApplication.launchArguments`. They are useful as flags, for example to enable UI-test mode or disable animations.

In the base-class example, the application receives `-ui_testing` and `-disable_animations`. `add(_:)` preserves order and appends every supplied value, including repeats, so the same argument may intentionally be passed more than once. `remove(_:)` deletes the first exact match, `removeAll()` clears the list, and `values` returns the current copy.

## Launch environment

Environment is a `[String: String]` dictionary in `XCUIApplication.launchEnvironment`. It is appropriate for key-value data such as a base URL, feature flags, initial application state, or a fixture name.

In the base-class example, all three values enter the launch environment. Use `set(_:for:)` for one value; `value(for:)`, `values`, `remove(_:)`, and `removeAll()` inspect or clear the store.

During `XCEasyTestCase.setUpWithError()`, arguments are appended to `XCUIApplication.launchArguments`, and environment values are merged into `launchEnvironment`; the Manager value wins for the same key. Changes made after `launchApplication()` take effect only on the next `reopenApplication()` or a new launch.

At the start of each test, the Managers create an execution-owned copy. Changes made in one parallel test's `configuration()` do not enter another test's launch configuration.

## Overriding and removing base settings

Calling `set` again with the same environment key replaces its value. Arguments have no keys, so replacing one means removing the exact old string and adding the new one.

```swift
final class ProductionLikeTests: BaseTestCase {
    override func configuration() {
        super.configuration()
        LaunchArgumentsManager.remove("-disable_animations")
        LaunchArgumentsManager.add("-animation_speed=0.5")
        LaunchEnvironmentManager.set("https://preprod.example.com", for: "API_BASE_URL")
        LaunchEnvironmentManager.remove("FEATURE_FLAG_X")
    }

    func testPreprodCatalog() {
        find(identifier: "catalogScreen").assertIsDisplayed()
    }
}
```

To inherit no defaults, clear the managers and add only the required values:

```swift
override func configuration() {
    super.configuration()
    LaunchArgumentsManager.removeAll()
    LaunchEnvironmentManager.removeAll()
    LaunchEnvironmentManager.set("1", for: "IS_UI_TEST")
}
```

Changes after `super.configuration()` still apply because the app launches after the hook returns. Read through `LaunchArgumentsManager.values`, `LaunchEnvironmentManager.values`, and `value(for:)`, but do not dump the complete environment into a step because it may contain secrets.

A change inside a test method requires another launch:

```swift
func testFeatureAfterRelaunch() {
    closeApplication()
    LaunchEnvironmentManager.set("false", for: "FEATURE_FLAG_X")
    launchApplication()
    find(identifier: "legacyScreen").assertIsDisplayed()
}
```

The report shows `Close application → Launch application → Assert...`; environment values do not become steps.
