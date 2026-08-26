import XCTest
@testable import XCEasy

final class XCEasyComponentTests: XCTestCase {
    func testComponentAndThreeNestedLevelsStayLazy() {
        let context = ComponentTestContext()
        let component = NestedComponent(
            element: XCEasyUIElement(identifier: "root", timeout: 0, testContext: context)
        )

        let leaf = component.section.card.leaf

        XCTAssertEqual(context.appReadCount, 0)
        XCTAssertEqual(leaf.locatorDescriptor.segments.map(\.value), ["root", "section", "card", "leaf"])
        XCTAssertEqual(component.componentName, "Nested component")
    }

    func testComponentCollectionCreatesLazyFirstLastIndexAndRangeComponents() {
        resetSharedStepContext()
        let collection = XCEasyComponentCollection<IndexedComponent>()

        let first = collection.first
        let last = collection.last
        let third = collection.get(index: 2, componentName: "Recommended product")
        let range = collection.get(indices: 0..<3)

        XCTAssertEqual(first.position, .first)
        XCTAssertEqual(last.position, .last)
        XCTAssertEqual(first.componentName, "First IndexedComponent")
        XCTAssertEqual(last.componentName, "Last IndexedComponent")
        XCTAssertEqual(third.position, .index(2))
        XCTAssertEqual(third.componentName, "Recommended product")
        XCTAssertEqual(range.map(\.position), [.index(0), .index(1), .index(2)])
        XCTAssertEqual(
            range.map(\.componentName),
            [
                "IndexedComponent at index 0",
                "IndexedComponent at index 1",
                "IndexedComponent at index 2"
            ]
        )
        XCTAssertEqual(first.element.locatorDescriptor.segments.first?.selection, "first")
        XCTAssertEqual(last.element.locatorDescriptor.segments.first?.selection, "last")
        XCTAssertEqual(third.element.locatorDescriptor.segments.first?.index, 2)
    }

    func testComponentCollectionCountWaitsAndAssertionsCoverExactBoundsAndEmptiness() {
        let populated = collection(snapshot: .init(
            count: 3,
            displayedIndices: [0, 1, 2],
            isContextAvailable: true
        ))
        let empty = collection(snapshot: .init(
            count: 0,
            displayedIndices: [],
            isContextAvailable: true
        ))

        XCTAssertTrue(populated.waitForCount(3, timeout: 0))
        XCTAssertTrue(populated.waitForCount(atLeast: 2, timeout: 0))
        XCTAssertTrue(populated.waitForCount(atMost: 3, timeout: 0))
        XCTAssertFalse(populated.waitForCount(4, timeout: 0))
        XCTAssertFalse(populated.waitForCount(atMost: 2, timeout: 0))

        populated.assertCount(3, timeout: 0)
        populated.assertCount(atLeast: 2, timeout: 0)
        populated.assertCount(atMost: 3, timeout: 0)
        populated.assertIsNotEmpty(timeout: 0)
        empty.assertIsEmpty(timeout: 0)

        XCTExpectFailure("Mismatched collection assertions intentionally record XCTest failures") {
            populated.assertCount(2, timeout: 0)
            populated.assertIsEmpty(timeout: 0)
            empty.assertIsNotEmpty(timeout: 0)
        }
    }

    func testComponentCollectionPollingRequestsFreshSnapshotUntilCountMatches() {
        var requestedSnapshots = 0
        let collection = XCEasyComponentCollection<IndexedComponent>(snapshotProvider: { _ in
            requestedSnapshots += 1
            return XCEasyCollectionSnapshot(
                count: requestedSnapshots == 1 ? 1 : 3,
                displayedIndices: [],
                isContextAvailable: true
            )
        })

        XCTAssertTrue(collection.waitForCount(3, timeout: 0.2))
        XCTAssertEqual(requestedSnapshots, 2)
    }

    func testComponentCollectionAllDisplayedRequiresNonemptyCollectionAndEveryItem() {
        let displayed = collection(snapshot: .init(
            count: 3,
            displayedIndices: [0, 1, 2],
            isContextAvailable: true
        ))
        let partiallyHidden = collection(snapshot: .init(
            count: 3,
            displayedIndices: [0, 2],
            isContextAvailable: true
        ))
        let empty = collection(snapshot: .init(
            count: 0,
            displayedIndices: [],
            isContextAvailable: true
        ))

        XCTAssertTrue(displayed.waitForAllDisplayed(timeout: 0))
        XCTAssertFalse(partiallyHidden.waitForAllDisplayed(timeout: 0))
        XCTAssertFalse(empty.waitForAllDisplayed(timeout: 0))
        displayed.assertAllDisplayed(timeout: 0)

        XCTExpectFailure("Hidden and empty collections intentionally fail all-displayed assertions") {
            partiallyHidden.assertAllDisplayed(timeout: 0)
            empty.assertAllDisplayed(timeout: 0)
        }
    }

