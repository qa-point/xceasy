import Foundation

/// Bounded machine-readable evidence for one component-collection operation.
internal struct XCEasyCollectionEvidence: Codable, Equatable {
    /// One retained polling observation.
    internal struct Observation: Codable, Equatable {
        let attempt: Int
        let elapsedMilliseconds: Int64
        let count: Int
        let displayedCount: Int?
        let failedIndices: [Int]?
        let isContextAvailable: Bool
    }

    let expectation: String
    let expectedCount: Int?
    let actualCount: Int?
    let matched: Bool
    let attempts: Int
    let elapsedMilliseconds: Int64
    let selectedPosition: String?
    let selectedIndex: Int?
    let selectedIndices: [Int]?
    let displayedCount: Int?
    let failedIndices: [Int]?
    let isContextAvailable: Bool?
    let observations: [Observation]?
}
