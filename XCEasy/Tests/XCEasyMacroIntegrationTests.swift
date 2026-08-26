import XCTest
@testable import XCEasy

private struct MacroLoginCase {
    let id: String
    let login: String
    let password: String
    let expectedMessage: String
}

@attached(peer, names: prefixed(__xceasyTeam1_))
private macro Team1() = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

@Epic("Authentication")
@Owner("Owner1")
@Team1
final class XCEasyMacroIntegrationTests: XCTestCase {
    @DisplayName("Invalid login: {id}")
    @Feature("Login")
    @Severity(.critical)
    @Marker("Debug")
    @ParameterizedTest(
        name: "[{index}] {id}: login={login}",
        cases: [
            MacroLoginCase(
                id: "wrong-password",
                login: "admin",
                password: "wrong-password",
                expectedMessage: "Invalid credentials"
            ),
            MacroLoginCase(
                id: "empty-login",
                login: "",
                password: "password123",
                expectedMessage: "Login is required"
            )
        ],
        parameterRules: [.masked(\.password, excluded: true)]
    )
    private func invalidLogin(_ data: MacroLoginCase) {
        XCTAssertFalse(data.id.isEmpty)
        XCTAssertFalse(data.expectedMessage.isEmpty)
    }
}

@Epic("Pre-setup metadata")
@Owner("Owner1")
final class XCEasyMacroPreSetupTests: XCTestCase {
    override func setUp() {
        super.setUp()
        XCTAssertTrue(XCEasyTestContext.shared.labels.contains {
            $0.name == "epic" && $0.value == "Pre-setup metadata"
        })
        XCTAssertTrue(XCEasyTestContext.shared.labels.contains {
            $0.name == "owner" && $0.value == "Owner1"
        })
    }

    func testMetadataWasAvailableDuringSetup() {
        XCTAssertNotNil(XCEasyTestContext.shared.testResult)
    }
}
