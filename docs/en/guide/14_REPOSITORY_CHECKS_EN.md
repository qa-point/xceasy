# Verifying the repository itself

English · [Русский](../../ru/guide/14_REPOSITORY_CHECKS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


This section is for XCEasy maintainers and CI. A user who only writes tests with a released framework does not run these commands.

```bash
mise install
./scripts/check.sh all
```

Focused modes are `contracts`, `package`, `unit`, `race`, `fixture`, `coverage`, and `release`. The complete gate checks package build, unit tests, Thread Sanitizer, the internal UIKit/SwiftUI integration fixture, coverage, documentation, artifact schemas, and public API compatibility.

Host scripts under `scripts/` are for CI, artifact validation, performance comparison, and controlled AI-assisted healing. They are not part of the normal test API.

## Preparing the environment

`mise install` installs pinned tools including Tuist. A complete Xcode selected through `xcode-select`/`DEVELOPER_DIR`, `jq`, and an available simulator are required. Test modes look for `iPhone 17 Pro` by default; select another with `XC_EASY_TEST_DEVICE_ID=<UDID>`.

## `check.sh` modes

| Mode | Verification | When to run |
|---|---|---|
| `contracts` | RU/EN links/parity, Swift docs, shell contract tests, toolchain JSON, package manifest. | After docs, schemas, scripts, or public API changes. |
| `package` | A clean SPM copy through `xcodebuild build`. | After source/dependency/resource changes. |
| `unit` | `XCEasyTests` with coverage and an `.xcresult`. | After framework behavior changes. |
| `race` | Concurrency/context tests under Thread Sanitizer. | After state, parallelism, logging/lifecycle changes. |
| `fixture` | Internal UIKit and SwiftUI integration UI tests. | After user-facing UI API changes. |
| `coverage` | Coverage policy over unit/fixture `.xcresult` bundles. | After `unit` and `fixture`; bundles must already exist. |
| `release` | Metadata, version/tag, artifacts, and public API compatibility. | Before release. |
| `all` | Every mode in order. | Final gate. |

```bash
./scripts/check.sh contracts
./scripts/check.sh unit
./scripts/check.sh fixture
./scripts/check.sh all
```

Success means exit code `0`. A gate has not passed when Xcode/Tuist/a simulator was missing or execution stopped.

## Host scripts

- `validate-diagnostic-events.sh` and `validate-diagnostic-bundle.sh` validate per-test diagnostic contracts;
- `build-ai-handoff.sh`, `validate-ai-handoff.sh`, and `build-healing-source-bundle.sh` prepare bounded AI evidence;
- `invoke-healing-provider.sh` and `apply-healing-proposal.sh` handle an external provider and reviewable proposal;
- `generate-public-api-interface.sh`, `compare-public-api.sh`, and `check-public-api-compatibility.sh` protect Swift API compatibility.

Use `--help` or inspect a host script header first because inputs and environment differ. Released-package users do not need these scripts.

Multi-device execution, aggregate Allure validation, run-level integrity manifests, and cross-run performance comparison are verified in the independent `xceasy-runner` repository.

## Evidence for a failed check

Retain the command, exit code, Xcode/Swift/Tuist versions, destination UDID, and `.xcresult`. This lets a person or AI distinguish an XCEasy defect from a toolchain, simulator, or infrastructure problem.
