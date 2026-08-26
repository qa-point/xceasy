import Foundation
import UIKit
import XCTest
@testable import XCEasy

final class CoreUtilitiesTests: XCTestCase {
    func testScreenshotCaptureRequiresRunningApplicationAndExistingWindow() {
        XCTAssertTrue(ScreenshotUtils.canCaptureScreenshot(
            isApplicationRunning: true,
            windowExists: true
        ))
        XCTAssertFalse(ScreenshotUtils.canCaptureScreenshot(
            isApplicationRunning: false,
            windowExists: true
        ))
        XCTAssertFalse(ScreenshotUtils.canCaptureScreenshot(
            isApplicationRunning: true,
            windowExists: false
        ))
        XCTAssertFalse(ScreenshotUtils.canCaptureScreenshot(
            isApplicationRunning: false,
            windowExists: false
        ))
    }

    func testScreenshotFilenameSuffixPreservesExtensionAndCreatesDistinctAllureSource() {
        XCTAssertEqual(
            ScreenshotUtils.filename("failure.png", appendingSuffix: "-test"),
            "failure-test.png"
        )
        XCTAssertEqual(
            ScreenshotUtils.filename("failure", appendingSuffix: "-test"),
            "failure-test"
        )
        XCTAssertEqual(
            ScreenshotUtils.filename("failure.png", appendingSuffix: ""),
            "failure.png"
        )
    }

    func testFailureStatusDetailsPreserveStaticMetadataFlags() {
        let existing = StatusDetails(
            known: true,
            muted: true,
            flaky: true,
            message: nil,
            trace: nil
        )

        let details = XCEasyTestObserver.failureStatusDetails(
            preserving: existing,
            message: "Assertion failed",
            trace: "Failure trace"
        )

        XCTAssertEqual(details.known, true)
        XCTAssertEqual(details.muted, true)
        XCTAssertEqual(details.flaky, true)
        XCTAssertEqual(details.message, "Assertion failed")
        XCTAssertEqual(details.trace, "Failure trace")
    }

    override func setUp() {
        super.setUp()
        LaunchArgumentsManager.removeAll()
        LaunchEnvironmentManager.removeAll()
    }

    override func tearDown() {
        LaunchArgumentsManager.removeAll()
        LaunchEnvironmentManager.removeAll()
        XCDependencyContainer.shared.resetAll(resetLocalization: true)
        super.tearDown()
    }

    func testLaunchArgumentsSupportAddRemoveAndReset() {
        LaunchArgumentsManager.add("-first")
        LaunchArgumentsManager.add("-second")
        LaunchArgumentsManager.remove("-missing")
        LaunchArgumentsManager.remove("-first")

        XCTAssertEqual(LaunchArgumentsManager.values, ["-second"])

        LaunchArgumentsManager.removeAll()
        XCTAssertTrue(LaunchArgumentsManager.values.isEmpty)
    }

    func testLaunchEnvironmentSupportsEveryMutation() {
        LaunchEnvironmentManager.set("1", for: "FIRST")
        LaunchEnvironmentManager.set("2", for: "FIRST")
        LaunchEnvironmentManager.set(["SECOND": "2", "THIRD": "3"])

        XCTAssertEqual(LaunchEnvironmentManager.value(for: "FIRST"), "2")
        XCTAssertNil(LaunchEnvironmentManager.value(for: "MISSING"))
        XCTAssertEqual(
            LaunchEnvironmentManager.values,
            ["FIRST": "2", "SECOND": "2", "THIRD": "3"]
        )

        LaunchEnvironmentManager.remove("SECOND")
        XCTAssertNil(LaunchEnvironmentManager.value(for: "SECOND"))
        LaunchEnvironmentManager.removeAll()
        XCTAssertTrue(LaunchEnvironmentManager.values.isEmpty)
    }

    func testLaunchEnvironmentSerializesConcurrentWriters() {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "xceasy.launch-environment.tests", attributes: .concurrent)

