# ADR 0009: SPM, Tuist, and the CI contract

Status: accepted — 2026-08-08.

## Decision

Swift Package Manager is the primary consumer distribution manifest. Tuist remains the project-generation and local development mechanism. Tuist 4.203.3, Xcode 26.6/Swift 6.3.3, iOS 15 minimum, and iOS 26.5 tested simulator runtime are recorded in `xceasy.toolchain.json` and `.mise.toml`.

`scripts/check.sh all` is the complete local acceptance entry point. Hosted GitHub Actions uses `scripts/check.sh ci` for SwiftLint, contracts, the isolated package build, framework unit tests, and public Swift-interface compatibility. UI fixtures, race checks, and aggregate coverage stay in local acceptance because hosted simulator UI execution is comparatively expensive and unstable. `release-metadata.json.version` is the single version source; `CHANGELOG.md`, the remaining release metadata, and a versioned `.swiftinterface` form the release baseline. Generated workspaces, Derived data, IDE metadata, and result bundles are ignored.

## Consequences

Changing the supported matrix, distribution layout, or bootstrap target requires an ADR/migration and consumer verification. Generated projects are never hand-edited.
