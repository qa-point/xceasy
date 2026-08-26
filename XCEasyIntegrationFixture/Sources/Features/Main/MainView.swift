import SwiftUI

// MARK: - MainTabView

/// Main tab view that provides navigation to UIKit and SwiftUI screens.
///
/// This view serve as the main menu after successful login, allowing users
/// to navigate to either UIKit or SwiftUI demo screens.
struct MainTabView: View {

    // MARK: - Body

    var body: some View {
        TabView {
            UIKitScreenViewControllerRepresentable()
                .tabItem {
                    Label("UIKit", systemImage: "square")
                        .accessibilityIdentifier("uiKitTab")
                }

            SwiftUIScreenView()
                .tabItem {
                    Label("SwiftUI", systemImage: "circle")
                        .accessibilityIdentifier("swiftUiTab")

                }

        }
        .accessibilityIdentifier("mainTabView")
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
