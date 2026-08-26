# ADR 0012: Explicit assertion and runtime-helper API

## Status

Accepted, 2026-08-09. The required-child state decision is superseded by ADR 0013.

## Context

The beta API mixed tree presence with visual terminology, used non-Swift assertion names such as `assertEquals`, exposed two equivalent launch-configuration styles, and required a `DeeplinkRoute` wrapper for a path and report title. The project has not been released to production, so preserving ambiguous deprecated aliases would permanently increase the API and documentation surface without protecting a production consumer.

## Decision

- Tree presence uses `assertExists` and `assertDoesNotExist`.
- On-screen state uses `assertIsDisplayed` and `assertIsNotDisplayed`. The negative display assertion accepts either removal from the tree or a retained hidden state; `assertIsHidden` specifically requires tree presence.
- General hard assertions use singular Swift-style names and cover Boolean, equality, strict/inclusive comparison, string/collection containment, optional, empty, and throwing-closure cases.
- Reusable component required-child state is named `.displayed`.
- Launch configuration is available only through `LaunchArgumentsManager` and `LaunchEnvironmentManager`.
- Deep links use `Deeplink.open(_ path:name:)`; the scheme is read from the current test execution configuration at call time.
- Removed beta symbols have no deprecated forwarding aliases.

## Consequences

Tests written against the earlier beta must rename calls, but each public operation now communicates one state contract. Documentation can explain behavior without translating internal observation terms. The smaller launch and deep-link surface reduces duplicate tests and gives AI agents fewer equivalent code forms to generate.
