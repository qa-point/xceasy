# ADR 0005 — Политика сбора UI query evidence

Статус: принят. Дата: 8 августа 2026 года.

## Контекст

Development-измерения показали пользу bounded UI candidate snapshots для AI diagnosis, но чтение labels, values, frames и state из XCUI является remote operation. Сбор этих полей после каждого успешного lookup увеличил время репрезентативного UIKit banner test до 77,6 секунды. Для успешного однозначного query такой payload обычно не нужен, а failures и ambiguous matches должны сохранять его для self-healing.

Политика должна быть execution-scoped, чтобы параллельные тесты не меняли evidence level друг друга. Canonical events должны явно показывать, отсутствовали ли candidates в UI или были намеренно пропущены политикой.

## Рассмотренные варианты

- Всегда собирать все candidate snapshots: максимальное evidence успешных queries, но неприемлемый default overhead.
- Полностью убрать candidate snapshots: быстро, но нарушает требования failure diagnosis и self-healing.
- Случайно сэмплировать успешные queries: полезно на больших объёмах, но недетерминированно и сложнее для анализа одного test artifact.
- Ввести детерминированные levels с failure-focused default: предсказуемо, настраиваемо и сохраняет полное failure evidence.

## Решение

Добавить execution-scoped `XCEasyConfig.uiQueryEvidenceLevel` с тремя значениями:

- `off`: не создавать `ui.query.*` events и не читать candidate counts/snapshots; поведение query не меняется.
- `basic`: default; создавать lifecycle, selector, state, duration, attempts и candidate count, но собирать bounded candidate snapshots только при падении query или ambiguous result.
- `detailed`: создавать тот же lifecycle и собирать до пяти candidates для каждого завершённого query.

Schema `1.0.0` добавляет обязательные `queryEvidence.evidenceLevel` и `queryEvidence.candidateCollection`. `candidateCollection` равен `bounded`, когда framework пытался собрать snapshots, и `omitted_by_policy`, когда candidate array намеренно пропущен. Events уровня `detailed` обязаны использовать `bounded`; `omitted_by_policy` требует пустой array.

## Проверка

На simulator iPhone 17 Pro с iOS 26.5 один и тот же UIKit integration test для promo banner занял 77,561 секунды с прежней always-snapshot реализацией и 23,505 секунды с default policy `basic`: локальное сокращение примерно на 69,7%. Полученный artifact содержал 44 events schema 1.0.0 и 10 завершённых UI queries; все успешные однозначные queries явно использовали `omitted_by_policy` с пустыми candidate arrays. Измерение подтверждает выбранное направление, но не является performance guarantee для всех devices и не заменяет итоговый overhead budget F10.

## Последствия

- Успешные searches по умолчанию не выполняют самые дорогие diagnostic reads.
- Failures и ambiguous selectors остаются пригодными для AI diagnosis и candidate ranking.
- Consumer отличает пустой match set от пропуска по политике без inference.
- `off` — явный diagnostic tradeoff; его следует использовать для контролируемых performance measurements или в окружениях, запрещающих query telemetry.
- Полный span phase accounting и утверждённый overhead budget остаются будущей работой F10.
- Policy входит в первоначальную неопубликованную schema `1.0.0`; consumer migration не требуется.
