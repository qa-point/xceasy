# Руководство для ИИ-агентов

## 1. Цель

ИИ в XCEasy — инженер под теми же правилами review, а не источник непроверенных массовых изменений. Задача агента: понять evidence, сделать минимальный безопасный patch, подтвердить поведение и оставить код проще для следующего человека или агента.

## 2. Обязательный порядок чтения

1. `AGENTS.md` и документы, на которые он ссылается.
2. Конституция.
3. Техническое руководство и relevant ADR/spec.
4. Code style и contribution guide.
5. Тесты ближайшего компонента до изменения production code.

## 3. Протокол изменения

1. Зафиксировать requested outcome и non-goals.
2. Найти entry points, public API, tests и artifact flow через `rg`.
3. Проверить git status; сохранить чужие изменения.
4. Сформулировать hypothesis и evidence; не выдавать inference за факт.
5. Добавить reproducer/regression test.
6. Внести минимальный patch; не редактировать generated output.
7. Выполнить наиболее узкую проверку, затем расширить её пропорционально риску.
8. Проверить logs/artifacts и privacy.
9. Обновить RU/EN docs при изменении public behavior.
10. Сообщить изменённые файлы, проверки, ограничения и остаточные риски.

## 4. Правила диагностики

- Начинать с первого causal failure, а не последующих teardown/reporting ошибок.
- Связывать утверждение с event ID, test ID, source location или artifact.
- Разделять product defect, test defect, infrastructure failure и unknown.
- Не лечить flakiness повышением timeout без timeline/query evidence.
- Не обновлять expected/golden автоматически, пока не доказано новое корректное поведение.
- Если evidence недостаточно, сначала улучшить безопасную диагностику либо запросить конкретный artifact.

## 5. Правила генерации тестов

- Тест должен проверять observable contract, а не внутреннюю реализацию.
- Имена и fixtures детерминированы; сеть, часы, UUID и filesystem инъецируются.
- Для telemetry использовать golden/schema tests с нормализацией динамических полей.
- Для redaction использовать уникальные canary values и проверять весь diagnostic bundle.
- Для concurrency проверять несколько одновременных test contexts и отсутствие cross-test IDs/artifacts.

## 6. Запреты

ИИ не должен:

- удалять или ослаблять failing tests без одобрения;
- менять public API/schema «для удобства» без compatibility analysis;
- добавлять dependency без ADR и оценки license/security/maintenance;
- отправлять logs/source/artifacts во внешний сервис без явного разрешения;
- логировать больше данных, чем требуется для диагностики;
- утверждать, что тесты прошли, по чтению кода или неполному выводу;
- перезаписывать несвязанные пользовательские изменения.

## 7. Формат handoff

Финальный отчёт должен отвечать: какой outcome достигнут; что изменено; какие команды и результаты подтверждают это; что не проверено и почему; есть ли migration/security/compatibility impact. Для диагностики дополнительно: root cause, evidence, fix и regression coverage.

## 8. Возможности репозитория для автономной работы ИИ

Репозиторий уже содержит machine-readable toolchain manifest, pinned Tuist environment, deterministic entry point `scripts/check.sh`, CI workflow, versioned telemetry JSON Schema и migration notes, fixture diagnostic bundles, ADR, per-test evidence manifests и валидируемый local AI-handoff builder. Эти возможности не разрешают автономно менять source или отправлять artifacts наружу: агент по-прежнему ссылается на evidence, оставляет healing proposals на human review и явно сообщает ограничения проверки. Ownership map, automation dependency governance, host reconciliation crash bundles и release signing остаются задачами release hardening.
