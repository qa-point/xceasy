# F09 — Self-healing и генерация тестов

Статус 0.1.0: controlled selector-healing workflow реализован; full generated-test acceptance остаётся открытым.

## Цель

Диагностические данные должны позволять ИИ доказательно предложить восстановление selector-а, обновление Page Object/assertion или новый тест, не скрывая product defects и не изменяя тесты без контролируемой проверки.

## Границы

- Evidence collection и candidate generation обязательны.
- Автоматическое применение patch не является default behavior.
- Self-healing не должен превращать failed test в passed без повторного выполнения и audit trail.
- Product behavior и expected values не изменяются автоматически только потому, что UI изменился.

## Требования к evidence

- `F09-REQ-001`: failed UI query сохраняет canonical selector, parent chain, strategy, timeout, candidate count и bounded candidate snapshots.
- `F09-REQ-002`: candidate содержит element type, identifier, label/value после redaction, traits, frame, enabled/selected/hittable и hierarchy path.
- `F09-REQ-003`: before/after accessibility snapshots и screenshots связываются event/attachment IDs.
- `F09-REQ-004`: action/assertion сохраняет intent, preconditions, expected, actual, last observed state и source location.
- `F09-REQ-005`: manifest содержит git SHA/dirty state, app/framework versions, locale, device/OS, launch config и relevant test/Page Object source references.
- `F09-REQ-006`: для генерации теста записывается user journey как последовательность semantic actions, а не только coordinates/text log.
- `F09-REQ-007`: secrets и user-entered sensitive values заменяются typed placeholders до AI input.

## Реализованный baseline diagnostic handoff

Независимый `xceasy-runner` может агрегировать per-test evidence в стабильный итог run, integrity manifest и worker classifications. Эти host artifacts и policies версионируются runner, а не Swift package XCEasy.

Per-test schema `1.0.0` добавляет полные redacted parent chains, privacy-aware fingerprints, transition observations, source/performance/attachment correlation, failure screenshots, bounded redacted UI hierarchies и per-test integrity manifests. Default `basic` сохраняет до пяти candidates на failure/ambiguity; `detailed` делает это для каждого query.

Deterministic healing engine отклоняет semantic type mismatch, low confidence и почти равные alternatives. `XCEasyHealingConfiguration` по умолчанию работает в `observe`; `suggest` создаёт reviewable proposal, и каждый proposal требует human approval. `scripts/build-ai-handoff.sh` создаёт provider-neutral healing и test-generation requests. `build-healing-source-bundle.sh` экспортирует не более 20 явно указанных Swift-файлов и 1 MiB после проверки path, hash, canary и вероятных secrets. `invoke-healing-provider.sh` запускает явно настроенную local/external command с bounded timeout и проверяет, что response выбирает ranked candidate из evidence, не меняет assertion и по-прежнему требует human approval. Adapter не создаёт approval record и не изменяет source. `apply-healing-proposal.sh` принимает только отдельно reviewed suggested candidate, проверяет SHA-256 исходника, по умолчанию лишь готовит diff и может заменить ровно один selector literal с фиксированным verification profile. При провале проверки исходник восстанавливается. Assertion rewriting и in-process runtime mutation запрещены.

## Требования к healing

- `F09-REQ-008`: healing engine выдаёт ranked candidates с confidence, evidence и reason codes.
- `F09-REQ-009`: auto-healable изменение ограничено selector metadata/Page Object mapping; изменение assertion expectation требует human approval.
- `F09-REQ-010`: candidate отклоняется при неоднозначности выше configurable threshold или semantic type mismatch.
- `F09-REQ-011`: patch связывается с исходным execution/failure fingerprint и содержит diff, affected tests и rollback data.
- `F09-REQ-012`: после patch выполняются failed test, targeted related tests и selector contract tests на исходной environment.
- `F09-REQ-013`: test становится passed только по результату rerun; отчёт сохраняет original failure и healed attempt как связанные executions.
- `F09-REQ-014`: repeated healing одного selector-а считается instability и требует review, а не бесконечного auto-update.

## Требования к генерации тестов

- `F09-REQ-015`: generated test следует project code style, Page Object boundaries и Given/When/Then.
- `F09-REQ-016`: генератор использует stable identifiers; coordinate/index selectors допускаются только как помеченный fallback.
- `F09-REQ-017`: каждое assertion в generated test связано с наблюдаемым outcome/evidence, а не случайным snapshot property.
- `F09-REQ-018`: generated code компилируется и проходит lint/targeted run до предложения пользователю.
- `F09-REQ-019`: AI handoff перечисляет assumptions, evidence IDs, confidence и неподтверждённые gaps.
- `F09-REQ-020`: source export allowlisted, size-bounded, hash-addressed, остаётся внутри repository и отклоняется при secret canary или вероятном embedded credential.
- `F09-REQ-021`: применение требует versioned approval с reviewer, timestamp, proposal, candidate, точным source hash и verification profile.
- `F09-REQ-022`: dry-run является default; применённое изменение откатывается при неуспешной проверке и создаёт machine-readable audit.
- `F09-REQ-023`: AI provider подключается как allowlisted command-array adapter с bounded execution time; shell evaluation запрещён.
- `F09-REQ-024`: provider output остаётся suggestion-only и отклоняется, если proposal ID, evidence candidate index, identifier, reason codes, no-assertion-change flag или human-approval flag не соответствуют локальному контракту.

## Acceptance criteria

- Fixture со сменившимся identifier предлагает правильный replacement первым кандидатом и не применяет его без policy permission.
- Fixture с двумя визуально одинаковыми элементами останавливает auto-healing как ambiguous.
- Изменение expected business text не маскируется selector healing-ом.
- Canary secrets отсутствуют во всём AI input и generated code.
- Generated regression test падает на старом fixture и проходит на исправленном.

## Решения

- `F09-DEC-001`: providers являются pluggable host commands. Один contract поддерживает local model или client внешнего сервиса без vendor SDK в test runner. Shape конфигурации документирован в `xceasy.ai-provider.example.json`.
- `F09-DEC-002`: авторизованный host adapter поддерживает `package`, `unit`, внутренний `integration` или `all` verification и rollback.
- `F09-DEC-003`: source bundle explicit, hash-addressed и ограничен 20 Swift-файлами и 1 MiB.
