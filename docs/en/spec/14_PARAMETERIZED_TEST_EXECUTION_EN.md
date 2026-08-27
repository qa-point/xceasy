# F14 — Parameterized test executions

0.1.1 status: implemented for typed inline datasets through `@ParameterizedTest`; external runtime datasets remain out of scope.

## Goal

Allow a user to describe one scenario and an array of datasets so that every dataset becomes a separate XCTest execution with its own lifecycle, device, status, logs, diagnostics, and Allure result.

## Implemented baseline

- `parameter(name:value:excluded:mode:)` adds redacted metadata to the already running Allure result and participates in the final `historyId`.
- One test method receives an independent execution UUID, log, JSONL, performance summary, diagnostic bundle, and Allure result.
- Standard XCTest discovery sees every generated case as an ordinary independently addressable test method.
- `@ParameterizedTest` expands a compile-time Swift array into independently discoverable and schedulable XCTest methods. Each generated method can be selected or retried with ordinary XCTest tooling.
- A loop inside one test method is not parameterization: it shares one Setup/Teardown, one status, and one artifact set.

## Requirements

- `F14-REQ-001`: every dataset creates a separate XCTest execution and repeats the complete `configuration → Setup → test body → Teardown` lifecycle.
- `F14-REQ-002`: one dataset may contain a single strongly typed model or several fields; the public API accepts an array of datasets rather than a single string value only.
- `F14-REQ-003`: every dataset has a mandatory stable case ID unique within its parameterized test method.
- `F14-REQ-004`: the generated XCTest identifier and display name let a person distinguish and select one case without changing the source test body.
- `F14-REQ-005`: variants of one scenario have the same Allure `testCaseId`; `historyId` differs by sorted non-excluded parameters, while a retry of the same dataset retains its history ID.
- `F14-REQ-006`: XCEasy automatically adds the stable case ID as an Allure parameter; the user may add several named report parameters and mark volatile/secret values excluded/masked/hidden.
- `F14-REQ-007`: every case owns its log, events, screenshots, performance, diagnostic bundle, and result/container JSON; mutable global state is not shared with neighboring cases.
- `F14-REQ-008`: expanded cases expose ordinary XCTest identifiers; XCEasy metadata does not silently select, skip, repeat, or distribute them.
- `F14-REQ-009`: duplicate/empty case IDs, an empty dataset array, and impossible argument conversion fail discovery/preflight explicitly before application actions.
- `F14-REQ-010`: the public mechanism does not use private XCTest API, runtime method injection, or an unsupported `init(invocation:)` bridge.
- `F14-REQ-011`: case-level source location points to the dataset declaration and is retained in the XCTest issue, JSONL, and AI handoff.
- `F14-REQ-012`: values are redacted before console, XCTest name, Allure, and diagnostics; a secret cannot be used as a case ID.
- `F14-REQ-013`: macro output is deterministic, unit/golden tested, and identical for SPM and Tuist delivery.
- `F14-REQ-014`: local acceptance runs cases on at most two simulators; a wider device matrix remains a CI check.

## Selected public model

The primary API is a compile-time `@ParameterizedTest` Swift macro attached to a typed scenario method. Its inline `cases` array is expanded into ordinary no-argument XCTest methods. Every generated method selects one immutable dataset and calls the shared scenario body. A runtime loop and dynamic XCTest method injection are rejected because they do not provide a supported independently schedulable lifecycle.

```swift
struct InvalidLoginCase {
    let id: String
    let login: String
    let password: String
    let expectedMessage: String
}

final class LoginTests: XCEasyTestCase {
    @ParameterizedTest(
        name: "[{index}] {id}: login={login}",
        cases: [
            InvalidLoginCase(id: "wrong-password", login: "admin", password: "wrong-password", expectedMessage: "Invalid credentials"),
            InvalidLoginCase(id: "empty-login", login: "", password: "password123", expectedMessage: "Login is required")
        ],
        parameterRules: [
            .masked(\.password, excluded: true)
        ]
    )
    func invalidLogin(_ data: InvalidLoginCase) {
        find(identifier: "login").typeText(data.login)
        find(identifier: "password").typeText(data.password)
        find(identifier: "submit").tap()
        find(identifier: "loginError").assertLabel(value: data.expectedMessage)
    }
}
```

The first release accepts only compile-time-known inline cases with labeled initializer arguments. External JSON/API datasets are outside this feature and are not silently converted into methods.

## Acceptance criteria

- Two datasets produce two XCTest executions, two Setup/Teardown cycles, and two independent Allure results.
- One failed case does not alter the status, steps, or artifacts of a neighboring passed case.
- A specific case can be selected and retried independently.
- Ten cases are distributed deterministically across two available devices without a full copy on each.
- A non-secret parameter separates Allure variant history; an excluded parameter does not; masked/hidden raw values are absent from every artifact.
- Duplicate ID, empty ID, and an empty array are rejected by contract tests.
- Unit/golden tests verify expansion/plan, naming, identity, redaction, and filters; a two-device integration test verifies independent lifecycle.

## Decisions and open choice

- `F14-DEC-001`: `parameter(...)` remains an Allure metadata API and gains no hidden rerun side effect.
- `F14-DEC-002`: every dataset must be a real separate XCTest execution; virtual Allure-only subtests do not satisfy the contract.
- `F14-DEC-003`: the primary public UX is the compile-time `@ParameterizedTest` macro; the ordinary runtime `parameter(...)` API remains available and does not schedule executions.
- `F14-DEC-004`: generated method names use a deterministic sanitized `<scenario>__p<index>_<case-id>` form; secrets and report-only values are forbidden in XCTest identifiers.
- `F14-DEC-005`: generated variants share a canonical scenario identity used for `testCaseId`, while sorted non-excluded parameters determine `historyId`.
- `F14-DEC-006`: macro support must not raise the declared iOS deployment target. Swift 5.9 macro capability is necessary, but the supported Xcode/Swift matrix remains the repository toolchain manifest until CI proves a wider matrix.
