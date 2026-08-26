# ADR 0009: SPM, Tuist и CI contract

Статус: принят — 2026-08-08.

## Решение

Swift Package Manager является primary consumer distribution manifest. Tuist остаётся механизмом project generation и local development. Tuist 4.203.3, Xcode 26.5/Swift 6.3.2, minimum iOS 15 и tested simulator runtime iOS 26.5 зафиксированы в `xceasy.toolchain.json` и `.mise.toml`.

`scripts/check.sh all` — локальный CI-parity entry point. GitHub Actions выполняет contract/schema/redaction/parallel checks, public Swift-interface compatibility, все unit-тесты framework, каждый SwiftUI/UIKit sample test и aggregate coverage gate для `XCEasy.framework`. CI загружает raw XCTest и machine-readable coverage evidence. `release-metadata.json.version` является единым источником версии; `CHANGELOG.md`, остальные release metadata и versioned `.swiftinterface` формируют release baseline. Generated workspaces, Derived data, IDE metadata и result bundles игнорируются.

## Последствия

Изменение supported matrix, distribution layout или bootstrap target требует ADR/migration и consumer verification. Generated projects не редактируются вручную.
