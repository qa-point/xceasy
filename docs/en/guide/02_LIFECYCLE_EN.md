# Test and application lifecycle

English · [Русский](../../ru/guide/02_LIFECYCLE_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


Inherit from `XCEasyTestCase` so every test method receives isolated configuration, application, Allure result, log, and artifacts. The framework runs these phases in order:

```text
configuration → launchApplication → beforeTest → test method → afterTest → closeApplication
```

| Hook/method | When it runs | What belongs there |
|---|---|---|
| `configuration()` | Before application launch for every test. | `XCEasyConfig`, `XCEasyAllureConfig`, and launch arguments/environment. Call `super.configuration()` last so the effective settings enter the log. |
| `beforeTest()` | After application launch and before the test method. | Shared preconditions and Allure metadata for tests in the class. Call `super.beforeTest()`. |
| `afterTest()` | After the test method and before application termination. | User cleanup that needs the application to remain available. Call `super.afterTest()`. |
| `launchApplication()` | Automatically during setup; may be called manually after `closeApplication()`. | Launching the current `XCUIApplication` with configured arguments/environment. |
| `closeApplication()` | Automatically during teardown. | Explicit application termination inside a scenario. |
| `reopenApplication()` | Only when called by the user. | Full terminate + launch, for example to verify a persisted session. |
| `printDebugTree()` | Only when called by the user. | Local printing of the entire current accessibility tree. |

```swift
final class SessionTests: BaseTestCase {
    override func beforeTest() {
        feature("Session")
        super.beforeTest()
    }

    func testSessionSurvivesRestart() {
        find(identifier: "loginButton").tap()
        find(identifier: "homeScreen").assertIsDisplayed()

        reopenApplication()

        find(identifier: "homeScreen").assertIsDisplayed()
    }
}
```

Avoid overriding `setUpWithError()`/`tearDownWithError()` unless necessary: XCEasy creates and releases execution-scoped state there. Use the hooks above for normal test behavior.

## Examples of every public hook and method

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(localization: .en)
        LaunchArgumentsManager.add("-ui_testing")
        super.configuration()
    }

    override func beforeTest() {
        feature("Catalog")
        find(identifier: "homeScreen").assertIsDisplayed()
        super.beforeTest()
    }

    override func afterTest() {
        find(identifier: "debugMenu.close").tap()
        super.afterTest()
    }
}

final class ApplicationLifecycleTests: BaseTestCase {
    func testManualLifecycleOperations() {
        closeApplication()
        launchApplication()
        find(identifier: "rememberMe").tap()
        reopenApplication()
        printDebugTree()
        find(identifier: "homeScreen").assertIsDisplayed()
    }
}
```

`configuration`, `beforeTest`, and `afterTest` run for every test method. Use `reopenApplication()` for a complete restart. Use separate `closeApplication()`/`launchApplication()` calls when launch settings change between them.

## Report output

```text
Setup
  Test Configuration
  Launch application                 app.launch
  Before Test
testManualLifecycleOperations
  Close application                  app.terminate
  Launch application                 app.launch
  Reopen application                 app.reopen
    Close application                app.terminate
    Launch application               app.launch
Teardown
  After Test
  Close application                  app.terminate
```

`printDebugTree()` writes the tree only to the console and creates no assertion.
