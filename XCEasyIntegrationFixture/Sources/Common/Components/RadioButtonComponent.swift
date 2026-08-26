import SwiftUI

// MARK: - RadioButtonComponent

/// Reusable radio button component for both UIKit and SwiftUI screens.
///
/// This component provides a standardized radio button with accessibility support.
struct RadioButtonComponent: View {

    // MARK: - Properties

    let label: String
    let accessibilityIdentifier: String
    let groupName: String
    @Binding var selectedOption: String

    // MARK: - Initialization

    /// Creates a radio button component.
    /// - Parameters:
    ///   - label: The label text.
    ///   - accessibilityIdentifier: The accessibility identifier for testing.
    ///   - groupName: The group name for radio button selection.
    ///   - selectedOption: The bound selected option value.
    init(
        label: String,
        accessibilityIdentifier: String? = nil,
        groupName: String,
        selectedOption: Binding<String>
    ) {
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier ?? "SwiftUi.RadioButton"
        self.groupName = groupName
        self._selectedOption = selectedOption
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Image(systemName: selectedOption == groupName ? "circle.fill" : "circle")
                .foregroundColor(selectedOption == groupName ? .blue : .gray)
                .accessibilityIdentifier("SwiftUi.RadioButton.Indicator")

            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("SwiftUi.RadioButton.Label")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedOption = groupName
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RadioButtonComponent(
            label: "Option 1",
            accessibilityIdentifier: "radioButton1",
            groupName: "option1",
            selectedOption: .constant("")
        )
        RadioButtonComponent(
            label: "Option 2",
            accessibilityIdentifier: "radioButton2",
            groupName: "option2",
            selectedOption: .constant("")
        )
    }
    .padding()
}
