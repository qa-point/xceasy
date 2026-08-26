import XCEasy

// MARK: - Elments
class UIKitScreenPOM {
    var promoBanner: PromoBannerPOM {
        PromoBannerPOM(technology: .uiKit)
    }

    var showPromoBannerButton: XCEasyUIElement {
        find(identifier: "UIKit.PromoBanner.ShowButton", desc: "Show new UIKit promo banner")
    }

    var title: XCEasyUIElement {
        find(identifier: "UIKitscreenTitleLabel", desc: "Screen Title")
    }

    var input: XCEasyUIElement {
        find(identifier: "uiKitInputComponent", desc: "Input Field")
    }

    var switchComponent: XCEasyUIElement {
        find(identifier: "uiKitSwitchComponent", desc: "Enable feature Switch")
    }

    var checkbox: XCEasyUIElement {
        find(identifier: "uiKitCheckboxComponent", desc: "Accept terms")
    }

    var radioButton1: XCEasyUIElement {
        find(identifier: "uiKitRadioButton1")
    }

    var radioButton2: XCEasyUIElement {
        find(identifier: "uiKitRadioButton2")
    }

    var listItem1: XCEasyUIElement {
        find(identifier: "uiKitListItem1")
    }

    var listItem2: XCEasyUIElement {
        find(identifier: "uiKitListItem2")
    }

    var listItem3: XCEasyUIElement {
        find(identifier: "uiKitListItem3")
    }

    var loadContentButton: XCEasyUIElement {
        find(identifier: "uiKitLoadContentButton")
    }

    var loadingView: XCEasyUIElement {
        find(identifier: "uiKitLoadingView")
    }
}

// MARK: - Actions

extension UIKitScreenPOM {
    /// Enters text into the input field.
    @discardableResult
    func enterText(_ text: String) -> Self {
        step("Enter text into the input field") {
            input.typeText(text)
        }
        return self
    }

    /// Toggles the switch.
    @discardableResult
    func toggleSwitch() -> Self {
        step("Toggle the switch") {
            switchComponent.tap()
        }
        return self
    }

    /// Toggle the checkbox.
    @discardableResult
    func tapCheckbox() -> Self {
        step("Toggle the checkbox") {
            checkbox.tap()
        }
        return self
    }

    /// Taps radio button 1.
    @discardableResult
    func tapRadioButton1() -> Self {
        radioButton1.tap()
        return self
    }

    /// Taps radio button 2.
    @discardableResult
    func tapRadioButton2() -> Self {
        radioButton2.tap()
        return self
    }

    /// Taps the load content button.
    @discardableResult
    func tapLoadContent() -> Self {
        loadContentButton.tap()
        return self
    }
}
