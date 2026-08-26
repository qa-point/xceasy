# F03 — Assertions and steps

0.1.0 status: implemented and verified.

## Goal

Provide one contract for assertions and business steps with precise expected/actual data, correct nesting, and reproducible failure semantics.

## As-is

- Public assertions cover Boolean, equality/inequality, strict and inclusive comparisons, String/Collection containment, optional, empty, and throwing closures.
- UI assertions separately cover tree presence, on-screen display, hidden, selection, enabled, hittable, label, value, and transitions.
- Sync and async `given/when/then/and` wrap generic sync/async `step<T>`, preserve return values and thrown errors, and propagate execution state across suspension.
- Deferred failures and the observer attempt to preserve trees across XCTest interruption.
- Framework step/assert messages are localized in RU/EN.
- `softly` transparently routes regular value, UI, component, and collection assertion mismatches into execution-scoped bounded storage. Individual assertion steps remain failed, later checks continue, and the scope reports one redacted aggregate XCTest issue.

## Requirements

- `F03-REQ-001`: the assertion model stores matcher, expected, actual, target, timeout, and elapsed separately.
- `F03-REQ-002`: hard/soft behavior is explicit and consistent across general/UI assertions.
- `F03-REQ-003`: each step has ID, parent ID, source location, start/stop, and terminal status.
- `F03-REQ-004`: a throw/issue in a nested step marks the causal deepest step and ancestors without duplication.
- `F03-REQ-005`: localization changes rendered text, never canonical event/error codes.
- `F03-REQ-006`: custom descriptions do not replace canonical selector/operation evidence.
- `F03-REQ-007`: invalid matcher input yields a typed failure.
- `F03-REQ-008`: every built-in framework action and assertion automatically emits a step without requiring the user to wrap it in `step {}`.
- `F03-REQ-009`: the built-in operation catalog includes at least element lookup/observation, tap and press variants, text entry and clearing, swipe/scroll, value/state reads, waits, assertions, application launch/termination, orientation, clipboard, deep-link, and API operations supported by the public framework.
- `F03-REQ-010`: one canonical operation event drives both its Allure step and ordinary framework log entry so their status, duration, target, and failure reason cannot diverge.
- `F03-REQ-011`: built-in step titles and log messages are rendered from versioned localization templates with named parameters; public operation code contains no hard-coded user-facing sentence.
- `F03-REQ-012`: default templates produce concise human-readable sentences containing semantic operation, safe target description, outcome, and duration where known; raw selector diagnostics remain structured details rather than replacing the title.
- `F03-REQ-013`: user-defined business steps may contain automatic built-in steps; nesting and verbosity policy are configurable without disabling canonical events or timing data.
- `F03-REQ-014`: success, failure, timeout, skipped, and retry rendering use the same localization catalog while canonical operation/status/reason codes remain language-independent.
- `F03-REQ-015`: `softly` uses the existing assertion syntax without a collector parameter; it never converts actions, configuration errors, or framework failures into soft outcomes.
- `F03-REQ-016`: each assertion mismatch inside `softly` marks its own Allure step and all enclosing steps failed while the block continues and emits exactly one aggregate XCTest issue at scope exit.

## Default rendering examples

For English locale, representative titles are `Tap “Close”`, `Enter text into “Email”`, `Verify that “Promo banner” does not exist in the tree`, and `Verify that “Checkout” is displayed on screen`. The Russian catalog renders the equivalent `Нажать «Закрыть»`, `Ввести текст в «Email»`, `Проверить, что «Промо-баннер» отсутствует в дереве`, and `Проверить, что «Оформление заказа» отображается на экране`.

Sensitive values are never interpolated. A target uses, in order, an explicit semantic POM name, a localized accessibility label when safe, or a bounded normalized locator description. Localization affects presentation only; the event still contains stable fields such as `operation_code`, `target_id`, `status_code`, `reason_code`, and `duration_ms`.

Exact contracts for `does not exist`, `not displayed`, `hidden`, `not hittable`, and `disappears` are defined in [F11](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_EN.md).

## Acceptance criteria

- A unit matrix covers pass/fail/optional/boundary cases for every matcher.
- Golden tests verify nested-step trees for success, throw, and XCTest issue.
- One failure does not produce duplicate logical root failures.
- Structured events reconstruct the Given/When/Then tree without text parsing.
- Every built-in operation appears out of the box in both the per-test framework log and the owning Allure result with matching status and duration.
- Golden tests cover every built-in operation template in RU and EN, missing parameters, pluralization where used, and deterministic fallback.
- Changing report locale changes rendered titles but leaves canonical structured events byte-equivalent except for presentation fields.

## Decisions

- `F03-DEC-001`: async/throwing GWT and component steps use the same task-propagated execution context and preserve generic return values.
- `F03-DEC-002`: soft assertions are explicit through parameterless-closure `softly`; detailed failures are bounded to 50 by default, excess failures remain counted, and the old public collector API is removed before production release.
