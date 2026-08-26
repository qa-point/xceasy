import Foundation

/// Result of one deadline-bound polling operation.
internal struct ObservationSample<Value> {
    let attempt: Int
    let elapsedMilliseconds: Int64
    let value: Value
}

internal struct ObservationResult<Value> {
    let matched: Bool
    let first: Value
    let last: Value
    let attempts: Int
    let elapsedMilliseconds: Int64
    let samples: [ObservationSample<Value>]
}

/// Small deterministic polling engine. Time and sleeping are injected so unit
/// tests cover deadlines and transitions without a simulator or real sleeps.
internal struct ObservationEngine {
    private let nowNanoseconds: () -> UInt64
    private let sleep: (TimeInterval) -> Void

    /// Creates a polling engine with injectable monotonic time and sleeping.
    ///
    /// - Parameters:
    ///   - nowNanoseconds: Monotonic clock provider.
    ///   - sleep: Bounded delay invoked between samples.
    init(
        nowNanoseconds: @escaping () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
        sleep: @escaping (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    ) {
        self.nowNanoseconds = nowNanoseconds
        self.sleep = sleep
    }

    /// Samples immediately and then polls until a predicate matches or the deadline expires.
    ///
    /// - Parameters:
    ///   - timeout: Total deadline in seconds; nonpositive values still perform one sample.
    ///   - interval: Requested delay between samples, bounded by the remaining deadline.
    ///   - sample: Fresh value producer.
    ///   - matches: Predicate defining success.
    /// - Returns: First/last values, samples, attempts, elapsed time, and match outcome.
    func observe<Value>(
        timeout: TimeInterval,
        interval: TimeInterval,
        sample: () -> Value,
        matches: (Value) -> Bool
    ) -> ObservationResult<Value> {
        let start = nowNanoseconds()
        let timeoutNanoseconds = Self.nanoseconds(for: timeout)
        let deadline = start.addingReportingOverflow(timeoutNanoseconds)
        let end = deadline.overflow ? UInt64.max : deadline.partialValue

        var attempts = 1
        let first = sample()
        var last = first
        var matched = matches(first)
        var samples = [ObservationSample(
            attempt: attempts,
            elapsedMilliseconds: 0,
            value: first
        )]

        while !matched && nowNanoseconds() < end {
            let current = nowNanoseconds()
            let remaining = end > current ? end - current : 0
            let requested = Self.nanoseconds(for: max(0, interval))
            let sleepNanoseconds = min(remaining, requested)
            sleep(TimeInterval(sleepNanoseconds) / 1_000_000_000)
            attempts += 1
            last = sample()
            matched = matches(last)
            samples.append(ObservationSample(
                attempt: attempts,
                elapsedMilliseconds: Self.elapsedMilliseconds(from: start, to: nowNanoseconds()),
                value: last
            ))
        }

        let elapsed = nowNanoseconds() >= start ? nowNanoseconds() - start : 0
        return ObservationResult(
            matched: matched,
            first: first,
            last: last,
            attempts: attempts,
            elapsedMilliseconds: Int64(min(elapsed / 1_000_000, UInt64(Int64.max))),
            samples: samples
        )
    }

    /// Converts two monotonic timestamps into a saturating nonnegative duration.
    ///
    /// - Parameters:
    ///   - start: Start timestamp in nanoseconds.
    ///   - end: End timestamp in nanoseconds.
    /// - Returns: Elapsed milliseconds capped at `Int64.max`.
    private static func elapsedMilliseconds(from start: UInt64, to end: UInt64) -> Int64 {
        let elapsed = end >= start ? end - start : 0
        return Int64(min(elapsed / 1_000_000, UInt64(Int64.max)))
    }

    /// Converts seconds into a saturating unsigned nanosecond interval.
    ///
    /// - Parameter timeout: Interval in seconds.
    /// - Returns: Zero for nonpositive input, otherwise a value capped at `UInt64.max`.
    private static func nanoseconds(for timeout: TimeInterval) -> UInt64 {
        guard timeout > 0 else { return 0 }
        let value = timeout * 1_000_000_000
        return value >= Double(UInt64.max) ? UInt64.max : UInt64(value)
    }
}
