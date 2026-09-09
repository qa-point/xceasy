# Changelog

## [0.1.3] - 2026-09-09

- Update Alamofire to 5.12.0 in the public package and development build; preserve public Swift APIs and telemetry schema 1.0.0.
- Clarify diagnostic privacy policy and agent guidance without changing runtime evidence.

- Harden public CI, pin GitHub Actions, scan secrets, and document private vulnerability reporting.

All notable XCEasy changes are documented here. The project follows Semantic Versioning after the `0.1.0` contract baseline.

## [0.1.2] - 2026-09-07

### Changed

- Documented failure investigation, the supported toolchain, and current API contracts in English and Russian.
- Added a logo concept and aligned lint and public API validation tooling.
- Installed ripgrep explicitly for hosted contract checks.
- Preserved the 0.1.1 public API and runtime behavior.

## [0.1.1] - 2026-08-27

### Fixed

- Made scoped `assertDoesNotExist` observations safe when the last matching child disappears, avoiding an XCTest query-count failure after the expected absent state is reached.

## [0.1.0] - 2026-08-26

### Changed

- Added the `xceasy.device_type` Allure label for simulator/physical correlation supplied by XCEasy Runner 0.1.0.
- Split public UIKit and SwiftUI examples into the independent `xceasy-examples` repository and replaced the former hybrid sample with an internal integration fixture used only by framework CI and coverage.
- Extracted multi-simulator selection, sharding, recovery, aggregation, and run-level diagnostics into the independently versioned `xceasy-runner` repository; XCEasy retains per-test correlation and artifact emission only.
- Prevented failure-evidence capture from requesting an XCUI screenshot before the application window exists, avoiding recursive XCTest issues during launch failures.
- Added macro-first Allure metadata compatible with Android naming, including class defaults, method metadata, standard links, flaky/muted flags, and runtime API parity.
- Added `@ParameterizedTest` inline typed datasets that compile into independently selectable XCTest methods with redacted Allure parameters and canonical history identity.
- Added universal `@Marker`, consumer-defined literal marker aliases, and versioned build-artifact metadata consumed by external tooling.
- Replaced unpublished `desc`/`jira` and Jira-specific base URLs with `description`/`issue` and standard Allure link patterns.
- Replaced the unpublished `XCEasySoftAssertions` collector API with transparent execution-scoped `softly { ... }`: existing value, UI, component, and collection assertions now aggregate while retaining failed nested Allure steps; actions and framework errors remain hard.
- Renamed the unpublished component locator API from `container`/`collectionContainer` to the clearer `element`/`collection` pair without compatibility aliases; Allure result containers and telemetry selector fields are unchanged.
- Replaced ambiguous UI names `assertIsVisible`/`assertIsNotVisible` with explicit `assertIsDisplayed`/`assertIsNotDisplayed`; tree presence remains `assertExists`/`assertDoesNotExist`.
- Expanded value assertions with strict comparisons, collection containment, empty-state, and throwing-closure checks and normalized names such as `assertEqual` and `assertLessThan`.
- Removed the duplicate global launch DSL in favor of the thread-safe `LaunchArgumentsManager` and `LaunchEnvironmentManager` API.
- Simplified deep links to `Deeplink.open("/path", name: ...)`, removing the route wrapper.
- Made `ApiManager` honor the execution-scoped `XCEasyConfig.requestTimeout` instead of an old hard-coded 30-second value.
- Expanded the RU/EN README into a complete usage reference and added the F14 specification for independent parameterized XCTest executions.
- Simplified `XCEasyComponent` to element-only semantics and removed the unpublished `requiredChildren` descriptor API.
- Added execution-scoped `XCEasyActionPolicy` for every UI action: safe `.hittable` semantic dispatch by default and explicit `.displayed` coordinate dispatch with warning diagnostics.
- Added non-asserting `waitForDisplayed(timeout:)`, `waitForHittable(timeout:)`, `waitForEnabled(timeout:)`, and `waitForSelected(timeout:)` for UI and component elements; they return `Bool`, preserve timeout diagnostics, and safely handle an unavailable application context.
- Replaced the beta `XCEasyComponent.root`/`container` contract with `element`, replaced `componentStep` with a component-aware overload of `step`, added optional instance naming at POM initialization, and introduced `XCEasyIndexedComponent` with explicit zero-based conveniences. Component steps keep the ordinary sync/async Allure hierarchy and emit structured `component.step` diagnostics.
- Rebuilt the unpublished component collection API around `XCEasyComponentCollection<Component>()`, lazy `first`/`last`/`get` access, and explicit count, emptiness, and all-displayed waits/assertions. Every operation adds a localized default Allure step and schema-1.0.0 `collectionEvidence`; invalid indices and empty-last selection fail diagnostically without XCUI traps.
- Defined the initial canonical diagnostic event schema `1.0.0`, including symbolic selector selection and bounded collection observations for human and AI-assisted debugging.

These source-breaking changes intentionally replace the unpublished beta API instead of retaining deprecated aliases.

### Added

- Lazy reusable component locators and absence-safe UI assertions.
- Per-test Allure results, structured AI diagnostics, attachments and performance telemetry.
- Per-test execution correlation fields consumed by external orchestration tools.
- Controlled self-healing proposals with explicit review, patch and verification boundaries.
- Provider-neutral healing command adapter with timeout, evidence-only response validation, and no mutation or approval authority.
- Task-local, lock-protected execution isolation validated under Thread Sanitizer.
- Async GWT/component steps, aggregate soft assertions, required-child component contracts, lazy indexed component collections, and calibrated visibility policies.
- Unit/UI coverage policy, public Swift-interface compatibility baseline and clean SPM consumer checks.

### Compatibility

- Minimum deployment target: iOS 15.
- Validated toolchain: Xcode 26.6 and Swift 6.3.3.
- Diagnostic event schema: `1.0.0`.
- Runtime source mutation remains disabled; host-side healing application requires explicit approval.
