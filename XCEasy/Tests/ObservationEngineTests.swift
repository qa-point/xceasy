import XCTest
@testable import XCEasy

final class ObservationEngineTests: XCTestCase {
    func testImmediateMatchSamplesOnceWithoutSleeping() {
        let clock = FakeClock()
        var samples = 0
        let result = clock.engine.observe(timeout: 5, interval: 0.1, sample: {
            samples += 1
            return true
        }, matches: { $0 })

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertEqual(samples, 1)
        XCTAssertEqual(clock.sleepCount, 0)
        XCTAssertEqual(result.elapsedMilliseconds, 0)
        XCTAssertEqual(result.samples.count, 1)
    }

    func testPollingResamplesUntilStateChanges() {
        let clock = FakeClock()
        var values = [false, false, true]
        let result = clock.engine.observe(timeout: 1, interval: 0.1, sample: {
            values.removeFirst()
        }, matches: { $0 })

        XCTAssertTrue(result.matched)
        XCTAssertFalse(result.first)
        XCTAssertTrue(result.last)
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(result.elapsedMilliseconds, 200)
        XCTAssertEqual(result.samples.map(\.elapsedMilliseconds), [0, 100, 200])
    }

    func testTimeoutUsesOneDeadlineAndReturnsLastObservation() {
        let clock = FakeClock()
        var sample = 0
        let result = clock.engine.observe(timeout: 0.25, interval: 0.1, sample: {
            sample += 1
            return sample
        }, matches: { _ in false })

        XCTAssertFalse(result.matched)
        XCTAssertEqual(result.first, 1)
        XCTAssertEqual(result.last, 4)
        XCTAssertEqual(result.attempts, 4)
        XCTAssertEqual(result.elapsedMilliseconds, 250)
    }

    func testZeroTimeoutStillTakesOneObservation() {
        let clock = FakeClock()
        let result = clock.engine.observe(timeout: 0, interval: 1, sample: { "absent" }, matches: { $0 == "absent" })

        XCTAssertTrue(result.matched)
        XCTAssertEqual(result.attempts, 1)
        XCTAssertEqual(clock.sleepCount, 0)
    }
}

private final class FakeClock {
    private(set) var nanoseconds: UInt64 = 0
    private(set) var sleepCount = 0

    var engine: ObservationEngine {
        ObservationEngine(
            nowNanoseconds: { self.nanoseconds },
            sleep: { interval in
                self.sleepCount += 1
                self.nanoseconds += UInt64(interval * 1_000_000_000)
            }
        )
    }
}
