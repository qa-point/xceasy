# F07 — Allure lifecycle и совместимость

Статус 0.1.1: реализовано и проверено.

## Принятые продуктовые решения

- XCEasy поддерживает Allure Report 2 и Allure Report 3.
- XCEasy не загружает launch в Allure TestOps. Он создаёт стандартные результаты; upload выполняется внешним CLI.
- Обязательный output XCEasy — агрегированная директория `allure-results`. HTML-отчёт фреймворком не генерируется.
- Канонические diagnostic events не зависят от Allure; Allure writer является adapter-ом.

## Цель

После любого XCTest execution выпустить полный, валидный и независимо записанный набор Allure-артефактов, пригодный для объединения, построения отчёта обеими версиями Allure и последующей CLI-загрузки.

## Реализованный baseline

- Создаются `*-result.json`, `*-container.json`, screenshots, logs, `executor.json`, `environment.properties` и `categories.json`.
- Модели содержат большинство базовых Allure 2 fields.
- Реализованы execution UUID, stable SHA-256 `testCaseId`, deterministic parameter-aware `historyId`, standard labels и public redacted parameter API.
- Parameters поддерживают excluded/default/masked/hidden. Result, container, service JSON, screenshots, diagnostic data и performance summaries записываются атомарно.
- In-process Allure validation проверяет identities, timelines, fixture links и каждый attachment; aggregate shell validation использует тот же stable-identity contract. Allure 2/3 generator fixtures остаются внешним compatibility gate.

## Требования к lifecycle

- `F07-REQ-001`: adapter реализует explicit key-addressed lifecycle: schedule/start/update/stop/write test, fixture и step.
- `F07-REQ-002`: `uuid` уникален для execution; `testCaseId` стабилен для XCTest case; `historyId` детерминирован из `testCaseId` и sorted non-excluded parameters.
- `F07-REQ-003`: full name строится из module, qualified class и method без зависимости от display name.
- `F07-REQ-004`: retries одного test+parameters имеют разные UUID и одинаковый history ID.
- `F07-REQ-005`: parameters поддерживают `excluded`, `masked`, `hidden`; скрытие в UI не заменяет предварительный redaction.
- `F07-REQ-006`: автоматически добавляются `framework`, `language`, `host`, `thread`, `package`, `testClass`, `testMethod`, suite hierarchy и device/environment labels.
- `F07-REQ-007`: Setup/Teardown записываются fixtures container-а; каждый `children` ссылается на существующий test UUID.
- `F07-REQ-008`: attachments имеют UUID filename, MIME type и owning test/fixture/step; result пишется только после успешного завершения referenced attachments.
- `F07-REQ-009`: JSON и attachments записываются через temporary file + atomic rename.
- `F07-REQ-010`: status/stage/statusDetails строго соответствуют Allure enum и различают assertion failure, unexpected framework error, skipped и interrupted.
- `F07-REQ-011`: Allure 2 `environment.properties`, executor/categories/history inputs поддерживаются без конфликтов; Allure 3 получает необходимые labels для environments.
- `F07-REQ-012`: неизвестное дополнительное поле не используется вместо стандартного Allure field.
- `F07-REQ-013`: результаты проходят contract fixtures через Allure 2 и Allure 3 generators.
- `F07-REQ-014`: XCEasy не запускает `allure generate`, не требует установленного Allure CLI во время тестов и завершает run после валидации агрегированного `allure-results`.
- `F07-REQ-015`: артефакты simulator/device test runner экспортируются в host-level directory детерминированной post-run command; export отклоняет непустую destination, чтобы исключить смешивание runs.

## Public capability

Должны быть доступны metadata, parameter, link, issue/TMS, description, severity/owner/tags, known/muted/flaky, step, text/data/file attachment и environment APIs. Низкоуровневый lifecycle остаётся internal либо advanced API, чтобы пользователь не мог случайно разрушить state machine.

## Acceptance criteria

- Один test создаёт ровно один валидный result и корректный fixture container.
- Nested steps и attachments отображаются под правильным owner в Allure 2 и 3.
- История сохраняется после изменения display name; параметры устройства разделяют matrix executions.
- Interrupted/crashed worker не портит уже завершённые results других tests.
- Generated results принимаются Allure CLI без warnings о missing references/invalid fields.

## Официальные контракты

- [Test result file](https://allurereport.org/docs/how-it-works-test-result-file/)
- [Container file](https://allurereport.org/docs/how-it-works-container-file/)
- [Test identifiers](https://allurereport.org/docs/how-it-works-test-identifiers/)
- [History and retries](https://allurereport.org/docs/history-and-retries/)
