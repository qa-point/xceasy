# F17 — Custom markers

0.1.0 status: implemented as public metadata for XCTest, Allure, diagnostics, and the build-time manifest.

## Goal

Let teams classify tests with clear project vocabulary such as `Team1`, `Team2`, `Smoke`, or `Debug` without changing how ordinary `xcodebuild test` executes them.

## Public model

The universal API is `@Marker("name")`; it may be applied to a test class or method and may repeat:

```swift
@Marker("Team1")
final class PaymentTests: XCEasyTestCase {
    @Marker("Smoke")
    @Marker("Debug")
    func testCardPayment() { /* ... */ }
}
```

Literal aliases such as `@Team1` and `@Debug` are an optional convenience layer. Swift requires every attribute macro name to be declared. XCEasy therefore provides a declaration template that reuses `XCEasyMacroPlugin`; a consumer chooses the names but does not implement another compiler plugin. Aliases create the same `xceasy.annotation` metadata as `@Marker`.

A marker is metadata only. Adding `@Marker("Debug")` never skips other tests and never changes XCTest selection. Any future selection command belongs to a separately distributed runner and is not part of this specification.

## Requirements

- `F17-REQ-001`: `@Marker` accepts one non-empty normalized string and may repeat on XCTest classes and methods.
- `F17-REQ-002`: duplicate markers are removed deterministically; invalid, reserved, or secret-like values fail compilation/preflight with a safe source location.
- `F17-REQ-003`: the generated manifest contains the canonical test identifier, class markers, method markers, effective ordered union, and source location.
- `F17-REQ-004`: every effective marker is emitted as an Allure label `{ "name": "xceasy.annotation", "value": "<marker>" }` without replacing standard `tag` labels.
- `F17-REQ-005`: parameterized cases inherit scenario markers and retain independent canonical identifiers.
- `F17-REQ-006`: ordinary `xcodebuild test` runs every XCTest method regardless of its markers and records effective markers in reports and diagnostics.
- `F17-REQ-007`: a literal alias declaration reuses the shipped macro implementation and works through both SPM and Tuist without project-specific compiler-plugin implementation.

## Acceptance criteria

- Class inheritance and method union produce the expected stable marker set.
- Duplicate or invalid values are handled deterministically without exposing secret-like input.
- Allure labels, diagnostic metadata, and manifest records agree.
- Consumer fixtures compile and run universal and declared literal marker forms through SPM and Tuist.

## Decisions

- `F17-DEC-001`: `@Marker("...")` is the stable universal API.
- `F17-DEC-002`: markers do not implicitly select, skip, shard, or repeat tests.
- `F17-DEC-003`: literal project aliases use documented external-macro declarations; arbitrary undeclared Swift attributes remain unsupported by the language.
