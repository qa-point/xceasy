# Взаимодействие с устройством

Русский · [English](../../en/guide/10_DEVICE_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)

`Device` управляет устройством и всем экраном. Он не ищет accessibility element и не знает identifier приложения. Для конкретной кнопки или списка используйте `find(...).tap()`/`swipe(...)`: locator даст более точный log и диагностику. `Device` нужен для ориентации, clipboard и жеста в фиксированной области экрана.

## Доступные операции

| API | Что делает | Код операции в diagnostics |
|---|---|---|
| `Device.tap(at:)` | Нажимает в нормализованной позиции экрана. | `device.tap` |
| `Device.swipe(from:to:)` | Проводит жест между двумя позициями всего экрана. | `device.swipe` |
| `Device.press(at:duration:)` | Удерживает позицию заданное число секунд. | `device.press` |
| `Device.setOrientation(_:)` | Меняет ориентацию устройства. | `device.orientation.set` |
| `Device.getClipboardValue()` | Возвращает строку из clipboard или `""`. | `device.clipboard.read` |
| `Device.wait(seconds:)` | Делает фиксированную паузу. | `device.wait` |

Позиции: `.center`, `.leftCenter`, `.rightCenter`, `.topCenter`, `.bottomCenter`, `.leftTop`, `.leftBottom`, `.rightTop`, `.rightBottom`. Это готовые точки около центра или края экрана, а не координаты элемента.

Ориентации: `.portrait`, `.portraitUpsideDown`, `.landscapeLeft`, `.landscapeRight`, `.faceUp`, `.faceDown`, `.unknown`. Обычно UI-тесту нужны первые четыре; остальные отражают полный набор `XCUIDevice.Orientation`.

## Пример в тесте

```swift
final class DeviceTests: BaseTestCase {
    func testScreenAndClipboardOperations() {
        Device.setOrientation(.landscapeLeft)
        Device.tap(at: .center)
        Device.swipe(from: .rightCenter, to: .leftCenter)
        Device.press(at: .rightTop, duration: 1.5)

        let copiedText = Device.getClipboardValue()
        assertNotEmpty(actual: copiedText)

        Device.setOrientation(.portrait)
    }
}
```

В Allure появятся последовательные шаги вроде `Установить ориентацию [Landscape Left]`, `Нажать на экран [центр]`, `Свайпнуть по экрану [справа] → [слева]`, `Зажать экран...` и `Получить значение буфера обмена`. В JSONL сохраняются стабильные коды из таблицы и длительность; содержимое clipboard в step title не записывается.

## Когда допустим `wait`

```swift
Device.wait(seconds: 1)
```

Этот вызов тоже попадёт в отчёт, но фиксированная задержка всегда ждёт всё время и зависит от скорости окружения. Для UI-состояния предпочтительнее `waitForDisplayed`, `waitForEnabled` или assertion с timeout. Используйте `Device.wait` только когда наблюдаемого accessibility-состояния нет и причина паузы понятна из окружающего пользовательского `step`.
