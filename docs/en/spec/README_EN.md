# XCEasy Specification

Status: active versioned contract 0.1.1. Reconciled with source: August 27, 2026.

The specification is split by feature. Each status explicitly separates production behavior from partially implemented or planned requirements.

## Feature map

| ID | Feature | 0.1.1 status | Components |
|---|---|---|---|
| F01 | [Lifecycle and test context](01_LIFECYCLE_AND_CONTEXT_EN.md) | Implemented and verified | test case, app, observer, context |
| F02 | [UI elements and interaction](02_UI_INTERACTION_EN.md) | Implemented and verified | lazy lookup, actions, Device |
| F03 | [Assertions and steps](03_ASSERTIONS_AND_STEPS_EN.md) | Implemented and verified | value/UI assertions, GWT, soft assertions |
| F04 | [Reporting and AI diagnostics](04_REPORTING_AND_AI_DIAGNOSTICS_EN.md) | Implemented; retention/schema window is a policy boundary | Allure, JSONL, manifests |
| F05 | [Networking and runtime configuration](05_NETWORKING_AND_RUNTIME_CONFIGURATION_EN.md) | Partial: runtime API ready; full typed validation/cancellation taxonomy remains open | API, config, launch, deep links |
| F06 | [Delivery and quality](06_DELIVERY_AND_QUALITY_EN.md) | Release contract implemented; publication needs maintainer authority | SPM, Tuist, CI, release |
| F07 | [Allure lifecycle and compatibility](07_ALLURE_LIFECYCLE_EN.md) | Implemented and verified | identity, fixtures, attachments |
| F09 | [Self-healing and test generation](09_SELF_HEALING_AND_TEST_GENERATION_EN.md) | Partial: controlled healing ready; full test-generation acceptance remains open | evidence, provider adapter, safeguards |
| F10 | [Performance telemetry and optimization](10_PERFORMANCE_TELEMETRY_EN.md) | Implemented; project thresholds belong to user/CI | timings, baselines, budgets |
| F11 | [UI element state and negative assertions](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_EN.md) | Implemented and verified | absent, hidden, displayed, transitions |
| F12 | [Reusable UI components and POM](12_REUSABLE_COMPONENT_POM_EN.md) | Implemented and verified | components, collections, nested steps |
| F13 | [Test coverage and quality gates](13_TEST_COVERAGE_EN.md) | Implemented; diff coverage deferred | unit/UI coverage, CI policy |
| F14 | [Parameterized test executions](14_PARAMETERIZED_TEST_EXECUTION_EN.md) | Implemented and verified | datasets, independent cases |
| F15 | [UI action readiness policy](15_UI_ACTION_POLICY_EN.md) | Implemented and verified | action policy, waits, dispatch |
| F16 | [Allure metadata annotations](16_ALLURE_METADATA_ANNOTATIONS_EN.md) | Implemented and verified | macros, manifest, runtime parity |
| F17 | [Custom markers](17_CUSTOM_MARKERS_EN.md) | Implemented and verified | markers, Allure labels, manifest |

## Requirement rules

- `AS-IS`/implemented baseline is supported by current source/tests; runtime evidence level is stated in status and acceptance evidence.
- `REQ` is mandatory target behavior; `SHOULD` is recommended; `OPEN` is unresolved.
- IDs are stable and referenced by issues, tests, PRs, and telemetry fixtures.
- Requirement changes update RU/EN together and include migration impact.
- The constitution takes precedence over this specification.

## Shared Definition of Done

A feature is complete when its acceptance criteria pass, unit/integration/contract tests exist, public API and RU/EN docs agree, privacy is verified, and CI proves the supported toolchain matrix. A deliberately deferred criterion remains open and is not considered implemented.
