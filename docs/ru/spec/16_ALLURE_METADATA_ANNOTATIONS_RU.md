# F16 — Allure metadata-аннотации

Статус 0.1.1: реализовано. Compile-time annotations и параметры разрешаются до `setUp`; runtime alternatives остаются доступными.

## Цель

Дать XCTest знакомые раздельные Allure-аннотации и сохранить эквивалентный runtime API. В документации по умолчанию используются аннотации; тесты без macros продолжают работать через обычные функции.

## Канонический набор аннотаций

Названия и семантика следуют Allure Kotlin/JUnit 4 Android там, где есть прямой эквивалент:

- class и method: `@DisplayName`, `@Epic`/`@Epics`, `@Feature`/`@Features`, `@Story`/`@Stories`, `@Owner`, `@Severity`, `@Tag`/`@Tags`, `@Issue`/`@Issues`, `@TmsLink`/`@TmsLinks`, `@Link`/`@Links`, `@Flaky` и `@Muted`;
- только method: `@Description`, `@AllureId` и `@Lead`;
- execution-аннотация XCEasy: `@ParameterizedTest`, описанная в F14.

`@Step` и `@Attachment` намеренно отсутствуют. XCEasy уже создаёт automatic action/assertion steps, имеет обычную функцию `step(...)` и runtime-функции attachments. `@Jira`, `@Tms`, `@Suite`, `@Manual`, `@Known`, `@Param` и `@AllureParameter` не входят в контракт аннотаций.

## Требования

- `F16-REQ-001`: каждая поддерживаемая аннотация имеет public Swift macro declaration, compile-time validation места/значения, DocC и expansion tests.
- `F16-REQ-002`: static metadata класса/method хранится в детерминированном generated manifest по canonical XCTest scenario/method identifier и доступна до начала `setUp`.
- `F16-REQ-003`: `@DisplayName` на class задаёт читаемое имя suite; на method — имя test result без изменения stable identity.
- `F16-REQ-004`: `@AllureId` записывает стандартный label `AS_ID` и не заменяет внутренний `testCaseId` XCEasy.
- `F16-REQ-005`: `@Issue` записывает link type `issue`; `@TmsLink` — type `tms`; общий `@Link` сохраняет name, URL и optional type.
- `F16-REQ-006`: `@Flaky` и `@Muted` выставляют соответствующие flags в Allure `statusDetails`, а не custom labels.
- `F16-REQ-007`: metadata класса является defaults. Scalar values method переопределяют class; repeatable labels, tags и links объединяются в source order с удалением точных дублей.
- `F16-REQ-008`: runtime scalar metadata переопределяет static metadata текущего execution. Повторный runtime parameter с тем же именем использует last-write-wins. Каждое переопределение создаёт redacted structured diagnostic event.
- `F16-REQ-009`: эквивалентные runtime functions: `displayName`, `description`, `epic`, `feature`, `story`, `owner`, `lead`, `severity`, `tag`, `label`, `id`, `issue`, `tms`, `link(name:url:type:)`, `flaky`, `muted` и `parameter`.
- `F16-REQ-010`: неопубликованные нестандартные runtime names `desc` и `jira` заменяются на `description` и `issue` без deprecated aliases до первого production release.
- `F16-REQ-011`: secrets редактируются до macro diagnostics, generated source, console, XCTest identifiers, manifests, Allure и AI artifacts.
- `F16-REQ-012`: system-owned labels и identities остаются под контролем observer и не переопределяются аннотациями: UUID, `historyId`, `testCaseId`, full name, host, thread, language, framework, package, class, method, lifecycle status, stage, start и stop.
- `F16-REQ-013`: metadata работает для обычных и parameterized XCTest methods, с runtime additions и без них, при SPM и Tuist delivery.
- `F16-REQ-014`: существующая public JSON model `Link` переименовывается в `AllureLinkRecord` до публикации `@Link`, чтобы исключить конфликт public symbols.

## Пример

```swift
@Epic("Авторизация")
@Owner("Owner1")
final class LoginTests: XCEasyTestCase {
    @DisplayName("При неверном логине показывается ошибка")
    @Feature("Вход")
    @Story("Неверные данные")
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

Result содержит читаемое имя, behavior labels, owner/severity/tag, стандартные issue/TMS links, `AS_ID=9001`, runtime parameter, automatic device/framework labels и обычные вложенные XCEasy steps.

## Acceptance criteria

- Golden tests покрывают каждую аннотацию, допустимый target, repeatable form, порядок, invalid placement/value и class/method/runtime merge.
- Metadata присутствует, если `setUp` упал до test body.
- Обычные runtime-only tests создают те же стандартные Allure fields, что и macro-based tests.
- Allure 2/3 validators принимают result без custom substitutes вместо стандартных fields.
- Canary secret scan не находит raw value в build diagnostics и runtime artifacts.

## Решения

- `F16-DEC-001`: annotations — рекомендуемый путь документации; runtime APIs остаются first-class и полностью поддерживаются.
- `F16-DEC-002`: Android Allure annotation naming является compatibility reference, а Allure result JSON остаётся serialization authority.
- `F16-DEC-003`: annotations являются только compile-time metadata и не меняют XCTest execution, если F14 или F17 явно не задаёт такое поведение.

## Официальные источники

- [Репозиторий Allure Kotlin](https://github.com/allure-framework/allure-kotlin)
- [Android JUnit 4 sample Allure Kotlin](https://github.com/allure-framework/allure-kotlin/blob/master/samples/junit4-android/src/sharedTest/java/io/qameta/allure/sample/junit4/android/SampleActivitySuccessTest.kt)
- [Формат Allure test result](https://allurereport.org/docs/how-it-works-test-result-file/)
- [Идентификаторы Allure tests](https://allurereport.org/docs/how-it-works-test-identifiers/)
- [Модель Swift macros](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
