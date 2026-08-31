# Logs, diagnostics, and performance

English · [Русский](../../ru/guide/13_LOGS_DIAGNOSTICS_PERFORMANCE_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


XCEasy writes data for two audiences at the same time:

- people read the localized `.log` and Allure steps;
- AI or CI tooling reads versioned JSONL and a manifest with stable English codes, without parsing Russian or English prose.

## Files for one test

| File | Contents | Consumer |
|---|---|---|
| `<testId>_xceasy_log.log` | Sequential ANSI-free human log covering test lifecycle, actions, assertions, and errors. | People and an Allure attachment. |
| `<executionId>_events.jsonl` | One JSON event per line: lifecycle, steps, UI queries/actions/assertions, API, and attachments. Its schema is versioned. | AI, CI, and diagnostic tools. |
| `<executionId>_performance-summary.json` | Operation count and duration, min/max/mean/median/p90/p95/p99, and budget findings. | Slowdown detection and run comparison. |
| `<executionId>_diagnostic-summary.json` | Concise failure classification and stable fingerprint. | Grouping equivalent failures. |
| `<executionId>_reproduction.md` | Concise evidence-oriented reproduction description. | A person or AI preparing a fix/test. |
| `<executionId>_diagnostic-manifest.json` | Artifact index with path, MIME type, size, SHA-256, producer, privacy, and truncation metadata. | Bundle completeness and integrity checks. |
| `*-result.json`, `*-container.json`, attachments | Standard Allure test and fixture data. | Allure CLI/TestOps. |

`testId` links repeated runs of the same test, while the unique `executionId` isolates one attempt. Multi-device runs also record `runId`, device, shard, and attempt, so parallel tests do not mix data.

## What an operation records

For a regular tap, assertion, request, or custom step, an event contains available fields such as event type, stable `operationCode`, start/finish status, duration, parent operation, test/execution IDs, and source location. A UI query additionally records its lazy locator chain, expected and final state, timeout, attempts and candidate count, selected index, and reason code. `parentOperationId` relationships reconstruct “test → step → assertion → query”.

`uiQueryEvidenceLevel` controls query-evidence volume. `.basic` collects detailed candidates mainly on failure or ambiguity, while `.detailed` does so for every lookup and therefore costs more time and storage.

## What happens on failure

When possible, XCEasy stores a screenshot, bounded accessibility-tree snapshot, observed-state timeline, up to five matched/alternative candidates, final reason, and a healing proposal. A proposal is only a recommendation: runtime never changes source code or resumes the test with another locator. `diagnosticSnapshotByteLimit` bounds tree data; when content is truncated, the manifest records that fact explicitly.

Redaction runs before console, log, JSONL, and Allure sinks. Values resembling a token, password, Authorization/cookie, or another secret should not enter artifacts. Masked/hidden Allure parameters are replaced before writing. Even so, do not put real production secrets in step names or accessibility identifiers.

For a step-by-step first-cause workflow and a symptom-to-evidence matrix, use the [failure investigation playbook](16_FAILURE_INVESTIGATION_PLAYBOOK_EN.md).

## How to analyze performance

Timing automatically covers `ui.query`, `ui.tap` and other actions, UI/value assertions, API requests, `step`, and fixtures. `performance-summary.json` aggregates matching operation codes so you can distinguish an isolated slow call from a systematic slowdown.

A recommended workflow is:

1. Run a stable suite with `budgetPolicy: .observe` and collect a baseline on the same Xcode, simulator/device, and configuration.
2. Compare median and p95 across compatible runs. A slower `ui.query` often indicates an unstable locator or overloaded accessibility tree, while a slower API operation points toward backend/network behavior.
3. Set `operationBudgetsMilliseconds` when different operations need different normal limits.
4. Move confirmed thresholds to `.warn`; use `.fail` only when exceeding the threshold is truly a test failure.

Do not directly compare different device models, OS versions, or evidence modes without normalization: an environment difference is easy to misclassify as a product regression.

For manual inspection of the current screen:

```swift
find(identifier: "screenRoot").printDebugTree()
```

`printDebugTree()` prints the current tree to the console for local investigation. A normal test should not treat its text as an assertion or a machine-readable contract.

## Choosing diagnostic volume

| Scenario | Recommended setting | Trade-off |
|---|---|---|
| Normal local/CI run | `.basic`, `.strict`, performance `.basic/.observe` | Failure evidence without large success artifacts. |
| Flaky-locator investigation | `uiQueryEvidenceLevel: .detailed` | Candidates for every query; more artifacts and overhead. |
| Lightweight smoke | query evidence `.off`, performance `.off` | Steps/logs remain, but AI receives less context. |
| Performance baseline | performance `.detailed/.observe` | More phase data; budgets do not fail tests. |
| Soft control | `.basic/.warn` plus operation budgets | Warning without functional failure. |
| Hard SLA | `.basic/.fail` plus validated budgets | A slow operation becomes a failure. |

```swift
class DiagnosticBaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            printLogToConsole: true,
            uiQueryEvidenceLevel: .basic,
            uiQueryAmbiguityPolicy: .strict,
            performance: .init(
                level: .basic,
                defaultBudgetMilliseconds: 2_000,
                operationBudgetsMilliseconds: [
                    "ui.query": 1_500,
                    "ui.tap": 1_000,
                    "api.request": 5_000
                ],
                budgetPolicy: .observe
            ),
            healing: .init(mode: .observe),
            diagnosticSnapshotByteLimit: 512_000
        )
        super.configuration()
    }
}
```

## A correlated trace

```swift
func testCloseBanner() {
    step("Dismiss promo banner") {
        let banner = find(identifier: "promoBanner", desc: "Promo banner")
        banner.assertDisappears(timeout: 5) {
            banner.child(identifier: "promoBanner.close", desc: "Close button").tap()
        }
    }
}
```

```text
Dismiss promo banner                         passed  438 ms
  Assert [Promo banner] disappears           passed  431 ms
    Tap [Close button]                       passed   82 ms
      UI query                               passed   21 ms
    UI query: expected absent                passed  341 ms
```

AI sees the same relationships through `operationId`/`parentOperationId`, locator chain, expected `absent`, attempts, terminal state, and timing. On failure, the bundle adds screenshot/tree/candidates and a reason code; tooling need not parse a localized title.

## Performance budgets in practice

Budget lookup uses the exact operation code first and then `defaultBudgetMilliseconds`. `.observe` stores a finding, `.warn` adds a warning, and `.fail` records a failure. `.off` disables timing, so a budget cannot be applied meaningfully.

Do not choose thresholds from one run. Collect several runs on the same device/OS, inspect median and p95, and leave room for noise. UI query and API request almost always need different budgets.

## Safe AI handoff

Provide the manifest, JSONL, reproduction, performance summary, and linked attachments for one execution. Do not mix attempts or remove relationship identifiers. Redaction is a safety layer; still review privacy classification and team policy before external transfer.
