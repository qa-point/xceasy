// MARK: - Optional+Collection Extension

/// Extension for Optional where Wrapped is a Collection.
///
/// Provides a convenient way to check if an optional collection is nil or empty.
public extension Optional where Wrapped: Collection {

    /// Returns true if the optional collection is nil or empty.
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
