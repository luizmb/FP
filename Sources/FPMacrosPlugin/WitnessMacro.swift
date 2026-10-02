// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Parsed model

private struct WitnessMethod {
    let requirement: RequirementMethod
    let fieldName: String

    /// The closure-field type, e.g. `@Sendable (String, Int) async -> Bool`.
    var closureType: String { "@Sendable \(requirement.closureType)" }

    /// The closure that forwards to a captured `instance`, threading labels, `&` and effects. A typed
    /// `throws(E)` must be spelled on the closure literal, or it would be inferred as untyped `throws`.
    func forwarding(to instance: String) -> String {
        let params = requirement.params
        let call = "\(requirement.callMarkers)\(instance).\(requirement.baseName)("
            + params.enumerated().map { index, param in param.argument("p\(index)", labelled: true) }.joined(separator: ", ")
            + ")"
        let names = params.indices.map { "p\($0)" }.joined(separator: ", ")
        guard let error = requirement.throwsKind.typedError else {
            return params.isEmpty ? "{ \(call) }" : "{ \(names) in \(call) }"
        }
        return "{ (\(names))\(requirement.isAsync ? " async" : "") throws(\(error)) in \(call) }"
    }
}

private struct WitnessModel {
    let methods: [WitnessMethod]
    let properties: [RequirementProperty]
    let associatedTypes: [(name: String, constraint: String?)]
    let inheritedWitnesses: [String] // parent protocol names (already filtered of markers)
    let isClassBound: Bool

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
            context.diagnose(Diagnostic(node: node, message: ProtocolMacroDiagnostic(macro: .witness, kind: .notAProtocol)))
            return []
        }
        guard let model = parseModel(proto, node: node, in: context, diagnoses: true) else { return [] }

        let access = witnessAccess(proto.modifiers)
        let name = proto.name.trimmed.text
        let witnessName = "\(name)Witness"
        let generics = genericClause(model.associatedTypes)

        let fields = makeFields(model, access: access)
        let memberwiseInit = makeMemberwiseInit(model, access: access)
        let fromInstanceInit = makeFromInstanceInit(model, protocolName: name, access: access)

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
        // The peer role already reported every diagnostic; don't repeat them here.
        guard let proto = declaration.as(ProtocolDeclSyntax.self),
              let model = parseModel(proto, node: node, in: context, diagnoses: false)
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

/// Inherited protocols that carry no `@Witness`-able requirements of their own (markers, or stdlib
/// protocols whose requirements are `static`/operators); they're satisfied by `Base` and not composed.
private let nonWitnessParents: Set<String> = [
    "Any", "AnyObject", "class", "Sendable", "Copyable", "Escapable", "BitwiseCopyable", "SendableMetatype",
    "Equatable", "Hashable", "Comparable", "Identifiable", "Codable", "Encodable", "Decodable",
    "CustomStringConvertible", "CustomDebugStringConvertible", "LosslessStringConvertible", "Error"
]

/// Standard-library protocols with associated types: their witness would need generic arguments.
private let associatedTypeParents: Set<String> = [
    "Sequence", "Collection", "BidirectionalCollection", "RandomAccessCollection", "MutableCollection",
    "RangeReplaceableCollection", "IteratorProtocol", "RawRepresentable", "AsyncSequence",
    "AsyncIteratorProtocol", "SetAlgebra", "OptionSet", "Strideable", "Numeric", "SignedNumeric",
    "BinaryInteger", "FixedWidthInteger", "FloatingPoint", "BinaryFloatingPoint", "ExpressibleByArrayLiteral",
    "ExpressibleByDictionaryLiteral", "ExpressibleByIntegerLiteral", "ExpressibleByFloatLiteral",
    "ExpressibleByStringLiteral", "ExpressibleByBooleanLiteral"
]

private func parseModel(
    _ proto: ProtocolDeclSyntax,
    node: AttributeSyntax,
    in context: some MacroExpansionContext,
    diagnoses: Bool
) -> WitnessModel? {
    var aborted = false
    func abort(_ kind: ProtocolMacroDiagnostic.Kind, at syntax: Syntax) {
        if diagnoses { context.diagnose(Diagnostic(node: syntax, message: ProtocolMacroDiagnostic(macro: .witness, kind: kind))) }
        aborted = true
    }

    if explicitAccessLevel(from: proto.modifiers) == .private {
        if diagnoses {
            context.diagnose(Diagnostic(node: node, message: HostDiagnostic.privateHostUnsupported(macro: "@Witness", kind: "protocols")))
        }
        return nil
    }

    var requirements: [RequirementMethod] = []
    var properties: [RequirementProperty] = []
    for member in proto.memberBlock.members {
        let decl = member.decl
        if let function = decl.as(FunctionDeclSyntax.self) {
            if let method = parseRequirementMethod(function, macro: .witness, diagnose: abort) { requirements.append(method) }
        } else if let variable = decl.as(VariableDeclSyntax.self) {
            if let property = parseRequirementProperty(variable, macro: .witness, diagnose: abort) { properties.append(property) }
        } else if decl.is(InitializerDeclSyntax.self) {
            abort(.initRequirement, at: Syntax(decl))
        } else if decl.is(SubscriptDeclSyntax.self) {
            abort(.subscriptRequirement, at: Syntax(decl))
        }
    }

    let inherited = inheritedTypeNames(of: proto)
    let parents = inherited.filter { !nonWitnessParents.contains(unqualified($0)) && !$0.hasPrefix("~") }
    for parent in parents where parent.contains("<") || associatedTypeParents.contains(unqualified(parent)) {
        abort(.unsupportedParent(parent), at: Syntax(proto.name))
    }

    let names = disambiguatedNames(requirements)
    for (method, name) in zip(requirements, names) where name == nil {
        abort(.overloadCollision(method.baseName), at: Syntax(method.function))
    }

    return aborted ? nil : WitnessModel(
        methods: zip(requirements, names).compactMap { method, name in name.map { WitnessMethod(requirement: method, fieldName: $0) } },
        properties: properties,
        associatedTypes: associatedTypes(of: proto),
        inheritedWitnesses: parents,
        isClassBound: isClassBound(inherited)
    )
}

