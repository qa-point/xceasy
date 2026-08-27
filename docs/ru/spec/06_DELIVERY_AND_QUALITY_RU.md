# F06 — Delivery и quality

Статус 0.1.0: repository release contract реализован; подпись и публикация требуют maintainer authority.

## Цель

Сделать XCEasy воспроизводимо собираемым, подключаемым и проверяемым людьми, CI и ИИ на объявленной toolchain matrix.

## Реализованный baseline

- Tuist описывает framework/unit/UI targets, iOS 15 и Alamofire package.
- `Package.swift` является primary source-consumer manifest; Tuist остаётся project generator. Objective-C observer bootstrap вынесен в отдельный SPM target.
- `xceasy.toolchain.json` и `.mise.toml` фиксируют Tuist 4.203.3 и Xcode 26.5, Swift 6.3.2, minimum iOS 15, simulator iOS 26.5.
- `scripts/check.sh all` — точка входа для полного локального acceptance. Hosted GitHub Actions через `scripts/check.sh ci` запускает SwiftLint, contracts, iOS Swift Package consumer build, unit tests framework и release contract. Внутренний SwiftUI/UIKit fixture, race checks и aggregate [F13 coverage policy](13_TEST_COVERAGE_RU.md) остаются локальными acceptance gates.
- Generated workspaces, Derived output, IDE state и result bundles игнорируются. `release-metadata.json.version` является единым источником версии; `CHANGELOG.md` и versioned distributable Swift-interface baseline задают остальные части release-контракта `0.1.0`. `scripts/check.sh release` пересобирает interface с library evolution и отклоняет удалённые или изменённые baseline API lines, разрешая additions.

## Требования

- `F06-REQ-001`: machine-readable manifest фиксирует Tuist, Swift, Xcode и supported iOS/simulator matrix.
- `F06-REQ-002`: одна documented command локально воспроизводит hosted CI checks, а другая запускает полный local acceptance.
- `F06-REQ-003`: hosted CI выполняет lint, unit, schema/golden, redaction и contract tests; integration/UI и race checks входят в local acceptance.
- `F06-REQ-004`: distribution contract (SPM/Tuist/XCFramework) версионируется и проверяется consumer fixture.
- `F06-REQ-005`: generated artifact policy и `.gitignore` исключают user/machine-specific output.
- `F06-REQ-006`: внутренний integration fixture компилируется, использует относительные/temporary report paths и покрывает success/failure/parallel/AI diagnostic scenarios; публичные UIKit и SwiftUI examples выпускаются из отдельного репозитория `xceasy-examples`.
- `F06-REQ-007`: semver, changelog, deprecation и supported matrix публикуются для release.
- `F06-REQ-008`: public API compatibility проверяется автоматизированно.
- `F06-REQ-009`: dependency update требует license/security/maintenance проверки.
- `F06-REQ-010`: RU/EN docs link/example validation входит в CI.
- `F06-REQ-011`: local acceptance применяет versioned aggregate и critical-file coverage policy и создаёт machine-readable evidence.

## Acceptance criteria

- Clean checkout bootstrap и test проходят на каждом поддерживаемом Xcode.
- Consumer fixture подключает release artifact без repository internals.
- В committed files отсутствуют `.DS_Store`, user data, secrets и absolute home paths.
- Release содержит tag, notes, migration, compatibility и telemetry schema versions.

## Решения и оставшиеся вопросы

- `F06-DEC-001`: source SPM является primary consumer channel; pinned Tuist — project generator репозитория.
- `F06-DEC-002`: текущая matrix — Xcode 26.5/Swift 6.3.2, iOS 15 minimum, iOS 26.5 tested simulator; изменения требуют ADR/migration.
- `F06-DEC-003`: generated projects/workspaces, Derived output, user state и result bundles не коммитятся.
- `F06-DEC-004`: SemVer, changelog, release metadata и automated source-compatibility checks обязательны для release.
- `F06-DEC-005`: tag `v<version>` запускает полный release-readiness workflow и создаёт source archive с checksum; публикация или подпись всё ещё требует authority maintainer.
- `F06-OPEN-004`: подпись public tag/archive остаётся действием maintainer, потому что signing identity и publication authority находятся вне repository.
