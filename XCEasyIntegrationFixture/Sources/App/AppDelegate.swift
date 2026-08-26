import UIKit

// MARK: - AppDelegate

/// Application delegate for handling app lifecycle events.
///
/// This class integrates UIKit lifecycle methods with the SwiftUI app structure.
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Properties

    /// The main window of the application.
    var window: UIWindow?

    // MARK: - UIApplicationDelegate Methods

    /// Allows the integration fixture to finish launching without global mutable setup.
    ///
    /// - Parameters:
    ///   - application: Launching application instance.
    ///   - launchOptions: UIKit launch context, unused by this deterministic fixture.
    /// - Returns: Always `true` to continue launching.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    /// Receives activation without mutating fixture state.
    ///
    /// - Parameter application: Application that became active.
    func applicationDidBecomeActive(_ application: UIApplication) {}

    /// Receives resignation without mutating fixture state.
    ///
    /// - Parameter application: Application about to leave the active state.
    func applicationWillResignActive(_ application: UIApplication) {}

    /// Receives termination without persisting cross-test fixture state.
    ///
    /// - Parameter application: Application about to terminate.
    func applicationWillTerminate(_ application: UIApplication) {}
}
