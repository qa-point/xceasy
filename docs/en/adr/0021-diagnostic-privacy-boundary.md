# ADR 0021: diagnostic detail and credential privacy

Status: accepted on 2026-09-09 after maintainer discussion.

## Context

A UI-test framework needs screenshots, field values, UI trees and explicit debug output to explain failures. Existing regex filtering cannot guarantee removal of all credentials or personal data.

## Decision

Preserve current diagnostic behavior. Apply targeted filtering to supported credential forms in text sinks, avoid raw HTTP headers/bodies and infrastructure credentials, and document the filter's limitations. Synthetic accounts and artifact access/retention are consumer responsibilities. Blanket UI masking and disabling evidence require an explicit requirement; no new runtime controls are implemented here.

## Consequences

Constitution 2.0, F04, technical/security guides and agent instructions describe this boundary. Known filter gaps may be fixed separately with scoped regression tests. No Swift API, runtime behavior, artifact schema or published release changes here.
