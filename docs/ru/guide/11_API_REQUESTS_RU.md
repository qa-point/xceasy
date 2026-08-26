# Работа с API-запросами

Русский · [English](../../en/guide/11_API_REQUESTS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)

`ApiManager` — вспомогательный HTTP-клиент для подготовки или очистки backend-состояния UI-теста. Он не заменяет специализированный API-test framework: здесь нет schema assertions, моделей endpoint-ов, retry policy или генерации API-наборов.

## Конфигурация

Создайте manager с base URL. Маршрут просто добавляется к этой строке, поэтому используйте согласованную пару, например base без завершающего `/` и route с начальным `/`. Общий timeout задаётся через `XCEasyConfig.requestTimeout`.

```swift
class BaseTestCase: XCEasyTestCase {
    let api = ApiManager(baseURL: "https://staging.example.com")

    override func configuration() {
        XCEasyConfig.apply(requestTimeout: 20)
        super.configuration()
    }
}
```

`headers` — словарь HTTP headers. `body` имеет тип `Data?`: сериализуйте `Codable` через `JSONEncoder` или словарь через `JSONSerialization`. Успешными считаются только ответы `200..<300` с HTTP response и data.

## Async/await: рекомендуемый вариант

Все пять методов принимают `route`, опциональные `headers`, а методы с body — ещё `Data?`:

```swift
final class ProfileTests: BaseTestCase {
    func testPreparedPremiumProfile() async throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["plan": "premium"]
        )
        let headers = ["Content-Type": "application/json"]

        let created = try await api.post(route: "/test-data/profile", headers: headers, body: body)
        let loaded = try await api.get(route: "/test-data/profile", headers: headers)
        let replaced = try await api.put(route: "/test-data/profile", headers: headers, body: body)
        let changed = try await api.patch(route: "/test-data/profile", headers: headers, body: body)
        let deleted = try await api.delete(route: "/test-data/profile", headers: headers)

        assertEqual(actual: created.statusCode, expected: 201)
        assertEqual(actual: loaded.statusCode, expected: 200)
        assertEqual(actual: replaced.statusCode, expected: 200)
        assertEqual(actual: changed.statusCode, expected: 200)
        assertEqual(actual: deleted.statusCode, expected: 204)
    }
}
```

Async overloads бросают `ApiError`. Для обработки ожидаемой ошибки используйте `do/catch`; для обычной подготовки теста достаточно `try`, и ошибка завершит test method.

## Callback API

Callback overloads возвращают `ApiResult` и дополнительно имеют `soft`. При `soft: false` transport/API error сразу регистрирует XCTest failure; при `true` manager только возвращает `.failure`, а решение принимает тест.

```swift
func testCallbackPreparation() {
    api.get(route: "/test-data/profile", soft: true) { result in
        switch result {
        case .success(let response):
            assertEqual(actual: response.statusCode, expected: 200)
        case .failure(let error):
            fail("Не удалось подготовить профиль: \(error)")
        }
    }
}
```

Те же аргументы доступны для `post`, `put`, `patch`; `delete` не принимает body.

## Ответы и ошибки

`ApiResponse` содержит `data`, исходный `HTTPURLResponse`, `statusCode` и `headers`. Декодирование данных выполняет тест через `JSONDecoder`.

| `ApiError` | Причина |
|---|---|
| `.invalidURL` | Base URL + route не образуют HTTP(S) URL. |
| `.timeout` | Ответ не пришёл за `requestTimeout`. |
| `.noData` | Transport не вернул data. |
| `.invalidResponse` | Data есть, но нет корректного HTTP response. |
| `.network(Error)` | Сетевая/transport ошибка. |
| `.http(statusCode:)` | HTTP status вне `200..<300`. |
| `.unknown(Error)` | Резервный public case для неизвестной ошибки. |

## Что попадёт в отчёт

Каждый запрос создаёт timed step с кодом `api.request` и HTTP method. В debug log попадают redacted URL, method, количество headers и размер body, но не значения headers и не body. Например:

```text
Send API request [POST]                    passed  184 ms
  URL: https://staging.example.com/test-data/profile
  Method: POST
  Header count: 1
  Body bytes: 18
Assert equal [201]                         passed
```

Не помещайте token или персональные данные в route/название пользовательского шага. `Authorization` передавайте header-ом: его значение не выводится штатным API log.
