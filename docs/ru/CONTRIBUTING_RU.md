# Внесение изменений в XCEasy

## 1. Перед началом

Прочитайте конституцию, техническое руководство и code style. Проверьте dirty worktree и не изменяйте пользовательские/generated файлы вне задачи. Для значимого изменения сформулируйте проблему, acceptance criteria, compatibility/privacy impact и план проверки.

## 2. Классы изменений

- Bug fix: reproducer/regression test обязателен.
- Feature: требования, public API docs, positive/negative tests.
- Refactoring: behavior сохраняется; существующие тесты и targeted new tests подтверждают это.
- Telemetry/schema: schema version, golden fixtures, migration note, redaction tests.
- Breaking change: ADR, migration guide, deprecation/major-version decision.
- Documentation: примеры сверяются с компилируемым API и RU/EN паритетом.

## 3. Рабочий процесс

1. Создать issue/spec с observable outcome.
2. Для архитектурного решения добавить ADR.
3. Добавить failing test или fixture, если возможно.
4. Реализовать минимальное изменение без несвязанного cleanup.
5. Запустить formatter/linter, unit tests, targeted UI tests, затем полную suite.
6. Проверить diagnostic artifacts и отсутствие canary secrets.
7. Обновить docs/changelog/migration.
8. В PR описать evidence, риски, команды проверки и известные ограничения.

## 4. Проверки

Точка входа для полной локальной проверки:

```bash
mise install
./scripts/check.sh all
```

Для узкой итерации вместо `all` используйте `contracts`, `package`, `unit`, `race`, `fixture` или `release`. После instrumented unit и fixture runs режим `coverage` повторно проверяет их существующие `.xcresult` bundles. Версии toolchain заданы в `.mise.toml` и `xceasy.toolchain.json`, CI — в `.github/workflows/ci.yml`. Режим contracts проверяет shell fixtures, provider boundaries, rejection paths coverage policy, crash reconciliation, cross-run performance, controlled healing, schemas, manifests, Allure, ссылки в документации, RU/EN-паритет, Swift DocC и legacy banners. Package выполняет isolated iOS Simulator build. Race запускает shared execution, soft-assertion, diagnostic и core suites под Thread Sanitizer. Release пересобирает distributable Swift interface и сравнивает его с текущим SemVer baseline. Unit/fixture используют pinned Tuist и coverage; coverage объединяет оба result bundles и применяет `scripts/coverage-policy.json`.

Hosted GitHub CI запускает `./scripts/check.sh ci`: SwiftLint, contracts, isolated package build, unit-тесты framework и release contract. Race, integration/UI fixture и aggregate coverage остаются в локальном `all` и не выполняются на hosted runners.

Нельзя заявлять успешный прогон, если команда не запускалась. Укажите конкретную причину: отсутствует Xcode, simulator, dependency/network либо воспроизводимая ошибка кода.

## 5. Review checklist

- Соответствует конституции и scope?
- Есть тест, который доказывает изменение?
- Есть ли unit coverage для нового детерминированного поведения и targeted SwiftUI/UIKit integration coverage для platform behavior?
- Нет public/schema break без migration?
- Failure path даёт expected/actual и evidence?
- Secret redaction происходит до всех sinks?
- Parallel execution и shared state учтены?
- Документы/примеры соответствуют коду на обоих языках?
- Не добавлены Derived, `.DS_Store`, user data и absolute paths?

## 6. Коммиты и PR

Коммит атомарный, сообщение в imperative mood с областью, например `telemetry: add versioned event envelope`. PR отделяет обязательное изменение от дальнейших идей. Скриншоты/логи прикладываются без секретов. Generated Xcode/Tuist output коммитится только при принятой политике репозитория; до её фиксации не добавляйте новые generated artifacts.

## 7. Release discipline

Текущий source contract начинается с `0.1.0`. Поле `release-metadata.json.version` является единым источником версии; `CHANGELOG.md`, metadata и Swift-interface baseline обновляются вместе. Breaking API требует соответствующего SemVer-решения и migration. Публичный release дополнительно требует maintainer-owned signed tag, release notes, compatibility matrix, schema versions и ссылку на зелёный CI.
