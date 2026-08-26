# XCEasy

Русская документация · [English](README.md)

XCEasy — фреймворк поверх XCTest для UI-тестов iOS-приложений. Он упрощает тестовый код, автоматически создаёт шаги Allure и сохраняет логи и диагностические артефакты, удобные для человека и ИИ.

Этот README — краткая точка входа: в каждом разделе приведён один базовый сценарий. Все варианты API, параметры, ограничения и расширенные примеры находятся в [полном руководстве пользователя](docs/ru/PRODUCT_GUIDE_RU.md).

## Оглавление

- [Зачем нужен XCEasy](#зачем-нужен-xceasy)
- [Архитектура](#архитектура)
- [Требования и установка](#требования-и-установка)
- [Быстрый старт](#быстрый-старт)
- [Конфигурация](#конфигурация)
- [Жизненный цикл теста и приложения](#жизненный-цикл-теста-и-приложения)
- [Поиск и работа с элементами](#поиск-и-работа-с-элементами)
- [Проверки элементов](#проверки-элементов)
- [Обычные проверки значений](#обычные-проверки-значений)
- [Soft assertions](#soft-assertions)
- [Компоненты Page Object](#компоненты-page-object)
- [Launch arguments и environment](#launch-arguments-и-environment)
- [Given/When/Then](#givenwhenthen)
- [Deeplink](#deeplink)
- [Взаимодействие с устройством](#взаимодействие-с-устройством)
- [Работа с API-запросами](#работа-с-api-запросами)
- [Allure](#allure)
- [Логи, диагностика и производительность](#логи-диагностика-и-производительность)
- [Проверка самого репозитория](#проверка-самого-репозитория)
- [Дополнительная документация](#дополнительная-документация)

## Зачем нужен XCEasy

XCEasy даёт единый стиль для UIKit и SwiftUI тестов: ленивый поиск элементов, автоматические ожидания, Page Object-компоненты, локализованные шаги, Allure и отдельные артефакты каждого теста. Структурированные события можно использовать для диагностики и AI-assisted self-healing.

## Архитектура

XCEasy связывает lifecycle XCTest, ленивые UI locators и единую систему отчётности. `find` и `child` сохраняют только способ поиска. Реальный `XCUIElement` разрешается заново при действии, чтении или assertion, поэтому операция работает с текущим accessibility tree. Один execution владеет собственными config, приложением, шагами и artifacts.

```text
+----------------------+       +---------------------------+
| XCTest / Page Object |------>| XCEasyTestCase lifecycle  |
+----------+-----------+       | config + XCUIApplication |
           |                   +---------------------------+
           v
+----------------------+
| find / child         |       Хранит locator, но не UI-элемент
| lazy locator         |
+----------+-----------+
           | действие / чтение / assertion
           v
+----------------------+       +----------------------------+
| Текущий              |<----->| Action / read / assertion |
| accessibility tree   |       +-------------+--------------+
+----------------------+                     |
                                             v
                              +----------------------------+
                              | Единый operation step      |
                              +----+-----------+-----------+
                                   |           |
                         +---------+--+   +----+----------------+
                         | Allure     |   | Log + JSONL + timing |
                         +------------+   +----------------------+
```

Основные слои репозитория:

- `XCEasy/Sources/Public` и `TestStructure` — пользовательский Swift API, lifecycle и lazy elements;
- `XCEasy/Sources/Allure`, `Utils/Diagnostics`, `Utils/Performance` и `TestStructure/XCEasyTestLogger.swift` — единый pipeline шагов и artifacts;
- `XCEasy/Sources/Execution` — изоляция execution и machine-readable контракты;
- `XCEasy/Tests` и `XCEasyIntegrationFixture` — unit и внутреннее UIKit/SwiftUI integration coverage;
- `docs/{ru,en}/spec` и `schemas` — versioned requirements и машинные контракты.

Два независимых публичных приложения и их UI-тесты находятся в [`xceasy-examples`](https://github.com/qa-point/xceasy-examples): `UIKitExample` и `SwiftUIExample`. Multi-simulator orchestration, marker selection, sharding, recovery и run-level aggregation принадлежат независимому продукту [`xceasy-runner`](https://github.com/qa-point/xceasy-runner) и не входят в Swift API XCEasy.

## Требования и установка

Технический минимум package manifest — Xcode 15.0, Swift 5.9 и iOS 15. Он определяется `swift-tools-version: 5.9` и deployment target package. Xcode 14 и Swift 5.8 не смогут прочитать manifest. Поддержанная и проверенная сейчас toolchain matrix — Xcode 26.5 и Swift 6.3.2 в Swift 5 language mode. Xcode 15–26.4 может собрать package, но пока эти версии не входят в CI matrix, проект не гарантирует их совместимость.

В Xcode откройте **File → Add Package Dependencies**, укажите `https://github.com/qa-point/xceasy.git` и добавьте product `XCEasy` в UI-test target. Эквивалентная зависимость в `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/qa-point/xceasy.git",
        from: "0.1.0"
    )
]
```

Observer bootstrap входит в package и не требует ручной регистрации. Для приложения сохраняйте deployment target, который нужен продукту; iOS 15 — минимальная версия именно XCEasy.

## Быстрый старт

```swift
import XCTest
import XCEasy

final class LoginTests: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            localization: .ru
        )
        super.configuration()
    }

    func testSuccessfulLogin() {
        find(identifier: "emailField").typeText("user@example.com")
        find(identifier: "submitButton").tap()
        find(identifier: "homeScreen").assertIsDisplayed()
    }
}
```

Стандартные действия и проверки автоматически попадут в локализованный log и Allure.

Без `bundleId` XCEasy запускает приложение, связанное с UI-test target. Указывайте Bundle ID явно только тогда, когда тест должен открыть другое приложение.

## Конфигурация

Общие настройки размещайте в базовом `XCEasyTestCase`. Каждый параллельный тест получает собственный snapshot конфигурации.

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.example.app",
            assertionTimeout: 5,
            actionPolicy: .hittable,
            localization: .ru,
            deeplinkSchema: "example"
        )
        super.configuration()
    }
}
```

[Подробнее: все параметры и доступные значения](docs/ru/guide/01_CONFIGURATION_RU.md)

## Жизненный цикл теста и приложения

XCEasy выполняет `configuration → launchApplication → beforeTest → test → afterTest → closeApplication`. Для пользовательской подготовки используйте lifecycle hooks:

```swift
final class CatalogTests: BaseTestCase {
    override func beforeTest() {
        feature("Catalog")
        super.beforeTest()
    }

    func testCatalogOpens() {
        find(identifier: "catalogScreen").assertIsDisplayed()
    }
}
```

[Подробнее: lifecycle hooks и управление приложением](docs/ru/guide/02_LIFECYCLE_RU.md)

## Поиск и работа с элементами

Используйте стабильные accessibility identifiers. Дочерний locator ограничивает поиск контейнером:

```swift
let banner = find(identifier: "promoBanner")
let closeButton = banner.child(
    type: .button,
    identifier: "promoBanner.closeButton"
)

closeButton.tap()
```

При каждом `tap` или assertion цепочка разрешается заново по текущему UI.

[Подробнее: все способы поиска, действия, чтение и ожидания](docs/ru/guide/03_ELEMENT_LOOKUP_RU.md)

## Проверки элементов

Наличие в accessibility tree и отображение на экране — разные состояния:

```swift
let banner = find(identifier: "promoBanner")

banner.assertExists()
banner.assertIsDisplayed()
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5)
```

[Подробнее: все UI assertions и переходы состояний](docs/ru/guide/04_ELEMENT_ASSERTIONS_RU.md)

## Обычные проверки значений

Для моделей, ответов API и вычисленных значений доступны hard assertions:

```swift
assertEqual(actual: response.statusCode, expected: 200)
assertNotEmpty(actual: products)
assertLessThan(actual: requestDuration, expected: 2.0)
```

[Подробнее: Boolean, equality, comparison, optional, collection и throws assertions](docs/ru/guide/05_VALUE_ASSERTIONS_RU.md)

## Soft assertions

`softly` выполняет независимые проверки до конца и создаёт одну итоговую XCTest-ошибку, сохраняя отдельный failed step для каждой проблемы:

```swift
softly("Проверить главный экран") {
    homeScreen.navbar.assertIsDisplayed()
    homeScreen.tabbar.assertIsDisplayed()
    homeScreen.cards.get(index: 1).assertIsDisplayed()
}
```

Действия вроде `tap()` остаются hard failures.

[Подробнее: поддерживаемые проверки, вложенность и async](docs/ru/guide/06_SOFT_ASSERTIONS_RU.md)

## Компоненты Page Object

Компонент объединяет основной элемент и дочерние locators в повторно используемый POM:

```swift
struct PromoBanner: XCEasyComponent {
    let element = find(identifier: "promoBanner")

    var closeButton: XCEasyUIElement {
        element.child(identifier: "promoBanner.closeButton")
    }

    @discardableResult
    func dismiss() -> Self {
        step("Закрыть") {
            closeButton.tap()
        }
        return self
    }
}

PromoBanner().assertIsDisplayed().dismiss()
```

[Подробнее: componentName, component steps и коллекции компонентов](docs/ru/guide/07_PAGE_OBJECT_COMPONENTS_RU.md)

## Launch arguments и environment

Настройте их в `configuration()` до автоматического запуска приложения:

```swift
override func configuration() {
    LaunchArgumentsManager.add("-ui_testing")
    LaunchEnvironmentManager.set("true", for: "FEATURE_FLAG_X")
    super.configuration()
}
```

[Подробнее: изоляция, чтение, удаление и повторный запуск](docs/ru/guide/08_LAUNCH_CONFIGURATION_RU.md)

## Given/When/Then

GWT необязателен. Он объединяет несколько технических операций в понятный бизнес-шаг:

```swift
func testLogin() {
    given("Открыт экран входа") {
        find(identifier: "loginScreen").assertIsDisplayed()
    }
    and("Подготовлен тестовый пользователь") {
        find(identifier: "testAccountBadge").assertExists()
    }
    when("Пользователь заполняет и отправляет форму входа") {
        find(identifier: "emailField")
            .clearField()
            .typeText("user@example.com")
        find(identifier: "passwordField").typeText("test-password")
        find(identifier: "rememberMeSwitch").tap()
        find(identifier: "submitButton").tap()
    }
    then("Открывается главный экран") {
        find(identifier: "homeScreen").assertIsDisplayed()
    }
    and("Показывается имя пользователя") {
        find(identifier: "profileName").assertLabel(value: "Alex")
    }
}
```

`given`, `when`, `then` и `and` создают бизнес-уровень отчёта, а стандартные действия и assertions внутри них остаются вложенными техническими шагами. Например, в Allure шаг `When: Пользователь заполняет и отправляет форму входа` будет содержать `Очистить поле email → Ввести текст → Ввести пароль → Нажать remember me → Нажать submit`. `and` добавляет второе условие или результат без искусственного повторения `given`/`then`. GWT не обязателен; доступны синхронные и `async throws` overloads.

## Deeplink

Схема задаётся в конфигурации, а маршрут открывается непосредственно в тесте:

```swift
func testOpenPrivacySettings() {
    Deeplink.open(
        "/settings/privacy",
        name: "Настройки приватности"
    )
    find(identifier: "privacySettingsScreen").assertIsDisplayed()
}
```

Открытие станет отдельным timed step в Allure и diagnostics.

[Подробнее: схема, нормализация URL и отчёт](docs/ru/guide/09_DEEPLINKS_RU.md)

## Взаимодействие с устройством

`Device` объединяет управление устройством и вспомогательные операции, не привязанные к приложению, accessibility element или locator: ориентацию, clipboard и жесты по координатам всего экрана.

```swift
Device.setOrientation(.portrait)
Device.swipe(from: .bottomCenter, to: .topCenter)
```

[Подробнее: позиции экрана, ориентации, clipboard и жесты](docs/ru/guide/10_DEVICE_RU.md)

## Работа с API-запросами

`ApiManager` нужен прежде всего для подготовки backend-состояния UI-сценария, а не как полноценный API-test framework:

```swift
func testPreparedPremiumProfile() async throws {
    let api = ApiManager(baseURL: "https://staging.example.com")
    let body = try JSONSerialization.data(
        withJSONObject: ["plan": "premium"]
    )
    let response = try await api.post(
        route: "/test-data/profile",
        body: body
    )
    assertEqual(actual: response.statusCode, expected: 201)

    reopenApplication()
    find(identifier: "premiumBadge").assertIsDisplayed()
}
```

[Подробнее: конфигурация, HTTP-методы, callbacks, async и ошибки](docs/ru/guide/11_API_REQUESTS_RU.md)

## Allure

XCEasy автоматически создаёт `allure-results`; HTML и upload в TestOps выполняются отдельно. Для новых тестов метаданные рекомендуется задавать макросами:

```swift
@Epic("Authentication")
final class LoginTests: XCEasyTestCase {
    @DisplayName("Premium login")
    @Feature("Authorization")
    @Owner("Owner1")
    func testPremiumLogin() {
        find(identifier: "submitButton").tap()
    }
}
```

[Подробнее: lifecycle, labels, links, parameters и artifacts](docs/ru/guide/12_ALLURE_RU.md)

[Параметризованные XCTest, Allure-аннотации и пользовательские маркеры](docs/ru/guide/15_PARAMETERIZED_TESTS_AND_ANNOTATIONS_RU.md)

## Логи, диагностика и производительность

Обычные операции автоматически пишут человекочитаемый log, JSONL events и timing. Для начала используйте наблюдающий performance mode:

```swift
XCEasyConfig.apply(
    performance: .init(
        level: .basic,
        budgetPolicy: .observe
    )
)
```

При failure XCEasy по возможности добавляет screenshot, UI evidence и diagnostic bundle с redaction.

[Подробнее: файлы, схемы событий, performance budgets и self-healing evidence](docs/ru/guide/13_LOGS_DIAGNOSTICS_PERFORMANCE_RU.md)

## Проверка самого репозитория

Этот раздел нужен разработчикам XCEasy, а не пользователям готового package:

```bash
mise install
./scripts/check.sh all
```

[Подробнее: узкие режимы проверки и host scripts](docs/ru/guide/14_REPOSITORY_CHECKS_RU.md)

## Дополнительная документация

- [Полное руководство пользователя](docs/ru/PRODUCT_GUIDE_RU.md)
- [Техническое руководство](docs/ru/TECHNICAL_GUIDE_RU.md)
- [Спецификации по фичам](docs/ru/spec/README_RU.md)
- [Конституция проекта](docs/ru/PROJECT_CONSTITUTION_RU.md)
- [Code style](docs/ru/CODE_STYLE_RU.md)
- [Правила для AI-разработки](docs/ru/AI_DEVELOPMENT_GUIDE_RU.md)
- [Contribution guide](docs/ru/CONTRIBUTING_RU.md)

## Лицензия

XCEasy распространяется по лицензии Apache License 2.0. См. [LICENSE](LICENSE).
