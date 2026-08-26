# AI Agent Development Guide

## 1. Purpose

AI in XCEasy is an engineer subject to the same review rules, not a source of unverified bulk changes. The agent must interpret evidence, create the smallest safe patch, verify behavior, and leave the code easier for the next human or agent.

## 2. Mandatory reading order

1. `AGENTS.md` and its referenced documents.
2. The project constitution.
3. The technical guide and relevant ADR/specification.
4. Code style and contribution guide.
5. Tests nearest to the component before production-code changes.

## 3. Change protocol

1. Record the requested outcome and non-goals.
2. Locate entry points, public APIs, tests, and artifact flow using `rg`.
3. Check git status and preserve unrelated user changes.
4. State hypotheses and evidence; never present inference as fact.
5. Add a reproducer/regression test.
6. Apply the smallest patch and avoid generated output.
7. Run the narrowest verification first, then expand proportionally to risk.
8. Inspect logs/artifacts and privacy behavior.
9. Update RU/EN docs when public behavior changes.
10. Report changed files, verification, limitations, and residual risks.

## 4. Diagnosis rules

- Start with the first causal failure, not subsequent teardown/reporting errors.
- Link claims to event IDs, test IDs, source locations, or artifacts.
- Distinguish product defect, test defect, infrastructure failure, and unknown.
- Do not treat flakiness by raising timeouts without timeline/query evidence.
- Do not update expected/golden output automatically until the new behavior is proven correct.
- When evidence is insufficient, first improve safe diagnostics or request a specific artifact.

## 5. Test-generation rules

- Test observable contracts rather than internal implementation.
- Keep names and fixtures deterministic; inject network, clock, UUID, and filesystem.
- Use golden/schema tests for telemetry and normalize dynamic fields.
- Use unique canary values for redaction and scan the whole diagnostic bundle.
- For concurrency, run multiple simultaneous test contexts and verify no cross-test IDs/artifacts.

## 6. Prohibitions

AI must not:

- delete or weaken failing tests without approval;
- change public APIs/schemas for convenience without compatibility analysis;
- add a dependency without an ADR and license/security/maintenance assessment;
- send logs, source, or artifacts to an external service without explicit authorization;
- log more data than diagnosis requires;
- claim tests passed based on static reading or incomplete output;
- overwrite unrelated user changes.

## 7. Handoff format

The final report answers: what outcome was achieved; what changed; which commands/results prove it; what was not verified and why; and whether migration/security/compatibility is affected. For diagnosis also provide root cause, evidence, fix, and regression coverage.

## 8. Repository capabilities for AI autonomy

The repository now provides a machine-readable toolchain manifest, pinned Tuist environment, deterministic `scripts/check.sh` entry point, CI workflow, versioned telemetry JSON Schema and migration notes, fixture diagnostic bundles, ADRs, per-test evidence manifests, and a validated local AI-handoff builder. These capabilities do not authorize autonomous source mutation or artifact upload: agents still cite evidence, require human review for healing proposals, and explicitly report verification limitations. Ownership mapping, dependency-governance automation, crash-bundle host reconciliation, and release signing remain release-hardening work.
