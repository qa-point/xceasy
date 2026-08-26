# ADR 0007: per-test diagnostics и Allure identity

Статус: принят — 2026-08-08.

## Решение

Каждый execution имеет unique UUID и stable SHA-256 `testCaseId`; `historyId` строится из него и sorted non-excluded parameters. Parameters поддерживают default, masked, hidden и excluded, а redaction выполняется до storage. Schema diagnostic events 1.0.0 добавляет execution/process/thread correlation, source, privacy, attachment references, transition observations и performance evidence.

Каждый test атомарно пишет diagnostic manifest, summary, reproduction note, immutable log snapshot, events, performance summary и собственные Allure attachments. Manifest индексирует relative path, MIME, bytes, SHA-256, producer, truncation и privacy. Allure остаётся adapter; HTML generation и TestOps upload выполняются снаружи.

## Последствия

Решение входит в первоначальную неопубликованную schema `1.0.0`, поэтому schema migration не требуется. Внешние conformers `ConfigProviding` реализуют config requirements. Bundle и Allure validators являются release gates.
