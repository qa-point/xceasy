import XCTest
@testable import XCEasy

final class XCEasyStaticMetadataTests: XCTestCase {
    override func setUp() {
        super.setUp()
        XCEasyAllureConfig.apply(linkPatterns: [
            "issue": "https://issues.example.test/{}",
            "tms": "https://tms.example.test/%s"
        ])
    }

    func testResolverMergesClassMethodCaseAndMarkers() throws {
        let descriptors = [
            descriptor(kind: "Epic", scope: "class", declaration: "LoginTests", values: ["Authentication"]),
            descriptor(kind: "Marker", scope: "class", declaration: "LoginTests", values: ["Team1"]),
            descriptor(kind: "DisplayName", scope: "method", declaration: "invalidLogin", values: ["Invalid: {id}"]),
            descriptor(kind: "Marker", scope: "method", declaration: "invalidLogin", values: ["Debug"]),
            descriptor(kind: "Issue", scope: "method", declaration: "invalidLogin", values: ["TEST-ISSUE-001"]),
            descriptor(
                kind: "ParameterizedTest",
                scope: "method",
                declaration: "invalidLogin",
                concreteMethod: "testInvalidLogin__p001_wrong_password",
                canonicalScenario: "invalidLogin",
                values: ["wrong-password", "[1] wrong-password"],
                parameters: [
                    XCEasyStaticParameterDescriptor(name: "id", value: "wrong-password", excluded: false, mode: "default"),
                    XCEasyStaticParameterDescriptor(name: "password", value: "<redacted:parameter>", excluded: true, mode: "masked")
                ]
            )
        ]

        let result = XCEasyStaticMetadataResolver.resolve(
            descriptors: descriptors,
            concreteMethod: "testInvalidLogin__p001_wrong_password"
        )

        XCTAssertEqual(result.canonicalScenario, "invalidLogin")
        XCTAssertEqual(result.displayName, "Invalid: wrong-password")
        XCTAssertEqual(result.markers, ["Debug", "Team1"])
        XCTAssertTrue(result.labels.contains { $0.name == "epic" && $0.value == "Authentication" })
        XCTAssertTrue(result.labels.contains { $0.name == "xceasy.annotation" && $0.value == "Team1" })
        XCTAssertEqual(result.links.first?.url, "https://issues.example.test/TEST-ISSUE-001")
        XCTAssertEqual(result.parameters.last?.value, "<redacted:parameter>")
    }

    private func descriptor(
        kind: String,
        scope: String,
        declaration: String,
        concreteMethod: String? = nil,
        canonicalScenario: String? = nil,
        values: [String],
        parameters: [XCEasyStaticParameterDescriptor] = []
    ) -> XCEasyStaticMetadataDescriptor {
        XCEasyStaticMetadataDescriptor(
            schemaVersion: "1.0.0",
            kind: kind,
            scope: scope,
            declaration: declaration,
            targetType: "LoginTests",
            concreteMethod: concreteMethod,
            canonicalScenario: canonicalScenario,
            values: values,
            options: [:],
            parameters: parameters
        )
    }
}
