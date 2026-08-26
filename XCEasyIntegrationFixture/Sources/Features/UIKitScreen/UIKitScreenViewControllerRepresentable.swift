import SwiftUI
import UIKit

// MARK: - UIKitScreenViewControllerRepresentable

/// SwiftUI wrapper for UIKitScreenViewController.
///
/// This struct allows the UIKit view controller to be used within SwiftUI navigation.
struct UIKitScreenViewControllerRepresentable: UIViewControllerRepresentable {

    // MARK: - Methods

    /// Creates the UIKit fixture hosted by the SwiftUI tab.
    ///
    /// - Parameter context: SwiftUI representable creation context.
    /// - Returns: Newly configured UIKit screen controller.
    func makeUIViewController(context: Context) -> UIKitScreenViewController {
        let viewController = UIKitScreenViewController()
        viewController.title = "UIKit Screen"
        return viewController
    }

    /// Preserves the controller as-is because the fixture owns no SwiftUI-driven state.
    ///
    /// - Parameters:
    ///   - uiViewController: Existing hosted UIKit controller.
    ///   - context: SwiftUI representable update context.
    func updateUIViewController(_ uiViewController: UIKitScreenViewController, context: Context) {}
}
