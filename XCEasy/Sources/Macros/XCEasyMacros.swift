@_exported import Foundation

/// Controls how one parameterized-case field is represented in Allure and diagnostics.
public struct XCEasyParameterRule<Case> {
    /// Field name captured by the macro from the supplied key path.
    public let fieldName: String

    /// Allure presentation mode for the field.
    public let mode: AllureParameterMode

    /// Whether the field is excluded from history identity.
    public let excluded: Bool

    private init<Value>(
        keyPath: KeyPath<Case, Value>,
        mode: AllureParameterMode,
        excluded: Bool
    ) {
        fieldName = String(describing: keyPath)
        self.mode = mode
        self.excluded = excluded
    }

    /// Reports a field as masked and removes its raw value before every report sink.
    ///
    /// - Parameters:
    ///   - keyPath: Dataset field to protect.
    ///   - excluded: Whether the field is omitted from Allure history identity.
    /// - Returns: A typed parameter rule consumed by `@ParameterizedTest`.
    public static func masked<Value>(
        _ keyPath: KeyPath<Case, Value>,
        excluded: Bool = false
    ) -> Self {
        Self(keyPath: keyPath, mode: .masked, excluded: excluded)
    }

    /// Reports only that a field exists and removes its raw value before every report sink.
    ///
    /// - Parameters:
    ///   - keyPath: Dataset field to hide.
    ///   - excluded: Whether the field is omitted from Allure history identity.
    /// - Returns: A typed parameter rule consumed by `@ParameterizedTest`.
    public static func hidden<Value>(
        _ keyPath: KeyPath<Case, Value>,
        excluded: Bool = false
    ) -> Self {
        Self(keyPath: keyPath, mode: .hidden, excluded: excluded)
    }

    /// Excludes a visible non-secret field from Allure history identity.
    ///
    /// - Parameter keyPath: Dataset field whose changes should not create a history variant.
    /// - Returns: A typed parameter rule consumed by `@ParameterizedTest`.
    public static func excluded<Value>(_ keyPath: KeyPath<Case, Value>) -> Self {
        Self(keyPath: keyPath, mode: .default, excluded: true)
    }
}

/// Generates one independently schedulable XCTest method for every inline dataset.
@attached(peer, names: arbitrary)
public macro ParameterizedTest<Case>(
    name: String = "[{index}] {id}",
    cases: [Case],
    parameterRules: [XCEasyParameterRule<Case>] = []
) = #externalMacro(module: "XCEasyMacroPlugin", type: "ParameterizedTestMacro")

/// Changes the readable Allure name of a test class or method.
@attached(peer, names: prefixed(__xceasyDisplayName_))
public macro DisplayName(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds a method description to Allure.
@attached(peer, names: prefixed(__xceasyDescription_))
public macro Description(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one epic label.
@attached(peer, names: prefixed(__xceasyEpic_))
public macro Epic(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several epic labels.
@attached(peer, names: prefixed(__xceasyEpics_))
public macro Epics(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one feature label.
@attached(peer, names: prefixed(__xceasyFeature_))
public macro Feature(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several feature labels.
@attached(peer, names: prefixed(__xceasyFeatures_))
public macro Features(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one story label.
@attached(peer, names: prefixed(__xceasyStory_))
public macro Story(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several story labels.
@attached(peer, names: prefixed(__xceasyStories_))
public macro Stories(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Assigns the test owner.
@attached(peer, names: prefixed(__xceasyOwner_))
public macro Owner(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Assigns the method lead.
@attached(peer, names: prefixed(__xceasyLead_))
public macro Lead(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Assigns Allure severity.
@attached(peer, names: prefixed(__xceasySeverity_))
public macro Severity(_ value: SeverityState) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one tag.
@attached(peer, names: prefixed(__xceasyTag_))
public macro Tag(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several tags.
@attached(peer, names: prefixed(__xceasyTags_))
public macro Tags(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Associates an Allure automated-test ID with a method.
@attached(peer, names: prefixed(__xceasyAllureId_))
public macro AllureId(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one issue link.
@attached(peer, names: prefixed(__xceasyIssue_))
public macro Issue(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several issue links.
@attached(peer, names: prefixed(__xceasyIssues_))
public macro Issues(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one test-management link.
@attached(peer, names: prefixed(__xceasyTmsLink_))
public macro TmsLink(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several test-management links.
@attached(peer, names: prefixed(__xceasyTmsLinks_))
public macro TmsLinks(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds one generic Allure link.
@attached(peer, names: prefixed(__xceasyLink_))
public macro Link(
    _ value: String = "",
    name: String = "",
    url: String = "",
    type: String = "custom"
) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds several generic link URLs.
@attached(peer, names: prefixed(__xceasyLinks_))
public macro Links(_ values: String...) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Marks a class or method as flaky in Allure status details.
@attached(peer, names: prefixed(__xceasyFlaky_))
public macro Flaky() = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Marks a class or method as muted in Allure status details.
@attached(peer, names: prefixed(__xceasyMuted_))
public macro Muted() = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")

/// Adds a project-defined marker used by report diagnostics and explicit test selection.
@attached(peer, names: prefixed(__xceasyMarker_))
public macro Marker(_ value: String) = #externalMacro(module: "XCEasyMacroPlugin", type: "MetadataMacro")
