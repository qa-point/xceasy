import Foundation

/// Model representing a screenshot attachment for test reports.
///
/// Contains the screenshot data along with metadata such as name,
/// filename, and image type.
public struct ScreenshotAttachment {
    public let name: String
    public let filename: String
    public let data: Data
    public let type: AttachmentType

    /// Creates an in-memory screenshot ready for atomic persistence and Allure attachment.
    ///
    /// - Parameters:
    ///   - name: Human-readable attachment name.
    ///   - filename: Execution-unique destination filename.
    ///   - data: Encoded image bytes.
    ///   - type: Image MIME type; defaults to PNG.
    public init(name: String, filename: String, data: Data, type: AttachmentType = .png) {
        self.name = name
        self.filename = filename
        self.data = data
        self.type = type
    }

    public enum AttachmentType: String {
        case png = "image/png"
        case jpg = "image/jpeg"
    }
}
