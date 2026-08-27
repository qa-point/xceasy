# F16 — Allure metadata annotations

0.1.1 status: implemented. Compile-time annotations and parameter metadata are resolved before `setUp`; runtime alternatives remain supported.

## Goal

Offer familiar, separate Allure annotations for XCTest while keeping an equivalent runtime API. The default documentation path uses annotations; tests that cannot use macros continue to work with ordinary functions.

## Canonical annotation surface

The naming and semantics follow Allure Kotlin/JUnit 4 Android where a direct equivalent exists:

- class and method: `@DisplayName`, `@Epic`/`@Epics`, `@Feature`/`@Features`, `@Story`/`@Stories`, `@Owner`, `@Severity`, `@Tag`/`@Tags`, `@Issue`/`@Issues`, `@TmsLink`/`@TmsLinks`, `@Link`/`@Links`, `@Flaky`, and `@Muted`;
- method only: `@Description`, `@AllureId`, and `@Lead`;
- XCEasy-only execution annotation: `@ParameterizedTest`, specified by F14.

`@Step` and `@Attachment` are deliberately absent. XCEasy already owns automatic action/assertion steps, the ordinary `step(...)` function, and runtime attachment functions. `@Jira`, `@Tms`, `@Suite`, `@Manual`, `@Known`, `@Param`, and `@AllureParameter` are not part of the annotation contract.

## Requirements

- `F16-REQ-001`: every supported annotation has a public Swift macro declaration, compile-time placement/value validation, DocC, and expansion tests.
- `F16-REQ-002`: static class/method metadata is stored in a deterministic generated manifest keyed by the canonical XCTest scenario/method identifier and is available before `setUp` starts.
- `F16-REQ-003`: `@DisplayName` on a class defines the readable suite name; on a method it defines the test result name without changing stable identity.
- `F16-REQ-004`: `@AllureId` writes the standard `AS_ID` label and never replaces XCEasy's internal `testCaseId`.
- `F16-REQ-005`: `@Issue` writes link type `issue`; `@TmsLink` writes link type `tms`; generic `@Link` preserves name, URL, and optional type.
- `F16-REQ-006`: `@Flaky` and `@Muted` set the corresponding Allure `statusDetails` flags rather than custom labels.
- `F16-REQ-007`: class metadata acts as defaults. Method scalar values override class values; repeatable labels, tags, and links merge in source order with exact duplicate removal.
- `F16-REQ-008`: runtime scalar metadata overrides static metadata for the current execution. Repeated runtime parameters with the same name use last-write-wins. Every override produces a redacted structured diagnostic event.
- `F16-REQ-009`: equivalent runtime functions include `displayName`, `description`, `epic`, `feature`, `story`, `owner`, `lead`, `severity`, `tag`, `label`, `id`, `issue`, `tms`, `link(name:url:type:)`, `flaky`, `muted`, and `parameter`.
- `F16-REQ-010`: the unpublished nonstandard runtime names `desc` and `jira` are replaced by `description` and `issue` without deprecated aliases before the first production release.
- `F16-REQ-011`: secret values are redacted before macro diagnostics, generated source, console, XCTest identifiers, manifests, Allure, and AI artifacts.
- `F16-REQ-012`: system-owned labels and identities remain observer-owned and cannot be overridden by annotations: UUID, `historyId`, `testCaseId`, full name, host, thread, language, framework, package, class, method, lifecycle status, stage, start, and stop.
- `F16-REQ-013`: metadata works for ordinary and parameterized XCTest methods, with or without runtime additions, under SPM and Tuist delivery.
- `F16-REQ-014`: the existing public JSON model named `Link` is renamed to `AllureLinkRecord` before exposing `@Link`, avoiding a public symbol collision.

## Example

```swift
@Epic("Authentication")
@Owner("Owner1")
final class LoginTests: XCEasyTestCase {
    @DisplayName("Invalid login shows an error")
    @Feature("Login")
    @Story("Invalid credentials")
    @Severity(.critical)
    @Tag("negative")
    @Issue("TEST-ISSUE-001")
    @TmsLink("TEST-CASE-001")
    @AllureId("9001")
    func testInvalidLogin() {
        parameter("login", value: "unknown-user")
        find(identifier: "submit").tap()
        find(identifier: "loginError").assertIsDisplayed()
    }
}
```

The result contains the readable name, behavior labels, owner/severity/tag, standard issue/TMS links, `AS_ID=9001`, the runtime parameter, automatic device/framework labels, and the ordinary nested XCEasy steps.

## Acceptance criteria

- Golden tests cover every annotation, allowed target, repeatable form, ordering, invalid placement/value, and class/method/runtime merge.
- Metadata is present when `setUp` fails before the test body.
- Ordinary runtime-only tests produce the same standard Allure fields as macro-based tests.
- Allure 2/3 validators accept the result without custom substitutes for standard fields.
- Canary secret scanning finds no raw value in build diagnostics or runtime artifacts.

## Decisions

- `F16-DEC-001`: annotations are the recommended documentation path; runtime APIs remain first-class and fully supported.
- `F16-DEC-002`: Android Allure annotation naming is the compatibility reference, while Allure result JSON remains the serialization authority.
- `F16-DEC-003`: annotations are compile-time metadata only and do not change XCTest execution unless F14 or F17 explicitly defines that behavior.

## Official references

- [Allure Kotlin repository](https://github.com/allure-framework/allure-kotlin)
- [Allure Kotlin Android JUnit 4 sample](https://github.com/allure-framework/allure-kotlin/blob/master/samples/junit4-android/src/sharedTest/java/io/qameta/allure/sample/junit4/android/SampleActivitySuccessTest.kt)
- [Allure test result format](https://allurereport.org/docs/how-it-works-test-result-file/)
- [Allure test identifiers](https://allurereport.org/docs/how-it-works-test-identifiers/)
- [Swift macro model](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
