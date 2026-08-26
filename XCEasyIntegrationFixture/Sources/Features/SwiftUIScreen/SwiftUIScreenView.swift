import SwiftUI

// MARK: - SwiftUIScreenView

/// SwiftUI view demonstrating all reusable components.
///
/// This screen displays all reusable components (input, switch, checkbox,
/// radio buttons, list items) with a loading indicator for testing purposes.
struct SwiftUIScreenView: View {

    // MARK: - Properties

    @State private var inputText: String = ""
    @State private var switchValue: Bool = false
    @State private var checkboxValue: Bool = false
    @State private var selectedRadioOption: String = ""
    @State private var isLoading: Bool = false
    @State private var isPromoBannerPresented: Bool = true
    @State private var promoBannerGeneration: Int = 1

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Screen Title

                Text("SwiftUI Screen")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)

                SwiftUIPromoBanner(
                    isPresented: $isPromoBannerPresented,
                    generation: promoBannerGeneration
                )

                Button("Show new promo banner") {
                    promoBannerGeneration += 1
                    isPromoBannerPresented = true
                }
                .accessibilityIdentifier("SwiftUI.PromoBanner.ShowButton")

                // MARK: - Input Section

                SectionView(title: "Input") {
                    InputComponent(
                        placeholder: "Enter text",
                        text: $inputText
                    )
                }

                // MARK: - Switch Section

                SectionView(title: "Switch") {
                    SwitchComponent(
                        label: "Enable feature",
                        isOn: $switchValue
                    )
                }

                // MARK: - Checkbox Section

                SectionView(title: "Checkbox") {
                    CheckboxComponent(
                        label: "Accept terms",
                        isChecked: $checkboxValue
                    )
                }

                // MARK: - Radio Buttons Section

                SectionView(title: "Radio Buttons") {
                    VStack(alignment: .leading, spacing: 8) {
                        RadioButtonComponent(
                            label: "Option 1",
                            groupName: "option1",
                            selectedOption: $selectedRadioOption
                        )

                        RadioButtonComponent(
                            label: "Option 2",
                            groupName: "option2",
                            selectedOption: $selectedRadioOption
                        )
                    }
                }

                // MARK: - List Items Section

                SectionView(title: "List Items") {
                    VStack(spacing: 8) {
                        ListItemComponent(
                            icon: "star.fill",
                            text: "Item 1"
                        )

                        ListItemComponent(
                            icon: "heart.fill",
                            text: "Item 2"
                        )

                        ListItemComponent(
                            icon: "bookmark.fill",
                            text: "Item 3"
                        )
                    }
                }

                // MARK: - Actions Section

                SectionView(title: "Actions") {
                    Button(action: loadContent) {
                        Text("Load Content")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .accessibilityIdentifier("SwiftUi.LoadingView.Button")

                    LoadingView(
                        accessibilityIdentifier: "SwiftUi.LoadingView",
                        isLoading: $isLoading
                    )
                }
            }
            .padding()
        }
        .navigationTitle("SwiftUI Screen")
    }

    // MARK: - Methods

    /// Loads content with a delay to demonstrate loading state.
    private func loadContent() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    SwiftUIScreenView()
}
