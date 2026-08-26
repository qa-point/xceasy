# ADR 0011: Execution isolation, lazy components, calibrated visibility и provider boundary

Статус: принят — 2026-08-09. Часть про required children заменена ADR 0013.

## Решение

Каждый XCTest execution владеет одним lock-protected reference state. Structured-concurrency work получает этот state через task-local propagation; thread-local bridge остаётся только для синхронных XCTest callbacks. Configuration, lifecycle, logging, attachments и terminal-result ownership привязаны к одному execution state. Terminal transition захватывается атомарно и ровно один раз.

Переиспользуемые Page Objects хранят locator intent, а не resolved XCUI objects. `XCEasyComponent` может объявлять lazy required children, а `XCEasyComponentCollection` создаёт компоненты по zero-based index без implicit UI-backed count. Каждый action, assertion и value read выполняет resolution по текущему accessibility tree.

Default visibility требует finite nonempty frame элемента, пересекающий app viewport. Если XCUI не предоставляет usable viewport, XCEasy может применить fallback по finite element frame, но записывает low-confidence reason. Опциональная политика `nonEmptyFrame` включается явно и не является default.

AI healing provider является external command за versioned request/response contract. Adapter имеет bounded timeout, передаёт аргументы без shell evaluation и принимает только suggested candidate, уже присутствующий в diagnostic evidence. Он не может создать approval, изменить assertions, модифицировать source или публиковать artifacts.

## Последствия

Parallel child tasks разделяют только state своего теста, а независимые executions остаются изолированными. Component values можно хранить при replacement UI без появления stale snapshot. Negative assertions не падают только из-за отсутствия элемента, а visibility claims раскрывают geometry confidence. Provider implementations заменяемы без расширения authority; изменение source по-прежнему требует отдельного review, approval, verification и rollback.
