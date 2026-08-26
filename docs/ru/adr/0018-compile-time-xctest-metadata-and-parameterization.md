# ADR-0018 — Compile-time XCTest metadata и параметризация

## Статус

Принято 11 августа 2026 года для запланированной реализации. Заменяет открытый выбор архитектуры в F14.

## Контекст

XCTest не имеет нативной JUnit-style модели parameterized tests или произвольных annotations. Цикл внутри одного method не даёт независимые Setup/Teardown, scheduling, status и artifacts. Runtime Allure calls также выполняются слишком поздно, чтобы описать failure в `setUp`. Private XCTest method injection не входит в поддерживаемый product contract.

Пользователю нужен source, похожий на Allure Android, при сохранении работающего function API. Swift attached macros являются compile-time declarations, а не runtime reflection metadata, поэтому generated information нужен стабильный bridge к observer и host coordinator.

## Решение

- Добавить SwiftSyntax compiler-plugin target и public macro declarations, сохранив обычную runtime library XCEasy.
- `@ParameterizedTest` принимает известные при компиляции typed inline cases и генерирует по одному обычному no-argument XCTest peer method на case. Swift Testing, dynamic `XCTestSuite` и runtime injection не используются.
- Все generated variants используют canonical scenario key для Allure `testCaseId`; non-excluded parameters разделяют `historyId`.
- Раздельные Allure metadata macros используют Android-compatible surface из F16. `@Step` и `@Attachment` исключены.
- Детерминированный versioned metadata manifest связывает конкретные generated/discovered XCTest identifiers с scenario identity, static metadata, parameters и source locations. Observer загружает его до Setup; coordinator использует до execution planning.
- Macro и runtime metadata объединяются по F16. Runtime APIs остаются first-class, документация показывает оба пути.
- Реализация не повышает iOS 15 deployment target. Pinned toolchain репозитория остаётся authoritative; более широкая Xcode/Swift compatibility заявляется только после CI evidence.
- SwiftSyntax является новой build dependency и до merge требует pinned compiler compatibility, license/security review, SPM/Tuist fixtures и update policy.

## Отклонённые варианты

- Runtime loop: один lifecycle и result для всех datasets.
- Runtime method injection или private XCTest invocation: unsupported и toolchain-fragile.
- Host runner как первый parameterization UX: поддерживает external data, но не даёт запрошенный компактный typed source и отдельные Test navigator methods в одной сборке.
- Runtime-only annotations: Swift не сохраняет unknown attributes для последующей reflection.

## Последствия

Parameterized cases становятся настоящими XCTest executions, а static metadata доступна даже при падении Setup. Цена решения — compiler-plugin complexity, generated manifest contract и более строгие правила inline case syntax. External runtime datasets остаются future work, а не имитируются как независимые tests.
