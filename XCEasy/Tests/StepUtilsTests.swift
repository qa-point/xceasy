import XCTest
@testable import XCEasy

final class StepUtilsTests: XCTestCase {
    private let attachment = Attachment(name: "log", source: "log.txt", type: "text/plain")

    func testFindLastFailedStepPrefersLatestDepthFirstFailure() {
        let first = StepResult(name: "first", status: .failed)
        let nested = StepResult(name: "nested", status: .broken)
        let parent = StepResult(name: "parent", status: .passed, steps: [nested])

        XCTAssertEqual(StepUtils.findLastFailedStep(in: [first, parent])?.name, "nested")
        XCTAssertNil(StepUtils.findLastFailedStep(in: [StepResult(name: "passed", status: .passed)]))
    }

    func testAttachToLastFailedStepHandlesRootAndNestedFailures() {
        let root = StepResult(name: "root", status: .failed)
        let rootResult = StepUtils.attachToLastFailedStep(steps: [root], attachment: attachment)
        XCTAssertEqual(rootResult[0].attachments?.first?.source, "log.txt")

        let nested = StepResult(name: "nested", status: .failed)
        let parent = StepResult(name: "parent", status: .passed, steps: [nested])
        let nestedResult = StepUtils.attachToLastFailedStep(steps: [parent], attachment: attachment)
        XCTAssertEqual(nestedResult[0].steps?[0].attachments?.first?.source, "log.txt")
    }

    func testAttachToLastFailedStepLeavesSuccessfulHierarchyUnchanged() {
        let steps = [StepResult(name: "passed", status: .passed)]

        let result = StepUtils.attachToLastFailedStep(steps: steps, attachment: attachment)

        XCTAssertNil(result[0].attachments)
    }

    func testAttachToDeepestStepHandlesEmptyRootAndNestedHierarchy() {
        XCTAssertTrue(StepUtils.attachToDeepestStep(steps: [], attachment: attachment).isEmpty)

        let leaf = StepResult(name: "leaf", status: .passed)
        let parent = StepResult(name: "parent", status: .passed, steps: [leaf])
        let result = StepUtils.attachToDeepestStep(steps: [parent], attachment: attachment)

        XCTAssertEqual(result[0].steps?[0].attachments?.first?.name, "log")
    }
}
