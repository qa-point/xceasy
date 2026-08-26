import XCEasy

/// One component object used for equivalent UIKit and SwiftUI fixtures.
struct PromoBannerPOM: XCEasyComponent {
    private let technology: Technology
    let componentName: String

    enum Technology: String {
        case uiKit = "UIKit"
        case swiftUI = "SwiftUI"
    }

    init(technology: Technology, componentName: String? = nil) {
        self.technology = technology
        self.componentName = componentName ?? "\(technology.rawValue) promo banner"
    }

    var element: XCEasyUIElement {
        find(identifier: "\(technology.rawValue).PromoBanner", desc: "\(technology.rawValue) promo banner")
    }

    var title: XCEasyUIElement {
        element.child(identifier: "\(technology.rawValue).PromoBanner.Title", desc: "Promo banner title")
    }

    var subtitle: XCEasyUIElement {
        element.child(identifier: "\(technology.rawValue).PromoBanner.Subtitle", desc: "Promo banner subtitle")
    }

    var closeButton: XCEasyUIElement {
        switch technology {
        case .uiKit:
            element.child(
                type: .button,
                identifier: "UIKit.PromoBanner.CloseButton",
                desc: "Promo banner close button"
            )
        case .swiftUI:
            element.child(
                type: .button,
                identifier: "SwiftUI.PromoBanner.CloseButton",
                desc: "Promo banner close button"
            )
        }
    }

    @discardableResult
    func assertContentExists() -> Self {
        step("Check content") {
            assertIsDisplayed()
            title.assertIsDisplayed()
            subtitle.assertIsDisplayed()
            closeButton.assertIsHittable()
        }
        return self
    }

    @discardableResult
    func assertGeneration(_ generation: Int) -> Self {
        step("Check generation \(generation)") {
            title.assertLabel(value: "Special offer \(generation)")
        }
        return self
    }

    @discardableResult
    func dismiss() -> Self {
        step("Dismiss") {
            element.assertDisappears(timeout: 3) {
                closeButton.tap()
            }
        }
        return self
    }
}
