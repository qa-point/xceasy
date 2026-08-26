# Конфигурация

Русский · [English](../../en/guide/01_CONFIGURATION_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Настройку обычно выполняют в `configuration()` базового `XCEasyTestCase`. У каждого параллельного теста своя копия effective configuration и свой язык логов.

```swift
import XCTest
import XCEasy

class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.yourcompany.app",
            findTimeout: 15,
            actionTimeout: 10,
            assertionTimeout: 5,
            requestTimeout: 30,
            actionPolicy: .hittable,
            localization: .ru,
            deeplinkSchema: "myapp",
            printLogToConsole: true,
            uiQueryEvidenceLevel: .basic,
            uiQueryAmbiguityPolicy: .strict,
            visibilityPolicy: .onScreen,
            performance: .init(
                level: .basic,
                defaultBudgetMilliseconds: 2_000,
                operationBudgetsMilliseconds: ["ui.tap": 1_000],
                budgetPolicy: .observe
            ),
            healing: .init(
                mode: .observe,
                minimumConfidence: 0.75,
                minimumScoreGap: 0.12
            ),
            diagnosticSnapshotByteLimit: 512_000
        )

        // Вызывайте после пользовательских настроек: XCEasy запишет effective config в лог.
        super.configuration()
    }
}
```

## Основные параметры

| Параметр | По умолчанию | Назначение |
|---|---:|---|
| `bundleId` | `""` | Bundle ID тестируемого приложения. Пустое значение использует обычный `XCUIApplication()` текущего UI-test target. |
| `findTimeout` | 10 с | Сколько ждать положительного поиска элемента для операций, использующих timeout locator-а. |
| `actionTimeout` | 10 с | Стандартное ожидание для действий и булевых проверок состояния. |
| `assertionTimeout` | 10 с | Стандартное ожидание для UI assertions. Отрицательная проверка ждёт ожидаемого отсутствия до истечения этого времени. |
| `requestTimeout` | 10 с | Timeout HTTP-запросов `ApiManager`. |
| `actionPolicy` | `.hittable` | Default для `tap`, `doubleTap`, `press`, `swipe`, `typeText` и `clearField`. `.hittable` ждёт безопасную semantic action; `.displayed` ждёт отображения и использует coordinate dispatch с warning-диагностикой. |
| `localization` | `.en` | Язык стандартных шагов и сообщений: `.en` или `.ru`. На identifiers не влияет. |
| `deeplinkSchema` | `DEFAULT_DEEPLINK_SCHEMA` | Схема до `://`, например `myapp` для `myapp://settings`. |
| `printLogToConsole` | `true` | `true` дублирует framework log в консоль Xcode; файловые и Allure-артефакты сохраняются независимо. |
| `diagnosticSnapshotByteLimit` | 65 536 | Максимальный размер одного снимка accessibility tree в байтах. `0` отключает содержимое snapshot; меньший лимит уменьшает артефакты, но оставляет меньше данных для отладки. |

`apply` изменяет только переданные значения: `nil` означает «оставить текущее». Поэтому дочерний test class может переопределить один параметр, не копируя весь base config. Значения snapshot-ятся для каждого test execution и не протекают в соседние параллельные тесты.

## Action policy и язык

| Значение | Поведение |
|---|---|
| `actionPolicy: .hittable` | Безопасный default. Действие ждёт `isHittable` и вызывает semantic XCUI action. Overlay или неподходящая hit point приводят к диагностируемому failure. |
| `actionPolicy: .displayed` | Compatibility mode. Действие ждёт видимый frame и отправляется по координатам. Может попасть в перекрывающий view, поэтому XCEasy пишет warning. |
| `localization: .ru` | Русские стандартные названия шагов и сообщений. |
| `localization: .en` | Английские стандартные названия шагов и сообщений; default. |

Policy можно переопределить для одной операции: `icon.tap(policy: .displayed)`. Это не меняет config остальных действий.

## `uiQueryEvidenceLevel`

| Значение | Что сохраняется |
|---|---|
| `.off` | Не пишет события `ui.query.*`. Сам поиск и обычные action/assertion logs продолжают работать. |
| `.basic` | Рекомендуемый default: состояние, locator, время, число результатов; подробности кандидатов собираются при failure или ambiguity. |
| `.detailed` | Добавляет ограниченные сведения о кандидатах для каждого поиска. Полезно при сложной диагностике, но создаёт больше данных. |

## `uiQueryAmbiguityPolicy`

| Значение | Поведение при нескольких найденных элементах |
|---|---|
| `.strict` | Default. Операция падает, чтобы тест случайно не нажал не тот элемент. Уточните locator или задайте `index`. |
| `.permissive` | Берёт первый элемент и пишет warning с диагностикой. Включайте только осознанно. |

## `visibilityPolicy`

| Значение | Когда элемент считается отображаемым |
|---|---|
| `.onScreen` | Default. Frame элемента должен пересекаться с frame приложения. Это обычный вариант для UIKit и SwiftUI. |
| `.nonEmptyFrame` | Достаточно любого конечного непустого frame, даже вне viewport. Нужен только для нестандартных accessibility bridges с ненадёжным viewport. |

## `performance`

- `level: .off` — timing evidence отключён;
- `.basic` — длительность операции и итоговая статистика;
- `.detailed` — дополнительно доступные фазы операции;
- `defaultBudgetMilliseconds` — общий допустимый лимит; `nil` означает «лимита нет»;
- `operationBudgetsMilliseconds` — отдельные лимиты по кодам вроде `ui.tap`, `ui.query`, `test.step`; они важнее общего лимита;
- `budgetPolicy: .observe` — только записать превышение;
- `.warn` — записать warning, но не падать;
- `.fail` — явно завершить тест с failure при превышении.

Для первого подключения используйте `.observe`, соберите baseline на стабильном окружении и только затем вводите предупреждения или failures.

## `healing`

Self-healing никогда не меняет исходный код во время теста.

- `mode: .observe` — сохраняет evidence, но не создаёт предложение замены locator-а;
- `.suggest` — может сформировать reviewable proposal для подходящего кандидата;
- `minimumConfidence` — минимальная оценка лучшего кандидата от `0` до `1`;
- `minimumScoreGap` — минимальный отрыв лучшего кандидата от второго от `0` до `1`.

Предложение должно быть проверено человеком или отдельным approved automation workflow.

## Конфигурация ссылок Allure

`XCEasyAllureConfig` хранит patterns стандартных типов ссылок. Они используются функциями `issue(_:)` и `tms(_:)`; на создание локального `allure-results` не влияют.

```swift
override func configuration() {
    XCEasyAllureConfig.apply(linkPatterns: [
        "issue": "https://jira.example.com/browse",
        "tms": "https://testops.example.com/testcase"
    ])
    super.configuration()
}
```

## Что будет в логах и отчёте

Вызов `super.configuration()` создаёт fixture `Setup → Test Configuration`, внутри которого выводятся effective значения:

```text
Setup
  Test Configuration
    Basic XCEasy configuration
      assertionTimeout: 5.0
      actionPolicy: hittable
      localization: ru
      performance.level: basic
      performance.budgetPolicy: observe
```

Config хранится отдельно для каждого execution. Секреты не следует задавать в публичных названиях или URL; launch environment и HTTP headers предназначены для чувствительных runtime-значений, но и там действует redaction.
