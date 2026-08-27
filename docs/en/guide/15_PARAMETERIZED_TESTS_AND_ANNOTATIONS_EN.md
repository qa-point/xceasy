# Parameterized XCTest, Allure annotations, and markers

## What this API solves

XCEasy remains an XCTest/XCUITest framework. `@ParameterizedTest` turns one typed scenario and its inline datasets into ordinary no-argument XCTest methods. Every dataset therefore receives independent setup/teardown, status, logs, artifacts, and Allure result, while Xcode can select and schedule it independently.

Build macros with the pinned project toolchain: Xcode 26.6, Swift 6.3.3, and SwiftSyntax 603.0.2. The application deployment target remains iOS 15. Ordinary XCTest methods and runtime metadata APIs continue to work without applying macros.

## Parameterized test

```swift
struct InvalidLoginCase {
    let id: String
    let login: String
    let password: String
    let expectedMessage: String
}

final class LoginTests: XCEasyTestCase {
    @DisplayName("Invalid login: {id}")
    @Feature("Login")
    @ParameterizedTest(
        name: "[{index}] {id}: login={login}",
        cases: [
            InvalidLoginCase(id: "wrong-password", login: "admin", password: "wrong", expectedMessage: "Invalid credentials"),
            InvalidLoginCase(id: "empty-login", login: "", password: "password123", expectedMessage: "Login is required")
        ],
        parameterRules: [.masked(\.password, excluded: true)]
    )
    func invalidLogin(_ data: InvalidLoginCase) {
        find(identifier: "login").typeText(data.login)
        find(identifier: "password").typeText(data.password)
        find(identifier: "submit").tap()
        find(identifier: "loginError").assertLabel(value: data.expectedMessage)
    }
}
```

XCTest discovers `testInvalidLogin__p001_wrong_password()` and `testInvalidLogin__p002_empty_login()`. Allure shows the readable names. `.masked` and `.hidden` remove raw values before report sinks; `.excluded` keeps a safe value visible but excludes it from history identity. Every case needs a unique stable literal `id`, and one case can be selected with ordinary `-only-testing`.

## Allure annotations

Macros are the recommended path because their metadata is available before `setUp`:

```swift
@Epic("Authentication")
@Owner("Owner1")
@Marker("Team1")
final class LoginTests: XCEasyTestCase {
    @DisplayName("Successful login")
    @Description("The user signs in with valid credentials")
    @Feature("Login")
    @Story("Password login")
    @Severity(.critical)
    @Tags("smoke", "ios")
    @AllureId("4821")
    @Issue("TEST-ISSUE-001")
    @TmsLink("TEST-CASE-001")
    @Link(name: "Design", url: "https://design.example.test/login", type: "design")
    @Flaky
    func testLogin() { /* test */ }
}
```

The complete surface is `DisplayName`, `Description`, `Epic/Epics`, `Feature/Features`, `Story/Stories`, `Owner`, `Lead`, `Severity`, `Tag/Tags`, `AllureId`, `Issue/Issues`, `TmsLink/TmsLinks`, `Link/Links`, `Flaky`, `Muted`, and `Marker`. Class values are defaults; method values refine them. Repeatable labels are merged and deduplicated.

Configure standard links once with `XCEasyAllureConfig.apply(linkPatterns:)`. Runtime alternatives remain first-class: `displayName`, `description`, `epic`, `feature`, `story`, `owner`, `lead`, `severity`, `tag`, `label`, `id`, `issue`, `tms`, `link`, `flaky`, `muted`, and `parameter`. Use `XCEasy.description("...")` inside an XCTestCase to disambiguate it from `XCTestCase.description`.

## Custom annotations

A project can declare a literal no-argument marker alias without implementing another compiler plugin:

```swift
@attached(peer, names: prefixed(__xceasyTeam1_))
macro Team1() = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

@Team1
final class CatalogTests: XCEasyTestCase { /* tests */ }
```

The token after `__xceasy` must match the alias name. The universal `@Marker("Team1")` needs no declaration.
