import Foundation
import ObjectiveC.runtime
import XCTest

/// One redacted parameter embedded by `@ParameterizedTest` before XCTest starts the case.
internal struct XCEasyStaticParameterDescriptor: Codable, Equatable {
    let name: String
    let value: String
    let excluded: Bool
    let mode: String
}

/// Versioned compile-time metadata record returned by generated class methods.
internal struct XCEasyStaticMetadataDescriptor: Codable, Equatable {
    let schemaVersion: String
    let kind: String
    let scope: String
    let declaration: String
    let targetType: String?
    let concreteMethod: String?
    let canonicalScenario: String?
    let values: [String]
    let options: [String: String]
    let parameters: [XCEasyStaticParameterDescriptor]
}

/// Fully merged metadata for one concrete XCTest execution.
internal struct XCEasyResolvedMetadata {
    var canonicalScenario: String?
    var displayName: String?
    var resultDescription: String?
    var labels: [Label] = []
    var links: [AllureLinkRecord] = []
    var parameters: [Parameter] = []
    var flaky = false
    var muted = false
    var markers: [String] = []
}

/// Discovers generated metadata providers and converts them into one execution-scoped record.
internal enum XCEasyStaticMetadataResolver {
    private static let providerPrefix = "__xceasy_metadata"

    /// Resolves generated metadata for an XCTest instance before `setUp` begins.
    ///
    /// - Parameter testCase: Concrete XCTest execution whose class providers are inspected.
    /// - Returns: Merged static metadata and parameterization identity.
    static func resolve(testCase: XCTestCase) -> XCEasyResolvedMetadata {
        let method = concreteMethodName(testCase.name)
        return resolve(descriptors: descriptors(testCaseClass: type(of: testCase)), concreteMethod: method)
    }

    /// Merges decoded descriptors using class defaults followed by method values.
    ///
    /// - Parameters:
    ///   - descriptors: Generated records returned by macro providers.
    ///   - concreteMethod: Concrete XCTest method selected for this execution.
    /// - Returns: Deterministic metadata suitable for the observer and Allure adapter.
    static func resolve(
        descriptors: [XCEasyStaticMetadataDescriptor],
        concreteMethod: String
    ) -> XCEasyResolvedMetadata {
        let parameterized = descriptors.first {
            $0.kind == "ParameterizedTest" && $0.concreteMethod == concreteMethod
        }
        let canonicalScenario = parameterized?.canonicalScenario
        let applicable = descriptors.filter { descriptor in
            if descriptor.kind == "ParameterizedTest" {
                return descriptor.concreteMethod == concreteMethod
            }
            if descriptor.scope == "class" { return true }
            return descriptor.declaration == concreteMethod || descriptor.declaration == canonicalScenario
        }.sorted { lhs, rhs in
            if lhs.scope != rhs.scope { return lhs.scope == "class" }
            if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
            return lhs.values.joined(separator: "\u{1f}") < rhs.values.joined(separator: "\u{1f}")
        }

        var resolved = XCEasyResolvedMetadata(canonicalScenario: canonicalScenario)
        if let parameterized {
            resolved.parameters = parameterized.parameters.map {
                Parameter(name: $0.name, value: $0.value, excluded: $0.excluded, mode: $0.mode)
            }
            resolved.displayName = parameterized.values.dropFirst().first
        }

        for descriptor in applicable where descriptor.kind != "ParameterizedTest" {
            apply(descriptor, to: &resolved)
        }
        resolved.labels = deduplicated(resolved.labels)
        resolved.links = deduplicated(resolved.links)
        resolved.markers = Array(Set(resolved.markers)).sorted()
        return resolved
    }

