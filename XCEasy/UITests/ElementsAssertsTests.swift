import XCEasy
import Foundation

class ElementsAssertsTests: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.apple.mobilesafari",
            findTimeout: 3,
            localization: .ru
        )
        super.configuration()
    }

    // MARK: - Positive tests

    func test_assertElementIsExistsWithLabel() {
        let element = find(identifier: "SidebarButton", desc: "Sidebar Button")
        element.assertExists()
    }

    func test_assertElementIsExistsWithoutLabel() {
        let element = find(identifier: "SidebarButton")
        element.assertExists()
    }

    func test_assertElementIsNotExistsWithLabel() {
        let element = find(identifier: "Not existed button", desc: "Not existed button")
        element.assertDoesNotExist()
    }

    func test_assertElementIsNotExistsWithoutLabel() {
        let element = find(identifier: "Not existed button")
        element.assertDoesNotExist()
    }

    func test_assertElementIsEnabledWithLabel() {
        let element = find(identifier: "SidebarButton", desc: "Sidebar Button")
        element.assertIsEnabled()
    }

    func test_assertElementIsEnabledWithoutLabel() {
        let element = find(identifier: "SidebarButton")
        element.assertIsEnabled()
    }

    func test_assertElementIsDisabledWithLabel() {
        let element = find(identifier: "ForwardButton", desc: "Forward Button")
        element.assertIsDisabled()
    }

    func test_assertElementIsDisabledWithoutLabel() {
        let element = find(identifier: "ForwardButton")
        element.assertIsDisabled()
    }

    func test_assertElementIsSelectedWithLabel() {
        let tabOverviewButton = find(identifier: "TabOverviewButton")
        tabOverviewButton.press(forDuration: 3)

        let selectedField = find(identifier: "Local", desc: "Selected element")
        selectedField.assertIsSelected()
    }

    func test_assertElementIsSelectedWithoutLabel() {
        let tabOverviewButton = find(identifier: "TabOverviewButton")
        tabOverviewButton.press(forDuration: 3)

        let selectedField = find(identifier: "Local")
        selectedField.assertIsSelected()
    }

    func test_assertElementIsNotSelectedWithLabel() {
        let element = find(identifier: "SidebarButton", desc: "Sidebar Button")
        element.assertIsNotSelected()
    }

    func test_assertElementIsNotSelectedWithoutLabel() {
        let element = find(identifier: "SidebarButton")
        element.assertIsNotSelected()
    }

    // MARK: - Negative tests

    func test_assertElementIsExistsFailed() {
        let element = find(identifier: "SidebarButton2", desc: "Not existed button")
        element.assertExists()
    }

    func test_assertElementIsNotExistsFailed() {
        let element = find(identifier: "SidebarButton", desc: "Existed button")
        element.assertDoesNotExist()
    }

    func test_assertElementIsEnabledFailed() {
        let element = find(identifier: "ForwardButton", desc: "Disabled Button")
        element.assertIsEnabled()
    }

    func test_assertElementIsDisabledFailed() {
        let element = find(identifier: "SidebarButton", desc: "Enabled Button")
        element.assertIsDisabled()
    }

    func test_assertElementIsNotSelectedFailed() {
        let tabOverviewButton = find(identifier: "TabOverviewButton")
        tabOverviewButton.press(forDuration: 3)

        let selectedField = find(identifier: "Local")
        selectedField.assertIsNotSelected()
    }

    func test_assertElementIsSelectedFailed() {
        let element = find(identifier: "SidebarButton", desc: "Non-selected Button")
        element.assertIsSelected()
    }
}
