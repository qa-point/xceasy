import XCEasy

struct SwiftUIScreenPOM {
    var promoBanner: PromoBannerPOM {
        PromoBannerPOM(technology: .swiftUI)
    }

    var showPromoBannerButton: XCEasyUIElement {
        find(identifier: "SwiftUI.PromoBanner.ShowButton", desc: "Show new SwiftUI promo banner")
    }

    var inputField: SwiftUIInputComponentPOM {
        SwiftUIInputComponentPOM()
    }

    var switchComponent: XCEasyUIElement {
        find(identifier: "swiftUiSwitchComponent")
    }

    var checkbox: XCEasyUIElement {
        find(identifier: "swiftUiCheckboxComponent")
    }

    var radioButton1: XCEasyUIElement {
        find(identifier: "swiftUiRadioButton1")
    }

    var radioButton2: XCEasyUIElement {
        find(identifier: "swiftUiRadioButton2")
    }

    var listItems: XCEasyComponentCollection<SwiftUIListItemComponentPOM> {
        XCEasyComponentCollection()
    }

    var loadContentButton: XCEasyUIElement {
        find(identifier: "swiftUiLoadContentButton")
    }

    var loadingView: XCEasyUIElement {
        find(identifier: "swiftUiLoadingView")
    }
}

extension SwiftUIScreenPOM {
    /// Returns a list-item component by its one-based business number.
    ///
    /// - Parameter index: One-based item number used in human-readable test steps.
    /// - Returns: Lazy component for the requested item.
    @discardableResult
    func listItem(index: Int) -> SwiftUIListItemComponentPOM {
        listItems.get(index: index - 1, componentName: "List item \(index)")
    }
}