    func testComponentCollectionOperationsWriteDefaultStepsAndStructuredEvidence() throws {
        resetSharedStepContext()
        let populated = collection(snapshot: .init(
            count: 3,
            displayedIndices: [0, 1, 2],
            isContextAvailable: true
        ))
        let empty = collection(snapshot: .init(
            count: 0,
            displayedIndices: [],
            isContextAvailable: true
        ))

        _ = populated.first
        _ = populated.last
        _ = populated.get(index: 1)
        _ = populated.get(indices: 0..<2)
        populated.assertCount(3, timeout: 0)
        populated.assertCount(atLeast: 2, timeout: 0)
        populated.assertCount(atMost: 3, timeout: 0)
        populated.assertIsNotEmpty(timeout: 0)
        empty.assertIsEmpty(timeout: 0)
        _ = populated.waitForCount(3, timeout: 0)
        _ = populated.waitForCount(atLeast: 2, timeout: 0)
        _ = populated.waitForCount(atMost: 3, timeout: 0)
        populated.assertAllDisplayed(timeout: 0)
        _ = populated.waitForAllDisplayed(timeout: 0)

        let expectedCodes: Set<String> = [
            "component.collection.select_first",
            "component.collection.select_last",
            "component.collection.select_index",
            "component.collection.select_range",
            "component.collection.assert_count_exact",
            "component.collection.assert_count_at_least",
            "component.collection.assert_count_at_most",
            "component.collection.assert_not_empty",
            "component.collection.assert_empty",
            "component.collection.wait_count_exact",
            "component.collection.wait_count_at_least",
            "component.collection.wait_count_at_most",
            "component.collection.assert_all_displayed",
            "component.collection.wait_all_displayed"
        ]
        let eventURL = try XCTUnwrap(XCEasyTestLogger.shared.currentEventFileURL())
        let events = try String(contentsOf: eventURL, encoding: .utf8)
            .split(separator: "\n")
            .map { try JSONDecoder().decode(DiagnosticEvent.self, from: Data($0.utf8)) }
        let completed = events.filter { $0.event == "ui.collection.finished" }
        let codes = Set(completed.compactMap(\.operationCode))
        let exact = try XCTUnwrap(completed.last {
            $0.operationCode == "component.collection.wait_count_exact"
        })

        XCTAssertTrue(expectedCodes.isSubset(of: codes))
        XCTAssertEqual(exact.selector?.segments.map(\.value), ["item"])
        XCTAssertEqual(exact.collectionEvidence?.expectation, "count_exact")
        XCTAssertEqual(exact.collectionEvidence?.expectedCount, 3)
        XCTAssertEqual(exact.collectionEvidence?.actualCount, 3)
        XCTAssertEqual(exact.collectionEvidence?.matched, true)
        XCTAssertFalse(XCEasyTestContext.shared.testResult?.steps?.isEmpty ?? true)
        XCTAssertTrue(
            XCEasyTestContext.shared.testResult?.steps?.contains {
                $0.name == "Create locator for the first component"
            } ?? false
        )
    }

    func testComponentCollectionVisibilityEvidenceBoundsLargeFailureLists() throws {
        resetSharedStepContext()
        let largeCollection = collection(snapshot: .init(
            count: 150,
            displayedIndices: [],
            isContextAvailable: true
        ))

        XCTAssertFalse(largeCollection.waitForAllDisplayed(timeout: 0))

        let eventURL = try XCTUnwrap(XCEasyTestLogger.shared.currentEventFileURL())
        let events = try String(contentsOf: eventURL, encoding: .utf8)
            .split(separator: "\n")
            .map { try JSONDecoder().decode(DiagnosticEvent.self, from: Data($0.utf8)) }
        let finished = try XCTUnwrap(events.last {
            $0.event == "ui.collection.finished"
                && $0.operationCode == "component.collection.wait_all_displayed"
        })

        XCTAssertEqual(finished.collectionEvidence?.actualCount, 150)
        XCTAssertEqual(finished.collectionEvidence?.failedIndices?.count, 100)
        XCTAssertEqual(finished.collectionEvidence?.failedIndices?.first, 0)
        XCTAssertEqual(finished.collectionEvidence?.failedIndices?.last, 99)
        XCTAssertEqual(finished.collectionEvidence?.observations?.last?.failedIndices?.count, 100)
    }

