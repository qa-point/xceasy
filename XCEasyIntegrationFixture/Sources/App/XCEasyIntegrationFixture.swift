import SwiftUI

// MARK: - XCEasyIntegrationFixture

/// Main entry point for the XCEasyIntegrationFixture application.
///
/// This app demonstrates hybrid UIKit and SwiftUI integration
/// for testing purposes with the XCEasy framework.
@main
struct XCEasyIntegrationFixture: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - RootView

/// Root view that manages navigation between screens.
struct RootView: View {

    // MARK: - Properties

    @State private var isLoading: Bool = true

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                LoadingContainerView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            startLoading()
        }
    }

    // MARK: - Methods

    /// Starts loading simulation for 2 seconds.
    private func startLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
        }
    }
}

// MARK: - LoadingContainerView

/// Container view that displays loading indicator.
struct LoadingContainerView: View {

    // MARK: - Body

    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
