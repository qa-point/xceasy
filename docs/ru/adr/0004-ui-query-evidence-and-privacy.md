# ADR 0004 — Evidence UI query и privacy

Статус: принят. Дата: 8 августа 2026 года.

## Контекст

Lazy locator chains и корректные negative assertions делают UI tests надёжными, но сами по себе не объясняют, почему query прошёл или упал. Человеку и ИИ нужны полная selector scope, наблюдаемое состояние, candidate count, polling timeline и bounded alternatives. Raw text, predicates, labels и values могут содержать credentials или персональные данные, поэтому по умолчанию их нельзя копировать в diagnostics.

У XCUI также есть consistency edge case: `XCUIElementQuery.count` может временно вернуть zero, когда выбранный `firstMatch.exists` равен true. Если считать count более сильным evidence, возникает ложный `ancestor_absent`.

## Решение

Diagnostic event schema `1.0.0` добавляет `parentOperationId`, `selector` и `queryEvidence`. Каждое semantic UI resolution создаёт `ui.query.started`, затем `ui.query.resolved` или `ui.query.failed`. Query operation получает собственный ID и связывается с enclosing action/assertion operation, если она есть.

`selector` — immutable root-to-child sequence из type, strategy, redacted value metadata и optional index. Его SHA-256 fingerprint детерминирован по privacy-safe representation. `fingerprintConfidence` равен `exact` для неизменённых stable identifiers и `privacy_reduced`, если predicate/text/secret-bearing input был заменён; consumer не должен считать collision privacy-reduced fingerprint доказательством identity элемента.

`queryEvidence` фиксирует expected, initial и final states; match result; canonical reason code; elapsed milliseconds; attempts; matching candidate count; selected index; failed locator segment; ancestor state и до пяти candidate snapshots. Candidate identifiers проходят pattern redaction. Selector text/predicate и candidate labels/values до любого sink заменяются typed placeholders с исходной длиной.

Существующий selected element является первичным evidence совпавшего segment. Effective candidate count не меньше `selectedIndex + 1`, когда `exists == true`, даже если XCUI сообщил меньше. Missing ancestor даёт `query.ancestor_absent`, missing final segment — `query.element_absent`, permissive выбор при нескольких совпадениях — `query.ambiguous_first_match` с warning level.

JSON Schema хранится в `schemas/diagnostic-event-1.0.0.schema.json`. `scripts/validate-diagnostic-events.sh` выполняет dependency-free structural/canary contract check, используемый репозиторием.

## Последствия

- ИИ может восстановить component scope и outcome negative assertion без parsing локализованного текста.
- Query events связываются с вызвавшим их action/assertion.
- Sensitive labels, values, text selectors и predicates недоступны в raw form; diagnosis использует stable identifiers, длины, state, geometry и bounded alternatives.
- Чтение candidate count/snapshots добавляет overhead. Evidence ограничен, а performance должен продолжать измеряться.
- Strict ambiguity failure, полный accessibility snapshot, screenshot при timeout, source locations и configurable privacy policy остаются будущей работой.
- Решение входит в первоначальную неопубликованную schema `1.0.0`; consumer migration не требуется.
