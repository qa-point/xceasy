# Allure

English · [Русский](../../ru/guide/12_ALLURE_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


## Automatic behavior

At the start of every test, XCEasy creates a separate Allure test result and container. Actions, assertions, API operations, `step`, GWT, and component steps become nested steps. The result receives its final status and attachments when the test ends.

One test flows as follows:

1. The built-in observer sees XCTest start; no manual registration is required.
2. XCEasy creates a unique `executionId`, result, and isolated log/event files.
3. Every operation opens a step, records a stable operation code and duration, then closes the step with a status.
4. On failure, the framework adds any available screenshot, UI query evidence, and tree snapshot.
5. During teardown, unfinished steps are finalized safely, attachments are linked, JSON is validated, and files are written atomically to `allure-results`.

Every parallel test execution has independent identifiers, log, events, screenshots, and performance summary. Filenames in the shared directory are unique, so tests do not overwrite one another's data.

XCEasy creates:

- `*-result.json` — test, status, labels, parameters, steps, and attachments;
- `*-container.json` — the relationship to `Setup`/`Teardown` fixtures;
- attachment files — logs, screenshots, diagnostics, and performance data;
- `executor.json`, `environment.properties`, and `categories.json` — run-level information.

The default directory is `allure-results` in the project root. In CI, set an absolute or relative path with the `XC_EASY_REPORT_DIR` environment variable. XCEasy does **not** build HTML.

Local viewing with an installed Allure CLI:

```bash
allure serve allure-results
```

Uploading to TestOps is likewise a CLI/CI action after the tests; the XCEasy runtime does not send results over the network.

## Test metadata

```swift
override func beforeTest() {
    epic("Authorization")
    feature("Login")
    story("By email")
    suite("Regression")
    owner("Owner1")
    severity(.critical)
    tag("ios", "smoke")
    super.beforeTest()
}

func testValidLogin() {
    id("1001")
    displayName("Successful login with valid account")
    description("User opens the app and signs in with valid credentials")
    issue("TEST-ISSUE-001")
    tms("T-456")
    parameter("accountType", value: "premium", excluded: false)
    parameter("token", value: secretToken, excluded: true, mode: .masked)

    step("Submit login form") {
        find(identifier: "submitButton").tap()
    }
}
```

| Function | Purpose |
|---|---|
| `id` | Stable automated-test ID. |
| `displayName` | Readable name replacing the Swift method name in the report. |
| `desc` | Detailed test purpose. |
| `epic` / `feature` / `story` | Product hierarchy in the report. |
| `suite` | A set such as Smoke or Regression. |
| `owner` | Responsible person or team. |
| `severity` | `.blocker`, `.critical`, `.normal`, `.minor`, `.trivial`. |
| `tag` | One or more arbitrary tags. |
| `label` | Custom Allure label, for example `label("layer", "ui")`. |
| `link` | A regular URL link. |
| `issue` / `tms` | Link built from an ID and `XCEasyAllureConfig`. |
| `parameter` | Per-execution data and history-identity control. |

## Allure parameters and parameterized execution

`parameter(...)` describes the **already running test instance** in Allure:

| Argument | Behavior |
|---|---|
| `_ name` | Stable result parameter name, such as `accountType`. Calling it again with the same name replaces the value. |
| `value` | String value for the current execution. It is redacted before persistence. |
| `excluded` | `false` by default: the value participates in `historyId`, so variants have distinct history. `true`: it is shown in the result but does not split history; suitable for a timestamp or random request ID. |
| `mode: .default` | Persists the value after general sensitive-data removal. |
| `mode: .masked` | Never persists the raw value and writes a placeholder. The report still knows the parameter is present. |
| `mode: .hidden` | Also never persists the raw value. The mode asks Allure to hide the parameter in its presentation. |

Important: runtime `parameter(...)` only describes an already-running instance. Use `@ParameterizedTest` for real repetition: it generates one XCTest method per inline dataset, so variants are scheduled, retried, and stored independently. Do not loop over datasets inside one test.

[Complete `@ParameterizedTest`, redaction, annotation, and marker guide](15_PARAMETERIZED_TESTS_AND_ANNOTATIONS_EN.md)

Configure issue and TMS patterns once:

```swift
XCEasyAllureConfig.apply(linkPatterns: [
    "issue": "https://jira.example.com",
    "tms": "https://testops.example.com/testcase"
])
```

## Failures and nested steps

If XCTest abruptly interrupts a UI operation, XCEasy closes unfinished steps, marks the affected branch as failed, and attaches the screenshot/log to the failed or deepest known step. This prevents reports from remaining in `running` state and preserves failure context.

For the recommended order of inspecting the failed branch, screenshot, UI hierarchy, JSONL, log, and manifest, follow the [failure investigation playbook](16_FAILURE_INVESTIGATION_PLAYBOOK_EN.md).
