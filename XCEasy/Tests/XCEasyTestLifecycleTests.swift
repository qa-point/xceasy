import XCTest
@testable import XCEasy

final class XCEasyTestLifecycleTests: XCTestCase {
    func testHappyPathReachesFinished() throws {
        var machine = XCEasyTestLifecycleMachine()

        try machine.transition(to: .settingUp)
        try machine.transition(to: .running)
        try machine.transition(to: .tearingDown)
        try machine.transition(to: .finished)

        XCTAssertEqual(machine.state, .finished)
    }

    func testInvalidTransitionReturnsTypedError() {
        var machine = XCEasyTestLifecycleMachine()

        XCTAssertThrowsError(try machine.transition(to: .tearingDown)) { error in
            XCTAssertEqual(
                error as? XCEasyTestLifecycleMachine.TransitionError,
                .invalidTransition(from: .created, to: .tearingDown)
            )
        }
        XCTAssertEqual(machine.state, .created)
    }

    func testPlainXCTestLifecycleCanFinishDirectlyFromCreated() throws {
        var machine = XCEasyTestLifecycleMachine()

        try machine.transition(to: .finished)

        XCTAssertEqual(machine.state, .finished)
    }

    func testTerminalStateRejectsAdditionalTransitions() throws {
        var machine = XCEasyTestLifecycleMachine()
        try machine.transition(to: .interrupted)

        XCTAssertThrowsError(try machine.transition(to: .finished)) { error in
            XCTAssertEqual(
                error as? XCEasyTestLifecycleMachine.TransitionError,
                .alreadyTerminal(.interrupted)
            )
        }
    }

    func testSetupMayFinishOrInterruptBeforeRunning() throws {
        var finished = XCEasyTestLifecycleMachine()
        try finished.transition(to: .settingUp)
        try finished.transition(to: .finished)
        XCTAssertEqual(finished.state, .finished)

        var interrupted = XCEasyTestLifecycleMachine()
        try interrupted.transition(to: .settingUp)
        try interrupted.transition(to: .interrupted)
        XCTAssertEqual(interrupted.state, .interrupted)
    }

    func testRunningMayFinishOrInterruptWithoutTeardown() throws {
        var finished = XCEasyTestLifecycleMachine()
        try finished.transition(to: .settingUp)
        try finished.transition(to: .running)
        try finished.transition(to: .finished)
        XCTAssertEqual(finished.state, .finished)

        var interrupted = XCEasyTestLifecycleMachine()
        try interrupted.transition(to: .settingUp)
        try interrupted.transition(to: .running)
        try interrupted.transition(to: .interrupted)
        XCTAssertEqual(interrupted.state, .interrupted)
    }

    func testTeardownMayInterrupt() throws {
        var machine = XCEasyTestLifecycleMachine()
        try machine.transition(to: .settingUp)
        try machine.transition(to: .tearingDown)
        try machine.transition(to: .interrupted)

        XCTAssertEqual(machine.state, .interrupted)
    }
}
