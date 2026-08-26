# ADR 0009: SPM, Tuist, and the CI contract

Status: accepted — 2026-08-08.

## Decision

Swift Package Manager is the primary consumer distribution manifest. Tuist remains the project-generation and local development mechanism. Tuist 4.203.3, Xcode 26.5/Swift 6.3.2, iOS 15 minimum, and iOS 26.5 tested simulator runtime are recorded in `xceasy.toolchain.json` and `.mise.toml`.

`scripts/check.sh all` is the local CI-parity entry point. GitHub Actions runs contract/schema/redaction/parallel checks, public Swift-interface compatibility, all framework unit tests, every SwiftUI/UIKit sample test, and an aggregate `XCEasy.framework` coverage gate. Raw XCTest and machine-readable coverage evidence are uploaded by CI. `release-metadata.json.version` is the single version source; `CHANGELOG.md`, the remaining release metadata, and a versioned `.swiftinterface` form the release baseline. Generated workspaces, Derived data, IDE metadata, and result bundles are ignored.

## Consequences

Changing the supported matrix, distribution layout, or bootstrap target requires an ADR/migration and consumer verification. Generated projects are never hand-edited.
