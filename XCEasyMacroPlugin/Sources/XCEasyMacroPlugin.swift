import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct XCEasyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MetadataMacro.self,
        ParameterizedTestMacro.self
    ]
}

struct XCEasyMacroDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(_ code: String, _ message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        diagnosticID = MessageID(domain: "XCEasyMacros", id: code)
        self.severity = severity
    }
}

private enum MacroSupport {
    static func macroName(_ node: AttributeSyntax) -> String {
        node.attributeName.trimmedDescription.split(separator: ".").last.map(String.init) ?? "Unknown"
    }

    static func arguments(_ node: AttributeSyntax) -> LabeledExprListSyntax {
        guard case let .argumentList(arguments) = node.arguments else { return [] }
        return arguments
    }

    static func stringLiteral(_ expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self),
              literal.segments.count == 1,
              case let .stringSegment(segment)? = literal.segments.first else {
            return nil
        }
        return segment.content.text
    }

    static func literalDescription(_ expression: ExprSyntax) -> String? {
        if let value = stringLiteral(expression) { return value }
        if expression.is(IntegerLiteralExprSyntax.self) ||
            expression.is(FloatLiteralExprSyntax.self) ||
            expression.is(BooleanLiteralExprSyntax.self) {
            return expression.trimmedDescription
        }
        return nil
    }

    static func escapeJSONString(_ value: String) -> String {
        var result = ""
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22: result += "\\\""
            case 0x5C: result += "\\\\"
            case 0x08: result += "\\b"
            case 0x0C: result += "\\f"
            case 0x0A: result += "\\n"
            case 0x0D: result += "\\r"
            case 0x09: result += "\\t"
            case 0x00...0x1F: result += String(format: "\\u%04X", scalar.value)
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    static func jsonString(_ value: String) -> String {
        "\"\(escapeJSONString(value))\""
    }

    static func declarationName(_ declaration: some DeclSyntaxProtocol) -> String? {
        if let function = declaration.as(FunctionDeclSyntax.self) {
            return function.name.text
        }
        if let nominal = declaration.as(ClassDeclSyntax.self) {
            return nominal.name.text
        }
        if let nominal = declaration.as(StructDeclSyntax.self) {
            return nominal.name.text
        }
        return nil
    }

    static func descriptorJSON(
        macroName: String,
        scope: String,
        declarationName: String,
        targetType: String? = nil,
        values: [String],
        options: [String: String] = [:],
        concreteMethod: String? = nil,
        canonicalScenario: String? = nil,
        parametersJSON: String = "[]"
    ) -> String {
        let valuesJSON = values.map(jsonString).joined(separator: ",")
        let optionsJSON = options.keys.sorted().map {
            "\(jsonString($0)):\(jsonString(options[$0] ?? ""))"
        }.joined(separator: ",")
        let methodJSON = concreteMethod.map(jsonString) ?? "null"
        let scenarioJSON = canonicalScenario.map(jsonString) ?? "null"
        let targetTypeJSON = targetType.map(jsonString) ?? "null"
        return "{" + [
            "\"schemaVersion\":\"1.0.0\"",
            "\"kind\":\(jsonString(macroName))",
            "\"scope\":\(jsonString(scope))",
            "\"declaration\":\(jsonString(declarationName))",
            "\"targetType\":\(targetTypeJSON)",
            "\"concreteMethod\":\(methodJSON)",
            "\"canonicalScenario\":\(scenarioJSON)",
            "\"values\":[\(valuesJSON)]",
            "\"options\":{\(optionsJSON)}",
            "\"parameters\":\(parametersJSON)"
        ].joined(separator: ",") + "}"
    }

    static func enclosingTypeName(context: some MacroExpansionContext) -> String? {
        for syntax in context.lexicalContext.reversed() {
            if let declaration = syntax.as(ClassDeclSyntax.self) { return declaration.name.text }
            if let declaration = syntax.as(StructDeclSyntax.self) { return declaration.name.text }
        }
        return nil
    }

    static func providerDeclaration(
        json: String,
        explicitName: String? = nil,
        context: some MacroExpansionContext
    ) -> DeclSyntax {
        let uniqueName = explicitName ?? context.makeUniqueName("__xceasy_metadata").text
        let safeName = uniqueName.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let objectiveCName = "__xceasy_metadata_\(safeName)"
        let escaped = json.replacingOccurrences(of: "#", with: "\\u0023")
        return DeclSyntax(stringLiteral:
            "@objc(\(objectiveCName)) static func \(uniqueName)() -> Foundation.NSString { #\"\(escaped)\"# as Foundation.NSString }"
        )
    }

    static func metadataPeerName(macroName: String, declarationName: String) -> String {
        "__xceasy\(macroName)_\(declarationName)"
    }

    static func requireNonEmpty(
        _ values: [String],
        node: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> Bool {
        guard !values.isEmpty, values.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: XCEasyMacroDiagnostic("empty_value", "XCEasy annotation values must not be empty")
            ))
            return false
        }
        return true
    }

    static func isSensitiveField(_ name: String) -> Bool {
        let normalized = name.lowercased().replacingOccurrences(of: "_", with: "")
        return ["password", "passwd", "token", "secret", "apikey", "authorization"].contains {
            normalized.contains($0)
        }
    }

    static func containsSecretAssignment(_ value: String) -> Bool {
        let normalized = value.lowercased()
        return ["password=", "passwd=", "token=", "secret=", "apikey=", "authorization="].contains {
            normalized.contains($0)
        }
    }
}