        for index in 0..<50 {
            group.enter()
            queue.async {
                LaunchEnvironmentManager.set("\(index)", for: "KEY_\(index)")
                group.leave()
            }
        }
        group.wait()

        XCTAssertEqual(LaunchEnvironmentManager.values.count, 50)
    }

    func testLaunchConfigurationChangesRemainInsideCurrentExecution() {
        LaunchArgumentsManager.add("-default")
        LaunchEnvironmentManager.set("default", for: "SCOPE")

        LaunchArgumentsManager.beginExecution()
        LaunchEnvironmentManager.beginExecution()
        LaunchArgumentsManager.add("-execution")
        LaunchEnvironmentManager.set("execution", for: "SCOPE")

        XCTAssertEqual(LaunchArgumentsManager.values, ["-default", "-execution"])
        XCTAssertEqual(LaunchEnvironmentManager.value(for: "SCOPE"), "execution")

        LaunchEnvironmentManager.endExecution()
        LaunchArgumentsManager.endExecution()

        XCTAssertEqual(LaunchArgumentsManager.values, ["-default"])
        XCTAssertEqual(LaunchEnvironmentManager.value(for: "SCOPE"), "default")
    }

    func testLaunchArgumentsSerializeConcurrentWriters() {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "xceasy.launch-arguments.tests", attributes: .concurrent)

        for index in 0..<50 {
            group.enter()
            queue.async {
                LaunchArgumentsManager.add("-argument-\(index)")
                group.leave()
            }
        }
        group.wait()

        XCTAssertEqual(LaunchArgumentsManager.values.count, 50)
        XCTAssertEqual(Set(LaunchArgumentsManager.values).count, 50)
    }

    func testStringConstantsAndOptionalCollectionState() {
        XCTAssertEqual(
            [String.space, .nonBreakSpace, .plus, .hyphen, .minus, .dash, .slash, .colon,
             .newLine, .tab, .empty, .comma],
            [" ", " ", "+", "-", "−", "–", "/", ":", "\n", "\t", "", ","]
        )

        let missing: [Int]? = nil
        let empty: [Int]? = []
        let populated: [Int]? = [1]
        XCTAssertTrue(missing.isNilOrEmpty)
        XCTAssertTrue(empty.isNilOrEmpty)
        XCTAssertFalse(populated.isNilOrEmpty)
    }

    func testEveryDeviceOrientationMapsToUIKitValue() {
        let cases: [(DeviceOrientation, UIDeviceOrientation)] = [
            (.unknown, .unknown),
            (.portrait, .portrait),
            (.portraitUpsideDown, .portraitUpsideDown),
            (.landscapeLeft, .landscapeLeft),
            (.landscapeRight, .landscapeRight),
            (.faceUp, .faceUp),
            (.faceDown, .faceDown)
        ]

        for (orientation, expected) in cases {
            XCTAssertEqual(orientation.properties.key, expected)
            XCTAssertFalse(orientation.properties.name.isEmpty)
        }
    }

    func testEveryScreenPositionUsesNormalizedCoordinates() {
        let positions = [
            ScreenPosition.leftCenter, .rightCenter, .topCenter, .bottomCenter, .center,
            .leftTop, .leftBottom, .rightTop, .rightBottom
        ]

        XCTAssertEqual(positions.count, 9)
        for position in positions {
            XCTAssertTrue(0...1 ~= position.offset.dx)
            XCTAssertTrue(0...1 ~= position.offset.dy)
            XCTAssertFalse(position.description.isEmpty)
        }
    }

    func testLogFormatterAndEveryLevelProduceExpectedMetadata() {
        XCTAssertEqual(LogFormatter.getFrameworkName(), "XCEasy")
        XCTAssertFalse(LogFormatter.formatTimestamp(Date(timeIntervalSince1970: 0)).isEmpty)
        XCTAssertTrue(LogFormatter.formatMessage("message").contains("message"))

        let levels: [(LogLevel, String)] = [
            (.info, "INFO"), (.warning, "WARNING"), (.error, "ERROR"),
            (.debug, "DEBUG"), (.def, "DEFAULT")
        ]
        for (level, label) in levels {
            XCTAssertEqual(level.properties.label, label)
            XCTAssertTrue(LogFormatter.formatColorMessage("message", level: level).contains("message"))
        }
    }

    func testScreenshotAndApiModelsExposeStoredValues() throws {
        let image = ScreenshotAttachment(
            name: "screen",
            filename: "screen.jpg",
            data: Data([1, 2, 3]),
            type: .jpg
        )
        XCTAssertEqual(image.name, "screen")
        XCTAssertEqual(image.filename, "screen.jpg")
        XCTAssertEqual(image.data, Data([1, 2, 3]))
        XCTAssertEqual(image.type.rawValue, "image/jpeg")
        XCTAssertEqual(ScreenshotAttachment.AttachmentType.png.rawValue, "image/png")

        let url = try XCTUnwrap(URL(string: "https://example.test"))
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: 201,
            httpVersion: nil,
            headerFields: ["X-Test": "value"]
        ))
        let apiResponse = ApiResponse(data: Data("ok".utf8), response: response)
        XCTAssertEqual(apiResponse.statusCode, 201)
        XCTAssertEqual(apiResponse.data, Data("ok".utf8))
        XCTAssertEqual(apiResponse.headers["X-Test"] as? String, "value")
    }

    func testEveryApiErrorHasSafeDescription() {
        let error = NSError(domain: "tests", code: 7, userInfo: [NSLocalizedDescriptionKey: "offline"])
        let descriptions = [
            ApiError.invalidURL.description,
            ApiError.timeout.description,
            ApiError.noData.description,
            ApiError.invalidResponse.description,
            ApiError.network(error).description,
            ApiError.http(statusCode: 503).description,
            ApiError.unknown(error).description
        ]

        XCTAssertEqual(descriptions.count, 7)
        XCTAssertTrue(descriptions.allSatisfy { !$0.isEmpty })
        XCTAssertTrue(descriptions[4].contains("offline"))
        XCTAssertTrue(descriptions[5].contains("503"))
    }

    func testDefaultExpectationFactoryHandlesEmptyCompletedAndTimedOutWaits() {
        let factory = DefaultExpectationFactory()
        XCTAssertTrue(factory.waitForExpectations(timeout: 0))

        let completed = factory.makeExpectation(description: "completed")
        completed.fulfill()
        XCTAssertTrue(factory.waitForExpectations(timeout: 0.1))

        _ = factory.makeExpectation(description: "timeout")
        XCTAssertFalse(factory.waitForExpectations(timeout: 0))
        XCTAssertTrue(factory.waitForExpectations(timeout: 0))
    }

    func testDependencyContainerCanOverrideAndResetDependencies() {
        let context = UtilityTestContext()
        let localization = UtilityLocalizationManager()
        XCDependencyContainer.shared.testContext = context
        XCDependencyContainer.shared.localizationManager = localization

        XCTAssertTrue(
            XCDependencyContainer.shared.testContext as AnyObject === context
        )
        XCTAssertTrue(
            XCDependencyContainer.shared.localizationManager as AnyObject === localization
        )

        XCDependencyContainer.shared.reset()
        XCTAssertFalse(
            XCDependencyContainer.shared.testContext as AnyObject === context
        )
        XCDependencyContainer.shared.resetAll(resetLocalization: true)
        XCTAssertTrue(
            XCDependencyContainer.shared.localizationManager as AnyObject === LocalizationManager.shared
        )
    }
}

private final class UtilityLocalizationManager: LocalizationManaging {
    func setLocalization(for language: String) {}
    func string(forKey key: String) -> String { key }
    func string(forKey key: String, arguments: [CVarArg]) -> String { key }
}

private final class UtilityTestContext: TestContextProviding {
    var app: XCUIApplication?
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
    func clearApp() { app = nil }
    func setApp() { app = XCUIApplication() }
    func pushStep(_ step: StepResult) { stepStack.append(step) }
    func popStep() -> StepResult? { stepStack.popLast() }
}
