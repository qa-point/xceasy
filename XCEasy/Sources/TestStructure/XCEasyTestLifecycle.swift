import Foundation

internal enum XCEasyTestLifecycleState: String, Codable, CaseIterable {
    case created
    case settingUp = "setting_up"
    case running
    case tearingDown = "tearing_down"
    case finished
    case interrupted
}

internal struct XCEasyTestLifecycleMachine: Equatable {
    internal enum TransitionError: Error, Equatable {
        case invalidTransition(from: XCEasyTestLifecycleState, to: XCEasyTestLifecycleState)
        case alreadyTerminal(XCEasyTestLifecycleState)
    }

    private(set) var state: XCEasyTestLifecycleState = .created

    /// Moves the lifecycle to an explicitly allowed nonterminal or terminal state.
    ///
    /// - Parameter next: Requested lifecycle state.
    /// - Throws: ``TransitionError/alreadyTerminal(_:)`` after termination, or
    ///   ``TransitionError/invalidTransition(from:to:)`` for an unsupported edge.
    mutating func transition(to next: XCEasyTestLifecycleState) throws {
        guard state != .finished, state != .interrupted else {
            throw TransitionError.alreadyTerminal(state)
        }
        guard Self.allowedTransitions[state, default: []].contains(next) else {
            throw TransitionError.invalidTransition(from: state, to: next)
        }
        state = next
    }

    private static let allowedTransitions: [XCEasyTestLifecycleState: Set<XCEasyTestLifecycleState>] = [
        // `finished` is allowed for plain XCTestCase subclasses that do not use
        // XCEasyTestCase hooks but are still observed and reported by XCEasy.
        .created: [.settingUp, .finished, .interrupted],
        .settingUp: [.running, .tearingDown, .finished, .interrupted],
        .running: [.tearingDown, .finished, .interrupted],
        .tearingDown: [.finished, .interrupted]
    ]
}
