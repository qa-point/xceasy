# Failure investigation playbook

English · [Русский](../../ru/guide/16_FAILURE_INVESTIGATION_PLAYBOOK_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Diagnostics](13_LOGS_DIAGNOSTICS_PERFORMANCE_EN.md)

Use this playbook for the first 5–10 minutes after an XCEasy test fails. Its purpose is to identify the first causal failure, classify it, and preserve the smallest useful evidence set. It does not replace a product incident process or the formal [reporting contract](../spec/04_REPORTING_AND_AI_DIAGNOSTICS_EN.md).

## Before you start

Analyze one test attempt at a time. Use its unique `executionId`; do not combine files from retries, shards, devices, or neighboring parameterized cases. Record the test name, attempt, device, OS, app build, Xcode/toolchain, and execution mode before comparing the result with another run.

The default `.basic` query-evidence level is appropriate for normal local and CI runs. An `.off` run has fewer UI-query artifacts, while `.detailed` adds candidate evidence for successful queries and should be used for a controlled rerun when the original evidence is insufficient.

## First-pass workflow

### 1. Start with the failed Allure branch

Open the failed test and expand the deepest failed or broken step. Record:

- operation and target;
- expected and actual/final state;
- elapsed time;
- source file and line when present;
- the first useful error message.

Do not start from a teardown or reporting error merely because it appears last. An interrupted operation may produce later cleanup messages after the causal failure.

### 2. Compare the screenshot with the UI hierarchy

Use the screenshot to understand what a person would have seen. Use `Redacted UI hierarchy` to check the accessibility state that XCUI could query.

For a failed XCEasy UI query or component-collection observation with query evidence enabled, XCEasy captures the current application `debugDescription`, redacts it, limits it to `diagnosticSnapshotByteLimit`, and attaches it to the test result. The producing diagnostic event links the same artifact. This is an application accessibility hierarchy, not a pixel-perfect description of visual occlusion.

The hierarchy is not guaranteed when:

- the failure did not pass through an XCEasy UI query, for example a plain value `XCTAssert` failure;
- query evidence was `.off`;
- the application context was unavailable;
- artifact writing failed.

A foreground application window is also required for a failure screenshot. The observer attaches an available XCTest-issue screenshot to the test and to the last failed step, or to the deepest known step as a fallback. A launch/context failure can therefore legitimately have no screenshot.

If the hierarchy looks incomplete, inspect the diagnostic manifest. `truncated: true` means the configured byte limit cut the snapshot; it does not mean that XCUI returned a complete tree.

### 3. Find the first causal event

Open `<executionId>_events.jsonl` and find the earliest relevant operation with `statusCode: "failed"` or an error-level event. Follow `parentOperationId` toward the containing action, assertion, or user step and compare:

- `operationCode` and `reasonCode`;
- locator chain in `selector`;
- `queryEvidence.expectedState` and `finalState`;
- attempts, duration, candidate count, selected index, and failed segment;
- source location and linked attachments.

The localized Allure title is presentation text. Use stable operation and reason codes when grouping failures or passing evidence to automation.

### 4. Use the log as the chronological narrative

Read `<testId>_xceasy_log.log` around the causal operation. The log is useful for setup, preceding business steps, API preparation, relaunches, and cleanup. Treat it as supporting evidence; use JSONL and artifact references for machine correlation.

### 5. Check bundle integrity

Open `<executionId>_diagnostic-manifest.json` and verify that referenced artifacts exist. Use its MIME type, byte count, SHA-256, producer event, privacy classification, and truncation flag to distinguish a deliberately bounded artifact from a missing or changed one.

Telemetry or attachment failures must remain visible, but they do not replace the original test outcome. Record both the causal test failure and the evidence failure.

## Symptom guide

