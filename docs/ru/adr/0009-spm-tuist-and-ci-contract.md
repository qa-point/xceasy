# ADR 0009: SPM, Tuist и CI contract

Статус: принят — 2026-08-08.

## Решение

Swift Package Manager является primary consumer distribution manifest. Tuist остаётся механизмом project generation и local development. Tuist 4.203.3, Xcode 26.6/Swift 6.3.3, minimum iOS 15 и tested simulator runtime iOS 26.5 зафиксированы в `xceasy.toolchain.json` и `.mise.toml`.

`scripts/check.sh all` — точка входа для полного local acceptance. Hosted GitHub Actions использует `scripts/check.sh ci` для SwiftLint, contracts, isolated package build, unit-тестов framework и проверки public Swift-interface compatibility. UI fixtures, race checks и aggregate coverage остаются в local acceptance, потому что UI-прогоны на hosted simulators сравнительно дороги и нестабильны. `release-metadata.json.version` является единым источником версии; `CHANGELOG.md`, остальные release metadata и versioned `.swiftinterface` формируют release baseline. Generated workspaces, Derived data, IDE metadata и result bundles игнорируются.

## Последствия

Изменение supported matrix, distribution layout или bootstrap target требует ADR/migration и consumer verification. Generated projects не редактируются вручную.
