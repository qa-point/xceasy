import Foundation
import XCTest
@testable import XCEasy

final class XCEasyExecutionContextTests: XCTestCase {
    override func tearDown() {
        XCEasyConfig.endExecution()
        XCEasyTestContext.shared.clearApp()
        XCEasyTestContext.shared.clearTestStorages()
        super.tearDown()
    }

    func testStructuredChildTasksRetainIdentityConfigurationAndAtomicLabels() async {
        let context = XCEasyTestContext.shared
        context.beginExecution(testId: "stable-test", executionId: "attempt-1")
        XCEasyConfig.beginExecution()
        XCEasyConfig.findTimeout = 3

        let observations = await context.withCurrentExecution {
            await withTaskGroup(of: String.self, returning: [String].self) { group in
                for index in 0..<100 {
                    group.addTask {
                        await Task.yield()
                        context.addLabel(Label(name: "child", value: "\(index)"))
                        return "\(context.testId ?? "missing")|\(context.executionId ?? "missing")|\(XCEasyConfig.findTimeout)"
                    }
                }
                var values: [String] = []
                for await value in group { values.append(value) }
                return values
            }
        }

        XCTAssertEqual(Set(observations), ["stable-test|attempt-1|3.0"])
        XCTAssertEqual(context.labels.count, 100)
        XCTAssertEqual(Set(context.labels.map(\.value)).count, 100)
    }

    func testTerminalEventHasExactlyOneWinnerAcrossConcurrentTasks() async {
        let context = XCEasyTestContext.shared
        context.beginExecution(testId: "stable-test", executionId: "attempt-terminal")

        let claims = await context.withCurrentExecution {
            await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
                for _ in 0..<100 {
                    group.addTask { context.claimTerminalEvent() }
                }
                var values: [Bool] = []
                for await value in group { values.append(value) }
                return values
            }
        }

        XCTAssertEqual(claims.filter { $0 }.count, 1)
        XCTAssertEqual(claims.filter { !$0 }.count, 99)
    }

    func testLoggerEndSynchronouslyRejectsFurtherWrites() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xceasy-logger-end-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let loggerId = "logger-end"
        let logger = XCEasyTestLogger.shared
        logger.start(id: loggerId, logDir: directory)
        logger.log("before-end", loggerId: loggerId)
        let logURL = try XCTUnwrap(directory.contents.first { $0.pathExtension == "log" })

        logger.end(id: loggerId)
        let sizeAfterEnd = try Data(contentsOf: logURL).count
        logger.log("after-end", loggerId: loggerId)

        XCTAssertEqual(try Data(contentsOf: logURL).count, sizeAfterEnd)
        XCTAssertFalse(try String(contentsOf: logURL).contains("after-end"))
    }
}

private extension URL {
    var contents: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil
        )) ?? []
    }
}
