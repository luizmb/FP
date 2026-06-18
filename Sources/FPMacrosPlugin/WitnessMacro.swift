// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsed model

private struct WitnessParam {
    let label: String? // nil when the parameter label is `_`
    let type: String
}

private struct WitnessMethod {
    let baseName: String
    let params: [WitnessParam]
    let returnType: String // "Void" when absent
    let isAsync: Bool
    let isThrows: Bool

    var effects: String {
        (isAsync ? " async" : "") + (isThrows ? " throws" : "")
    }

    /// The closure-field type, e.g. `@Sendable (String, Int) async -> Bool`.
    var closureType: String {
        "@Sendable (\(params.map(\.type).joined(separator: ", ")))\(effects) -> \(returnType)"
    }

    /// The closure body that forwards to a captured `instance`, threading labels.
    func forwarding(to instance: String) -> String {
        let args = params.enumerated()
            .map { index, param in (param.label.map { "\($0): " } ?? "") + "$\(index)" }
            .joined(separator: ", ")
        let call = "\(instance).\(baseName)(\(args))"
        let prefix = (isThrows ? "try " : "") + (isAsync ? "await " : "")
        return "{ \(prefix)\(call) }"
    }
}

private struct WitnessProperty {
    let name: String
    let type: String
    let isSettable: Bool
}

private struct WitnessModel {
    let methods: [WitnessMethod]
    let properties: [WitnessProperty]
    let associatedTypes: [(name: String, constraint: String?)]
    let inheritedWitnesses: [String] // parent protocol names (already filtered of markers)

    var hasSettable: Bool { properties.contains(where: \.isSettable) }
}

// MARK: - Macro (peer struct)

public struct WitnessMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: WitnessDiagnostic.notAProtocol))
            return []
        }
        guard let model = parseModel(proto, node: node, in: context) else { return [] }

        let access = witnessAccess(proto.modifiers)
        let name = proto.name.trimmed.text
        let witnessName = "\(name)Witness"
        let generics = genericClause(model.associatedTypes)

        let fields = makeFields(model, access: access)
        let memberwiseInit = makeMemberwiseInit(model, access: access)
        let fromInstanceInit = makeFromInstanceInit(
            model,
            protocolName: name,
            witnessName: witnessName,
            generics: generics,
            access: access
        )

        let body = (fields + [memberwiseInit, fromInstanceInit]).joined(separator: "\n    ")
        let decl: DeclSyntax = """
        \(raw: access.prefix)struct \(raw: witnessName)\(raw: generics.declaration): Sendable {
            \(raw: body)
        }
        """
        return [decl]
    }
}

// MARK: - Macro (`.witness` conversion extension)

extension WitnessMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self),
              let model = parseModel(proto, node: node, in: context)
        else { return [] }

        let access = witnessAccess(proto.modifiers)
        let witnessName = "\(proto.name.trimmed.text)Witness"
        let generics = genericClause(model.associatedTypes)
        let witnessType = witnessName + generics.usage
        // Settable requirements force a reference-type source (see the from-instance init), so the
        // `.witness` convenience is gated to `AnyObject` in that case; value types build it by hand.
        let selfConstraint = "Sendable" + (model.hasSettable ? " & AnyObject" : "")
        let ext: DeclSyntax = """
        extension \(type.trimmed) where Self: \(raw: selfConstraint) {
            \(raw: access.prefix)var witness: \(raw: witnessType) { \(raw: witnessName)(self) }
        }
        """
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

// MARK: - Parsing

