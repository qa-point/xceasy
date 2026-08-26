import CryptoKit
import Foundation

internal struct AllureIdentity: Equatable {
    let testCaseId: String
    let historyId: String

    /// Derives stable Allure identities from the XCTest name and history parameters.
    ///
    /// - Parameters:
    ///   - fullName: Fully qualified XCTest name used as the stable test-case identity.
    ///   - parameters: Redacted Allure parameters; excluded values do not affect history.
    /// - Returns: Stable SHA-256 test-case and history identifiers.
    static func make(fullName: String, parameters: [Parameter]) -> AllureIdentity {
        let testCaseId = digest(fullName)
        let historyParameters = parameters
            .filter { $0.excluded != true }
            .map { "\($0.name ?? "")=\($0.value ?? "")" }
            .sorted()
            .joined(separator: "&")
        return AllureIdentity(
            testCaseId: testCaseId,
            historyId: digest("\(testCaseId)|\(historyParameters)")
        )
    }

    /// Produces the lowercase SHA-256 representation required by the Allure contract.
    ///
    /// - Parameter value: Canonical identity input.
    /// - Returns: A 64-character lowercase hexadecimal digest.
    private static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
