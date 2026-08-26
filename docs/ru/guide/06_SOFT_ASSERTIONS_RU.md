# Soft assertions

Русский · [English](../../en/guide/06_SOFT_ASSERTIONS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


`softly` нужен, когда несколько независимых проверок следует выполнить за один раз и показать все расхождения. Внутри блока используются обычные assertions XCEasy — отдельный объект `check` и отдельные методы `expect...` больше не нужны:

```swift
softly("Проверить главный экран") {
    homeScreen.navbar.assertIsDisplayed()
    homeScreen.tabbar.assertIsDisplayed()
    homeScreen.cards.get(index: 1).assertIsDisplayed()
    assertEqual(actual: homeScreen.title.getLabel(), expected: "Главная")
}
```

В soft-режим автоматически переходят:

| Проверки внутри `softly` | Поведение |
|---|---|---|
| Все value assertions: `assertTrue`, `assertEqual`, `assertLessThan`, `assertNotNil` и остальные | Ошибка записывается, следующая строка выполняется. |
| Assertions `XCEasyUIElement` и `XCEasyComponent` | Сохраняют обычный локализованный шаг, locator, UI evidence и timeout. |
| Assertions `XCEasyComponentCollection` | Накапливают ошибки count, empty и displayed-проверок. |

Каждая неуспешная проверка остаётся отдельным failed step в Allure и получает собственную диагностику. Родительский step `softly` тоже помечается как failed. После блока XCTest получает одно итоговое падение с ограниченным списком redacted ошибок и исходными строками вызова. Есть и async-overload: `await softly("...") { ... }` сохраняет execution context после suspension.

`softly` меняет только assertions. `tap`, ввод текста, сетевые действия, ошибки конфигурации и другие framework failures остаются hard. Не помещайте в soft-блок зависимый сценарий: если без успешного login продолжать нельзя, сначала используйте обычный assertion вне `softly`.

```text
Проверить главный экран                    failed
  Проверить navbar отображается            passed
  Проверить tabbar отображается            failed
  Проверить карточку 1 отображается        failed
  Проверить равенство заголовка            passed
```

После блока XCTest получает один aggregate failure, поэтому teardown и artifacts текущего execution сохраняются штатно.