private func parseModel(
    _ proto: ProtocolDeclSyntax,
    node: AttributeSyntax,
    in context: some MacroExpansionContext
) -> WitnessModel? {
    var methods: [WitnessMethod] = []
    var properties: [WitnessProperty] = []
    var associatedTypes: [(name: String, constraint: String?)] = []
    var aborted = false

    func abort(_ message: WitnessDiagnostic, at syntax: some SyntaxProtocol) {
        context.diagnose(Diagnostic(node: syntax, message: message))
        aborted = true
    }

    for member in proto.memberBlock.members {
        let decl = member.decl
        if let assoc = decl.as(AssociatedTypeDeclSyntax.self) {
            let constraint = assoc.inheritanceClause?.inheritedTypes
                .map(\.type.trimmedDescription).joined(separator: " & ")
            associatedTypes.append((assoc.name.text, constraint))
        } else if let function = decl.as(FunctionDeclSyntax.self) {
            if let method = parseMethod(function, abort: abort) { methods.append(method) }
        } else if let variable = decl.as(VariableDeclSyntax.self) {
            if let property = parseProperty(variable, abort: abort) { properties.append(property) }
        } else if decl.is(InitializerDeclSyntax.self) {
            abort(.initRequirement, at: decl)
        } else if decl.is(SubscriptDeclSyntax.self) {
            abort(.subscriptRequirement, at: decl)
        }
    }

    let inherited = (proto.inheritanceClause?.inheritedTypes ?? [])
        .map(\.type.trimmedDescription)
        .filter { !markerProtocols.contains($0) }

    return aborted ? nil : WitnessModel(
        methods: methods,
        properties: properties,
        associatedTypes: associatedTypes,
        inheritedWitnesses: inherited
    )
}

private func parseMethod(
    _ function: FunctionDeclSyntax,
    abort: (WitnessDiagnostic, FunctionDeclSyntax) -> Void
) -> WitnessMethod? {
    let modifiers = Set(function.modifiers.map(\.name.text))
    if modifiers.contains("static") { abort(.staticRequirement, function); return nil }
    if modifiers.contains("mutating") { abort(.mutatingRequirement, function); return nil }

    var paramTypes = function.signature.parameterClause.parameters.map { param in
        WitnessParam(
            label: param.firstName.text == "_" ? nil : param.firstName.text,
            type: param.type.trimmedDescription
        )
    }
    let returnType = function.signature.returnClause?.type.trimmedDescription ?? "Void"

    // Generic parameters → erase each to its existential constraint when sound, else abort.
    if let genericClause = function.genericParameterClause {
        for genericParam in genericClause.parameters {
            let paramName = genericParam.name.text
            guard let constraint = genericParam.inheritedType?.trimmedDescription else {
                abort(.unconstrainedGeneric, function); return nil
            }
            if appears(paramName, in: returnType) { abort(.genericInReturn, function); return nil }
            let existential = "any \(constraint)"
            paramTypes = paramTypes.map { WitnessParam(label: $0.label, type: substitute(paramName, with: existential, in: $0.type)) }
        }
    }

    return WitnessMethod(
        baseName: function.name.text,
        params: paramTypes,
        returnType: returnType,
        isAsync: function.signature.effectSpecifiers?.asyncSpecifier != nil,
        isThrows: function.signature.effectSpecifiers?.throwsClause != nil
    )
}

private func parseProperty(
    _ variable: VariableDeclSyntax,
    abort: (WitnessDiagnostic, VariableDeclSyntax) -> Void
) -> WitnessProperty? {
    if variable.modifiers.contains(where: { $0.name.text == "static" }) {
        abort(.staticRequirement, variable); return nil
    }
    guard let binding = variable.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmedDescription
    else { return nil }

    var isSettable = false
    if case let .accessors(accessors) = binding.accessorBlock?.accessors {
        isSettable = accessors.contains { $0.accessorSpecifier.text == "set" }
    }
    return WitnessProperty(name: identifier, type: type, isSettable: isSettable)
}

// MARK: - Field & init generation

private func makeFields(_ model: WitnessModel, access: AccessLevel) -> [String] {
    var fields: [String] = []
    let names = disambiguatedNames(model.methods)

    for (method, fieldName) in zip(model.methods, names) {
        fields.append("\(access.prefix)var \(fieldName): \(method.closureType)")
    }
    for property in model.properties {
        fields.append("\(access.prefix)var \(property.name): @Sendable () -> \(property.type)")
        if property.isSettable {
            fields.append("\(access.prefix)var set\(property.name.capitalizedFirst): @Sendable (\(property.type)) -> Void")
        }
    }
    for parent in model.inheritedWitnesses {
        fields.append("\(access.prefix)var \(parent.lowercasedFirst): \(parent)Witness")
    }
    return fields
}

