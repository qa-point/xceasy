// MARK: - LabelType

/// Enumeration representing Allure label types.
///
/// Used to categorize tests with different metadata types.
public enum LabelType: String {

    /// Epic label for high-level feature grouping.
    case epic = "epic"

    /// Feature label for feature grouping.
    case feature = "feature"

    /// Story label for user story identification.
    case story = "story"

    /// Suite label for test suite identification.
    case suite = "suite"

    /// Owner label for test owner identification.
    case owner = "owner"

    /// Severity label for test severity level.
    case severity = "severity"

    /// Tag label for custom tagging.
    case tag = "tag"

    /// AS_ID label for automated test identification.
    case id = "AS_ID"
}
