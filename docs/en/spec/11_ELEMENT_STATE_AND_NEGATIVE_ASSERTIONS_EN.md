# F11 — UI element state and negative assertions

0.1.0 status: implemented and verified on UIKit/SwiftUI fixtures.

## Goal

Lookup and assertions must work correctly when an element is absent from the accessibility tree. Expected absence is not a lookup error. The framework must distinguish absence, invisibility, non-interactability, and state transitions.

## Motivating scenario

A screen contains a banner with a close button. After tapping it, the application may:

1. remove the banner from the accessibility tree;
2. retain it in the tree but hide it;
3. leave it visible but non-hittable;
4. animate and remove it later;
5. fail to remove it because of a product defect.

Assertions must report exactly which result was observed and must not fail merely because an expected-absent element cannot be found.

## Implemented baseline

- `find(...)` and `child(...)` create lazy immutable locator intent; negative assertions observe absence directly without a preliminary positive wait.
- Explicit `absent`, `hidden`, `visible`, `hittable`, `enabled`, and `selected` observations and `assertDisappears(after:)` are implemented with fresh root-to-child resolution on every poll.
- Query schema `1.0.0` records expected/initial/final state, elapsed time, attempts, matching count, failed segment, ancestor state, a bounded state timeline, canonical reasons, source/correlation data, and candidate-collection policy. Already-absent root and child-under-absent-ancestor are distinct successful results.
- An existing selected element overrides a transiently stale `query.count == 0`, preventing false `ancestor_absent` evidence.
- Ambiguity is strict by default (`query.ambiguous_match`); explicitly selected permissive mode uses the first match and emits bounded evidence. `assertBecomesHidden(timeout:after:)`, transition timelines, failure screenshot/debug-tree capture, and per-test artifact linkage are implemented. Visibility is calibrated by a pure geometry matrix representing UIKit, SwiftUI, and WebView descendants. Snapshot-overhead measurement remains performance work rather than a state-semantics gap.

## Terms and states

- Locator: immutable query description; creating it does not access UI and cannot fail the test.
- Observation: timestamped result of executing a locator and reading state.
- `absent`: the element does not exist in the current accessibility snapshot (`exists == false`).
- `present`: `exists == true`, regardless of visibility or hittability.
- `visible`: present with a finite non-empty frame intersecting the current application viewport under default `.onScreen` policy. XCUI cannot reliably prove complete occlusion by another view.
- `hidden`: present but not matching the accepted visibility predicate.
- `hittable`: XCUI `isHittable == true`; interactability is not synonymous with visibility.
- `enabled`: present and XCUI `isEnabled == true`.
- `selected`: present and XCUI `isSelected == true`.
- `disappeared`: a `present → absent` transition observed within one transition assertion.

## Architecture contract

- `F11-REQ-001`: `find(...)` returns a locator/proxy without implicit wait or warning/error logging.
- `F11-REQ-002`: query construction is separate from observation; observation receives the expected predicate and one deadline.
- `F11-REQ-003`: positive actions/assertions may wait for `present`; negative assertions never pre-wait for `present` unless the contract requires a transition.
- `F11-REQ-004`: all polling shares one monotonic deadline; nested resolve/state checks never multiply timeout.
- `F11-REQ-005`: observations contain locator, expected state, final state, reason code, elapsed, attempts, first/last snapshots, and candidate count.
- `F11-REQ-006`: an absent element is the `absent` value, not a thrown/fatal lookup error.
- `F11-REQ-007`: invalid locator, unavailable app/context, and XCUI query failure are distinct from valid `absent`.
- `F11-REQ-008`: logs/Allure/JSONL use canonical reason codes rather than deriving meaning from localized text.
- `F11-REQ-025`: a resolved element and its state are scoped to one observation attempt only; the next attempt or semantic operation resolves the immutable locator again against the current tree.
- `F11-REQ-026`: transition assertions retain state values, timestamps, and bounded evidence, never a resolved element handle as the source of later observations.
- `F11-REQ-027`: `waitForDisplayed(timeout:)`, `waitForHittable(timeout:)`, `waitForEnabled(timeout:)`, and `waitForSelected(timeout:)` use one monotonic deadline, return `true` immediately after reaching the state, and return `false` after timeout without an XCTest failure.
- `F11-REQ-028`: callers may ignore a non-asserting wait result, but timeout still leaves canonical query evidence; an unavailable application context safely returns `false` instead of creating a synthetic XCUI object or Objective-C exception.

## Public assertions

### Final-state assertions

