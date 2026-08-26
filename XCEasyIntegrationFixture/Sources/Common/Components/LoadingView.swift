import SwiftUI

// MARK: - LoadingView

/// Reusable loading view component for displaying activity indicator.
///
/// This component provides a standardized loading indicator with accessibility support.
struct LoadingView: View {

    // MARK: - Properties

    let accessibilityIdentifier: String
    @Binding var isLoading: Bool

    // MARK: - Initialization

    /// Creates a loading view component.
    /// - Parameters:
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    ///   - isLoading: The bound isLoading value.
    init(
        accessibilityIdentifier: String,
        isLoading: Binding<Bool>
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self._isLoading = isLoading
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .accessibilityIdentifier(accessibilityIdentifier)
                    .accessibilityLabel("Loading")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoadingView(
        accessibilityIdentifier: "loadingView",
        isLoading: .constant(true)
    )
    .padding()
}