private func makeMemberwiseInit(_ model: WitnessModel, access: AccessLevel) -> String {
    let params = initParams(model)
    let assignments = initFieldNames(model).map { "self.\($0) = \($0)" }.joined(separator: "; ")
    return "\(access.prefix)init(\(params.joined(separator: ", "))) { \(assignments) }"
}

private func makeFromInstanceInit(
    _ model: WitnessModel,
    protocolName: String,
    witnessName: String,
    generics: GenericClause,
    access: AccessLevel
) -> String {
    let whereClause = model.associatedTypes.isEmpty
        ? ""
        : " where " + model.associatedTypes.map { "Base.\($0.name) == \($0.name)" }.joined(separator: ", ")
    let names = disambiguatedNames(model.methods)

    var args: [String] = []
    for (method, fieldName) in zip(model.methods, names) {
        args.append("\(fieldName): \(method.forwarding(to: "instance"))")
    }
    for property in model.properties {
        args.append("\(property.name): { instance.\(property.name) }")
        if property.isSettable {
            // The protocol's setter is `mutating`, so it needs a `var`; `instance` is `AnyObject`-gated,
            // so the rebound `target` is the same object and the write lands on the shared instance.
            args.append("set\(property.name.capitalizedFirst): { var target = instance; target.\(property.name) = $0 }")
        }
    }
    for parent in model.inheritedWitnesses {
        args.append("\(parent.lowercasedFirst): \(parent)Witness(instance)")
    }

    // A settable property's setter mutates through `instance`; that needs a reference type,
    // so the from-instance init is gated to `AnyObject` when any requirement is settable.
    let baseConstraint = "\(protocolName) & Sendable" + (model.hasSettable ? " & AnyObject" : "")
    return "\(access.prefix)init<Base: \(baseConstraint)>(_ instance: Base)\(whereClause) { "
        + "self.init(\(args.joined(separator: ", "))) }"
}

private func initParams(_ model: WitnessModel) -> [String] {
    let names = disambiguatedNames(model.methods)
    var params: [String] = []
    for (method, fieldName) in zip(model.methods, names) {
        params.append("\(fieldName): @escaping \(method.closureType)")
    }
    for property in model.properties {
        params.append("\(property.name): @escaping @Sendable () -> \(property.type)")
        if property.isSettable {
            params.append("set\(property.name.capitalizedFirst): @escaping @Sendable (\(property.type)) -> Void")
        }
    }
    for parent in model.inheritedWitnesses {
        params.append("\(parent.lowercasedFirst): \(parent)Witness")
    }
    return params
}

private func initFieldNames(_ model: WitnessModel) -> [String] {
    var names = disambiguatedNames(model.methods)
    for property in model.properties {
        names.append(property.name)
        if property.isSettable { names.append("set\(property.name.capitalizedFirst)") }
    }
    names.append(contentsOf: model.inheritedWitnesses.map(\.lowercasedFirst))
    return names
}

// MARK: - Overload disambiguation

private func disambiguatedNames(_ methods: [WitnessMethod]) -> [String] {
    var counts: [String: Int] = [:]
    for method in methods {
        counts[method.baseName, default: 0] += 1
    }

    return methods.map { method in
        guard counts[method.baseName, default: 0] > 1 else { return method.baseName }
        let parts = method.params.map { ($0.label ?? typeToken($0.type)).capitalizedFirst }
        return method.baseName + "With" + parts.joined(separator: "And")
    }
}

func typeToken(_ type: String) -> String {
    let cleaned = type.filter { $0.isLetter || $0.isNumber }
    return cleaned.isEmpty ? "Value" : cleaned
}

