# Contributing to XCEasy

## 1. Before starting

Read the constitution, technical guide, and code style. Inspect the dirty worktree and do not change user/generated files outside scope. For material work, state the problem, acceptance criteria, compatibility/privacy impact, and verification plan.

## 2. Change classes

- Bug fix: reproducer/regression test required.
- Feature: requirements, public API docs, positive/negative tests.
- Refactor: behavior preserved and proven by existing plus targeted tests.
- Telemetry/schema: schema version, golden fixtures, migration note, redaction tests.
- Breaking change: ADR, migration guide, and deprecation/major-version decision.
- Documentation: examples checked against compilable APIs and RU/EN parity.

## 3. Workflow

1. Create an issue/spec with an observable outcome.
2. Add an ADR for architectural decisions.
3. Add a failing test or fixture where possible.
4. Implement the smallest scoped change without unrelated cleanup.
5. Run formatter/linter, unit tests, targeted UI tests, then the full suite.
6. Inspect diagnostic artifacts and verify canary secrets are absent.
7. Update docs, changelog, and migration material.
8. In the PR, report evidence, risks, verification commands, and known limitations.

## 4. Verification

The pinned local/CI entry point is:

```bash
mise install
./scripts/check.sh all
```

Use `contracts`, `package`, `unit`, `race`, `fixture`, or `release` instead of `all` for a narrow iteration. After instrumented unit and fixture runs, `coverage` re-evaluates their existing `.xcresult` bundles. Toolchain versions are defined by `.mise.toml` and `xceasy.toolchain.json`; CI is defined by `.github/workflows/ci.yml`. Contract mode validates shell fixtures, provider boundaries, coverage-policy rejection paths, crash reconciliation, cross-run performance, controlled healing, schemas, manifests, Allure, documentation links, RU/EN parity, Swift DocC coverage, and legacy banners. Package mode performs an isolated iOS Simulator build. Race mode runs the shared execution, soft-assertion, diagnostic, and core suites under Thread Sanitizer. Release mode rebuilds the distributable Swift interface and compares it with the current SemVer baseline. Unit and fixture modes generate projects with pinned Tuist and coverage; coverage mode merges both result bundles and applies `scripts/coverage-policy.json`.

Never claim a successful run when the command did not execute. Report the exact blocker: missing Xcode, simulator, dependency/network access, or a reproducible code failure.

## 5. Review checklist

- Does it comply with the constitution and stated scope?
- Is there a test proving the change?
- Does new deterministic behavior have unit coverage, and does platform behavior have targeted SwiftUI/UIKit integration coverage?
- Is every public/schema break accompanied by migration?
- Does the failure path provide expected/actual and evidence?
- Does secret redaction occur before every sink?
- Are parallel execution and shared state considered?
- Do bilingual docs/examples match the code?
- Are Derived, `.DS_Store`, user data, and absolute paths excluded?

## 6. Commits and PRs

Keep commits atomic and use imperative scoped subjects, for example `telemetry: add versioned event envelope`. Separate required work from follow-up ideas. Attach only redacted screenshots/logs. Commit generated Xcode/Tuist output only under an approved repository policy; until then, add no new generated artifacts.

## 7. Release discipline

The current source contract starts at `0.1.0`. `release-metadata.json.version` is the single version source; update the changelog, metadata, and Swift-interface baseline together. Breaking API changes require the appropriate SemVer decision and migration. A published release also requires a maintainer-owned signed tag, release notes, compatibility matrix, schema versions, and a link to green CI.
