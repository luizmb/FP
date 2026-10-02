// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

private let notImplementedMessage = "Mock function not implemented for test case"

/// Inherited protocols a mock satisfies without synthesising anything.
private let markerParents: Set<String> = ["Any", "AnyObject", "class", "Sendable", "Copyable", "Escapable"]

// MARK: - Macro

public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: ProtocolMacroDiagnostic(macro: .mock, kind: .notAProtocol)))
            return []
        }
        if rejectPrivateHost(proto.modifiers, macro: "@Mock", kind: "protocols", node: node, context: context) { return [] }

        // The mock must *conform* to the protocol, but a syntactic macro can't see an inherited
        // protocol's requirements — so it can't synthesise them. Reject inheritance.
        let inherited = inheritedTypeNames(of: proto)
        guard inherited.allSatisfy({ markerParents.contains(unqualified($0)) || $0.hasPrefix("~") }) else {
            context.diagnose(Diagnostic(node: node, message: ProtocolMacroDiagnostic(macro: .mock, kind: .inheritanceUnsupported)))
            return []
        }

        guard let parsed = collectMembers(proto, in: context) else { return [] }

        let style = MockStyle(
            access: witnessAccess(proto.modifiers),
            isClass: isClassBound(inherited),
            isSendable: isSendableProtocol(inherited)
        )
        let pieces = zip(parsed.methods, parsed.fieldNames).map { mockMethod($0, fieldName: $1, style: style) }
            + parsed.properties.map { mockProperty($0, style: style) }

        let generics = genericClause(parsed.associatedTypes)
        let storedVars = pieces.map(\.storedVar).joined(separator: "\n    ")
        let initParams = pieces.flatMap(\.initParams).joined(separator: ", ")
        let assignments = pieces.flatMap(\.assignments).joined(separator: "; ")
        let conforming = pieces.map(\.conforming).joined(separator: "\n    ")
        let name = proto.name.trimmed.text
        let kind = style.isClass ? "final class" : "struct"

        let decl: DeclSyntax = """
        #if DEBUG
        \(raw: style.access.prefix)\(raw: kind) \(raw: name)Mock\(raw: generics.declaration): \(raw: name) {
            \(raw: storedVars)
            \(raw: style.access.prefix)init(\(raw: initParams)) { \(raw: assignments) }
            \(raw: conforming)
        }
        #endif
        """
        return [decl]
    }
}

/// How the mock is shaped: a `final class` for class-bound protocols (with immutable storage when it
/// must also be `Sendable`), `@Sendable` closures for `Sendable` protocols.
private struct MockStyle {
    let access: AccessLevel
    let isClass: Bool
    let isSendable: Bool

    var binding: String { isClass && isSendable ? "let" : "var" }
    var closureAttribute: String { isSendable ? "@Sendable " : "" }
}

// MARK: - Member collection

private struct ParsedMembers {
    let associatedTypes: [(name: String, constraint: String?)]
    let methods: [RequirementMethod]
    let fieldNames: [String]
    let properties: [RequirementProperty]
}

private func collectMembers(_ proto: ProtocolDeclSyntax, in context: some MacroExpansionContext) -> ParsedMembers? {
    var methods: [RequirementMethod] = []
    var properties: [RequirementProperty] = []
    var aborted = false

    func abort(_ kind: ProtocolMacroDiagnostic.Kind, at syntax: Syntax) {
        context.diagnose(Diagnostic(node: syntax, message: ProtocolMacroDiagnostic(macro: .mock, kind: kind)))
        aborted = true
    }

    for member in proto.memberBlock.members {
        let decl = member.decl
        if let function = decl.as(FunctionDeclSyntax.self) {
            if let method = parseRequirementMethod(function, macro: .mock, diagnose: abort) { methods.append(method) }
        } else if let variable = decl.as(VariableDeclSyntax.self) {
            if let property = parseRequirementProperty(variable, macro: .mock, diagnose: abort) { properties.append(property) }
        } else if decl.is(InitializerDeclSyntax.self) {
            abort(.initRequirement, at: Syntax(decl))
        } else if decl.is(SubscriptDeclSyntax.self) {
            abort(.subscriptRequirement, at: Syntax(decl))
        }
    }

    let names = disambiguatedNames(methods)
    for (method, name) in zip(methods, names) where name == nil {
        abort(.overloadCollision(method.baseName), at: Syntax(method.function))
    }

    return aborted ? nil : ParsedMembers(
        associatedTypes: associatedTypes(of: proto),
        methods: methods,
        fieldNames: names.compactMap(\.self),
        properties: properties
    )
}