public struct MetadataMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if let function = declaration.as(FunctionDeclSyntax.self) {
            return provider(node: node, declarationName: function.name.text, scope: "method", context: context)
        }
        if let nominalName = MacroSupport.declarationName(declaration) {
            return companionProvider(node: node, declarationName: nominalName, context: context)
        }
        return []
    }

    private static func provider(
        node: AttributeSyntax,
        declarationName: String,
        scope: String,
        context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let name = MacroSupport.macroName(node)
        let arguments = MacroSupport.arguments(node)
        var values: [String] = []
        var options: [String: String] = [:]
        let standardNames: Set<String> = [
            "DisplayName", "Description", "Epic", "Epics", "Feature", "Features",
            "Story", "Stories", "Owner", "Lead", "Severity", "Tag", "Tags",
            "AllureId", "Issue", "Issues", "TmsLink", "TmsLinks", "Link", "Links",
            "Flaky", "Muted", "Marker"
        ]

        for argument in arguments {
            if let label = argument.label?.text, name == "Link" {
                guard let value = MacroSupport.stringLiteral(argument.expression) else {
                    context.diagnose(Diagnostic(
                        node: Syntax(argument.expression),
                        message: XCEasyMacroDiagnostic("literal_required", "@Link arguments must be string literals")
                    ))
                    return []
                }
                options[label] = value
            } else {
                let value: String?
                if name == "Severity" {
                    value = argument.expression.trimmedDescription.split(separator: ".").last.map { $0.uppercased() }
                } else {
                    value = MacroSupport.stringLiteral(argument.expression)
                }
                guard let value else {
                    context.diagnose(Diagnostic(
                        node: Syntax(argument.expression),
                        message: XCEasyMacroDiagnostic("literal_required", "@\(name) values must be compile-time literals")
                    ))
                    return []
                }
                values.append(value)
            }
        }

        if name == "Link", let first = arguments.first,
           first.label == nil,
           let value = MacroSupport.stringLiteral(first.expression) {
            values = [value]
        }
        let isAlias = !standardNames.contains(name) && arguments.isEmpty
        if isAlias { values = [name] }
        if (values + options.values).contains(where: MacroSupport.containsSecretAssignment) {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: XCEasyMacroDiagnostic("secret_literal_rejected", "XCEasy annotation metadata must not contain secret assignments")
            ))
            return []
        }
        if name != "Flaky" && name != "Muted" && !MacroSupport.requireNonEmpty(values + options.values, node: node, context: context) {
            return []
        }
        let json = MacroSupport.descriptorJSON(
            macroName: isAlias ? "Marker" : name,
            scope: scope,
            declarationName: declarationName,
            targetType: scope == "class" ? declarationName : MacroSupport.enclosingTypeName(context: context),
            values: values,
            options: options
        )
        let explicitName = scope == "method"
            ? MacroSupport.metadataPeerName(macroName: name, declarationName: declarationName)
            : nil
        return [MacroSupport.providerDeclaration(json: json, explicitName: explicitName, context: context)]
    }

    private static func companionProvider(
        node: AttributeSyntax,
        declarationName: String,
        context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let providers = provider(
            node: node,
            declarationName: declarationName,
            scope: "class",
            context: context
        )
        guard let provider = providers.first else { return [] }
        let kind = MacroSupport.macroName(node)
        let companion = MacroSupport.metadataPeerName(macroName: kind, declarationName: declarationName)
        return [DeclSyntax(stringLiteral:
            "@objc final class \(companion): Foundation.NSObject { \(provider.trimmedDescription) }"
        )]
    }
}