| Symptom | Check first | Likely directions |
|---|---|---|
| No matching element | Locator chain, failed segment, final hierarchy, app state, screenshot | Wrong screen/precondition, changed identifier, element not exposed to accessibility, product UI absent. |
| Multiple matches in `.strict` mode | Candidate count and bounded candidates | Identifier is not unique, scope is too broad, repeated component needs explicit selection. |
| Element exists but is not displayed or hittable | Final state, frame/viewport evidence, screenshot, action policy | Off-screen element, overlay, disabled control, wrong readiness expectation. XCUI geometry does not prove complete visual occlusion. |
| Wait or action timed out | Attempts, observation timeline, duration, preceding operation | Product transition did not happen, unstable locator/state, backend delay, blocked UI. Do not raise the timeout before identifying which state remained unchanged. |
| Application did not launch or no window exists | Setup/launch events, app state, simulator and toolchain logs | Application crash/configuration, simulator/infrastructure, unsupported environment. Missing screenshot can be expected here. |
| Plain value assertion failed | Assertion expected/actual, source, log and events | Product data or test expectation. A UI hierarchy may be absent because no UI query failed. |
| Teardown or reporting error appears last | Earlier failed operation and parent chain | Usually secondary cleanup/evidence failure; preserve it without replacing the first cause. |
| Artifact is missing or hash/size differs | Manifest entry and telemetry errors | Incomplete collection, changed artifact, framework/reporting defect, or external modification. |
| Performance budget failed | Performance evidence and compatible baseline | Real slowdown, incompatible environments, noisy threshold, or heavy diagnostics. Compare only compatible runs. |

## Classify the result

Choose one classification and cite the evidence that supports it:

| Classification | Use when |
|---|---|
| Product | The observed application behavior violates the expected product contract while the test preconditions and locator intent remain valid. |
| Test | The selector, setup, test data, ordering assumption, or expected result is stale or incorrect. |
| Infrastructure | The simulator/device, Xcode/toolchain, network dependency, signing, installation, or host prevented a valid execution. |
| Framework | XCEasy lifecycle, lookup semantics, step status, serialization, isolation, redaction, or artifact ownership is incorrect. |
| Unknown | Available evidence cannot distinguish the alternatives. State what artifact or controlled rerun is required next. |

Do not relabel an intermittent failure as infrastructure only because a rerun passed. Compare fingerprints, timelines, environment keys, and application state first.

## When evidence is insufficient

Rerun only after preserving the original execution. Keep the same app build, test data, simulator/device class, and toolchain when possible. For a locator investigation, change only the evidence level:

```swift
override func configuration() {
    XCEasyConfig.apply(
        uiQueryEvidenceLevel: .detailed,
        uiQueryAmbiguityPolicy: .strict,
        diagnosticSnapshotByteLimit: 512_000
    )
    super.configuration()
}
```

Increasing `diagnosticSnapshotByteLimit` can preserve more of a large hierarchy, but also increases artifact size. `.detailed` changes diagnostic overhead, so do not use that rerun as a performance comparison with a `.basic` run.

Never add production tokens, passwords, cookies, personal data, or raw network bodies to improve diagnostics. Redaction is a safety layer, not authorization to export artifacts.

## Handoff package

For another engineer or an approved AI workflow, provide one execution-scoped package:

- test name, `testId`, `executionId`, attempt, and source location;
- device/OS, app build, Xcode/toolchain, and execution mode;
- failed Allure branch and status details;
- diagnostic summary, reproduction note, manifest, and JSONL;
- linked screenshot, UI hierarchy, candidate evidence, and log;
- your classification, evidence, and remaining hypothesis;
- exact reproduction/verification command when known.

Before any external transfer, review privacy classification and team policy. Do not mix artifacts from separate attempts or remove correlation identifiers.

## Completion checklist

The first-pass investigation is complete when:

- the first causal operation is identified, or the missing evidence is named;
- product, test, infrastructure, framework, or unknown is recorded;
- screenshot and hierarchy availability or absence is explained;
- manifest truncation/integrity has been checked;
- the next action is specific: product fix, test fix, environment recovery, framework defect, or controlled rerun;
- no build, test, or fix is claimed without an actual successful verification command.
