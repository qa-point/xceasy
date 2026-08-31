# Руководство пользователя XCEasy

Русская документация · [English](../en/PRODUCT_GUIDE_EN.md) · [Краткий README](../../README_RU.md)

Короткие основы — назначение, архитектура, установка, быстрый старт и Given/When/Then — полностью находятся в [корневом README](../../README_RU.md). Ниже перечислены темы, которым нужен отдельный подробный документ.

| № | Раздел | Что находится внутри |
|---:|---|---|
| 1 | [Конфигурация](guide/01_CONFIGURATION_RU.md) | Все свойства `XCEasyConfig`, значения и рекомендации. |
| 2 | [Жизненный цикл теста и приложения](guide/02_LIFECYCLE_RU.md) | Hooks, запуск, перезапуск и завершение приложения. |
| 3 | [Поиск и работа с элементами](guide/03_ELEMENT_LOOKUP_RU.md) | Lazy locators, способы поиска, действия, чтение и waits. |
| 4 | [Проверки элементов](guide/04_ELEMENT_ASSERTIONS_RU.md) | UI-состояния, отрицательные assertions и transitions. |
| 5 | [Обычные проверки значений](guide/05_VALUE_ASSERTIONS_RU.md) | Boolean, equality, comparison, optional, collection и throws assertions. |
| 6 | [Soft assertions](guide/06_SOFT_ASSERTIONS_RU.md) | Агрегация независимых проверок, Allure и async. |
| 7 | [Компоненты Page Object](guide/07_PAGE_OBJECT_COMPONENTS_RU.md) | `XCEasyComponent`, component steps и component collections. |
| 8 | [Launch arguments и environment](guide/08_LAUNCH_CONFIGURATION_RU.md) | Настройка запуска, изоляция и повторный запуск. |
| 9 | [Deeplink](guide/09_DEEPLINKS_RU.md) | Схема, маршруты, открытие и отчётность. |
| 10 | [Взаимодействие с устройством](guide/10_DEVICE_RU.md) | Ориентация, clipboard и жесты по экрану. |
| 11 | [Работа с API-запросами](guide/11_API_REQUESTS_RU.md) | Подготовка backend-состояния, HTTP-методы, callbacks, async и ошибки. |
| 12 | [Allure](guide/12_ALLURE_RU.md) | Lifecycle, metadata, parameters, artifacts и TestOps boundary. |
| 13 | [Логи, диагностика и производительность](guide/13_LOGS_DIAGNOSTICS_PERFORMANCE_RU.md) | JSONL, diagnostic bundle, timings, budgets и healing evidence. |
| 14 | [Проверка самого репозитория](guide/14_REPOSITORY_CHECKS_RU.md) | Локальные и CI quality gates, предназначенные для разработчиков XCEasy. |
| 15 | [Параметризованные тесты, аннотации и маркеры](guide/15_PARAMETERIZED_TESTS_AND_ANNOTATIONS_RU.md) | Независимые executions наборов данных, compile-time metadata и пользовательские Allure labels. |
| 16 | [Playbook расследования падений](guide/16_FAILURE_INVESTIGATION_PLAYBOOK_RU.md) | Поиск первой причины, разбор artifacts, classification и чек-лист передачи. |

Формальные гарантии и target requirements находятся отдельно в [спецификациях по фичам](spec/README_RU.md). В случае расхождения спецификация и конституция имеют приоритет над пользовательским руководством.

## Связанная документация

- [Техническое руководство](TECHNICAL_GUIDE_RU.md)
- [Конституция проекта](PROJECT_CONSTITUTION_RU.md)
- [Code style](CODE_STYLE_RU.md)
- [Contribution guide](CONTRIBUTING_RU.md)
- [Правила для AI-разработки](AI_DEVELOPMENT_GUIDE_RU.md)
