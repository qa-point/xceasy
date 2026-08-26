# ADR 0012: Явный API assertions и runtime helpers

## Статус

Принято 2026-08-09. Решение о required-child state заменено ADR 0013.

## Контекст

Beta API смешивал наличие в дереве с визуальными терминами, использовал нехарактерные для Swift имена вроде `assertEquals`, предоставлял два одинаковых способа настройки launch configuration и требовал обёртку `DeeplinkRoute` ради path и названия шага. Проект ещё не выпущен в production, поэтому deprecated aliases навсегда увеличили бы API и документацию, не защищая production-пользователей.

## Решение

- Наличие в дереве проверяют `assertExists` и `assertDoesNotExist`.
- Состояние на экране проверяют `assertIsDisplayed` и `assertIsNotDisplayed`. Отрицательная display-проверка допускает удаление из дерева или скрытое состояние; `assertIsHidden` отдельно требует наличия в дереве.
- Общие hard assertions используют имена в единственном числе и покрывают Boolean, equality, строгие/нестрогие comparisons, String/Collection containment, optional, empty и throwing closures.
- Required-child state переиспользуемого компонента называется `.displayed`.
- Launch configuration доступна только через `LaunchArgumentsManager` и `LaunchEnvironmentManager`.
- Deeplink открывается через `Deeplink.open(_ path:name:)`; scheme читается из конфигурации текущего test execution в момент вызова.
- Для удалённых beta symbols deprecated forwarding aliases не добавляются.

## Последствия

Тестам на старом beta API потребуется переименование вызовов, зато каждая public operation теперь выражает один понятный контракт состояния. Документация описывает поведение без необходимости переводить внутренние observation-термины. Меньший launch/deeplink API сокращает дублирование тестов и число равнозначных вариантов кода, которые может генерировать ИИ.
