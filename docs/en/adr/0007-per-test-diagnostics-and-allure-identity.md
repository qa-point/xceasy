# ADR 0007: per-test diagnostics and Allure identity

Status: accepted — 2026-08-08.

## Decision

Each execution has a unique UUID and a stable SHA-256 `testCaseId`; `historyId` is derived from that ID plus sorted, non-excluded parameters. Parameters support default, masked, hidden, and excluded behavior, with redaction before storage. Diagnostic event schema 1.0.0 adds execution/process/thread correlation, source, privacy, attachment references, transition observations, and performance evidence.

Every test writes an atomic diagnostic manifest, summary, reproduction note, immutable log snapshot, events, performance summary, and owned Allure attachments. The manifest indexes relative path, MIME, bytes, SHA-256, producer, truncation, and privacy. Allure remains an adapter; HTML generation and TestOps upload remain external.

## Consequences

This decision is included in the initial unpublished schema `1.0.0`; no schema migration is required. External `ConfigProviding` conformers must implement the configuration requirements. Bundle and Allure validators are release gates.
