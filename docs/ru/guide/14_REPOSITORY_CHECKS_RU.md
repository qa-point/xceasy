# Проверка самого репозитория

Русский · [English](../../en/guide/14_REPOSITORY_CHECKS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Этот раздел нужен разработчикам XCEasy и CI. Пользователь, который только пишет автотесты с готовой версией framework, эти команды не запускает.

```bash
mise install
./scripts/check.sh all
```

Узкие режимы: `contracts`, `package`, `unit`, `race`, `fixture`, `coverage`, `release`. Полный gate проверяет package build, unit tests, Thread Sanitizer, внутренний UIKit/SwiftUI integration fixture, coverage, документацию, схемы артефактов и совместимость public API.

Host scripts в `scripts/` предназначены для CI, проверки artifacts, performance comparison и контролируемого AI-assisted healing. Они не являются частью API обычного теста.

## Подготовка окружения

`mise install` устанавливает закреплённые инструменты, включая Tuist. Нужны полный Xcode, выбранный через `xcode-select`/`DEVELOPER_DIR`, `jq` и доступный simulator. По умолчанию test modes ищут `iPhone 17 Pro`; другой simulator задаётся через `XC_EASY_TEST_DEVICE_ID=<UDID>`.

## Режимы `check.sh`

| Режим | Что проверяет | Когда запускать |
|---|---|---|
| `contracts` | RU/EN links/parity, Swift docs, shell contract tests, toolchain JSON, package manifest. | После docs, schemas, scripts или public API changes. |
| `package` | Чистую SPM-копию через `xcodebuild build`. | После source/dependency/resource changes. |
| `unit` | `XCEasyTests` с coverage и `.xcresult`. | После framework behavior change. |
| `race` | Concurrent/context tests под Thread Sanitizer. | После state, parallelism, logging/lifecycle changes. |
| `fixture` | Внутренние UIKit и SwiftUI integration UI-tests. | После user-facing UI API changes. |
| `coverage` | Coverage policy по unit/fixture `.xcresult`. | После `unit` и `fixture`; отдельно bundles должны уже существовать. |
| `release` | Metadata, version/tag, artifacts и public API compatibility. | Перед release. |
| `all` | Все режимы по порядку. | Финальный gate. |

```bash
./scripts/check.sh contracts
./scripts/check.sh unit
./scripts/check.sh fixture
./scripts/check.sh all
```

Успех — только exit code `0`. Нельзя считать gate пройденным, если Xcode/Tuist/simulator отсутствовал или команда остановлена.

## Host scripts

- `validate-diagnostic-events.sh`, `validate-diagnostic-bundle.sh` — проверка per-test diagnostic contracts;
- `build-ai-handoff.sh`, `validate-ai-handoff.sh`, `build-healing-source-bundle.sh` — ограниченный evidence bundle для ИИ;
- `invoke-healing-provider.sh`, `apply-healing-proposal.sh` — внешний provider и reviewable proposal;
- `generate-public-api-interface.sh`, `compare-public-api.sh`, `check-public-api-compatibility.sh` — compatibility Swift API.

Перед отдельным host script используйте `--help` или прочитайте header: входы и environment отличаются. Пользователю готового package они не нужны.

Multi-device execution, aggregate Allure validation, run-level integrity manifests и cross-run performance comparison проверяются в независимом репозитории `xceasy-runner`.

## Что сохранять при ошибке

Сохраните команду, exit code, Xcode/Swift/Tuist versions, destination UDID и `.xcresult`. Так человек или ИИ отличит дефект XCEasy от toolchain/simulator/infrastructure проблемы.
