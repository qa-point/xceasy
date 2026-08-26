# F15 — UI action readiness policy

0.1.0 status: implemented and verified.

## Goal

Every UI action waits for the state required for safe dispatch. A user can change the execution-scoped default or override one call without changing the Page Object.

## Implemented baseline

- `XCEasyActionPolicy` supports `.hittable` and `.displayed`.
- `XCEasyConfig.actionPolicy` defaults to `.hittable` and belongs to one test-execution snapshot.
- `tap`, `doubleTap`, `press`, `swipe`, `typeText`, and `clearField` accept a `timeout` and optional local `policy`.
- Every action performs a fresh observation of the complete locator chain. On timeout no gesture is dispatched, the test receives a framework failure, and query evidence contains initial/final state and elapsed time.
- `.displayed` emits warning events because coordinate dispatch may interact with a covering overlay.

## Policy contract

- `F15-REQ-001`: `.hittable` is the safe default for every UI action.
- `F15-REQ-002`: `.hittable` waits for `XCUIElement.isHittable == true` and uses the semantic XCUI action.
- `F15-REQ-003`: `.displayed` waits for display according to `XCEasyConfig.visibilityPolicy` and uses coordinate dispatch inside the element frame.
- `F15-REQ-004`: a local `policy` overrides `XCEasyConfig.actionPolicy` for the current call only.
- `F15-REQ-005`: a local `timeout` overrides `XCEasyConfig.actionTimeout` for the current call only.
- `F15-REQ-006`: policy never changes a locator or caches a resolved `XCUIElement` across operations.
- `F15-REQ-007`: failure to reach the expected state before timeout records `ui.action.target_not_ready` and prevents dispatch.

## Action matrix

| Action | `.hittable` | `.displayed` |
|---|---|---|
| `tap` | semantic `XCUIElement.tap()` | tap at the center coordinate |
| `doubleTap` | semantic `XCUIElement.doubleTap()` | double tap at the center coordinate |
| `press` | semantic `XCUIElement.press(...)` | coordinate press at the center |
| `swipe` | semantic direction-specific swipe | coordinate drag between normalized offsets inside the frame |
| `typeText` | semantic tap for focus, then `typeText` | coordinate tap for focus, then `typeText` |
| `clearField` | semantic tap for focus, then delete keys | coordinate tap for focus, then delete keys |

- `F15-REQ-008`: text and icons may be action targets even when a parent view owns the handler; hittable means an available touch coordinate, not handler ownership.
- `F15-REQ-009`: when a child is not a separate accessibility node, the framework does not guess a target; the user addresses the root or the app supplies a stable identifier.
- `F15-REQ-010`: automatic `.hittable` to `.displayed` fallback is prohibited so an overlay or skeleton cannot be hidden by an accidental coordinate action.

## Public API

```swift
public enum XCEasyActionPolicy: String, Codable, Sendable {
    case hittable
    case displayed
}

XCEasyConfig.apply(actionPolicy: .hittable)

tile.title.tap()
tile.icon.tap(timeout: 5, policy: .displayed)
list.swipe(.up, policy: .displayed)
field.typeText("value", policy: .hittable)
field.clearField(policy: .hittable)
```

## Configuration and parallelism

- `F15-REQ-011`: `actionPolicy` is copied into execution configuration at test start and does not leak into a parallel execution.
- `F15-REQ-012`: a suite default is set before parallel execution; exceptions use a local argument instead of mutating the shared default during an action.
- `F15-REQ-013`: effective policy is read when the element is used semantically, not when its locator or POM is created.

## Diagnostics and privacy

- `F15-REQ-014`: every action records operation code, target locator, effective policy, expected state, dispatch type, duration, and correlation IDs.
- `F15-REQ-015`: `ui.action.policy` uses reason `action.policy.hittable` or `action.policy.displayed`.
- `F15-REQ-016`: `ui.action.dispatched` uses reason `action.dispatch.semantic` or `action.dispatch.coordinate`.
- `F15-REQ-017`: `.displayed` policy and coordinate dispatch have warning level even when the action succeeds.
- `F15-REQ-018`: `typeText` never writes input text, and `clearField` never writes the current value to console, JSONL, Allure, or a failure description.
- `F15-REQ-019`: the query observation remains a child operation of the action and contains a state timeline for AI diagnosis.

## Compatibility

The project is not in production. Existing no-argument action calls remain source compatible through default parameters. Removing the F12 required-child API is an intentional beta breaking change: actions now own readiness and composite component readiness uses an explicit POM method.

## Acceptance criteria

- The default action policy is `.hittable`.
- A global `.displayed` value does not change another parallel execution's default.
- A local `.displayed` value does not change global or execution-scoped policy.
- Every action in the matrix compiles with the default and a local policy.
- On readiness timeout there is no dispatch event, the test fails, and the diagnostic query contains expected and final states.
- A successful `.hittable` action records semantic dispatch.
- A successful `.displayed` action records coordinate dispatch and a warning.
- UIKit and SwiftUI samples prove the default tap/type flow and at least one explicit displayed coordinate action.
- Canary input text and field values are absent from every diagnostic artifact.

## Decisions

- `F15-DEC-001`: one policy covers every UI action instead of a dedicated `tapPolicy`.
- `F15-DEC-002`: `.hittable` is the default; `.displayed` is an explicit compatibility mode only.
- `F15-DEC-003`: action readiness belongs to the action API rather than hidden component metadata.