- `F11-REQ-009`: `assertExists(timeout:)` passes when observation reaches `present`.
- `F11-REQ-010`: `assertDoesNotExist(timeout:)` passes when observation reaches `absent`, including already absent on the first attempt.
- `F11-REQ-011`: `assertIsDisplayed(timeout:)` requires presence and an internal `visible` or `hittable` state.
- `F11-REQ-012`: `assertIsNotDisplayed(timeout:)` accepts `absent` or `hidden` and explicitly reports which occurred.
- `F11-REQ-013`: `assertIsHidden(timeout:)` requires `present + hidden`; `absent` fails because tree presence is part of the contract.
- `F11-REQ-014`: `assertIsHittable(timeout:)` requires `present + hittable`.
- `F11-REQ-015`: `assertIsNotHittable(timeout:)` accepts `absent` or `present + non-hittable` and explicitly reports the reason.

### State-transition assertions

- `F11-REQ-016`: `assertDisappears(timeout:)` passes only after observing `present → absent` within the assertion window.
- `F11-REQ-017`: if the first observation is already `absent`, `assertDisappears` fails with `transition_initial_state_not_observed` instead of claiming proven disappearance.
- `F11-REQ-018`: `assertBecomesHidden(timeout:)` requires `visible → hidden`; removal from the tree does not satisfy this narrow contract.
- `F11-REQ-019`: transition assertions retain a timeline of observed state changes and link it to the triggering step/action when known.

## Naming

The public API uses the canonical names `assertExists`, `assertDoesNotExist`, `assertIsDisplayed`, `assertIsNotDisplayed`, `assertIsHidden`, and `assertDisappears`.

## Logging and performance telemetry

- `F11-REQ-020`: successful negative assertions log success, never a “not found” warning.
- `F11-REQ-021`: results include `initial_state`, `final_state`, `matched_reason`, and `duration_ms`.
- `F11-REQ-022`: performance spans separate query evaluation, polling wait, and snapshot collection.
- `F11-REQ-023`: timeout captures last observation, UI snapshot, and screenshot; immediate expected absence creates no heavy artifacts by default.
- `F11-REQ-024`: an ambiguous query is not absence; strict mode yields `ambiguous_match` even for a negative assertion when unexpected candidates exist.

## API example

A non-asserting wait for optional UI:

```swift
if find(identifier: "optionalBanner").waitForDisplayed(timeout: 2) {
    find(identifier: "optionalBanner.closeButton").tap()
}

guard find(identifier: "submit").waitForHittable(timeout: 5) else { return }
guard find(identifier: "submit").waitForEnabled(timeout: 5) else { return }

find(identifier: "filterChip").tap()
guard find(identifier: "filterChip").waitForSelected(timeout: 2) else { return }
```

A final-state assertion:

```swift
let banner = find(identifier: "promoBanner")

banner.assertExists()
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5)
```

When the transition itself must be proven:

```swift
let banner = find(identifier: "promoBanner")
banner.assertDisappears(timeout: 5) {
    find(identifier: "promoBanner.closeButton").tap()
}
```

The closure form links the triggering action and transition timeline within one operation.

For reusable component POMs, container/child semantics and the recommended `closeAndAssertGone` are defined in [F12](12_REUSABLE_COMPONENT_POM_EN.md).

## Acceptance criteria

- An already absent element immediately passes `assertDoesNotExist` without waiting for find timeout.
- An element disappearing after animation passes once `absent` is observed within one deadline.
- An element remaining present at timeout fails with last state and evidence, not “not found”.
- `assertDisappears` fails when the element was already absent before the transition began.
- `assertIsNotDisplayed` distinguishes `absent` and `hidden`; `assertIsHidden` does not pass for absent.
- Static text may be visible and non-hittable at the same time.
- Parallel assertions never mix locators, observations, or timelines across tests.
- Performance telemetry reports one real elapsed wait without double timeout.
- The same locator variable can observe `present`, then `absent`, then `present` again as the UI changes; no public variable recreation is required.
- Every poll can observe a tree change made after the preceding attempt.
- A non-asserting wait returns `true` immediately on a match, returns `false` after one timeout, and creates no XCTest failure.
- A non-asserting wait with no application context returns `false` without an XCUI exception.

## Decisions and remaining questions

- `F11-DEC-001`: `.onScreen` is the default visibility policy for UIKit, SwiftUI, and WebView accessibility descendants. Full viewport intersection and partial intersection are high-confidence visible observations; a valid frame outside the viewport is high-confidence hidden. If XCUI does not expose a valid app viewport, the framework accepts a valid element frame with explicit low-confidence `visibility.viewport_unavailable_fallback`. `.nonEmptyFrame` is an explicit medium-confidence compatibility policy.
- `F11-DEC-002`: the primary transition API accepts an `after` action closure so the trigger and observation share one semantic operation.
- `F11-DEC-003`: strict ambiguity is the default; permissive first-match behavior requires explicit configuration.
