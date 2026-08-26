# ADR 0020: границы репозиториев framework, examples и runner

Статус: принято 13 августа 2026 года.

## Контекст

Исходный репозиторий объединял исходники framework, гибридное UIKit/SwiftUI sample-приложение и экспериментальные host-side scripts для multi-device запуска. У этих частей разные пользователи, release cycles и гарантии стабильности. Общий репозиторий создавал впечатление, что sample является частью framework, а экспериментальный runner уже доступен пользователю.

## Решение

- `xceasy` хранит Swift package, public API, unit tests, спецификации, schemas, release contract и минимальный внутренний `XCEasyIntegrationFixture`, который используется только CI и coverage framework.
- `xceasy-examples` хранит два независимых приложения: `UIKitExample` и `SwiftUIExample`. У них разные bundle identifiers, lifecycles, source trees, Page Objects, UI-test targets и schemes. Общими остаются только repository tooling и выбранная dependency XCEasy.
- Публичные examples подключают released-версию XCEasy. Явный environment switch может включить соседний local checkout во время разработки framework.
- `xceasy-runner` является отдельным независимо версионируемым продуктом и владеет host-side enumeration, marker selection, sharding/replication, recovery, Allure aggregation и run-level evidence. Его конфигурация и артефакты не являются Swift API XCEasy.
- Public-документация не должна представлять внутренний fixture или принадлежащий runner host orchestration как фичи Swift package XCEasy.

## Последствия

Изменения framework сначала проверяются unit-тестами и внутренним fixture. Examples проверяются отдельно с released dependency и могут дополнительно проверяться с соседним checkout перед согласованным release. Cross-repository changes не могут опираться на один атомарный commit, поэтому compatibility должна удерживаться версиями, а не relative paths.

Репозиторий framework остаётся самодостаточным для release verification. Репозиторий examples остаётся понятным пользователю, потому что UIKit и SwiftUI не смешаны в одном application. Runner можно развивать, не превращая детали host-реализации в контракт Swift package. Принятые runner ADR и executable contracts перенесены вместе с implementation; XCEasy сохраняет только поддержку per-test correlation.
