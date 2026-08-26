# ADR 0020: framework, examples, and runner repository boundaries

Status: accepted on 2026-08-13.

## Context

The original repository combined framework source, a hybrid UIKit/SwiftUI sample application, and experimental host-side multi-device scripts. These artifacts have different users, release cycles, and stability promises. Keeping them together made the sample look like framework internals and made experimental runner behavior look publicly available.

## Decision

- `xceasy` owns the Swift package, public API, unit tests, specifications, schemas, release contract, and a minimal internal `XCEasyIntegrationFixture` used only by framework CI and coverage.
- `xceasy-examples` owns two independent applications: `UIKitExample` and `SwiftUIExample`. They have separate bundle identifiers, lifecycles, source trees, Page Objects, UI-test targets, and schemes. They share only repository tooling and the selected XCEasy dependency.
- Published examples consume a released XCEasy package version. An explicit environment switch may use an adjacent local checkout during framework development.
- `xceasy-runner` is a separate, independently versioned product and owns host-side enumeration, marker selection, sharding/replication, recovery, Allure aggregation, and run-level evidence. Its configuration and artifacts are not XCEasy Swift APIs.
- Public documentation must not present the internal fixture or runner-owned host orchestration as XCEasy Swift-package features.

## Consequences

Framework changes are verified first by unit tests and the internal fixture. Example changes are verified independently against a released dependency and may also be tested against an adjacent checkout before a coordinated release. Cross-repository changes cannot rely on one atomic commit, so compatibility must be maintained through versions rather than relative paths.

The framework repository remains self-sufficient for release verification. The examples repository stays readable for users because UIKit and SwiftUI are not mixed into one application. Runner design can evolve without making host implementation details part of the Swift package contract. Accepted runner ADRs and executable contracts were transferred with their implementation; XCEasy retains only per-test correlation support.
