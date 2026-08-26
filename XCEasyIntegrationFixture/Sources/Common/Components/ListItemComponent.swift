import SwiftUI

// MARK: - ListItemComponent

/// Reusable list item component with icon and text for both UIKit and SwiftUI screens.
///
/// This component provides a standardized list item layout with accessibility support.
struct ListItemComponent: View {

    // MARK: - Properties

    let icon: String
    let text: String
    let accessibilityIdentifier: String

    // MARK: - Initialization

    /// Creates a list item component.
    /// - Parameters:
    ///   - icon: The SF Symbol name for the icon.
    ///   - text: The text content.
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    init(
        icon: String,
        text: String,
        accessibilityIdentifier: String? = nil
    ) {
        self.icon = icon
        self.text = text
        self.accessibilityIdentifier = accessibilityIdentifier ?? "SwiftUi.ListItem"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .accessibilityIdentifier("SwiftUi.ListItem.Icon")

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("SwiftUi.ListItem.Title")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ListItemComponent(
            icon: "star.fill",
            text: "Item 1",
            accessibilityIdentifier: "listItem"
        )
        ListItemComponent(
            icon: "heart.fill",
            text: "Item 2",
            accessibilityIdentifier: "listItem"
        )
        ListItemComponent(
            icon: "bookmark.fill",
            text: "Item 3",
            accessibilityIdentifier: "listItem"
        )
    }
    .padding()
}
