import XCEasy

private struct SwiftUIInputCase {
    let id: String
    let text: String
}

@Epic("XCEasyIntegrationFixtureTests")
@Feature("SwiftUI")
@Marker("SwiftUI")
final class SwiftUICComponentsTests: XCEasyIntegrationFixtureTestCase {
    override func beforeTest() {
        epic("XCEasyIntegrationFixtureTests")
        feature("SwiftUI")
        story("Test Components")
        suite("Regression")
        owner("Owner1")
        severity(.blocker)
        tag("Example")

        super.beforeTest()
    }

    func test_listItemComponents() {
        id("0001")
        displayName("Check all list items exist")
        issue("QP-0001")
        tms("TR-0001")

        given("user on main screen") {
            tabBar
                .assertExist()
        }
        when("user switch tab to SwiftUI") {
            tabBar
                .select(tab: .swiftUI)
        }
        then("user should see 3 list items") {
            let items = swiftUIScreen.listItems
            items.assertCount(3)
            items.assertAllDisplayed()
            items.first.title.assertLabel(value: "Item 1")
            items.get(index: 1).title.assertLabel(value: "Item 2")
            items.last.title.assertLabel(value: "Item 3")
        }
    }

    @DisplayName("SwiftUI input: {id}")
    @Story("Parameterized input")
    @ParameterizedTest(
        name: "[{index}] SwiftUI input {id}",
        cases: [
            SwiftUIInputCase(id: "latin", text: "Hello, World!"),
            SwiftUIInputCase(id: "digits", text: "12345")
        ]
    )
    private func inputComponent(_ data: SwiftUIInputCase) {
        given("user on main screen") {
            tabBar
                .assertExist()
        }
        when("user switch tab to SwiftUI") {
            tabBar
                .select(tab: .swiftUI)
        }
        and("user set some text to input") {
            swiftUIScreen.inputField
                .fill(text: data.text)
        }
        then("user should see filled input") {
            swiftUIScreen.inputField
                .assertValue(text: data.text)
        }
    }
}
