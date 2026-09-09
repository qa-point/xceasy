# XCEasy: стиль кода

## 1. База

Следуем Swift API Design Guidelines и существующей структуре проекта. Этот документ уточняет обязательные локальные правила. SwiftLint закреплён в `mise.toml`; `.swiftlint.yml` является исполняемым источником истины, но не отменяет конституцию.

## 2. Форматирование и файлы

- 4 пробела, без tabs и trailing whitespace; одна пустая строка в конце файла.
- Один основной public/internal type на файл; имя файла совпадает с типом. Extensions группируются как `Type+Concern.swift`.
- Порядок: imports, type declaration, nested types, properties, init, public methods, internal/private methods, extensions.
- `// MARK: -` использовать для крупных смысловых секций, не для каждого метода.
- Generated каталоги не редактировать и не использовать как образец стиля.
- Imports минимальны и отсортированы системные/Apple, затем внешние модули.
- Концептуальные схемы в Markdown-документации оформляются через Mermaid для единообразного отображения в GitHub. Console output, logs и буквальные деревья каталогов остаются в fenced-блоках `text`.

## 3. Имена и API

- Типы: `UpperCamelCase`; методы/свойства/локальные значения: `lowerCamelCase`.
- Boolean читается как утверждение: `isEnabled`, `hasAttachments`, `shouldRedact`.
- Не использовать неочевидные сокращения; допустимы XCTest, UI, URL, ID, API, HTTP.
- Public API формулируется со стороны вызывающего кода и документируется `///` с поведением, параметрами, результатом, failure semantics и thread-safety при необходимости.
- Параметры по умолчанию не должны скрывать дорогую или опасную операцию.
- Fluent method, меняющий состояние, помечается `@discardableResult` и возвращает `Self` последовательно.
- Опечатки в новом API запрещены; существующий `Delimeters` должен мигрировать к `Delimiters` через deprecation, а не мгновенный break.

## 4. Типы, ошибки и optional

- Предпочитать value types для immutable event/config/model.
- Dependency injection через protocol/init; новый глобальный singleton требует ADR.
- Не использовать `!`, `as!`, `try!`, `fatalError` в runtime path. Исключение — доказанный programmer invariant с комментарием и тестом.
- Не подавлять ошибку `try?`, если она влияет на artifact или результат; логировать typed error и возвращать/throw.
- Ошибки — domain enums/structs с machine-readable code и безопасным description.
- `guard` используется для preconditions/early exit; happy path остаётся плоским.

## 5. Concurrency

- Каждый mutable shared state имеет документированного owner и synchronization strategy.
- Не вызывать пользовательский callback под lock/barrier.
- IDs и test-scoped state нельзя выводить только из глобального singleton при parallel execution.
- Execution state, общий для structured child tasks, переносится через task-local и имеет одного документированного lock-protected reference owner; thread-local storage используется только как синхронный XCTest bridge.
- Async API предпочтительнее блокирующего expectation wrapper; continuation завершается ровно один раз.
- Добавлять race/parallel tests при изменении context, observer, logger или sinks и запускать `./scripts/check.sh race` перед handoff.

## 6. Логи и telemetry

- Event name: lowercase dot notation (`ui.query.failed`); fields: `snake_case`.
- Канонические keys/messages codes — английские; localized text является presentation field.
- Логировать факт и evidence, не догадку. Hypothesis явно помечается как hypothesis.
- Все события получают source/correlation IDs через общий emitter.
- Точечная фильтрация учётных данных выполняется до текстового sink; нельзя сначала сохранить секреты, затем очистить. Сохраняйте намеренный UI/debug evidence согласно ADR 0021; не добавляйте тотальное маскирование UI как несвязанное улучшение.
- Expected/actual хранятся раздельно; duration — числом и с единицей в имени.
- Не менять event semantics без schema version/migration.

## 7. XCTest и UI-тесты

- Имя теста описывает behavior и outcome; бизнес ID хранится отдельно в `id()`.
- Arrange/Act/Assert либо Given/When/Then; не смешивать стили бессистемно.
- UI детали инкапсулировать в Page Objects; asserts результата могут оставаться в тесте.
- Selector priority: accessibility identifier → typed stable predicate → text → index.
- Timeout берётся из config либо именованной причины; magic sleep запрещён, кроме теста времени как функции.
- Failure message содержит operation, target, expected, actual и elapsed.
- Regression test должен падать на старой реализации и проходить после исправления.

## 8. Тестируемость

- Pure logic покрывать unit tests без simulator.
- Observer/UI integration — integration/UI tests.
- Telemetry/serialization — schema, golden и malformed-input tests.
- Redaction — table-driven tests и canary secrets.
- Не использовать реальную сеть в детерминированных unit tests; применять stubbed protocol/session.

## 9. Комментарии

Комментарий объясняет «почему», invariant или внешний constraint, а не пересказывает код. TODO имеет owner/issue: `TODO(QP-123): ...`. Закомментированный код и author/date/file banners удаляются.

Каждая callable declaration в hand-written production Swift sources имеет DocC-комментарий на английском. Public API описывает behavior, parameters, return value, thrown/failure semantics, а также concurrency/privacy constraints, если они значимы. Для неочевидного public workflow добавляется компилируемый пример; для простого private helper достаточен краткий контракт. Документация точно описывает lazy/deferred behavior и не утверждает, что работа выполняется при конструировании, если она отложена до операции. Coverage проверяет `scripts/validate-swift-documentation.sh`, он же запрещает legacy banners. Пользовательские руководства остаются синхронными RU/EN.
