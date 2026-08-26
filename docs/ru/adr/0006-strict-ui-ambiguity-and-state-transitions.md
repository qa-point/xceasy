# ADR 0006: строгая неоднозначность UI и наблюдаемые переходы состояния

Статус: принят — 2026-08-08.

## Решение

Locator без index по умолчанию использует `XCEasyUIQueryAmbiguityPolicy.strict`. Несколько candidates дают `query.ambiguous_match`, а не неявный `firstMatch`. `.permissive` — явный compatibility mode с reason `query.ambiguous_first_match`. Каждый poll заново разрешает immutable root-to-child locator и сохраняет bounded timeline изменений. `assertBecomesHidden` доказывает `visible → hidden`; отсутствие element его не удовлетворяет.

## Последствия

Selectors, случайно зависевшие от first match, должны получить stable identifier, scope или explicit index. Valid absence остаётся успехом negative assertion, но ambiguity никогда не считается absence. На failure сохраняются screenshot и ограниченная redacted hierarchy.
