import SwiftUI

// MARK: - SectionView

/// Reusable section view with title.
struct SectionView<Content: View>: View {

    // MARK: - Properties

    let title: String
    let content: Content

    // MARK: - Initialization

    /// Creates a titled SwiftUI fixture section.
    ///
    /// - Parameters:
    ///   - title: Visible and accessible section title.
    ///   - content: View-builder closure producing the section content once.
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .accessibilityIdentifier("SwiftUI.SectionView.title")

            content
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("SwiftUI.SectionView.container")
    }
}
