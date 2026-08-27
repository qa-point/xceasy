# Параметризованные XCTest, Allure-аннотации и маркеры

## Что решает этот API

XCEasy остаётся фреймворком на XCTest/XCUITest. Макрос `@ParameterizedTest` превращает один сценарий с набором данных в несколько обычных методов XCTest без аргументов. Поэтому каждый набор данных получает собственные `setUp`/`tearDown`, статус, логи, артефакты и Allure result, а Xcode может независимо запускать его и распределять по устройствам.

Для сборки макросов используйте зафиксированный toolchain проекта: Xcode 26.6, Swift 6.3.3 и SwiftSyntax 603.0.2. Минимальная версия запуска приложения остаётся iOS 15. Обычные тесты и runtime API работают без применения макросов.

## Параметризованный тест

```swift
struct InvalidLoginCase {
    let id: String
    let login: String
    let password: String
    let expectedMessage: String
}

final class LoginTests: XCEasyTestCase {
    @DisplayName("Неуспешная авторизация: {id}")
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

XCTest увидит методы `testInvalidLogin__p001_wrong_password()` и `testInvalidLogin__p002_empty_login()`. В отчёте появятся читаемые имена `[1] wrong-password: login=admin` и `[2] empty-login: login=`. Пароль попадёт в отчёт только как `<redacted:parameter>`, а `excluded: true` исключит его из history identity.

Правила набора данных:

- `cases` задаётся непустым inline-массивом типизированных значений;
- у каждого значения обязателен уникальный стабильный строковый `id`;
- поля должны передаваться label-аргументами с literal-значениями;
- `.masked(\.field)` и `.hidden(\.field)` удаляют исходное значение до логов и отчёта;
- `.excluded(\.field)` оставляет значение видимым, но не учитывает его в истории;
- один вариант запускается обычным `-only-testing:Target/LoginTests/testInvalidLogin__p002_empty_login`.

## Allure-аннотации

Макросы — рекомендуемый вариант: метаданные доступны observer ещё до `setUp` и сохраняются даже при ошибке подготовки теста.

```swift
@Epic("Authentication")
@Owner("Owner1")
@Marker("Team1")
final class LoginTests: XCEasyTestCase {
    @DisplayName("Проверка логина")
    @Description("Пользователь входит с корректными данными")
    @Feature("Login")
    @Story("Password login")
    @Severity(.critical)
    @Tags("smoke", "ios")
    @AllureId("4821")
    @Issue("TEST-ISSUE-001")
    @TmsLink("TEST-CASE-001")
    @Link(name: "Макет", url: "https://design.example.test/login", type: "design")
    @Flaky
    func testLogin() { /* test */ }
}
```

Доступны отдельные аннотации `DisplayName`, `Description`, `Epic/Epics`, `Feature/Features`, `Story/Stories`, `Owner`, `Lead`, `Severity`, `Tag/Tags`, `AllureId`, `Issue/Issues`, `TmsLink/TmsLinks`, `Link/Links`, `Flaky`, `Muted` и `Marker`. Значения класса действуют как defaults; значения метода уточняют их. Повторяемые labels объединяются и дедуплицируются.

Ссылки на issue и TMS настраиваются один раз:

```swift
XCEasyAllureConfig.apply(linkPatterns: [
    "issue": "https://jira.example.test/browse/{}",
    "tms": "https://testops.example.test/testcase/%s"
])
```

Без макросов остаётся runtime API: `displayName`, `description`, `epic`, `feature`, `story`, `owner`, `lead`, `severity`, `tag`, `label`, `id`, `issue`, `tms`, `link`, `flaky`, `muted` и `parameter`. Внутри наследника `XCTestCase` вызывайте `XCEasy.description("...")`, чтобы отличить функцию от свойства `XCTestCase.description`. Runtime-вызов выполняется уже после начала lifecycle, поэтому для метаданных, необходимых до `setUp`, используйте макрос.

## Пользовательские аннотации

Для частых командных маркеров можно объявить короткий alias без собственной реализации compiler plugin:

```swift
@attached(peer, names: prefixed(__xceasyTeam1_))
macro Team1() = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

@Team1
final class CatalogTests: XCEasyTestCase { /* tests */ }
```

Имя после `__xceasy` обязано совпадать с именем alias. Alias без аргументов преобразуется в маркер с тем же именем. Универсальный `@Marker("Team1")` не требует дополнительного объявления и подходит для динамически выбираемых названий.
