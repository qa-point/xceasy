# F13 — Test coverage и quality gates

Статус 0.1.1: unit/UI coverage gate реализован; diff coverage отложен до появления стабильной history.

## Цель

Сохранять поведение framework проверяемым при развитии XCEasy и разделять детерминированные unit-контракты и поведение, которому нужен живой XCTest UI runner.

## Реализованный baseline

- Команды framework unit и внутреннего fixture включают Xcode code coverage и сохраняют отдельные `.xcresult` bundles.
- `scripts/validate-code-coverage.sh` экспортирует и объединяет unit и fixture coverage через `xccov`, после чего оценивает только `XCEasy.framework`.
- `scripts/coverage-policy.json` задаёт общий минимум line coverage 70%. Детерминированные файлы identity, artifact isolation, privacy redaction, ambiguity и lifecycle требуют 100%; lazy search — 85%, orchestration UI assertions — 65%.
- `scripts/evaluate-code-coverage.sh` создаёт machine-readable JSON summary и возвращает non-zero status при нарушении общего или file-порога либо отсутствии target. Shell contract fixtures доказывают все rejection paths.
- Детерминированное поведение API использует injectable transport и unit-тесты вместо реальной сети. Проверены все callback/async HTTP methods и typed response branches.
- Внутренний fixture target запускает все SwiftUI/UIKit integration UI-тесты. Banner scenarios на живом accessibility tree доказывают lazy re-resolution, visible/hittable state, removal transitions и absence-safe negative assertions.

## Требования

- `F13-REQ-001`: production coverage собирается одновременно из framework unit tests и поддерживаемого внутреннего UI integration fixture.
- `F13-REQ-002`: coverage inputs объединяются до проверки, чтобы код из разных XCTest runners учитывался один раз.
- `F13-REQ-003`: gate явно выбирает `XCEasy.framework` и исключает dependencies, applications, generated-code targets и test targets из общего порога.
- `F13-REQ-004`: каждая детерминированная ветка покрывается unit-тестом с injected fake без реальной сети, внешних сервисов и произвольных sleeps.
- `F13-REQ-005`: XCUI resolution, actions, negative states и lifecycle integration покрываются simulator tests на SwiftUI и UIKit fixtures там, где значимо platform behavior.
- `F13-REQ-006`: файлы identity, per-test artifact isolation, redaction, query ambiguity и lifecycle state machine сохраняют 100% line coverage.
- `F13-REQ-007`: общие и file thresholds являются machine-readable, проверяются как source code и не снижаются только ради зелёного CI.
- `F13-REQ-008`: CI загружает raw `.xcresult`, merged coverage JSON и policy summary для диагностики человеком и ИИ.
- `F13-REQ-009`: coverage failure сообщает actual/required значения и точный target или file.
- `F13-REQ-010`: процент покрытия дополняет behavioral assertions, но не доказывает корректность и не заменяет positive, negative, concurrency, privacy и artifact-integrity tests.

## Acceptance criteria

- `./scripts/check.sh all` запускает contracts, build, полные unit/fixture suites и aggregate coverage policy.
- `./scripts/check.sh coverage` повторно проверяет существующие unit и fixture `.xcresult` bundles без перезапуска тестов.
- Fixture ниже общего порога, ниже critical-file threshold или без framework target отклоняется.
- Все настроенные critical files присутствуют в coverage report и проходят индивидуальные thresholds.
- CI artifacts содержат достаточно structured evidence для определения непокрытых файлов без разбора build console.

## Решения и оставшаяся работа

- `F13-DEC-001`: line coverage используется как portable CI gate, потому что Xcode стабильно создаёт его для unit и UI runners.
- `F13-DEC-002`: thresholds вводятся поэтапно и не снижаются. Platform failure branches, намеренно вызывающие `XCTFail`, не исполняются искусственно только ради 100% метрики.
- `F13-DEC-003`: coverage third-party и test code выводится Xcode, но исключено из product gate.
- `F13-OPEN-004`: добавить diff coverage после появления стабильной main-branch history и согласованной политики external reporting.
