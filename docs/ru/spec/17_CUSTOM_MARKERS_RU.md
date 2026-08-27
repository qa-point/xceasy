# F17 — Пользовательские маркеры

Статус 0.1.1: реализованы как публичные метаданные для XCTest, Allure, diagnostics и build-time manifest.

## Цель

Позволить командам классифицировать тесты понятными проектными именами `Team1`, `Team2`, `Smoke` или `Debug`, не меняя поведение обычного `xcodebuild test`.

## Публичная модель

Универсальный API — `@Marker("name")`; его можно добавлять к test class или method и повторять:

```swift
@Marker("Team1")
final class PaymentTests: XCEasyTestCase {
    @Marker("Smoke")
    @Marker("Debug")
    func testCardPayment() { /* ... */ }
}
```

Короткие aliases `@Team1` и `@Debug` — опциональный convenience layer. Swift требует объявлять каждое имя attribute macro. Поэтому XCEasy предоставляет declaration template, переиспользующий `XCEasyMacroPlugin`: consumer выбирает имена, но не пишет ещё один compiler plugin. Aliases создают те же метаданные `xceasy.annotation`, что и `@Marker`.

Marker — только метаданные. `@Marker("Debug")` не пропускает другие тесты и не меняет XCTest selection. Будущая selection-команда относится к отдельно поставляемому runner и не входит в эту спецификацию.

## Требования

- `F17-REQ-001`: `@Marker` принимает одну непустую normalized string и может повторяться на XCTest classes и methods.
- `F17-REQ-002`: duplicate markers удаляются детерминированно; invalid, reserved или secret-like values завершают compilation/preflight безопасной ошибкой с source location.
- `F17-REQ-003`: generated manifest содержит canonical test identifier, class markers, method markers, effective ordered union и source location.
- `F17-REQ-004`: каждый effective marker записывается как Allure label `{ "name": "xceasy.annotation", "value": "<marker>" }`, не заменяя стандартные `tag` labels.
- `F17-REQ-005`: parameterized cases наследуют markers scenario и сохраняют независимые canonical identifiers.
- `F17-REQ-006`: обычный `xcodebuild test` запускает все XCTest methods независимо от markers и записывает effective markers в отчёты и diagnostics.
- `F17-REQ-007`: declaration literal alias переиспользует shipped macro implementation и работает через SPM и Tuist без project-specific compiler-plugin implementation.

## Acceptance criteria

- Наследование class и union с method создают ожидаемый стабильный marker set.
- Duplicate или invalid values обрабатываются детерминированно без раскрытия secret-like input.
- Allure labels, diagnostic metadata и manifest records совпадают.
- Consumer fixtures собирают и запускают universal и declared literal marker forms через SPM и Tuist.

## Решения

- `F17-DEC-001`: `@Marker("...")` — стабильный universal API.
- `F17-DEC-002`: markers сами по себе не выбирают, не пропускают, не распределяют и не повторяют тесты.
- `F17-DEC-003`: literal project aliases используют documented external-macro declarations; произвольные undeclared Swift attributes не поддерживаются самим языком.