    func testComponentNonAssertingWaitsObserveOnlyElementAndReturnFalse() {
        let previousEvidenceLevel = XCEasyConfig.uiQueryEvidenceLevel
        XCEasyConfig.uiQueryEvidenceLevel = .off
        defer { XCEasyConfig.uiQueryEvidenceLevel = previousEvidenceLevel }

        let context = ComponentTestContext()
        let component = NestedComponent(
            element: XCEasyUIElement(identifier: "root", timeout: 0, testContext: context)
        )

        XCTAssertFalse(component.waitForDisplayed(timeout: 0))
        XCTAssertFalse(component.waitForHittable(timeout: 0))
        XCTAssertFalse(component.waitForEnabled(timeout: 0))
        XCTAssertFalse(component.waitForSelected(timeout: 0))
        XCTAssertEqual(context.appReadCount, 4)
    }

    func testIndexedComponentUsesZeroWhenIndexIsOmitted() {
        let first = IndexedComponent()
        let third = IndexedComponent(index: 2)
        let named = IndexedComponent(index: 1, componentName: "Recommended product")

        XCTAssertEqual(first.position, .first)
        XCTAssertEqual(first.element.locatorDescriptor.segments.first?.index, 0)
        XCTAssertEqual(first.componentName, "First IndexedComponent")
        XCTAssertEqual(third.position, .index(2))
        XCTAssertEqual(third.componentName, "IndexedComponent at index 2")
        XCTAssertEqual(third.element.locatorDescriptor.segments.first?.index, 2)
        XCTAssertEqual(named.componentName, "Recommended product")
    }

    func testInvalidAndEmptySymbolicPositionsProduceSafeQueryReasons() {
        let invalid = XCEasyQuerySelection.resolve(position: .index(-1), reportedCount: 3)
        let emptyLast = XCEasyQuerySelection.resolve(position: .last, reportedCount: 0)
        let currentLast = XCEasyQuerySelection.resolve(position: .last, reportedCount: 3)

        XCTAssertNil(invalid.selectedIndex)
        XCTAssertEqual(invalid.failureReason, "query.invalid_index")
        XCTAssertEqual(emptyLast.selectedIndex, 0)
        XCTAssertTrue(emptyLast.usesFirstMatch)
        XCTAssertEqual(emptyLast.failureReason, "query.collection_empty")
        XCTAssertEqual(currentLast.selectedIndex, 2)
        XCTAssertFalse(currentLast.usesFirstMatch)
        XCTAssertNil(currentLast.failureReason)
    }

    func testComponentOwnedStepPreservesOrdinaryAndNestedComponentHierarchy() throws {
        resetSharedStepContext()
        let component = StepComponent()

        step("Outer test step") {
            component.step("Read banner") {
                assertTrue(expression: true, label: "banner is ready")
                component.step("Read title") {
                    step("Decode value") {}
                }
            }
        }

        let outer = try XCTUnwrap(XCEasyTestContext.shared.testResult?.steps?.last)
        let componentStep = try XCTUnwrap(outer.steps?.first)
        let nestedComponentStep = try XCTUnwrap(componentStep.steps?.last)

        XCTAssertEqual(outer.name, "Outer test step")
        XCTAssertEqual(componentStep.name, "Promo banner: Read banner")
        XCTAssertEqual(componentStep.steps?.count, 2)
        XCTAssertEqual(nestedComponentStep.name, "Promo banner: Read title")
        XCTAssertEqual(nestedComponentStep.steps?.map(\.name), ["Decode value"])
        XCTAssertEqual(XCEasyTestContext.shared.activeStepDepth, 0)
        XCTAssertTrue(XCEasyTestContext.shared.stepStack.isEmpty)
    }

    func testComponentOwnedStepWritesStructuredInstanceAndElementEvidence() throws {
        resetSharedStepContext()
        let component = StepComponent()

        component.step("Read banner") {}

        let eventURL = try XCTUnwrap(XCEasyTestLogger.shared.currentEventFileURL())
        let events = try String(contentsOf: eventURL, encoding: .utf8)
            .split(separator: "\n")
            .map { try JSONDecoder().decode(DiagnosticEvent.self, from: Data($0.utf8)) }
        let started = try XCTUnwrap(events.last {
            $0.event == "step.started" && $0.operationCode == "component.step"
        })
        let finished = try XCTUnwrap(events.last {
            $0.event == "step.finished" && $0.operationCode == "component.step"
        })

        XCTAssertEqual(started.target, "Promo banner")
        XCTAssertEqual(started.title, "Promo banner: Read banner")
        XCTAssertEqual(started.selector?.segments.map(\.value), ["promoBanner"])
        XCTAssertEqual(finished.target, "Promo banner")
        XCTAssertEqual(finished.statusCode, "passed")
        XCTAssertEqual(finished.performance?.operationKey, "component.step")
    }

