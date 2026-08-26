import SwiftUI

// MARK: - SwitchComponent

/// Reusable switch component for both UIKit and SwiftUI screens.
///
/// This component provides a standardized toggle switch with accessibility support.
struct SwitchComponent: View {

    // MARK: - Properties

    let label: String
    let accessibilityIdentifier: String
    @Binding var isOn: Bool

    // MARK: - Initialization

    /// Creates a switch component.
    /// - Parameters:
    ///   - label: The label text.
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    ///   - isOn: The bound isOn value.
    init(
        label: String,
        accessibilityIdentifier: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier ?? "SwiftUi.SwitchComponent"
        self._isOn = isOn
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("SwiftUi.SwitchComponent.Label")

            Toggle("", isOn: $isOn)
                .accessibilityIdentifier("SwiftUi.SwitchComponent.Toggle")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Preview

#Preview {
    SwitchComponent(
        label: "Enable feature",
        accessibilityIdentifier: "switchComponent",
        isOn: .constant(false)
    )
    .padding()
}