// MARK: - Generics

struct GenericClause {
    let declaration: String // e.g. "<Item, Failure: Error>" or ""
    let usage: String // e.g. "<Item, Failure>" or ""
}

func genericClause(_ associatedTypes: [(name: String, constraint: String?)]) -> GenericClause {
    guard !associatedTypes.isEmpty else { return GenericClause(declaration: "", usage: "") }
    let decl = associatedTypes
        .map { entry in entry.constraint.map { "\(entry.name): \($0)" } ?? entry.name }
        .joined(separator: ", ")
    let use = associatedTypes.map(\.name).joined(separator: ", ")
    return GenericClause(declaration: "<\(decl)>", usage: "<\(use)>")
}

// MARK: - Helpers

let markerProtocols: Set<String> = ["Sendable", "AnyObject", "Any"]

func witnessAccess(_ modifiers: DeclModifierListSyntax) -> AccessLevel {
    for modifier in modifiers {
        switch modifier.name.text {
        case "open",
             "public":
            return .public // `open` structs are illegal → public witness

        case "package":
            return .package

        case "internal":
            return .internal

        case "fileprivate":
            return .fileprivate

        case "private":
            return .private

        default:
            continue
        }
    }
    return .internal
}

/// Whole-identifier check: does `name` appear as a standalone token in `text`?
func appears(_ name: String, in text: String) -> Bool {
    substitute(name, with: " {0}", in: text).contains(" {0}")
}

/// Replace standalone occurrences of identifier `name` with `replacement`, respecting
/// identifier boundaries so `T` doesn't match inside `Tally`.
func substitute(_ name: String, with replacement: String, in text: String) -> String {
    func isIdentifierChar(_ c: Character) -> Bool { c.isLetter || c.isNumber || c == "_" }
    var result = ""
    let chars = Array(text)
    var i = 0
    while i < chars.count {
        let leftBoundary = i == 0 || !isIdentifierChar(chars[i - 1])
        let rightBoundary = i + name.count >= chars.count || !isIdentifierChar(chars[i + name.count])
        if chars[i] == name.first, matches(name, in: chars, at: i), leftBoundary, rightBoundary {
            result += replacement
            i += name.count
        } else {
            result.append(chars[i])
            i += 1
        }
    }
    return result
}

func matches(_ name: String, in chars: [Character], at index: Int) -> Bool {
    let target = Array(name)
    guard index + target.count <= chars.count else { return false }
    for offset in 0..<target.count where chars[index + offset] != target[offset] {
        return false
    }
    return true
}

extension String {
    var capitalizedFirst: String { isEmpty ? self : prefix(1).uppercased() + dropFirst() }
    var lowercasedFirst: String { isEmpty ? self : prefix(1).lowercased() + dropFirst() }
}

// MARK: - Diagnostics

private enum WitnessDiagnostic: DiagnosticMessage {
    case notAProtocol
    case staticRequirement
    case mutatingRequirement
    case initRequirement
    case subscriptRequirement
    case unconstrainedGeneric
    case genericInReturn

    var message: String {
        switch self {
        case .notAProtocol:
            "@Witness can only be applied to protocols"

        case .staticRequirement:
            "@Witness can't witness `static` requirements (a value witness has no Self)"

        case .mutatingRequirement:
            "@Witness can't witness `mutating` requirements in a value witness"

        case .initRequirement:
            "@Witness can't witness `init` requirements"

        case .subscriptRequirement:
            "@Witness can't witness `subscript` requirements"

        case .unconstrainedGeneric:
            "@Witness can't witness a method with an unconstrained generic parameter "
                + "(no protocol/class constraint to erase to `any`). Add a constraint or remove the requirement."

        case .genericInReturn:
            "@Witness can't witness a method whose generic parameter appears in the return type "
                + "(e.g. `decode<T>(_: T.Type) -> T`) — it can't be lowered to an existential."
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "Witness.\(self)") }
    var severity: DiagnosticSeverity { .error }
}
