# F14 — Параметризованные test executions

Статус 0.1.1: реализовано для типизированных inline datasets через `@ParameterizedTest`; внешние runtime datasets остаются вне scope.

## Цель

Позволить пользователю описать один сценарий и массив наборов данных так, чтобы каждый набор стал отдельным XCTest execution со своим lifecycle, устройством, статусом, логами, диагностикой и Allure result.

## Реализованный baseline

- `parameter(name:value:excluded:mode:)` добавляет redacted metadata уже запущенному Allure result и участвует в итоговом `historyId`.
- Один test method имеет отдельные execution UUID, log, JSONL, performance summary, diagnostic bundle и Allure result.
- Стандартный XCTest discovery видит каждый generated case как обычный независимо адресуемый test method.
- `@ParameterizedTest` разворачивает известный при компиляции Swift-массив в независимо обнаруживаемые и запускаемые XCTest methods. Каждый generated method можно отдельно выбрать или перезапустить обычными средствами XCTest.
- Цикл внутри одного test method не считается параметризацией: он использует один Setup/Teardown, один статус и один набор artifacts.

## Требования

- `F14-REQ-001`: каждый dataset создаёт отдельный XCTest execution и повторяет полный `configuration → Setup → test body → Teardown` lifecycle.
- `F14-REQ-002`: один dataset может содержать одну strongly typed модель или несколько полей; public API принимает массив datasets, а не только одно строковое значение.
- `F14-REQ-003`: каждый dataset имеет обязательный stable case ID, уникальный в пределах параметризованного test method.
- `F14-REQ-004`: generated XCTest identifier и display name позволяют человеку отличить case и выбрать его отдельно без изменения исходного test body.
- `F14-REQ-005`: варианты одного сценария имеют одинаковый Allure `testCaseId`; `historyId` различается по sorted non-excluded parameters, а retry того же dataset сохраняет history ID.
- `F14-REQ-006`: XCEasy автоматически добавляет stable case ID как Allure parameter; пользователь может добавить несколько named report parameters и отметить volatile/secret значения как excluded/masked/hidden.
- `F14-REQ-007`: каждый case владеет собственными log, events, screenshots, performance, diagnostic bundle и result/container JSON; данные соседних cases не разделяются через mutable global state.
- `F14-REQ-008`: expanded cases имеют обычные XCTest identifiers; метаданные XCEasy скрыто не выбирают, не пропускают, не повторяют и не распределяют их.
- `F14-REQ-009`: duplicate/empty case IDs, пустой dataset array и невозможное преобразование arguments завершают discovery/preflight явной ошибкой до действий с приложением.
- `F14-REQ-010`: public mechanism не использует private XCTest API, runtime method injection или неподдерживаемый `init(invocation:)` bridge.
- `F14-REQ-011`: case-level source location указывает на объявление dataset и сохраняется в XCTest issue, JSONL и AI handoff.
- `F14-REQ-012`: значения проходят redaction до console, XCTest name, Allure и diagnostics; secret нельзя использовать как case ID.
- `F14-REQ-013`: macro output детерминирован, проверяется unit/golden tests и одинаков для SPM и Tuist delivery.
- `F14-REQ-014`: локальный acceptance запускает cases максимум на двух simulators; расширенная device matrix остаётся CI-проверкой.

## Выбранная публичная модель

Основной API — compile-time Swift macro `@ParameterizedTest` над typed scenario method. Inline-массив `cases` разворачивается в обычные no-argument XCTest methods. Каждый сгенерированный method выбирает один immutable dataset и вызывает общее тело сценария. Runtime loop и динамическое добавление XCTest methods не принимаются, потому что не дают поддерживаемый независимо планируемый lifecycle.

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

Первая версия принимает только известные при компиляции inline cases с именованными аргументами initializer. Внешние JSON/API datasets не входят в эту фичу и не превращаются в methods скрыто.

## Acceptance criteria

- Два datasets создают два XCTest executions, два Setup/Teardown и два независимых Allure results.
- Один failed case не меняет status, steps или artifacts соседнего passed case.
- Конкретный case можно выбрать и перезапустить отдельно.
- Десять cases детерминированно распределяются на два доступных устройства без полного повтора на каждом.
- Несекретный parameter разделяет Allure history вариантов; excluded parameter её не разделяет; masked/hidden raw value отсутствует во всех artifacts.
- Duplicate ID, empty ID и empty array отклоняются contract tests.
- Unit/golden tests проверяют expansion/plan, naming, identity, redaction и filters; двухустройственный integration test проверяет независимый lifecycle.

## Решения и открытый выбор

- `F14-DEC-001`: `parameter(...)` остаётся Allure metadata API и не получает скрытый side effect повторного запуска.
- `F14-DEC-002`: каждый dataset обязан быть настоящим отдельным XCTest execution; виртуальные Allure-only subtests не удовлетворяют контракту.
- `F14-DEC-003`: основной public UX — compile-time macro `@ParameterizedTest`; обычный runtime API `parameter(...)` остаётся доступным и не планирует executions.
- `F14-DEC-004`: generated method names используют детерминированный sanitized-формат `<scenario>__p<index>_<case-id>`; secrets и report-only values запрещены в XCTest identifiers.
- `F14-DEC-005`: generated variants используют общий canonical scenario identity для `testCaseId`, а sorted non-excluded parameters определяют `historyId`.
- `F14-DEC-006`: macro support не повышает declared iOS deployment target. Возможность macros требует Swift 5.9, но supported Xcode/Swift matrix остаётся заданной repository toolchain manifest, пока более широкая матрица не доказана CI.
