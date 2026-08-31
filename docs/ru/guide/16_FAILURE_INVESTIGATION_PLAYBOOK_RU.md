# Playbook расследования падений

Русский · [English](../../en/guide/16_FAILURE_INVESTIGATION_PLAYBOOK_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Диагностика](13_LOGS_DIAGNOSTICS_PERFORMANCE_RU.md)

Используйте этот playbook в первые 5–10 минут после падения теста XCEasy. Его задача — найти первое причинное падение, классифицировать его и сохранить минимальный полезный набор evidence. Он не заменяет процесс разбора product incidents или формальный [контракт отчётности](../spec/04_REPORTING_AND_AI_DIAGNOSTICS_RU.md).

## Перед началом

Анализируйте по одной попытке теста. Используйте её уникальный `executionId`; не смешивайте файлы разных retries, shards, devices или соседних параметризованных cases. До сравнения с другим прогоном запишите имя теста, attempt, device, OS, app build, Xcode/toolchain и execution mode.

Уровень query evidence `.basic` по умолчанию подходит для обычных локальных и CI-прогонов. В режиме `.off` UI-query artifacts меньше, а `.detailed` добавляет candidate evidence для успешных queries и нужен для контролируемого перезапуска, когда исходных данных недостаточно.

## Первый проход

### 1. Начните с упавшей ветки Allure

Откройте failed test и разверните самый глубокий failed или broken step. Зафиксируйте:

- operation и target;
- expected и actual/final state;
- elapsed time;
- source file и line, если они есть;
- первое содержательное сообщение об ошибке.

Не начинайте с teardown или reporting error только потому, что она записана последней. После причинного падения прерванная операция может создать дополнительные cleanup-сообщения.

### 2. Сопоставьте screenshot и UI hierarchy

По screenshot определите, что видел человек. По `Redacted UI hierarchy` проверьте accessibility-состояние, которое мог запрашивать XCUI.

При неуспешном XCEasy UI query или наблюдении component collection с включённым query evidence XCEasy снимает текущий `debugDescription` приложения, выполняет redaction, ограничивает его размером `diagnosticSnapshotByteLimit` и прикрепляет к test result. Создавший artifact diagnostic event содержит ссылку на него. Это accessibility hierarchy приложения, а не pixel-perfect описание визуального перекрытия элементов.

Hierarchy не гарантируется, если:

- падение не прошло через XCEasy UI query, например упал обычный value `XCTAssert`;
- query evidence был `.off`;
- application context был недоступен;
- запись artifact завершилась ошибкой.

Для failure screenshot также нужно foreground application window. Observer прикрепляет доступный screenshot XCTest issue к тесту и последнему failed step либо, как fallback, к самому глубокому известному шагу. Поэтому при launch/context failure screenshot может законно отсутствовать.

Если hierarchy выглядит неполной, проверьте diagnostic manifest. `truncated: true` означает, что snapshot был обрезан настроенным byte limit; это не подтверждает, что XCUI вернул полное дерево.

### 3. Найдите первое причинное событие

Откройте `<executionId>_events.jsonl` и найдите первую относящуюся к проблеме operation со `statusCode: "failed"` или event уровня error. По `parentOperationId` поднимитесь к содержащему action, assertion или пользовательскому step и сопоставьте:

- `operationCode` и `reasonCode`;
- locator chain в `selector`;
- `queryEvidence.expectedState` и `finalState`;
- attempts, duration, candidate count, selected index и failed segment;
- source location и связанные attachments.

Локализованный заголовок Allure — presentation text. Для группировки падений и автоматизированного анализа используйте стабильные operation и reason codes.

### 4. Используйте log как хронологию

Прочитайте `<testId>_xceasy_log.log` вокруг причинной операции. Log полезен для анализа setup, предшествующих business steps, подготовки через API, relaunch и cleanup. Считайте его supporting evidence; для машинной корреляции используйте JSONL и ссылки на artifacts.

### 5. Проверьте целостность bundle

Откройте `<executionId>_diagnostic-manifest.json` и убедитесь, что указанные artifacts существуют. MIME type, byte count, SHA-256, producer event, privacy classification и truncation flag помогают отличить намеренно ограниченный artifact от потерянного или изменённого.

Ошибки telemetry или attachments должны оставаться видимыми, но не заменять исходный outcome теста. Зафиксируйте и причинное падение теста, и ошибку evidence.

## Справочник по симптомам

