import XCTest
@testable import XCEasy

final class AllureIdentityTests: XCTestCase {
    func testTestCaseIdIsStableAcrossExecutions() {
        let first = AllureIdentity.make(fullName: "Module/LoginTests/testLogin()", parameters: [])
        let second = AllureIdentity.make(fullName: "Module/LoginTests/testLogin()", parameters: [])

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.testCaseId.count, 64)
    }

    func testHistoryIdUsesSortedNonExcludedParameters() {
        let first = AllureIdentity.make(fullName: "Module/Test/test()", parameters: [
            Parameter(name: "device", value: "phone"),
            Parameter(name: "shard", value: "1", excluded: true),
            Parameter(name: "locale", value: "ru")
        ])
        let reordered = AllureIdentity.make(fullName: "Module/Test/test()", parameters: [
            Parameter(name: "locale", value: "ru"),
            Parameter(name: "device", value: "phone"),
            Parameter(name: "shard", value: "9", excluded: true)
        ])

        XCTAssertEqual(first.historyId, reordered.historyId)
        XCTAssertEqual(first.testCaseId, reordered.testCaseId)
    }

    func testHistoryIdChangesForIncludedParameter() {
        let phone = AllureIdentity.make(
            fullName: "Module/Test/test()",
            parameters: [Parameter(name: "device", value: "phone")]
        )
        let tablet = AllureIdentity.make(
            fullName: "Module/Test/test()",
            parameters: [Parameter(name: "device", value: "tablet")]
        )

        XCTAssertNotEqual(phone.historyId, tablet.historyId)
    }

    func testMaskedParameterDoesNotPersistRawValue() {
        let parameter = Parameter(
            name: "password",
            value: "password=canary",
            mode: AllureParameterMode.masked.rawValue
        )

        XCTAssertFalse(parameter.value?.contains("canary") == true)
    }

    func testIdentityWithoutParametersIsStableAndLowercaseHex() {
        let identity = AllureIdentity.make(fullName: "Module/Test/test()", parameters: [])
        let hex = CharacterSet(charactersIn: "0123456789abcdef")

        XCTAssertEqual(identity.testCaseId.count, 64)
        XCTAssertEqual(identity.historyId.count, 64)
        XCTAssertNil(identity.testCaseId.unicodeScalars.first { !hex.contains($0) })
        XCTAssertNil(identity.historyId.unicodeScalars.first { !hex.contains($0) })
    }
}
