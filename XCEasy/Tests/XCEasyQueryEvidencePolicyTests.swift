import XCTest
@testable import XCEasy

final class XCEasyQueryEvidencePolicyTests: XCTestCase {
    func testOffSuppressesQueryEventsAndCandidates() {
        XCTAssertFalse(XCEasyQueryEvidencePolicy.shouldEmitEvents(level: .off))
        XCTAssertEqual(
            XCEasyQueryEvidencePolicy.candidateCollection(
                level: .off,
                matched: false,
                candidateCount: 3
            ),
            .omittedByPolicy
        )
    }

    func testBasicOmitsCandidatesForSuccessfulUnambiguousQuery() {
        XCTAssertTrue(XCEasyQueryEvidencePolicy.shouldEmitEvents(level: .basic))
        XCTAssertEqual(
            XCEasyQueryEvidencePolicy.candidateCollection(
                level: .basic,
                matched: true,
                candidateCount: 1
            ),
            .omittedByPolicy
        )
    }

    func testBasicCollectsCandidatesForFailureAndAmbiguity() {
        XCTAssertEqual(
            XCEasyQueryEvidencePolicy.candidateCollection(
                level: .basic,
                matched: false,
                candidateCount: 0
            ),
            .bounded
        )
        XCTAssertEqual(
            XCEasyQueryEvidencePolicy.candidateCollection(
                level: .basic,
                matched: true,
                candidateCount: 2
            ),
            .bounded
        )
    }

    func testDetailedCollectsCandidatesForSuccessfulQuery() {
        XCTAssertEqual(
            XCEasyQueryEvidencePolicy.candidateCollection(
                level: .detailed,
                matched: true,
                candidateCount: 1
            ),
            .bounded
        )
    }
}
