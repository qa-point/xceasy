protocol ScreenProvider {
    // MARK: - UiKit Screen
    var uiKitScreen: UIKitScreenPOM { get }

    // MARK: - SwiftUI Screen
    var swiftUIScreen: SwiftUIScreenPOM { get }

    // MARK: - Components
    var tabBar: TabBarPOM { get }
}

extension ScreenProvider {
    // MARK: - UiKit Screen
    var uiKitScreen: UIKitScreenPOM { UIKitScreenPOM() }

    // MARK: - SwiftUI Screen
    var swiftUIScreen: SwiftUIScreenPOM { SwiftUIScreenPOM() }

    // MARK: - Components
    var tabBar: TabBarPOM { TabBarPOM() }
}
