import SwiftUI

struct SwiftUIPromoBanner: View {
    @Binding var isPresented: Bool
    let generation: Int

    var body: some View {
        if isPresented {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Special offer \(generation)")
                            .font(.headline)
                            .accessibilityIdentifier("SwiftUI.PromoBanner.Title")
                        Text("Reusable SwiftUI banner component")
                            .font(.subheadline)
                            .accessibilityIdentifier("SwiftUI.PromoBanner.Subtitle")
                    }
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close promotion banner")
                    .accessibilityIdentifier("SwiftUI.PromoBanner.CloseButton")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("SwiftUI.PromoBanner")
        }
    }
}