public struct ParameterizedTestMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: XCEasyMacroDiagnostic("function_required", "@ParameterizedTest can only be attached to a function")
            ))
            return []
        }
        guard function.signature.parameterClause.parameters.count == 1 else {
            context.diagnose(Diagnostic(
                node: Syntax(function.signature.parameterClause),
                message: XCEasyMacroDiagnostic("one_parameter_required", "@ParameterizedTest scenario must accept exactly one dataset parameter")
            ))
            return []
        }

        let arguments = MacroSupport.arguments(node)
        let nameTemplate = arguments.first(where: { $0.label?.text == "name" })
            .flatMap { MacroSupport.stringLiteral($0.expression) } ?? "[{index}] {id}"
        guard let casesExpression = arguments.first(where: { $0.label?.text == "cases" })?.expression,
              let cases = casesExpression.as(ArrayExprSyntax.self),
              !cases.elements.isEmpty else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: XCEasyMacroDiagnostic("inline_cases_required", "@ParameterizedTest requires a non-empty inline cases array")
            ))
            return []
        }

        let rules = parseRules(arguments.first(where: { $0.label?.text == "parameterRules" })?.expression)
        let scenario = function.name.text
        let testBase = scenario.hasPrefix("test") ? scenario : "test" + scenario.prefix(1).uppercased() + scenario.dropFirst()
        var identifiers = Set<String>()
        var declarations: [DeclSyntax] = []

        for (offset, element) in cases.elements.enumerated() {
            guard let call = element.expression.as(FunctionCallExprSyntax.self) else {
                context.diagnose(Diagnostic(
                    node: Syntax(element.expression),
                    message: XCEasyMacroDiagnostic("initializer_required", "Each parameterized case must be an inline initializer call")
                ))
                continue
            }
            var fields: [(String, String)] = []
            for argument in call.arguments {
                guard let label = argument.label?.text,
                      let value = MacroSupport.literalDescription(argument.expression) else {
                    context.diagnose(Diagnostic(
                        node: Syntax(argument),
                        message: XCEasyMacroDiagnostic("labeled_literal_required", "Case fields must use labeled literal arguments")
                    ))
                    fields = []
                    break
                }
                fields.append((label, value))
            }
            guard !fields.isEmpty,
                  let caseID = fields.first(where: { $0.0 == "id" })?.1,
                  !caseID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                context.diagnose(Diagnostic(
                    node: Syntax(element.expression),
                    message: XCEasyMacroDiagnostic("case_id_required", "Each parameterized case requires a non-empty literal id")
                ))
                continue
            }
            guard identifiers.insert(caseID).inserted else {
                context.diagnose(Diagnostic(
                    node: Syntax(element.expression),
                    message: XCEasyMacroDiagnostic("duplicate_case_id", "Parameterized case id '\(caseID)' is duplicated")
                ))
                continue
            }
            guard !MacroSupport.containsSecretAssignment(caseID) else {
                context.diagnose(Diagnostic(
                    node: Syntax(element.expression),
                    message: XCEasyMacroDiagnostic("unsafe_case_id", "Parameterized case id must not contain secret-like data")
                ))
                continue
            }

            let suffix = sanitizeIdentifier(caseID)
            let concreteMethod = "\(testBase)__p\(String(format: "%03d", offset + 1))_\(suffix)"
            let protectedFields = Set(rules.keys).union(fields.map(\.0).filter(MacroSupport.isSensitiveField))
            let displayName = render(template: nameTemplate, index: offset + 1, fields: fields, protectedFields: protectedFields)
            let parametersJSON = fields.map { field, value in
                let rule = rules[field] ?? (MacroSupport.isSensitiveField(field) ? Rule(mode: "masked", excluded: true) : nil)
                let storedValue = rule?.mode == "masked" || rule?.mode == "hidden"
                    ? "<redacted:parameter>"
                    : value
                return "{" + [
                    "\"name\":\(MacroSupport.jsonString(field))",
                    "\"value\":\(MacroSupport.jsonString(storedValue))",
                    "\"excluded\":\((rule?.excluded ?? false) ? "true" : "false")",
                    "\"mode\":\(MacroSupport.jsonString(rule?.mode ?? "default"))"
                ].joined(separator: ",") + "}"
            }.joined(separator: ",")
            let json = MacroSupport.descriptorJSON(
                macroName: "ParameterizedTest",
                scope: "method",
                declarationName: scenario,
                targetType: MacroSupport.enclosingTypeName(context: context),
                values: [caseID, displayName],
                concreteMethod: concreteMethod,
                canonicalScenario: scenario,
                parametersJSON: "[\(parametersJSON)]"
            )
            declarations.append(DeclSyntax(stringLiteral:
                "@objc func \(concreteMethod)() { \(scenario)(\(element.expression.trimmedDescription)) }"
            ))
            declarations.append(MacroSupport.providerDeclaration(json: json, context: context))
        }
        return declarations
    }

    private struct Rule {
        let mode: String
        let excluded: Bool
    }

    private static func parseRules(_ expression: ExprSyntax?) -> [String: Rule] {
        guard let array = expression?.as(ArrayExprSyntax.self) else { return [:] }
        var result: [String: Rule] = [:]
        for element in array.elements {
            guard let call = element.expression.as(FunctionCallExprSyntax.self) else { continue }
            let called = call.calledExpression.trimmedDescription
            let mode: String
            if called.hasSuffix(".masked") { mode = "masked" }
            else if called.hasSuffix(".hidden") { mode = "hidden" }
            else if called.hasSuffix(".excluded") { mode = "default" }
            else { continue }
            guard let first = call.arguments.first else { continue }
            let field = first.expression.trimmedDescription.split(separator: ".").last.map(String.init) ?? ""
            let explicitExcluded = call.arguments.first(where: { $0.label?.text == "excluded" })?.expression.trimmedDescription == "true"
            result[field] = Rule(mode: mode, excluded: mode == "default" || explicitExcluded)
        }
        return result
    }

    private static func sanitizeIdentifier(_ value: String) -> String {
        let mapped = value.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar).lowercased()) : "_"
        }
        let collapsed = String(mapped).replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_")).isEmpty ? "case" : collapsed
    }

    private static func render(
        template: String,
        index: Int,
        fields: [(String, String)],
        protectedFields: Set<String>
    ) -> String {
        var result = template.replacingOccurrences(of: "{index}", with: String(index))
        for (field, value) in fields {
            let replacement = protectedFields.contains(field) ? "<redacted>" : value
            result = result.replacingOccurrences(of: "{\(field)}", with: replacement)
        }
        return result
    }
}
