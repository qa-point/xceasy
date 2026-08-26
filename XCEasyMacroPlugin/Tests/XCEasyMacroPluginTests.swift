import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import XCEasyMacroPlugin

final class XCEasyMacroPluginTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "ParameterizedTest": ParameterizedTestMacro.self,
        "Epic": MetadataMacro.self
    ]

    /// Verifies that both public macro implementations are linked into the compiler plugin.
    func testPluginProvidesMetadataAndParameterizedMacros() {
        let plugin = XCEasyMacroPlugin()

        XCTAssertEqual(plugin.providingMacros.count, 2)
        XCTAssertTrue(plugin.providingMacros.contains { $0 == MetadataMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == ParameterizedTestMacro.self })
    }

    func testParameterizedTestRejectsEmptyInlineCases() {
        assertMacroExpansion(
            """
            @ParameterizedTest(cases: [])
            func scenario(_ data: LoginCase) {}
            """,
            expandedSource: """
            func scenario(_ data: LoginCase) {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ParameterizedTest requires a non-empty inline cases array",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testMetadataRejectsRuntimeExpressions() {
        assertMacroExpansion(
            """
            @Epic(dynamicName)
            func testCheckout() {}
            """,
            expandedSource: """
            func testCheckout() {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Epic values must be compile-time literals",
                    line: 1,
                    column: 7
                )
            ],
            macros: macros
        )
    }
}
