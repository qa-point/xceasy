# XCEasy agent instructions

These instructions apply to the entire repository.

Before changing code, read and follow:

1. `docs/en/PROJECT_CONSTITUTION_EN.md` — binding project principles.
2. `docs/en/TECHNICAL_GUIDE_EN.md` — current architecture and known limitations.
3. `docs/en/CODE_STYLE_EN.md` — Swift, testing, concurrency, and telemetry style.
4. `docs/en/CONTRIBUTING_EN.md` — change and verification workflow.
5. `docs/en/AI_DEVELOPMENT_GUIDE_EN.md` — AI-specific diagnosis and handoff protocol.
6. `docs/en/spec/README_EN.md` and the relevant feature specification — current behavior, target requirements, and acceptance criteria.

Use the Russian equivalents for user-facing Russian documentation. Keep RU/EN documents aligned when public behavior or project policy changes.

Non-negotiable summary:

- Preserve unrelated user changes and never edit generated files manually.
- Reproduce defects and add regression coverage before or with the fix.
- Never expose secrets; redact before every log/report sink.
- Treat public Swift APIs, telemetry schemas, and artifact layouts as versioned contracts.
- Avoid fatal errors, force unwraps, silent error suppression, magic sleeps, and machine-specific paths on runtime paths.
- Prefer stable accessibility identifiers and explicit, test-isolated dependencies.
- Never claim a build/test passed unless the command actually completed successfully.
- Report verification limitations and residual risks explicitly.

If instructions conflict, precedence is: project constitution, approved specification/ADR, code style, contribution/AI guides, then README.
