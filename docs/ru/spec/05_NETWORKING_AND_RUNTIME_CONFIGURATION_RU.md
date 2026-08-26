# F05 — Networking и runtime configuration

Статус 0.1.0: runtime API реализован; `F05-REQ-002` и полная cancellation/error taxonomy ещё не закрыты.

## Цель

Обеспечить воспроизводимую настройку теста, безопасную подготовку данных через API и управляемые integrations без глобальных утечек состояния.

## As-is

- `XCEasyConfig` сохраняет backward-compatible static API, но создаёт snapshot mutable values на XCTest execution thread; localization catalogs используют ту же границу isolation.
- `actionPolicy` является частью того же execution snapshot; local action override не мутирует config.
- `XCEasyAllureConfig` хранит patterns стандартных Allure links, например `issue` и `tms`.
- Единственные public launch managers создают execution-owned copies arguments/environment до запуска app; дублирующий DSL отсутствует.
- `Deeplink.open(_ path:name:)` собирает URL из path и scheme текущего execution без отдельной route-модели. `LocalizationManager` и `XCDependencyContainer` предоставляют остальные runtime services.
- `ApiManager` сохраняет CRUD/PATCH callback и async APIs поверх internal injectable transport. Production adapter использует Alamofire вне main queue, а детерминированные unit tests подставляют fakes. Каждый request использует effective `XCEasyConfig.requestTimeout`; wait timeout и invalid non-HTTP(S) URL дают typed failures. Request logs содержат method/URL и размеры вместо raw headers/body.

## Требования

- `F05-REQ-001`: effective config immutable на execution и сериализуется после redaction.
- `F05-REQ-002`: config validation отклоняет отрицательные timeouts, invalid URLs/schemes и unwritable destinations typed errors.
- `F05-REQ-003`: environment/arguments изолированы между tests и имеют deterministic ordering.
- `F05-REQ-004`: secrets помечаются типом и никогда не выводятся raw.
- `F05-REQ-005`: networking является async-first, injectable transport; unit tests не используют real network.
- `F05-REQ-006`: API event содержит sanitized URL, method, status, timing, sizes и redacted attachment references.
- `F05-REQ-007`: timeout/cancel/network/http/decoding failures различаются стабильными codes.
- `F05-REQ-008`: deeplink construction валидирует scheme/path и создаёт typed failure, не `fatalError`.
- `F05-REQ-009`: localization fallback детерминирован и missing key диагностируется.
- `F05-REQ-010`: reset API гарантированно возвращает services к documented defaults.
- `F05-REQ-011`: presentation locale для report/log является execution-scoped configuration value; из коробки она детерминированно использует английский (`.en`, сохраняя текущий public default) и не зависит от shared mutable process state.
- `F05-REQ-012`: XCEasy поставляет полные RU и EN catalogs для каждой built-in operation; приложения могут добавлять overrides или дополнительные locales без изменения canonical codes.
- `F05-REQ-013`: localization lookup выполняется в порядке `execution override → application catalog → framework catalog для requested locale → framework English fallback → diagnostic placeholder`; missing keys и parameters создают non-recursive diagnostic event.
- `F05-REQ-014`: callback и async API используют execution-scoped `requestTimeout` и передают одно значение одновременно в transport request и ожидание completion.
- `F05-REQ-015`: `actionPolicy` имеет documented default `.hittable`, изолирован между executions и читается при semantic action.

## Acceptance criteria

- Unit tests используют fake transport/clock/config store и не требуют simulator/network.
- Параллельные тесты не видят environment/config другого execution.
- Redaction matrix покрывает headers, query, JSON, form и text bodies.
- Cancellation и timeout завершают request/step ровно один раз.
- Callback и async success/failure branches покрыты unit-тестами без real network.
- Изменение `requestTimeout` отражается в созданном `URLRequest` и не протекает в соседний parallel execution.
- Изменение `actionPolicy` внутри execution не протекает в соседний parallel execution; local override не меняет snapshot.
- Два parallel executions могут использовать разные presentation locales без смешивания локализованных steps или logs.
- Unknown locale или отсутствующий application override всё равно даёт читаемое built-in message и localization diagnostic, не завершая test с failure.

## Открытые вопросы

- `F05-OPEN-001`: сохранить Alamofire или перейти на URLSession abstraction.
- `F05-OPEN-002`: compatibility strategy для singleton static API.
