# ADR 0008: components, performance и контролируемый healing

Статус: принят — 2026-08-08.

## Решение

`XCEasyComponent` — public boundary reusable POM: он владеет lazy root, semantic name, root assertions, disappearance и component steps. Performance collection execution-scoped (`off/basic/detailed`) и создаёт per-test min/max/mean/median/p90/p95/p99 metrics и budget findings. Default budget policy — observe; warn и fail включаются явно.

Healing основан на evidence и по умолчанию работает в observe. Он ранжирует только type-compatible alternatives, блокирует low confidence и почти равные candidates и всегда выставляет `requiresHumanApproval`. XCEasy не переписывает business expectations или source code автоматически. `build-ai-handoff.sh` создаёт healing proposals, semantic test-generation request, assumptions, evidence IDs, confidence, gaps и reproduction guidance.

## Последствия

Optimization/healing findings не могут незаметно превратить failed test в passed. Изменение selector требует review и controlled rerun с сохранением исходного failure.
