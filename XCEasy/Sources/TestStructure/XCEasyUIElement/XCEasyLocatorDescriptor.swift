import CryptoKit
import Foundation

/// Immutable, redacted description of a complete root-to-element locator chain.
internal struct XCEasyLocatorDescriptor: Codable, Equatable {
    internal enum Strategy: String, Codable {
        case any
        case identifier
        case predicate
        case text
    }

    internal struct Segment: Codable, Equatable {
        let elementType: String
        let strategy: Strategy
        let value: String?
        let valueLength: Int?
        let isValueRedacted: Bool
        let index: Int?
        let selection: String?

        /// Creates a privacy-safe locator segment using the strongest supplied strategy.
        ///
        /// - Parameters:
        ///   - type: Optional XCUI element type constraint.
        ///   - identifier: Stable accessibility identifier, preferred when available.
        ///   - predicate: Predicate text; stored only as redacted metadata and length.
        ///   - text: Visible text; stored only as redacted metadata and length.
        ///   - index: Explicit candidate index, if selection is order-dependent.
        ///   - componentPosition: Optional symbolic component-collection selection.
        init(
            type: XCEasyUIElement.ElementType?,
            identifier: String?,
            predicate: String?,
            text: String?,
            index: Int?,
            componentPosition: XCEasyComponentPosition? = nil
        ) {
            self.elementType = String(describing: type ?? .any)
            self.index = index
            switch componentPosition {
            case .first:
                self.selection = "first"
            case .last:
                self.selection = "last"
            case .index:
                self.selection = "index"
            case .none:
                self.selection = nil
            }

            if let identifier {
                let safeIdentifier = SensitiveDataRedactor.redact(identifier)
                self.strategy = .identifier
                self.value = safeIdentifier
                self.valueLength = identifier.count
                self.isValueRedacted = safeIdentifier != identifier
            } else if let predicate {
                self.strategy = .predicate
                self.value = "<redacted:predicate>"
                self.valueLength = predicate.count
                self.isValueRedacted = true
            } else if let text {
                self.strategy = .text
                self.value = "<redacted:text>"
                self.valueLength = text.count
                self.isValueRedacted = true
            } else {
                self.strategy = .any
                self.value = nil
                self.valueLength = nil
                self.isValueRedacted = false
            }
        }

        fileprivate var canonicalValue: String {
            let values: [String] = [
                elementType,
                strategy.rawValue,
                value ?? "",
                valueLength.map(String.init) ?? "",
                String(isValueRedacted),
                index.map(String.init) ?? "",
                selection ?? ""
            ]
            let lengthPrefixedValues = values.map { value in
                "\(value.utf8.count):\(value)"
            }
            return lengthPrefixedValues.joined(separator: "|")
        }
    }

    let segments: [Segment]
    let fingerprint: String
    let fingerprintConfidence: String

    /// Creates a stable fingerprint for a complete root-to-leaf locator chain.
    ///
    /// - Parameter segments: Ordered locator segments beginning at the application root.
    init(segments: [Segment]) {
        self.segments = segments
        let canonicalValue = segments.map(\.canonicalValue).joined(separator: "/")
        self.fingerprint = SHA256.hash(data: Data(canonicalValue.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        self.fingerprintConfidence = segments.contains(where: \.isValueRedacted)
            ? "privacy_reduced"
            : "exact"
    }
}

extension XCEasyUIElement {
    internal var locatorDescriptor: XCEasyLocatorDescriptor {
        let segment = XCEasyLocatorDescriptor.Segment(
            type: type,
            identifier: identifier,
            predicate: format,
            text: text,
            index: index,
            componentPosition: componentPosition
        )
        let parentSegments = parentLocator?.locatorDescriptor.segments ?? []
        return XCEasyLocatorDescriptor(segments: parentSegments + [segment])
    }
}
