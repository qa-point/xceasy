// MARK: - SeverityState

/// Enumeration representing test severity levels.
///
/// Used to indicate the importance or criticality of a test.
public enum SeverityState: String {

    /// Blocker severity - highest priority, blocks testing.
    case blocker = "BLOCKER"

    /// Critical severity - high priority, critical functionality.
    case critical = "CRITICAL"

    /// Normal severity - standard priority.
    case normal = "NORMAL"

    /// Minor severity - low priority, minor issues.
    case minor = "MINOR"

    /// Trivial severity - lowest priority, cosmetic issues.
    case trivial = "TRIVIAL"
}
