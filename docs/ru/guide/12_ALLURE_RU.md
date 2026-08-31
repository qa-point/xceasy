# Allure

Русский · [English](../../en/guide/12_ALLURE_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


## Что происходит автоматически

При старте каждого теста XCEasy создаёт отдельный Allure test result и container. Действия, assertions, API operations, `step`, GWT и component steps становятся вложенными шагами. В конце теста result получает итоговый статус и attachments.

Поток одного теста выглядит так:

1. Встроенный observer замечает начало XCTest; вручную регистрировать его не нужно.
2. XCEasy создаёт уникальный `executionId`, result и отдельные log/event-файлы.
3. Каждая операция открывает шаг, записывает стабильный код операции и длительность, затем закрывает шаг со статусом.
4. При ошибке фреймворк добавляет доступные screenshot, UI query evidence и снимок дерева.
5. В `tearDown` незакрытые шаги безопасно завершаются, attachments связываются с тестом, JSON валидируется и атомарно записывается в `allure-results`.

Каждый параллельный test execution имеет собственные идентификаторы, log, events, screenshots и performance summary. В общей папке имена файлов уникальны, поэтому тесты не записывают данные друг друга.

XCEasy создаёт:

- `*-result.json` — тест, статус, labels, parameters, steps и attachments;
- `*-container.json` — связь теста с `Setup`/`Teardown` fixtures;
- attachment-файлы — log, screenshot, diagnostics и performance data;
- `executor.json`, `environment.properties`, `categories.json` — общая информация запуска.

По умолчанию папка называется `allure-results` в корне проекта. Для CI задайте абсолютный или относительный путь через environment variable `XC_EASY_REPORT_DIR`. XCEasy **не** строит HTML.

Локальный просмотр при установленном Allure CLI:

```bash
allure serve allure-results
```

Upload в TestOps также выполняется вашим CLI/CI после тестов; runtime XCEasy не отправляет результаты по сети.

## Разметка теста

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

| Функция | Для чего нужна |
|---|---|
| `id` | Стабильный ID автоматизированного теста. |
| `displayName` | Понятное имя вместо имени Swift-метода. |
| `desc` | Подробное описание цели теста. |
| `epic` / `feature` / `story` | Иерархия продукта в отчёте. |
| `suite` | Набор тестов, например Smoke или Regression. |
| `owner` | Ответственная команда или человек. |
| `severity` | `.blocker`, `.critical`, `.normal`, `.minor`, `.trivial`. |
| `tag` | Один или несколько произвольных тегов. |
| `label` | Пользовательский Allure label: `label("layer", "ui")`. |
| `link` | Обычная URL-ссылка. |
| `issue` / `tms` | Ссылка, собранная из ID и `XCEasyAllureConfig`. |
| `parameter` | Данные конкретного запуска и управление history identity. |

## Параметры Allure и параметризованные запуски

`parameter(...)` описывает **уже запущенный экземпляр теста** в Allure:

| Аргумент | Что делает |
|---|---|
| `_ name` | Стабильное имя параметра в result, например `accountType`. Повторный вызов с тем же именем заменяет значение. |
| `value` | Строковое значение текущего запуска. Перед сохранением проходит redaction. |
| `excluded` | `false` по умолчанию: значение участвует в `historyId`, поэтому варианты имеют разную историю. `true`: значение показывается в result, но не разделяет историю; подходит для timestamp или случайного request ID. |
| `mode: .default` | Сохраняет значение после общего удаления чувствительных данных. |
| `mode: .masked` | Не сохраняет исходное значение, а записывает placeholder. В отчёте видно наличие параметра. |
| `mode: .hidden` | Также не сохраняет исходное значение. Режим передаётся Allure как просьба скрыть параметр в представлении. |

Важно: runtime-вызов `parameter(...)` описывает только уже запущенный экземпляр. Для настоящего повторения сценария используйте `@ParameterizedTest`: он генерирует отдельный XCTest method для каждого inline dataset, поэтому варианты независимо распределяются, перезапускаются и сохраняют артефакты. Не делайте `for data in datasets` внутри одного теста.

[Полный пример `@ParameterizedTest`, правила redaction, аннотации и маркеры](15_PARAMETERIZED_TESTS_AND_ANNOTATIONS_RU.md)

Для `issue` и `tms` один раз задайте patterns:

```swift
XCEasyAllureConfig.apply(linkPatterns: [
    "issue": "https://jira.example.com",
    "tms": "https://testops.example.com/testcase"
])
```

## Падения и вложенные шаги

Если XCTest аварийно прерывает UI-операцию, XCEasy закрывает незавершённые шаги, отмечает проблемную ветку как failed и прикрепляет screenshot/log к failed или самому глубокому известному шагу. Благодаря этому отчёт не остаётся в состоянии `running` и содержит контекст падения.

Рекомендуемый порядок проверки failed branch, screenshot, UI hierarchy, JSONL, log и manifest приведён в [playbook расследования падений](16_FAILURE_INVESTIGATION_PLAYBOOK_RU.md).
