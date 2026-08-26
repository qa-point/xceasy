# XCEasy Integration Fixture

[English version](README_EN.md)

Это внутренний технический стенд репозитория XCEasy. Он не является публичным sample-приложением и не предназначен для копирования пользователями.

Стенд нужен для проверки XCEasy на реальном accessibility tree UIKit и SwiftUI, сбора integration coverage и воспроизводимых regression-сценариев.

Запуск из корня framework-репозитория:

```bash
./scripts/check.sh fixture
```

Публичные независимые UIKit и SwiftUI примеры находятся в отдельном репозитории `xceasy-examples`.
