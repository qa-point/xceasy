import Foundation

public struct ScreenPosition {
    let offset: CGVector
    let description: String

    /// Creates an internal normalized screen position and localized description.
    ///
    /// - Parameters:
    ///   - offset: Normalized coordinate where both axes use the `0...1` range.
    ///   - description: Human-readable position used in report steps.
    private init(offset: CGVector, description: String) {
        self.offset = offset
        self.description = description
    }

    public static let leftCenter = ScreenPosition(
        offset: CGVector(dx: 0.01, dy: 0.5),
        description: LocalizationManager.shared.string(forKey: "screen_position_left_center")
    )
    public static let rightCenter = ScreenPosition(
        offset: CGVector(dx: 0.99, dy: 0.5),
        description: LocalizationManager.shared.string(forKey: "screen_position_right_center")
    )
    public static let topCenter = ScreenPosition(
        offset: CGVector(dx: 0.5, dy: 0.01),
        description: LocalizationManager.shared.string(forKey: "screen_position_top_center")
    )
    public static let bottomCenter = ScreenPosition(
        offset: CGVector(dx: 0.5, dy: 0.99),
        description: LocalizationManager.shared.string(forKey: "screen_position_bottom_center")
    )
    public static let center = ScreenPosition(
        offset: CGVector(dx: 0.5, dy: 0.5),
        description: LocalizationManager.shared.string(forKey: "screen_position_center")
    )

    public static let leftTop = ScreenPosition(
        offset: CGVector(dx: 0.01, dy: 0.01),
        description: LocalizationManager.shared.string(forKey: "screen_position_left_top")
    )
    public static let leftBottom = ScreenPosition(
        offset: CGVector(dx: 0.01, dy: 0.99),
        description: LocalizationManager.shared.string(forKey: "screen_position_left_bottom")
    )
    public static let rightTop = ScreenPosition(
        offset: CGVector(dx: 0.99, dy: 0.01),
        description: LocalizationManager.shared.string(forKey: "screen_position_right_top")
    )
    public static let rightBottom = ScreenPosition(
        offset: CGVector(dx: 0.99, dy: 0.99),
        description: LocalizationManager.shared.string(forKey: "screen_position_right_bottom")
    )
}
