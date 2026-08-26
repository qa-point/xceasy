# Логи, диагностика и производительность

Русский · [English](../../en/guide/13_LOGS_DIAGNOSTICS_PERFORMANCE_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


XCEasy пишет данные одновременно для двух аудиторий:

- человек читает локализованный `.log` и шаги Allure;
- ИИ или CI-инструмент читает versioned JSONL и manifest со стабильными английскими кодами, не разбирая русский или английский текст.

## Файлы одного теста

| Файл | Что в нём находится | Для кого |
|---|---|---|
| `<testId>_xceasy_log.log` | Последовательный человекочитаемый log без ANSI: test lifecycle, действия, проверки и ошибки. | Человек, Allure attachment. |
| `<executionId>_events.jsonl` | По одному JSON event на строку: lifecycle, steps, UI queries/actions/assertions, API и attachments. Schema версионируется. | ИИ, CI, диагностические инструменты. |
| `<executionId>_performance-summary.json` | Количество и длительность операций, min/max/mean/median/p90/p95/p99 и превышения budget. | Поиск замедлений и сравнение прогонов. |
| `<executionId>_diagnostic-summary.json` | Краткая classification ошибки и стабильный fingerprint. | Группировка одинаковых падений. |
| `<executionId>_reproduction.md` | Краткое evidence-oriented описание воспроизведения. | Человек или ИИ, который готовит fix/test. |
| `<executionId>_diagnostic-manifest.json` | Индекс artifacts: path, MIME type, размер, SHA-256, producer, privacy и признак truncation. | Проверка полноты и целостности bundle. |
| `*-result.json`, `*-container.json`, attachments | Стандартные данные Allure для теста и fixtures. | Allure CLI/TestOps. |

`testId` стабильно связывает повторы одного теста, а уникальный `executionId` отделяет конкретную попытку. В multi-device запуске дополнительно записываются `runId`, device, shard и attempt, поэтому два параллельных теста не смешиваются.

## Что записывается для операции

Для обычного `tap`, assertion, запроса или пользовательского `step` event содержит доступные поля: тип события, стабильный `operationCode`, start/finish status, duration, родительскую операцию, test/execution IDs и source location. UI query дополнительно сохраняет ленивую locator chain, ожидаемое и последнее состояние, timeout, число попыток и кандидатов, выбранный index и reason code. Благодаря связям `parentOperationId` можно восстановить цепочку «тест → шаг → assertion → поиск».

Уровень `uiQueryEvidenceLevel` управляет объёмом query evidence. `.basic` собирает подробных кандидатов в основном при failure или ambiguity, а `.detailed` — при каждом поиске и поэтому медленнее и больше по размеру.

## Что происходит при падении

При failure XCEasy по возможности сохраняет screenshot, ограниченный снимок accessibility tree, timeline наблюдаемых состояний, до пяти подходящих/альтернативных кандидатов, итоговую причину и healing proposal. Proposal является только рекомендацией: runtime не меняет source code и не продолжает тест с другим locator-ом. `diagnosticSnapshotByteLimit` ограничивает дерево; если данные обрезаны, manifest явно содержит truncation metadata.

Перед console, log, JSONL и Allure sink применяется redaction. Значения, похожие на token, password, Authorization/cookie или другой secret, не должны попадать в artifacts. Masked/hidden Allure parameters заменяются до записи. Всё равно не передавайте реальные production secrets в названия шагов или accessibility identifiers.

## Как анализировать производительность

Timing автоматически охватывает `ui.query`, `ui.tap` и другие actions, UI/value assertions, API requests, `step` и fixtures. `performance-summary.json` агрегирует одинаковые operation codes, чтобы отличить единичный медленный вызов от систематического замедления.

Рекомендуемый процесс:

1. Запустите стабильный набор с `budgetPolicy: .observe` и соберите baseline на одинаковом Xcode, simulator/device и configuration.
2. Сравнивайте median и p95 между совместимыми прогонами. Например, рост `ui.query` часто указывает на нестабильный locator или перегруженное accessibility tree, а рост API operation — на backend/network.
3. Задайте отдельные `operationBudgetsMilliseconds`, если разные операции имеют разные нормальные интервалы.
4. Переведите подтверждённые пороги в `.warn`; `.fail` используйте только для требований, где превышение действительно должно падать тестом.

Сравнивать результаты разных моделей устройств, версий OS или режимов evidence без отдельной нормализации нельзя: различие окружения легко принять за регрессию продукта.

Для ручной диагностики текущего экрана:

```swift
find(identifier: "screenRoot").printDebugTree()
```

`printDebugTree()` печатает текущее дерево в консоль и нужен для локального расследования. Обычный тест не должен полагаться на его текст как на assertion или машинный контракт.

## Как выбрать объём диагностики

| Сценарий | Рекомендуемая настройка | Компромисс |
|---|---|---|
| Обычный локальный/CI прогон | `.basic`, `.strict`, performance `.basic/.observe` | Evidence при failure без большого объёма на success. |
| Расследование flaky locator | `uiQueryEvidenceLevel: .detailed` | Кандидаты для каждого query; artifacts и overhead растут. |
| Лёгкий smoke | query evidence `.off`, performance `.off` | Steps/logs остаются, но ИИ получает меньше контекста. |
| Сбор baseline | performance `.detailed/.observe` | Больше phase data; budget не падает. |
| Мягкий контроль | `.basic/.warn` + operation budgets | Warning без functional failure. |
| Жёсткий SLA | `.basic/.fail` + проверенные budgets | Медленная операция становится failure. |

```swift
class DiagnosticBaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            printLogToConsole: true,
            uiQueryEvidenceLevel: .basic,
            uiQueryAmbiguityPolicy: .strict,
            performance: .init(
                level: .basic,
                defaultBudgetMilliseconds: 2_000,
                operationBudgetsMilliseconds: [
                    "ui.query": 1_500,
                    "ui.tap": 1_000,
                    "api.request": 5_000
                ],
                budgetPolicy: .observe
            ),
            healing: .init(mode: .observe),
            diagnosticSnapshotByteLimit: 512_000
        )
        super.configuration()
    }
}
```

## Как выглядит связанная трасса

```swift
func testCloseBanner() {
    step("Закрыть промобаннер") {
        let banner = find(identifier: "promoBanner", desc: "Промобаннер")
        banner.assertDisappears(timeout: 5) {
            banner.child(identifier: "promoBanner.close", desc: "Кнопка закрытия").tap()
        }
    }
}
```

```text
Закрыть промобаннер                         passed  438 ms
  Проверить исчезновение [Промобаннер]      passed  431 ms
    Нажать [Кнопка закрытия]                 passed   82 ms
      UI query                              passed   21 ms
    UI query: expected absent               passed  341 ms
```

ИИ видит те же связи по `operationId`/`parentOperationId`, locator chain, ожидаемое `absent`, attempts, terminal state и timing. При failure bundle добавляет screenshot/tree/candidates и reason code; локализованный заголовок разбирать не нужно.

## Performance budgets на практике

Budget ищется сначала по точному operation code, затем берётся `defaultBudgetMilliseconds`. `.observe` сохраняет finding, `.warn` добавляет warning, `.fail` регистрирует failure. `.off` отключает timing, поэтому budget применить осмысленно нельзя.

Не задавайте threshold по одному прогону. Соберите несколько запусков на одинаковом device/OS, смотрите median и p95 и оставьте запас на шум. Для UI query и API request почти всегда нужны разные budgets.

## Что безопасно передавать ИИ

Передавайте manifest, JSONL, reproduction, performance summary и связанные attachments одного execution. Не смешивайте попытки и не удаляйте identifiers связей. Redaction — защитный слой, но перед внешней отправкой всё равно проверьте privacy classification и правила команды.