    /// Reads every generated Objective-C class method whose selector uses the provider prefix.
    private static func descriptors(testCaseClass: XCTestCase.Type) -> [XCEasyStaticMetadataDescriptor] {
        var result = descriptors(providerClass: testCaseClass)
        let declarationName = NSStringFromClass(testCaseClass).split(separator: ".").last.map(String.init) ?? ""
        let expectedCount = objc_getClassList(nil, 0)
        guard expectedCount > 0 else { return result }
        let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedCount))
        defer { classes.deallocate() }
        let actualCount = objc_getClassList(AutoreleasingUnsafeMutablePointer(classes), expectedCount)
        for index in 0..<Int(actualCount) {
            guard let candidate = classes[index] else { continue }
            let runtimeName = NSStringFromClass(candidate)
            guard runtimeName.contains(".__xceasy") || runtimeName.hasPrefix("__xceasy") else { continue }
            result.append(contentsOf: descriptors(providerClass: candidate).filter {
                $0.scope == "class" && $0.declaration == declarationName
            })
        }
        return result
    }

    /// Decodes provider methods exposed by one Objective-C compatible class or metaclass.
    private static func descriptors(providerClass: AnyClass) -> [XCEasyStaticMetadataDescriptor] {
        guard let metaclass = object_getClass(providerClass) else { return [] }
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(metaclass, &count) else { return [] }
        defer { free(methods) }

        let decoder = JSONDecoder()
        var result: [XCEasyStaticMetadataDescriptor] = []
        for index in 0..<Int(count) {
            let method = methods[index]
            let selector = method_getName(method)
            guard NSStringFromSelector(selector).hasPrefix(providerPrefix) else { continue }
            typealias Provider = @convention(c) (AnyClass, Selector) -> Unmanaged<NSString>
            let implementation = method_getImplementation(method)
            let provider = unsafeBitCast(implementation, to: Provider.self)
            let payload = provider(providerClass, selector).takeUnretainedValue() as String
            guard let data = payload.data(using: .utf8),
                  let descriptor = try? decoder.decode(XCEasyStaticMetadataDescriptor.self, from: data),
                  descriptor.schemaVersion == "1.0.0" else {
                continue
            }
            result.append(descriptor)
        }
        return result
    }

    /// Extracts the Objective-C method portion from XCTest's bracketed case name.
    private static func concreteMethodName(_ testCaseName: String) -> String {
        testCaseName
            .split(separator: " ")
            .last
            .map(String.init)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "]")) ?? testCaseName
    }

    /// Applies one static descriptor to the merged execution metadata.
    private static func apply(
        _ descriptor: XCEasyStaticMetadataDescriptor,
        to resolved: inout XCEasyResolvedMetadata
    ) {
        let expandedValues = descriptor.values.map { expand($0, parameters: resolved.parameters) }
        switch descriptor.kind {
        case "DisplayName":
            if descriptor.scope == "class", let value = expandedValues.first {
                replaceScalarLabel(name: "suite", value: value, in: &resolved.labels)
            } else {
                resolved.displayName = expandedValues.first
            }
        case "Description": resolved.resultDescription = expandedValues.first
        case "Epic", "Epics": appendLabels(name: "epic", values: expandedValues, to: &resolved.labels)
        case "Feature", "Features": appendLabels(name: "feature", values: expandedValues, to: &resolved.labels)
        case "Story", "Stories": appendLabels(name: "story", values: expandedValues, to: &resolved.labels)
        case "Owner": replaceScalarLabel(name: "owner", value: expandedValues.first, in: &resolved.labels)
        case "Lead": replaceScalarLabel(name: "lead", value: expandedValues.first, in: &resolved.labels)
        case "Severity": replaceScalarLabel(name: "severity", value: expandedValues.first, in: &resolved.labels)
        case "Tag", "Tags": appendLabels(name: "tag", values: expandedValues, to: &resolved.labels)
        case "AllureId": replaceScalarLabel(name: "AS_ID", value: expandedValues.first, in: &resolved.labels)
        case "Issue", "Issues": appendPatternLinks(type: "issue", values: expandedValues, to: &resolved.links)
        case "TmsLink", "TmsLinks": appendPatternLinks(type: "tms", values: expandedValues, to: &resolved.links)
        case "Link":
            let value = expandedValues.first ?? ""
            let name = descriptor.options["name"].flatMap { $0.isEmpty ? nil : $0 } ?? value
            let url = descriptor.options["url"].flatMap { $0.isEmpty ? nil : $0 } ?? value
            resolved.links.append(AllureLinkRecord(name: name, url: url, type: descriptor.options["type"] ?? "custom"))
        case "Links":
            resolved.links.append(contentsOf: expandedValues.map { AllureLinkRecord(name: $0, url: $0, type: "custom") })
        case "Flaky": resolved.flaky = true
        case "Muted": resolved.muted = true
        case "Marker":
            resolved.markers.append(contentsOf: expandedValues)
            appendLabels(name: "xceasy.annotation", values: expandedValues, to: &resolved.labels)
        default: break
        }
    }

    /// Expands safe parameter placeholders in a readable metadata value.
    private static func expand(_ value: String, parameters: [Parameter]) -> String {
        parameters.reduce(value) { partial, parameter in
            guard let name = parameter.name, let value = parameter.value else { return partial }
            return partial.replacingOccurrences(of: "{\(name)}", with: value)
        }
    }

    /// Appends repeatable Allure labels while preserving source order.
    private static func appendLabels(name: String, values: [String], to labels: inout [Label]) {
        labels.append(contentsOf: values.map { Label(name: name, value: $0) })
    }

    /// Replaces a scalar label with the most specific available value.
    private static func replaceScalarLabel(name: String, value: String?, in labels: inout [Label]) {
        guard let value else { return }
        labels.removeAll { $0.name == name }
        labels.append(Label(name: name, value: value))
    }

    /// Resolves and appends links that use a configured standard Allure type.
    private static func appendPatternLinks(
        type: String,
        values: [String],
        to links: inout [AllureLinkRecord]
    ) {
        links.append(contentsOf: values.map {
            AllureLinkRecord(name: $0, url: XCEasyAllureConfig.resolveLink(type: type, value: $0), type: type)
        })
    }

    /// Removes duplicate labels without reordering the first occurrence.
    private static func deduplicated(_ labels: [Label]) -> [Label] {
        var seen = Set<String>()
        return labels.filter { seen.insert("\($0.name ?? "")\u{1f}\($0.value ?? "")").inserted }
    }

    /// Removes duplicate links without reordering the first occurrence.
    private static func deduplicated(_ links: [AllureLinkRecord]) -> [AllureLinkRecord] {
        var seen = Set<String>()
        return links.filter {
            seen.insert("\($0.name ?? "")\u{1f}\($0.url ?? "")\u{1f}\($0.type ?? "")").inserted
        }
    }
}
