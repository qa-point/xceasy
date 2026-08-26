import SwiftUI

// MARK: - InputComponent

/// Reusable input component for both UIKit and SwiftUI screens.
///
/// This component provides a standardized text input field with accessibility support.
struct InputComponent: View {

    // MARK: - Properties

    let placeholder: String
    let accessibilityIdentifier: String
    @Binding var text: String

    // MARK: - Initialization

    /// Creates an input component.
    /// - Parameters:
    ///   - placeholder: The placeholder text.
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    ///   - text: The bound text value.
    init(
        placeholder: String,
        accessibilityIdentifier: String? = nil,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.accessibilityIdentifier = accessibilityIdentifier ?? "SwiftUi.InputComponent"
        self._text = text
    }

    // MARK: - Body

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityIdentifier(accessibilityIdentifier)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

// MARK: - Preview

#Preview {
    InputComponent(
        placeholder: "Enter text",
        accessibilityIdentifier: "inputComponent",
        text: .constant("")
    )
    .padding()
}
