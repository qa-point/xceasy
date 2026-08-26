import SwiftUI

// MARK: - CheckboxComponent

/// Reusable checkbox component for both UIKit and SwiftUI screens.
///
/// This component provides a standardized checkbox with accessibility support.
struct CheckboxComponent: View {

    // MARK: - Properties

    let label: String
    let accessibilityIdentifier: String
    @Binding var isChecked: Bool

    // MARK: - Initialization

    /// Creates a checkbox component.
    /// - Parameters:
    ///   - label: The label text.
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    ///   - isChecked: The bound isChecked value.
    init(
        label: String,
        accessibilityIdentifier: String? = nil,
        isChecked: Binding<Bool>
    ) {
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier ?? "SwiftUi.CheckboxComponent"
        self._isChecked = isChecked
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .blue : .gray)
                .accessibilityIdentifier("SwiftUi.CheckboxComponent.Checkmark")

            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("SwiftUi.CheckboxComponent.Label")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isChecked.toggle()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Preview

#Preview {
    CheckboxComponent(
        label: "Accept terms",
        accessibilityIdentifier: "checkboxComponent",
        isChecked: .constant(false)
    )
    .padding()
}
