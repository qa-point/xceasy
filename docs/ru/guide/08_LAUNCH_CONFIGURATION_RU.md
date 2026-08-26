# Launch arguments и environment

Русский · [English](../../en/guide/08_LAUNCH_CONFIGURATION_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Для этого используется только Manager API — второго дублирующего DSL нет. Настройте значения до запуска приложения:

```swift
class BaseTestCase: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.yourcompany.app",
            localization: .ru
        )

        LaunchArgumentsManager.add("-ui_testing")
        LaunchArgumentsManager.add("-disable_animations")

        LaunchEnvironmentManager.set([
            "IS_UI_TEST": "1",
            "API_BASE_URL": "https://staging.example.com",
            "FEATURE_FLAG_X": "true"
        ])

        super.configuration()
    }
}
```

`XCEasyTestCase` применит эти значения к приложению после `configuration()` и до автоматического `launchApplication()`.

## Launch arguments

Arguments — упорядоченный массив строк в `XCUIApplication.launchArguments`. Их удобно использовать как флаги, например для включения UI-test режима или отключения анимаций.

В примере базового класса приложение получит `-ui_testing` и `-disable_animations`. `add(_:)` сохраняет порядок и добавляет каждое переданное значение, включая повторное; это позволяет намеренно передавать аргумент несколько раз. `remove(_:)` удаляет первое точное совпадение, `removeAll()` очищает список, а `values` возвращает текущую копию.

## Launch environment

Environment — словарь `[String: String]` в `XCUIApplication.launchEnvironment`. Он подходит для пар ключ–значение: base URL, feature flags, начального состояния приложения или имени fixture.

В примере базового класса все три значения попадут в environment запуска. Для одного значения используйте `set(_:for:)`; для чтения и очистки доступны `value(for:)`, `values`, `remove(_:)` и `removeAll()`.

В `XCEasyTestCase.setUpWithError()` arguments добавляются к `XCUIApplication.launchArguments`, а environment объединяется с `launchEnvironment`; значение Manager-а заменяет старое значение с тем же ключом. Изменения после `launchApplication()` подействуют только при следующем `reopenApplication()` или новом запуске.

В начале каждого теста Manager создаёт отдельную копию значений. Изменения в `configuration()` одного параллельного теста не попадают в launch configuration другого теста.

## Переопределение и удаление base-настроек

Environment value заменяется повторным `set` с тем же key. Argument не имеет key, поэтому для замены нужно удалить точную старую строку и добавить новую.

```swift
final class ProductionLikeTests: BaseTestCase {
    override func configuration() {
        super.configuration()
        LaunchArgumentsManager.remove("-disable_animations")
        LaunchArgumentsManager.add("-animation_speed=0.5")
        LaunchEnvironmentManager.set("https://preprod.example.com", for: "API_BASE_URL")
        LaunchEnvironmentManager.remove("FEATURE_FLAG_X")
    }

    func testPreprodCatalog() {
        find(identifier: "catalogScreen").assertIsDisplayed()
    }
}
```

Чтобы не наследовать defaults, очистите managers и задайте только нужное:

```swift
override func configuration() {
    super.configuration()
    LaunchArgumentsManager.removeAll()
    LaunchEnvironmentManager.removeAll()
    LaunchEnvironmentManager.set("1", for: "IS_UI_TEST")
}
```

Изменения после `super.configuration()` ещё применятся: приложение запускается после завершения hook. Для чтения доступны `LaunchArgumentsManager.values`, `LaunchEnvironmentManager.values` и `value(for:)`, но не выводите весь environment в step — там могут быть secrets.

Изменение внутри test method требует нового запуска:

```swift
func testFeatureAfterRelaunch() {
    closeApplication()
    LaunchEnvironmentManager.set("false", for: "FEATURE_FLAG_X")
    launchApplication()
    find(identifier: "legacyScreen").assertIsDisplayed()
}
```

В отчёте будут видны `Close application → Launch application → Assert...`; сами environment values шагами не становятся.