// MARK: - Field & init generation

private func propertyClosureType(_ property: RequirementProperty) -> String {
    "@Sendable ()\(property.effects) -> \(property.type)"
}

private func makeFields(_ model: WitnessModel, access: AccessLevel) -> [String] {
    var fields: [String] = []
    for method in model.methods {
        fields.append("\(access.prefix)var \(method.fieldName): \(method.closureType)")
    }
    for property in model.properties {
        fields.append("\(access.prefix)var \(property.name): \(propertyClosureType(property))")
        if property.isSettable {
            fields.append("\(access.prefix)var set\(property.name.capitalizedFirst): @Sendable (\(property.type)) -> Void")
        }
    }
    for parent in model.inheritedWitnesses {
        fields.append("\(access.prefix)var \(parentFieldName(parent)): \(parent)Witness")
    }
    return fields
}

private func parentFieldName(_ parent: String) -> String {
    (parent.split(separator: ".").last.map(String.init) ?? parent).lowercasedFirst
}

private func makeMemberwiseInit(_ model: WitnessModel, access: AccessLevel) -> String {
    let params = initParams(model)
    let assignments = initFieldNames(model).map { "self.\($0) = \($0)" }.joined(separator: "; ")
    return "\(access.prefix)init(\(params.joined(separator: ", "))) { \(assignments) }"
}

private func makeFromInstanceInit(_ model: WitnessModel, protocolName: String, access: AccessLevel) -> String {
    let whereClause = model.associatedTypes.isEmpty
        ? ""
        : " where " + model.associatedTypes.map { "Base.\($0.name) == \($0.name)" }.joined(separator: ", ")

    var args: [String] = []
    for method in model.methods {
        args.append("\(method.fieldName): \(method.forwarding(to: "instance"))")
    }
    for property in model.properties {
        let read = "\(property.callMarkers)instance.\(property.name)"
        if let error = property.throwsKind.typedError {
            args.append("\(property.name): { ()\(property.isAsync ? " async" : "") throws(\(error)) in \(read) }")
        } else {
            args.append("\(property.name): { \(read) }")
        }
        if property.isSettable {
            // A class-bound protocol's setter is non-mutating, so it writes through `instance` directly.
            // Otherwise the protocol's setter is `mutating` and needs a `var`; `instance` is
            // `AnyObject`-gated, so the rebound `target` is the same object and the write lands on it.
            let write = model.isClassBound
                ? "{ instance.\(property.name) = $0 }"
                : "{ var target = instance; target.\(property.name) = $0 }"
            args.append("set\(property.name.capitalizedFirst): \(write)")
        }
    }
    for parent in model.inheritedWitnesses {
        args.append("\(parentFieldName(parent)): \(parent)Witness(instance)")
    }

    // A settable property's setter mutates through `instance`; that needs a reference type,
    // so the from-instance init is gated to `AnyObject` when any requirement is settable.
    let baseConstraint = "\(protocolName) & Sendable" + (model.hasSettable ? " & AnyObject" : "")
    return "\(access.prefix)init<Base: \(baseConstraint)>(_ instance: Base)\(whereClause) { "
        + "self.init(\(args.joined(separator: ", "))) }"
}

private func initParams(_ model: WitnessModel) -> [String] {
    var params: [String] = []
    for method in model.methods {
        params.append("\(method.fieldName): @escaping \(method.closureType)")
    }
    for property in model.properties {
        params.append("\(property.name): @escaping \(propertyClosureType(property))")
        if property.isSettable {
            params.append("set\(property.name.capitalizedFirst): @escaping @Sendable (\(property.type)) -> Void")
        }
    }
    for parent in model.inheritedWitnesses {
        params.append("\(parentFieldName(parent)): \(parent)Witness")
    }
    return params
}

private func initFieldNames(_ model: WitnessModel) -> [String] {
    var names = model.methods.map(\.fieldName)
    for property in model.properties {
        names.append(property.name)
        if property.isSettable { names.append("set\(property.name.capitalizedFirst)") }
    }
    names.append(contentsOf: model.inheritedWitnesses.map(parentFieldName))
    return names
}
