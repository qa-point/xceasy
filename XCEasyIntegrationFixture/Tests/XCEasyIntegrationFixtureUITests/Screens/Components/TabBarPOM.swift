import XCEasy

// MARK: - Elements

struct TabBarPOM {
    private var element: XCEasyUIElement {
        find(type: .tabBar)
    }

    enum Tabs: String {
        case swiftUI = "swiftUiTab"
        case uiKit = "uiKitTab"
    }
}

// MARK: - Actions

extension TabBarPOM {
    @discardableResult
    func select(tab: Tabs) -> Self {
        step("Select tab '\(tab.rawValue)'") {
            element
                .child(identifier: tab.rawValue)
                .tap()
        }
        return self
    }
}

// MARK: - Asserts

extension TabBarPOM {
    @discardableResult
    func assertExist() -> Self {
        step("Check TabBar exists") {
            element
                .assertExists()
        }
        return self
    }
}
