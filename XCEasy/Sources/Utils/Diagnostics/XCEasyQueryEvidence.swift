import CoreGraphics
import Foundation
import XCTest

/// Bounded, redacted query evidence attached to canonical diagnostic events.
internal struct XCEasyQueryEvidence: Codable, Equatable {
    internal struct Observation: Codable, Equatable {
        let attempt: Int
        let elapsedMilliseconds: Int64
        let state: String
        let exists: Bool
        let isHittable: Bool
    }

    internal struct Frame: Codable, Equatable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        /// Converts an XCUI frame into JSON-stable numeric fields.
        ///
        /// - Parameter frame: Core Graphics frame reported by XCUI.
        init(_ frame: CGRect) {
            self.x = Double(frame.origin.x)
            self.y = Double(frame.origin.y)
            self.width = Double(frame.size.width)
            self.height = Double(frame.size.height)
        }
    }

    internal struct Candidate: Codable, Equatable {
        let relationship: String
        let elementType: String
        let identifier: String
        let label: String
        let labelLength: Int
        let value: String?
        let valueLength: Int?
        let frame: Frame
        let isEnabled: Bool
        let isSelected: Bool
        let isHittable: Bool

        /// Captures bounded, redacted evidence directly from an XCUI candidate.
        ///
        /// - Parameters:
        ///   - element: Candidate element read from the current query.
        ///   - relationship: Whether the candidate matched or came from an alternative query.
        init(element: XCUIElement, relationship: String) {
            let rawLabel = element.label
            let rawValue = element.value.map { String(describing: $0) }
            self.relationship = relationship
            self.elementType = String(describing: element.elementType)
            self.identifier = SensitiveDataRedactor.redact(element.identifier)
            self.label = rawLabel.isEmpty ? "" : "<redacted:label>"
            self.labelLength = rawLabel.count
            self.value = rawValue.map { _ in "<redacted:value>" }
            self.valueLength = rawValue?.count
            self.frame = Frame(element.frame)
            self.isEnabled = element.isEnabled
            self.isSelected = element.isSelected
            self.isHittable = element.isHittable
        }

        /// Creates deterministic candidate evidence for tests and non-XCUI producers.
        ///
        /// - Parameters:
        ///   - relationship: Candidate relationship to the failed locator.
        ///   - elementType: XCUI element type name.
        ///   - identifier: Accessibility identifier redacted before storage.
        ///   - label: Raw label converted to a redacted marker plus length.
        ///   - value: Raw value converted to a redacted marker plus length.
        ///   - frame: Candidate frame.
        ///   - isEnabled: Whether XCUI reports the candidate enabled.
        ///   - isSelected: Whether XCUI reports the candidate selected.
        ///   - isHittable: Whether XCUI reports the candidate hittable.
        init(
            relationship: String,
            elementType: String,
            identifier: String,
            label: String,
            value: String?,
            frame: CGRect,
            isEnabled: Bool,
            isSelected: Bool,
            isHittable: Bool
        ) {
            self.relationship = relationship
            self.elementType = elementType
            self.identifier = SensitiveDataRedactor.redact(identifier)
            self.label = label.isEmpty ? "" : "<redacted:label>"
            self.labelLength = label.count
            self.value = value.map { _ in "<redacted:value>" }
            self.valueLength = value?.count
            self.frame = Frame(frame)
            self.isEnabled = isEnabled
            self.isSelected = isSelected
            self.isHittable = isHittable
        }
    }

    let expectedState: String
    let initialState: String
    let finalState: String
    let evidenceLevel: String
    let candidateCollection: String
    let matched: Bool
    let reasonCode: String
    let attempts: Int
    let elapsedMilliseconds: Int64
    let candidateCount: Int
    let selectedIndex: Int?
    let failedSegmentIndex: Int?
    let ancestorState: String?
    let candidates: [Candidate]
    let observations: [Observation]?
}
