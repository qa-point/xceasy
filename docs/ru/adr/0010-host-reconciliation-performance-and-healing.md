# ADR 0010: Host reconciliation, performance history и controlled healing

Статус: принят — 2026-08-09.

## Решение

Evidence, которое должно переживать XCTest process, восстанавливается host tools, а не общим mutable runtime state. Missing planned executions становятся явно помеченными synthetic `broken` Allure results в новой директории; логический run остаётся interrupted.

Cross-run performance comparison использует versioned JSON baselines, разделённые explicit environment key. Regression требует minimum sample count и одновременного relative/absolute роста p95. Историю хранит CI или пользователь.

Healing остаётся provider-neutral и review-first. ИИ получает только explicit, bounded, hash-addressed source bundle после secret checks. Применение selector proposal требует versioned human approval, точный source hash, одну literal replacement, фиксированный verification profile и rollback при failure. Adapter не может менять assertions и business expectations.

## Последствия

Crash evidence восстанавливается без выдуманного success. Performance recommendation воспроизводима и ссылается на source summaries. AI provider может меняться без изменения artifact contract. Runtime теста не модифицирует source, а publication/signing authority остаётся вне automation.
