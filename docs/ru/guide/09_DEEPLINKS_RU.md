# Deeplink

Русский · [English](../../en/guide/09_DEEPLINKS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Отдельная модель route не нужна. `Deeplink.open(_:, name:)` принимает path без схемы, добавляет `XCEasyConfig.deeplinkSchema` и открывает URL через `XCUIDevice`.

## Конфигурация

Схема — часть URL до `://`. Она должна начинаться с буквы и может содержать буквы, цифры, `+`, `-`, `.`. Укажите только имя схемы:

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(localization: .ru, deeplinkSchema: "myapp")
        super.configuration()
    }
}
```

Схема должна быть зарегистрирована самим приложением. XCEasy не добавляет URL Types в target.

## Базовый пример

```swift
final class SettingsTests: BaseTestCase {
    func testOpenPrivacySettingsByDeeplink() {
        Deeplink.open(
            "/settings/privacy",
            name: "Настройки приватности"
        )

        find(identifier: "privacySettingsScreen").assertIsDisplayed()
    }
}
```

Схема `myapp` уже задана в `BaseTestCase.configuration()`, поэтому вызов откроет `myapp://settings/privacy`. Начальный `/` опционален. В Allure появится шаг `Открыть диплинк [Настройки приватности]`, а внутри canonical diagnostics — операция `deeplink.open` с `target = "Настройки приватности"` и её длительностью. Следующим отдельным шагом будет проверка экрана.

## Пути, query и понятные имена

```swift
final class DeeplinkTests: BaseTestCase {
    func testRoutes() {
        Deeplink.open("catalog")
        find(identifier: "catalogScreen").assertIsDisplayed()

        Deeplink.open("/product/42?source=ui-test", name: "Карточка тестового товара")
        find(identifier: "productScreen").assertIsDisplayed()

        Deeplink.open("settings/notifications", name: "Настройки уведомлений")
        find(identifier: "notificationSettingsScreen").assertIsDisplayed()
    }
}
```

Начальные `/` удаляются; `catalog` и `/catalog` дают один URL. Полный `https://...` или `myapp://...` передавать нельзя: API принимает только route, чтобы схема контролировалась конфигурацией. Пустая/некорректная схема, пустой path и `://` в path создают failure `deeplink.invalid_url`.

`name` не влияет на URL. Если `name == nil`, заголовок использует path; не делайте так для чувствительных query values.

```text
Открыть диплинк [Карточка тестового товара]     deeplink.open   passed   93 ms
Проверить отображение [productScreen]           assert.visible  passed
```

XCEasy не проверяет, что приложение обработало route: это делает следующий UI assertion. Раздельные шаги показывают, отправлен ли deeplink и открылся ли ожидаемый экран.