| Симптом | Что проверить сначала | Вероятные направления |
|---|---|---|
| Элемент не найден | Locator chain, failed segment, итоговую hierarchy, app state, screenshot | Неверный экран/precondition, изменённый identifier, элемент не опубликован в accessibility, product UI отсутствует. |
| В `.strict` найдено несколько элементов | Candidate count и ограниченный список candidates | Identifier не уникален, scope слишком широкий, repeated component требует явного выбора. |
| Элемент существует, но не displayed или hittable | Final state, frame/viewport evidence, screenshot, action policy | Элемент вне экрана, overlay, disabled control, неверное ожидание готовности. XCUI geometry не доказывает полное визуальное перекрытие. |
| Wait или action завершился по timeout | Attempts, observation timeline, duration, предыдущую operation | Product transition не произошёл, нестабильный locator/state, задержка backend, заблокированный UI. Не увеличивайте timeout, пока не определено неизменившееся состояние. |
| Приложение не запустилось или нет window | Setup/launch events, app state, simulator и toolchain logs | Crash/configuration приложения, simulator/infrastructure, неподдерживаемое окружение. Отсутствие screenshot здесь ожидаемо. |
| Упал обычный value assertion | Expected/actual assertion, source, log и events | Product data или ожидание теста. UI hierarchy может отсутствовать, потому что UI query не падал. |
| Последней показана teardown или reporting error | Более раннюю failed operation и parent chain | Обычно это вторичная cleanup/evidence error; сохраните её, не заменяя первую причину. |
| Artifact отсутствует или отличается hash/size | Manifest entry и telemetry errors | Неполный сбор, изменение artifact, дефект framework/reporting или внешняя модификация. |
| Упал performance budget | Performance evidence и совместимый baseline | Реальное замедление, несовместимые окружения, шумный threshold или тяжёлая диагностика. Сравнивайте только совместимые прогоны. |

## Классифицируйте результат

Выберите одну classification и укажите подтверждающие evidence:

| Classification | Когда использовать |
|---|---|
| Product | Наблюдаемое поведение приложения нарушает ожидаемый product contract, а preconditions теста и locator intent остаются корректными. |
| Test | Selector, setup, test data, зависимость от порядка или expected result устарели либо неверны. |
| Infrastructure | Simulator/device, Xcode/toolchain, network dependency, signing, installation или host помешали корректному execution. |
| Framework | Lifecycle XCEasy, lookup semantics, step status, serialization, isolation, redaction или artifact ownership работают неверно. |
| Unknown | Доступные evidence не позволяют различить варианты. Укажите, какой artifact или контролируемый перезапуск нужен дальше. |

Не называйте нестабильное падение infrastructure только потому, что retry прошёл. Сначала сопоставьте fingerprints, timelines, environment keys и состояние приложения.

## Если evidence недостаточно

Перезапускайте тест только после сохранения исходного execution. По возможности оставьте прежними app build, test data, simulator/device class и toolchain. Для расследования locator измените только evidence level:

```swift
override func configuration() {
    XCEasyConfig.apply(
        uiQueryEvidenceLevel: .detailed,
        uiQueryAmbiguityPolicy: .strict,
        diagnosticSnapshotByteLimit: 512_000
    )
    super.configuration()
}
```

Увеличение `diagnosticSnapshotByteLimit` сохраняет больше большой hierarchy, но увеличивает размер artifacts. `.detailed` меняет diagnostic overhead, поэтому не сравнивайте performance такого перезапуска с прогоном `.basic`.

Никогда не добавляйте production tokens, passwords, cookies, personal data или raw network bodies ради улучшения диагностики. Redaction — защитный слой, а не разрешение экспортировать artifacts.

## Пакет для передачи

Другому инженеру или разрешённому AI workflow передавайте набор одного execution:

- test name, `testId`, `executionId`, attempt и source location;
- device/OS, app build, Xcode/toolchain и execution mode;
- failed Allure branch и status details;
- diagnostic summary, reproduction note, manifest и JSONL;
- связанные screenshot, UI hierarchy, candidate evidence и log;
- вашу classification, evidence и оставшуюся hypothesis;
- точную команду воспроизведения/проверки, если она известна.

Перед внешней передачей проверьте privacy classification и правила команды. Не смешивайте artifacts разных попыток и не удаляйте correlation identifiers.

## Чек-лист завершения

Первичный разбор завершён, когда:

- найдена первая причинная operation либо названо отсутствующее evidence;
- записана classification product, test, infrastructure, framework или unknown;
- объяснено наличие или отсутствие screenshot и hierarchy;
- проверены truncation и integrity по manifest;
- следующее действие конкретно: product fix, test fix, восстановление окружения, framework defect или контролируемый rerun;
- build, test или fix не объявлены успешными без реально завершившейся verification command.
