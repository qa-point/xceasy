# ADR 0013: Readiness принадлежит action, component contract остаётся простым

## Статус

Принято 10 августа 2026 года. Заменяет required-child часть ADR 0011 и ADR 0012.

## Контекст

Первый component API позволял объявлять `requiredChildren`. Из-за этого `component.assertIsDisplayed()` имел скрытую семантику: одинаковый вызов мог проверять только root либо произвольный набор children. Пользователь всё равно ожидал, что `closeButton.tap()` самостоятельно дождётся возможности нажатия. Отдельный `tapPolicy` решил бы только один жест и оставил бы остальные действия с другим lifecycle.

Проект ещё не используется в production, поэтому сохранение лишнего beta API через deprecated aliases не имеет migration-пользы.

## Рассмотренные варианты

1. Сохранить `requiredChildren` как автоматическую component readiness.
2. Удалить hidden child metadata и оставить ожидание каждому action.
3. Добавить policy только для `tap`.
4. Добавить одну execution-scoped policy для всех UI-действий с local override.
5. Автоматически fallback с hittable на coordinate dispatch.

## Решение

- `XCEasyComponent` требует только `root`; `componentName` и root helpers остаются default API.
- `XCEasyComponentRequirement`, `XCEasyRequiredChildState`, `requiredChildren` и `assertRequiredChildren()` удаляются без deprecated aliases.
- `component.assertIsDisplayed()` проверяет только root. Составная готовность получает явное domain name вроде `assertIsReady()` внутри POM.
- `XCEasyActionPolicy` применяется к `tap`, `doubleTap`, `press`, `swipe`, `typeText` и `clearField`.
- `.hittable` является default и выполняет semantic XCUI dispatch после fresh state observation.
- `.displayed` является явным compatibility mode: он ждёт отображения и использует coordinate dispatch. Автоматического fallback нет.
- `XCEasyConfig.actionPolicy` execution-scoped; параметр `policy` одного action является локальным override.
- Effective policy, waited state и dispatch сохраняются в canonical diagnostics; coordinate mode имеет warning level. Input text и текущее значение поля не логируются.

## Последствия

Page Objects становятся короче, а одинаковые component assertions имеют одинаковый смысл. Действия с текстом, иконкой или container-ом сами ждут подходящий state. `.displayed` остаётся доступным для нестандартного accessibility tree, но его риск виден в коде и артефактах.

Beta-пользователь удаляет `requiredChildren` и при необходимости переносит составную проверку в именованный POM-метод. Вызовы действий без аргументов продолжают компилироваться и получают безопасное ожидание `.hittable`.

Public Swift interface и RU/EN документация обновляются в одной итерации. Поведение проверяется unit tests plan/config и UIKit/SwiftUI sample.
