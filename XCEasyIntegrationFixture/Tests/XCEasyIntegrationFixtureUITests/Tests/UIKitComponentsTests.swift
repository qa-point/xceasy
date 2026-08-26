import XCEasy

private struct UIKitInputCase {
    let id: String
    let text: String
}

@Epic("XCEasyIntegrationFixtureTests")
@Feature("UIKit")
@Marker("UIKit")
final class UIKitComponentsTests: XCEasyIntegrationFixtureTestCase {
    override func beforeTest() {
        epic("XCEasyIntegrationFixtureTests")
        feature("UIKit")
        story("Test Components")
        suite("Regression")
        super.beforeTest()
    }

    @DisplayName("UIKit input: {id}")
    @Story("Parameterized input")
    @ParameterizedTest(
        name: "[{index}] UIKit input {id}",
        cases: [
            UIKitInputCase(id: "latin", text: "UIKit input value"),
            UIKitInputCase(id: "digits", text: "67890")
        ]
    )
    private func inputComponent(_ data: UIKitInputCase) {
        tabBar.select(tab: .uiKit)

        uiKitScreen.enterText(data.text)

        uiKitScreen.input.assertValue(text: data.text)
    }

    func testSelectableComponents() {
        tabBar.select(tab: .uiKit)

        uiKitScreen.tapCheckbox()
        uiKitScreen.tapRadioButton1()

        assertTrue(
            expression: uiKitScreen.checkbox.waitForSelected(timeout: 2),
            label: "checkbox became selected"
        )
        uiKitScreen.checkbox.assertIsSelected()
        uiKitScreen.radioButton1.assertIsSelected()
        uiKitScreen.radioButton2.assertIsNotSelected()
    }
}
