import Foundation

/// Readiness and dispatch policy used by UI actions.
///
/// `hittable` is the safe default: an action waits until XCUI reports a valid hit point and then
/// uses the semantic `XCUIElement` action. `displayed` is an explicit compatibility mode for
/// unusual accessibility trees: it waits for on-screen display and dispatches through element
/// coordinates, which may interact with an overlay that covers the target.
public enum XCEasyActionPolicy: String, Codable, Sendable {
    case hittable
    case displayed
}

/// Immutable execution plan derived from one public action policy.
internal struct XCEasyActionPlan: Equatable {
    let expectedState: XCEasyElementState
    let dispatch: Dispatch

    /// Gesture dispatch mechanism selected by the public policy.
    internal enum Dispatch: String, Equatable {
        case semantic
        case coordinate
    }

    /// Maps a public policy to one stable wait-and-dispatch plan.
    ///
    /// - Parameter policy: Effective global or per-call action policy.
    init(policy: XCEasyActionPolicy) {
        switch policy {
        case .hittable:
            expectedState = .hittable
            dispatch = .semantic
        case .displayed:
            expectedState = .visible
            dispatch = .coordinate
        }
    }

    /// Evaluates whether an observed UI state satisfies this action plan.
    ///
    /// - Parameter state: Freshly observed state of the action target.
    /// - Returns: `true` when dispatch may start.
    func accepts(_ state: XCEasyElementState) -> Bool {
        switch expectedState {
        case .hittable:
            return state == .hittable
        case .visible:
            return state == .visible || state == .hittable
        case .absent, .hidden:
            return false
        }
    }
}
