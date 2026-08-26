# ADR-0018 — Compile-time XCTest metadata and parameterization

## Status

Accepted on August 11, 2026 for planned implementation. Supersedes the open architecture choice in F14.

## Context

XCTest has no JUnit-style native parameterized-test or arbitrary annotation model. A loop inside one method cannot provide independent Setup/Teardown, scheduling, status, or artifacts. Runtime Allure calls also execute too late to describe a failure in `setUp`. Private XCTest method injection is outside the supported product contract.

Users want the source form to resemble Allure Android while the existing function API remains valid. Swift attached macros are compile-time declarations, not runtime reflection metadata, so generated information needs a stable bridge to the observer and host coordinator.

## Decision

- Add a SwiftSyntax compiler-plugin target and public macro declarations while retaining the ordinary XCEasy runtime library.
- `@ParameterizedTest` accepts compile-time-known typed inline cases and generates one ordinary no-argument XCTest peer method per case. It does not use Swift Testing, dynamic `XCTestSuite`, or runtime injection.
- All generated variants use a canonical scenario key for Allure `testCaseId`; non-excluded parameters separate `historyId`.
- Separate Allure metadata macros use the F16 Android-compatible surface. `@Step` and `@Attachment` are excluded.
- A deterministic versioned metadata manifest maps concrete generated/discovered XCTest identifiers to their scenario identity, static metadata, parameters, and source locations. The observer loads it before Setup; the coordinator uses it before execution planning.
- Macro and runtime metadata merge according to F16. Runtime APIs remain first-class and the documentation shows both paths.
- The implementation must not increase the iOS 15 deployment target. The repository's pinned toolchain remains authoritative; wider Xcode/Swift compatibility is claimed only after CI evidence.
- SwiftSyntax is a new build dependency and therefore requires pinned compiler compatibility, license/security review, SPM/Tuist fixtures, and an update policy before merge.

## Rejected alternatives

- A runtime loop: one lifecycle and one result for all datasets.
- Runtime method injection or private XCTest invocation: unsupported and toolchain-fragile.
- A host runner as the first parameterization UX: supports external data but does not give the requested concise typed source and separate Test navigator methods in one build.
- Runtime-only annotations: Swift cannot preserve unknown attributes for later reflection.

## Consequences

Parameterized cases become real XCTest executions and static metadata is available even when Setup fails. The cost is compiler-plugin complexity, a generated manifest contract, and stricter rules for inline case syntax. External runtime datasets remain future work rather than being simulated as independent tests.