// MARK: - Per-member generation

private struct MockMember {
    let storedVar: String
    let initParams: [String]
    let assignments: [String]
    let conforming: String
}

/// A default that crashes when called: a closure literal (rather than `fail(...)` itself), so it also
/// fits closure types a generic can't stand for — non-escaping or `@autoclosure` parameters, `inout` —
/// and is `@Sendable` when the mock needs it to be.
private func failingDefault(arity: Int) -> String {
    let call = "CoreFP.fail(\"\(notImplementedMessage)\")()"
    guard arity > 0 else { return "{ \(call) }" }
    return "{ \(Array(repeating: "_", count: arity).joined(separator: ", ")) in \(call) }"
}

private func mockMethod(_ method: RequirementMethod, fieldName: String, style: MockStyle) -> MockMember {
    let function = method.function
    let stored = "wrapped\(fieldName.capitalizedFirst)"
    let closureType = style.closureAttribute + method.closureType

    let args = method.params.map { $0.argument($0.internalName, labelled: false) }.joined(separator: ", ")
    let call = "\(stored)(\(args))"
    let body: String
    if case .rethrows = method.throwsKind {
        // A `rethrows` method may only throw through its closure arguments, so a direct call to the
        // throwing stored closure is rejected; an immediately-applied closure is accepted and rethrows.
        let effects = method.isAsync ? " async throws" : " throws"
        body = "\(method.callMarkers){ ()\(effects) -> \(method.returnType) in \(method.callMarkers)\(call) }()"
    } else {
        body = method.callMarkers + call
    }

    // The conforming method reproduces the requirement, naming any unnamed parameter so it can forward it.
    let generics = function.genericParameterClause?.trimmedDescription ?? ""
    let effects = function.signature.effectSpecifiers.map { " \($0.trimmedDescription)" } ?? ""
    let returnClause = function.signature.returnClause.map { " \($0.trimmedDescription)" } ?? ""
    let whereClause = function.genericWhereClause.map { " \($0.trimmedDescription)" } ?? ""
    let params = method.params.map(\.signature).joined(separator: ", ")
    let conforming = "\(style.access.prefix)func \(method.baseName)\(generics)(\(params))\(effects)\(returnClause)\(whereClause)"
        + " { \(body) }"

    return MockMember(
        storedVar: "\(style.access.prefix)\(style.binding) \(stored): \(closureType)",
        initParams: ["\(fieldName): @escaping \(closureType) = \(failingDefault(arity: method.params.count))"],
        assignments: ["self.\(stored) = \(fieldName)"],
        conforming: conforming
    )
}

private func mockProperty(_ property: RequirementProperty, style: MockStyle) -> MockMember {
    let name = property.name
    let cap = name.capitalizedFirst
    let getStored = "wrapped\(cap)"
    let getterType = "\(style.closureAttribute)()\(property.effects) -> \(property.type)"
    let read = "\(property.callMarkers)\(getStored)()"

    var storedVars = ["\(style.access.prefix)\(style.binding) \(getStored): \(getterType)"]
    var initParams = ["\(name): @escaping \(getterType) = \(failingDefault(arity: 0))"]
    var assignments = ["self.\(getStored) = \(name)"]
    var accessor = property.accessorEffects.isEmpty ? "{ \(read) }" : "{ get \(property.accessorEffects) { \(read) } }"

    if property.isSettable {
        let setStored = "wrapped\(cap)Set"
        let setterType = "\(style.closureAttribute)(\(property.type)) -> Void"
        storedVars.append("\(style.access.prefix)\(style.binding) \(setStored): \(setterType)")
        initParams.append("set\(cap): @escaping \(setterType) = \(failingDefault(arity: 1))")
        assignments.append("self.\(setStored) = set\(cap)")
        accessor = "{ get { \(read) } set { \(setStored)(newValue) } }"
    }

    return MockMember(
        storedVar: storedVars.joined(separator: "\n    "),
        initParams: initParams,
        assignments: assignments,
        conforming: "\(style.access.prefix)var \(name): \(property.type) \(accessor)"
    )
}
