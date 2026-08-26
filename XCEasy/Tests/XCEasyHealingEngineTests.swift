import CoreGraphics
import XCTest
@testable import XCEasy

final class XCEasyHealingEngineTests: XCTestCase {
    func testChangedIdentifierRanksDeterministicReplacementButNeverAppliesIt() {
        let proposal = XCEasyHealingEngine.evaluate(
            input: input(candidates: [candidate(identifier: "promoBanner.closeButton.v2")]),
            configuration: XCEasyHealingConfiguration(mode: .suggest, minimumConfidence: 0.5)
        )

        XCTAssertEqual(proposal.disposition, "suggested")
        XCTAssertEqual(proposal.rankedCandidates.first?.identifier, "promoBanner.closeButton.v2")
        XCTAssertTrue(proposal.requiresHumanApproval)
    }

    func testEquivalentCandidatesBlockHealingAsAmbiguous() {
        let proposal = XCEasyHealingEngine.evaluate(
            input: input(candidates: [
                candidate(identifier: "promoBanner.closeButton.v2"),
                candidate(identifier: "promoBanner.closeButton.v3")
            ]),
            configuration: XCEasyHealingConfiguration(
                mode: .suggest,
                minimumConfidence: 0.5,
                minimumScoreGap: 0.2
            )
        )

        XCTAssertEqual(proposal.disposition, "blocked")
        XCTAssertEqual(proposal.reasonCode, "healing.ambiguous_candidates")
    }

    func testSemanticTypeMismatchIsRejected() {
        var value = candidate(identifier: "promoBanner.closeButton.v2")
        value = .init(
            relationship: value.relationship,
            elementType: "StaticText",
            identifier: value.identifier,
            label: "",
            value: nil,
            frame: .zero,
            isEnabled: true,
            isSelected: false,
            isHittable: true
        )

        let proposal = XCEasyHealingEngine.evaluate(
            input: input(candidates: [value]),
            configuration: XCEasyHealingConfiguration(mode: .suggest)
        )

        XCTAssertEqual(proposal.reasonCode, "healing.no_semantic_candidate")
    }

    private func input(candidates: [XCEasyQueryEvidence.Candidate]) -> XCEasyHealingInput {
        XCEasyHealingInput(
            executionId: "execution",
            failureFingerprint: String(repeating: "a", count: 64),
            selector: XCEasyLocatorDescriptor(segments: [
                .init(
                    type: .button,
                    identifier: "promoBanner.closeButton",
                    predicate: nil,
                    text: nil,
                    index: nil
                )
            ]),
            candidates: candidates
        )
    }

    private func candidate(identifier: String) -> XCEasyQueryEvidence.Candidate {
        .init(
            relationship: "alternative",
            elementType: "button",
            identifier: identifier,
            label: "",
            value: nil,
            frame: .zero,
            isEnabled: true,
            isSelected: false,
            isHittable: true
        )
    }
}