    func testThrownComponentOwnedStepRestoresParentBeforeNextRootStep() throws {
        resetSharedStepContext()
        let component = StepComponent()

        XCTExpectFailure("A thrown framework step intentionally records one XCTest failure") {
            do {
                try step("Outer test step") {
                    try component.step("Failing operation") {
                        throw ComponentTestError.expected
                    }
                }
            } catch {
                XCTAssertEqual(error as? ComponentTestError, .expected)
            }
        }
        step("Next root step") {}

        let steps = try XCTUnwrap(XCEasyTestContext.shared.testResult?.steps)
        XCTAssertEqual(steps.map(\.name), ["Outer test step", "Next root step"])
        XCTAssertEqual(steps.first?.steps?.map(\.name), ["Promo banner: Failing operation"])
        XCTAssertEqual(steps.first?.status, .failed)
        XCTAssertEqual(steps.first?.steps?.first?.status, .failed)
        XCTAssertEqual(XCEasyTestContext.shared.activeStepDepth, 0)
        XCTAssertTrue(XCEasyTestContext.shared.stepStack.isEmpty)
    }

    func testAsyncComponentOwnedStepPreservesHierarchyAcrossSuspension() async throws {
        resetSharedStepContext()
        let component = StepComponent()

        await step("Outer async step") {
            await component.step("Load banner") {
                await Task.yield()
                step("Read loaded state") {}
            }
        }

        let outer = try XCTUnwrap(XCEasyTestContext.shared.testResult?.steps?.last)
        let componentStep = try XCTUnwrap(outer.steps?.first)
        XCTAssertEqual(outer.name, "Outer async step")
        XCTAssertEqual(componentStep.name, "Promo banner: Load banner")
        XCTAssertEqual(componentStep.steps?.map(\.name), ["Read loaded state"])
        XCTAssertEqual(XCEasyTestContext.shared.activeStepDepth, 0)
        XCTAssertTrue(XCEasyTestContext.shared.stepStack.isEmpty)
    }

    private func resetSharedStepContext() {
        let context = XCEasyTestContext.shared
        context.stepStack = []
        context.activeStepDepth = 0
        var result = context.testResult ?? TestResult(uuid: "component-tests-result")
        result.steps = []
        context.testResult = result
        _ = context.consumeDeferredFailures()
    }

    private func collection(
        snapshot: XCEasyCollectionSnapshot
    ) -> XCEasyComponentCollection<IndexedComponent> {
        XCEasyComponentCollection(snapshotProvider: { _ in snapshot })
    }
}

private struct NestedComponent: XCEasyComponent {
    let element: XCEasyUIElement
    let componentName = "Nested component"

    var section: SectionComponent {
        SectionComponent(element: element.child(identifier: "section", timeout: 0))
    }

}

private struct SectionComponent: XCEasyComponent {
    let element: XCEasyUIElement

    var card: CardComponent {
        CardComponent(element: element.child(identifier: "card", timeout: 0))
    }
}

private struct CardComponent: XCEasyComponent {
    let element: XCEasyUIElement

    var leaf: XCEasyUIElement {
        element.child(identifier: "leaf", timeout: 0)
    }
}

private struct IndexedComponent: XCEasyIndexedComponent {
    static var collection: XCEasyUIElement {
        XCEasyUIElement(identifier: "item", timeout: 0)
    }

    let position: XCEasyComponentPosition
    let componentName: String

    init(position: XCEasyComponentPosition, componentName: String?) {
        self.position = position
        self.componentName = componentName ?? Self.defaultComponentName(for: position)
    }

    var element: XCEasyUIElement {
        Self.collection.element(at: position)
    }
}

private struct StepComponent: XCEasyComponent {
    let componentName = "Promo banner"
    let element = XCEasyUIElement(identifier: "promoBanner", timeout: 0)
}

private enum ComponentTestError: Error, Equatable {
    case expected
}

private final class ComponentTestContext: TestContextProviding {
    private var storedApp: XCUIApplication?
    private(set) var appReadCount = 0

    var app: XCUIApplication? {
        get {
            appReadCount += 1
            return storedApp
        }
        set { storedApp = newValue }
    }

    var testId: String?
    var displayName: String?
    var testResult: TestResult?
    var labels: [Label] = []
    var links: [AllureLinkRecord] = []
    var description: String?
    var testSuite: String?
    var stepStack: [StepResult] = []
    var screenshot: ScreenshotAttachment?

    func addLabel(_ label: Label) { labels.append(label) }
    func isLabelExists(_ name: String) -> Bool { labels.contains { $0.name == name } }
    func addLink(_ link: AllureLinkRecord) { links.append(link) }
    func clearTestStorages() {}
    func clearApp() { storedApp = nil }
    func setApp() { storedApp = XCUIApplication() }
    func pushStep(_ step: StepResult) { stepStack.append(step) }
    func popStep() -> StepResult? { stepStack.popLast() }
}
