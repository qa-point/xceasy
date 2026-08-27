# F15 — Политика готовности UI-действий

Статус 0.1.1: реализовано и проверено.

## Цель

Каждое UI-действие само ждёт состояние, необходимое для безопасного выполнения. Пользователь может изменить общий execution-scoped default или переопределить policy для одного вызова без изменения Page Object.

## Реализованный baseline

- `XCEasyActionPolicy` поддерживает `.hittable` и `.displayed`.
- `XCEasyConfig.actionPolicy` по умолчанию равен `.hittable` и входит в snapshot конкретного test execution.
- `tap`, `doubleTap`, `press`, `swipe`, `typeText` и `clearField` принимают `timeout` и optional локальный `policy`.
- Каждое действие выполняет fresh observation полной locator chain. При timeout жест не отправляется, test получает framework failure, а query evidence содержит initial/final state и elapsed time.
- `.displayed` отмечается warning-событиями, потому что coordinate dispatch может попасть в перекрывающий overlay.

## Контракт policy

- `F15-REQ-001`: `.hittable` является безопасным default для всех UI-действий.
- `F15-REQ-002`: `.hittable` ждёт `XCUIElement.isHittable == true` и использует semantic XCUI action.
- `F15-REQ-003`: `.displayed` ждёт состояние displayed согласно `XCEasyConfig.visibilityPolicy` и использует coordinate dispatch внутри frame элемента.
- `F15-REQ-004`: локальный `policy` имеет приоритет над `XCEasyConfig.actionPolicy` только для текущего вызова.
- `F15-REQ-005`: локальный `timeout` имеет приоритет над `XCEasyConfig.actionTimeout` только для текущего вызова.
- `F15-REQ-006`: policy никогда не меняет locator и не кеширует resolved `XCUIElement` между operations.
- `F15-REQ-007`: отсутствие ожидаемого state до timeout создаёт failure `ui.action.target_not_ready` и запрещает dispatch.

## Матрица действий

| Действие | `.hittable` | `.displayed` |
|---|---|---|
| `tap` | semantic `XCUIElement.tap()` | tap в center coordinate |
| `doubleTap` | semantic `XCUIElement.doubleTap()` | double tap в center coordinate |
| `press` | semantic `XCUIElement.press(...)` | coordinate press в центре |
| `swipe` | semantic direction-specific swipe | coordinate drag между normalized offsets внутри frame |
| `typeText` | semantic tap для focus, затем `typeText` | coordinate tap для focus, затем `typeText` |
| `clearField` | semantic tap для focus, затем delete keys | coordinate tap для focus, затем delete keys |

- `F15-REQ-008`: text и icon могут быть target действия, даже если обработчик находится на parent view; hittable означает доступную touch coordinate, а не владение handler-ом.
- `F15-REQ-009`: если child не представлен отдельным accessibility node, framework не угадывает target; пользователь обращается к root либо приложение предоставляет stable identifier.
- `F15-REQ-010`: автоматический fallback с `.hittable` на `.displayed` запрещён, чтобы overlay или skeleton не маскировались случайным coordinate action.

## Public API

```swift
public enum XCEasyActionPolicy: String, Codable, Sendable {
    case hittable
    case displayed
}

XCEasyConfig.apply(actionPolicy: .hittable)

tile.title.tap()
tile.icon.tap(timeout: 5, policy: .displayed)
list.swipe(.up, policy: .displayed)
field.typeText("value", policy: .hittable)
field.clearField(policy: .hittable)
```

## Конфигурация и параллельность

- `F15-REQ-011`: `actionPolicy` копируется в execution configuration при старте теста и не протекает в параллельный execution.
- `F15-REQ-012`: suite-level default задаётся до параллельного запуска; исключения выражаются локальным аргументом, а не мутацией общего default во время action.
- `F15-REQ-013`: effective policy читается при semantic use элемента, а не при создании locator-а или POM.

## Диагностика и privacy

- `F15-REQ-014`: каждое действие сохраняет operation code, target locator, effective policy, expected state, dispatch type, duration и correlation IDs.
- `F15-REQ-015`: событие `ui.action.policy` использует reason `action.policy.hittable` или `action.policy.displayed`.
- `F15-REQ-016`: событие `ui.action.dispatched` использует reason `action.dispatch.semantic` или `action.dispatch.coordinate`.
- `F15-REQ-017`: `.displayed` policy и coordinate dispatch имеют warning level даже при успешном действии.
- `F15-REQ-018`: `typeText` не пишет введённый text, а `clearField` не пишет текущее value ни в console, JSONL, Allure, ни в failure description.
- `F15-REQ-019`: query observation остаётся child operation action-а и содержит state timeline для AI diagnosis.

## Совместимость

Проект не находится в production. Старые action-вызовы без аргументов остаются source-compatible благодаря default parameters. Удаление required-child API из F12 является осознанным beta breaking change: actions теперь сами владеют readiness, а составная component readiness задаётся явным POM-методом.

## Acceptance criteria

- Default action policy равен `.hittable`.
- Global `.displayed` не изменяет default другого parallel execution.
- Local `.displayed` не меняет global или execution-scoped policy.
- Каждый action из матрицы компилируется с default и local policy.
- При readiness timeout dispatch event отсутствует, test падает, а diagnostic query содержит ожидаемый и последний state.
- Успешный `.hittable` action пишет semantic dispatch.
- Успешный `.displayed` action пишет coordinate dispatch и warning.
- UIKit и SwiftUI sample подтверждают default tap/type flow и хотя бы один explicit displayed coordinate action.
- Canary input text и field value отсутствуют во всех diagnostic artifacts.

## Решения

- `F15-DEC-001`: используется одна policy для всех UI-действий, а не отдельный `tapPolicy`.
- `F15-DEC-002`: default — `.hittable`; `.displayed` является только явным compatibility mode.
- `F15-DEC-003`: action readiness принадлежит action API, а не hidden component metadata.
