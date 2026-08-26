# Configuration

English · [Русский](../../ru/guide/01_CONFIGURATION_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


Configuration normally belongs in the base `XCEasyTestCase.configuration()`. Every parallel test receives its own effective configuration snapshot and logging language.

```swift
import XCTest
import XCEasy

class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.yourcompany.app",
            findTimeout: 15,
            actionTimeout: 10,
            assertionTimeout: 5,
            requestTimeout: 30,
            actionPolicy: .hittable,
            localization: .en,
            deeplinkSchema: "myapp",
            printLogToConsole: true,
            uiQueryEvidenceLevel: .basic,
            uiQueryAmbiguityPolicy: .strict,
            visibilityPolicy: .onScreen,
            performance: .init(
                level: .basic,
                defaultBudgetMilliseconds: 2_000,
                operationBudgetsMilliseconds: ["ui.tap": 1_000],
                budgetPolicy: .observe
            ),
            healing: .init(
                mode: .observe,
                minimumConfidence: 0.75,
                minimumScoreGap: 0.12
            ),
            diagnosticSnapshotByteLimit: 512_000
        )

        // Call this after custom settings so XCEasy logs the effective configuration.
        super.configuration()
    }
}
```

## Core properties

| Property | Default | Purpose |
|---|---:|---|
| `bundleId` | `""` | Bundle ID of the tested app. An empty value uses the regular `XCUIApplication()` for the current UI-test target. |
| `findTimeout` | 10 s | How long positive element lookups wait when an operation uses the locator timeout. |
| `actionTimeout` | 10 s | Default wait for actions and Boolean state checks. |
| `assertionTimeout` | 10 s | Default wait for UI assertions. A negative assertion waits for the expected absence until this timeout. |
| `requestTimeout` | 10 s | Timeout for `ApiManager` HTTP requests. |
| `actionPolicy` | `.hittable` | Default for `tap`, `doubleTap`, `press`, `swipe`, `typeText`, and `clearField`. `.hittable` waits for safe semantic dispatch; `.displayed` waits for display and uses coordinate dispatch with warning diagnostics. |
| `localization` | `.en` | Standard step and message language: `.en` or `.ru`. It does not affect identifiers. |
| `deeplinkSchema` | `DEFAULT_DEEPLINK_SCHEMA` | The part before `://`, such as `myapp` for `myapp://settings`. |
| `printLogToConsole` | `true` | `true` mirrors framework logs to the Xcode console; files and Allure artifacts are still persisted independently. |
| `diagnosticSnapshotByteLimit` | 65,536 | Maximum bytes for one accessibility-tree snapshot. `0` disables snapshot contents; a smaller limit reduces artifacts but leaves less debugging evidence. |

`apply` changes only supplied values: `nil` means “keep the current value.” A derived test class can override one setting without copying the complete base configuration. Values are snapshotted per test execution and do not leak into neighboring parallel tests.

## Action policy and language

| Value | Behavior |
|---|---|
| `actionPolicy: .hittable` | Safe default. The action waits for `isHittable` and invokes the semantic XCUI action. An overlay or invalid hit point produces a diagnosed failure. |
| `actionPolicy: .displayed` | Compatibility mode. The action waits for a visible frame and dispatches through coordinates. It may hit an overlay, so XCEasy emits a warning. |
| `localization: .ru` | Russian standard step titles and messages. |
| `localization: .en` | English standard step titles and messages; the default. |

Override the policy for one operation with `icon.tap(policy: .displayed)`. This does not alter other actions.

## `uiQueryEvidenceLevel`

| Value | Evidence |
|---|---|
| `.off` | Does not emit `ui.query.*` events. Lookup behavior and normal action/assertion logs remain active. |
| `.basic` | Recommended default: state, locator, timing, and match count; candidate details are collected for failures and ambiguity. |
| `.detailed` | Adds bounded candidate information to every lookup. Useful for difficult diagnosis but produces more data. |

## `uiQueryAmbiguityPolicy`

| Value | Multiple-match behavior |
|---|---|
| `.strict` | Default. Fails so the test cannot accidentally interact with the wrong element. Refine the locator or set `index`. |
| `.permissive` | Uses the first element and emits a diagnostic warning. Enable deliberately. |

## `visibilityPolicy`

| Value | When an element is displayed |
|---|---|
| `.onScreen` | Default. The element frame must intersect the application frame. This is the normal UIKit and SwiftUI choice. |
| `.nonEmptyFrame` | Any finite, nonempty frame is accepted, even outside the viewport. Use only with unusual accessibility bridges that report an unreliable viewport. |

## `performance`

- `level: .off` disables timing evidence;
- `.basic` records operation duration and aggregate statistics;
- `.detailed` includes available operation phases;
- `defaultBudgetMilliseconds` is the fallback limit; `nil` means no limit;
- `operationBudgetsMilliseconds` provides per-code limits such as `ui.tap`, `ui.query`, and `test.step`; overrides win over the default;
- `budgetPolicy: .observe` records a violation only;
- `.warn` emits a warning without failing;
- `.fail` explicitly fails the test when a budget is exceeded.

Start with `.observe`, collect a baseline on a stable environment, and only then introduce warnings or failures.

## `healing`

Self-healing never changes source code while a test is running.

- `mode: .observe` retains evidence but produces no locator replacement proposal;
- `.suggest` may create a reviewable proposal for a suitable candidate;
- `minimumConfidence` is the minimum best-candidate score from `0` to `1`;
- `minimumScoreGap` is the minimum lead over the second candidate from `0` to `1`.

A human or a separately approved automation workflow must verify any proposal.

## Allure link configuration

`XCEasyAllureConfig` stores patterns for standard Allure link types. They are used by `issue(_:)` and `tms(_:)` and do not affect local `allure-results` generation.

```swift
override func configuration() {
    XCEasyAllureConfig.apply(linkPatterns: [
        "issue": "https://jira.example.com/browse",
        "tms": "https://testops.example.com/testcase"
    ])
    super.configuration()
}
```

## Log and report output

Calling `super.configuration()` creates `Setup → Test Configuration`, where effective values are emitted:

```text
Setup
  Test Configuration
    Basic XCEasy configuration
      assertionTimeout: 5.0
      actionPolicy: hittable
      localization: en
      performance.level: basic
      performance.budgetPolicy: observe
```

Configuration is isolated per execution. Do not place secrets in public names or URLs; launch environment and HTTP headers are intended for sensitive runtime values, and redaction still applies.
