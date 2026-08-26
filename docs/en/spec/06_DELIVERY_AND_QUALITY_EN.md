# F06 — Delivery and quality

0.1.0 status: repository release contract is implemented; signing and publication require maintainer authority.

## Goal

Make XCEasy reproducibly buildable, consumable, and verifiable by humans, CI, and AI on a declared toolchain matrix.

## Implemented baseline

- Tuist defines framework/unit/UI targets, iOS 15, and the Alamofire package.
- `Package.swift` is the primary source-consumer manifest; Tuist remains the project generator. The Objective-C observer bootstrap is a separate SPM target.
- `xceasy.toolchain.json` and `.mise.toml` pin Tuist 4.203.3 and record Xcode 26.5, Swift 6.3.2, iOS 15 minimum, and iOS 26.5 simulator verification.
- `scripts/check.sh all` is the CI-parity entry point. GitHub Actions runs contracts, schema/redaction/parallel checks, an iOS Swift Package consumer build, framework unit tests, the internal SwiftUI/UIKit integration fixture, and the aggregate [F13 coverage policy](13_TEST_COVERAGE_EN.md).
- Generated workspaces, Derived output, IDE state, and result bundles are ignored. `release-metadata.json.version` is the single version source; `CHANGELOG.md` and the versioned distributable Swift-interface baseline define the remaining `0.1.0` release contract. `scripts/check.sh release` rebuilds the interface with library evolution enabled and rejects removed or changed baseline API lines while allowing additions.

## Requirements

- `F06-REQ-001`: a machine-readable manifest pins Tuist, Swift, Xcode, and the supported iOS/simulator matrix.
- `F06-REQ-002`: one documented command reproduces CI checks locally.
- `F06-REQ-003`: CI runs format/lint, unit, integration/UI, schema/golden, redaction, and parallel tests.
- `F06-REQ-004`: the distribution contract (SPM/Tuist/XCFramework) is versioned and tested by a consumer fixture.
- `F06-REQ-005`: generated-artifact policy and `.gitignore` exclude user/machine-specific output.
- `F06-REQ-006`: the internal integration fixture builds, uses relative/temporary report paths, and covers success/failure/parallel/AI-diagnostic scenarios; public UIKit and SwiftUI examples are released from the separate `xceasy-examples` repository.
- `F06-REQ-007`: releases publish semver, changelog, deprecation, and supported matrix.
- `F06-REQ-008`: public API compatibility is checked automatically.
- `F06-REQ-009`: dependency updates require license/security/maintenance review.
- `F06-REQ-010`: CI validates RU/EN documentation links and examples.
- `F06-REQ-011`: CI enforces the versioned aggregate and critical-file coverage policy and publishes machine-readable evidence.

## Acceptance criteria

- Clean-checkout bootstrap and test pass on every supported Xcode version.
- A consumer fixture imports the release artifact without repository internals.
- Committed files contain no `.DS_Store`, user data, secrets, or absolute home paths.
- A release includes tag, notes, migration, compatibility, and telemetry schema versions.

## Decisions and remaining questions

- `F06-DEC-001`: source SPM is the primary consumer channel; pinned Tuist is the repository project generator.
- `F06-DEC-002`: the current matrix is Xcode 26.5/Swift 6.3.2, iOS 15 minimum, iOS 26.5 tested simulator; changes require an ADR/migration.
- `F06-DEC-003`: generated projects, workspaces, Derived output, user state, and result bundles are not committed.
- `F06-DEC-004`: SemVer, changelog, release metadata, and automated source-compatibility checks are mandatory release inputs.
- `F06-DEC-005`: a `v<version>` tag runs the full release-readiness workflow and produces a checksummed source archive; publishing or signing it still requires maintainer authority.
- `F06-OPEN-004`: signing a public tag/archive remains a maintainer action because signing identity and publication authority are external to the repository.
