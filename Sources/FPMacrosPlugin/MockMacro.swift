// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

private let notImplementedMessage = "Mock function not implemented for test case"

// MARK: - Macro

public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let proto = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: MockDiagnostic.notAProtocol))
            return []
        }
        // The mock must *conform* to the protocol, but a syntactic macro can't see an inherited
        // protocol's requirements — so it can't synthesise them. Reject inheritance.
        let inherited = (proto.inheritanceClause?.inheritedTypes ?? [])
            .map(\.type.trimmedDescription)
            .filter { !markerProtocols.contains($0) }
        guard inherited.isEmpty else {
            context.diagnose(Diagnostic(node: node, message: MockDiagnostic.inheritanceUnsupported))
            return []
        }

        guard let parsed = collectMembers(proto, in: context) else { return [] }

        let access = witnessAccess(proto.modifiers)
        let collisions = baseNameCollisions(parsed.functions)

        var aborted = false
        func abort(_ message: MockDiagnostic, at function: FunctionDeclSyntax) {
            context.diagnose(Diagnostic(node: function, message: message))
            aborted = true
        }

        var pieces: [MockMember] = []
        for function in parsed.functions {
            let collides = collisions.contains(function.name.text)
            guard let member = mockMethod(function, access: access, collides: collides, abort: abort) else { return [] }
            pieces.append(member)
        }
        guard !aborted else { return [] }
        for variable in parsed.variables {
            if let member = mockProperty(variable, access: access) { pieces.append(member) }
        }

        let generics = genericClause(parsed.associatedTypes)
        let storedVars = pieces.map(\.storedVar).joined(separator: "\n    ")
        let initParams = pieces.flatMap(\.initParams).joined(separator: ", ")
        let assignments = pieces.flatMap(\.assignments).joined(separator: "; ")
        let conforming = pieces.map(\.conforming).joined(separator: "\n    ")

        let decl: DeclSyntax = """
        #if DEBUG
        \(raw: access.prefix)struct \(raw: proto.name.trimmed.text)Mock\(raw: generics.declaration): \(raw: proto.name.trimmed.text) {
            \(raw: storedVars)
            \(raw: access.prefix)init(\(raw: initParams)) { \(raw: assignments) }
            \(raw: conforming)
        }
        #endif
        """
        return [decl]
    }
}

// MARK: - Member collection

private struct ParsedMembers {
    let associatedTypes: [(name: String, constraint: String?)]
    let functions: [FunctionDeclSyntax]
    let variables: [VariableDeclSyntax]
}

private func collectMembers(_ proto: ProtocolDeclSyntax, in context: some MacroExpansionContext) -> ParsedMembers? {
    var associatedTypes: [(name: String, constraint: String?)] = []
    var functions: [FunctionDeclSyntax] = []
    var variables: [VariableDeclSyntax] = []
    var aborted = false

    func abort(_ message: MockDiagnostic, at syntax: some SyntaxProtocol) {
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
            let modifiers = Set(function.modifiers.map(\.name.text))
            if modifiers.contains("static") {
                abort(.staticRequirement, at: function)
            } else if modifiers.contains("mutating") {
                abort(.mutatingRequirement, at: function)
            } else {
                functions.append(function)
            }
        } else if let variable = decl.as(VariableDeclSyntax.self) {
            if variable.modifiers.contains(where: { $0.name.text == "static" }) {
                abort(.staticRequirement, at: variable)
            } else {
                variables.append(variable)
            }
        } else if decl.is(InitializerDeclSyntax.self) {
            abort(.initRequirement, at: decl)
        } else if decl.is(SubscriptDeclSyntax.self) {
            abort(.subscriptRequirement, at: decl)
        }
    }

    return aborted ? nil : ParsedMembers(associatedTypes: associatedTypes, functions: functions, variables: variables)
}

// MARK: - Per-member generation

private struct MockMember {
    let storedVar: String
    let initParams: [String]
    let assignments: [String]
    let conforming: String
}

private func mockMethod(
    _ function: FunctionDeclSyntax,
    access: AccessLevel,
    collides: Bool,
    abort: (MockDiagnostic, FunctionDeclSyntax) -> Void
) -> MockMember? {
    let baseName = function.name.text
    let params = function.signature.parameterClause.parameters
    var paramTypes = params.map(\.type.trimmedDescription)
    let returnType = function.signature.returnClause?.type.trimmedDescription ?? "Void"

    // Erase each sound method generic to its existential constraint, else abort.
    if let genericClause = function.genericParameterClause {
        for genericParam in genericClause.parameters {
            let paramName = genericParam.name.text
            guard let constraint = genericParam.inheritedType?.trimmedDescription else {
                abort(.unconstrainedGeneric, function); return nil
            }
            if appears(paramName, in: returnType) { abort(.genericInReturn, function); return nil }
            paramTypes = paramTypes.map { substitute(paramName, with: "any \(constraint)", in: $0) }
        }
    }

    let isAsync = function.signature.effectSpecifiers?.asyncSpecifier != nil
    let isThrows = function.signature.effectSpecifiers?.throwsClause != nil
    let effects = (isAsync ? " async" : "") + (isThrows ? " throws" : "")
    let closureType = "(\(paramTypes.joined(separator: ", ")))\(effects) -> \(returnType)"

    let labels = params.map { ($0.firstName.text == "_" ? typeToken($0.type.trimmedDescription) : $0.firstName.text).capitalizedFirst }
    let name = collides ? baseName + "With" + labels.joined(separator: "And") : baseName
    let stored = "wrapped\(name.capitalizedFirst)"

    // Conforming method reproduces the protocol signature verbatim and delegates to the closure.
    let genericDecl = function.genericParameterClause?.trimmedDescription ?? ""
    let whereClause = function.genericWhereClause.map { " \($0.trimmedDescription)" } ?? ""
    let forwardArgs = params.map { ($0.secondName ?? $0.firstName).text }.joined(separator: ", ")
    let callPrefix = (isThrows ? "try " : "") + (isAsync ? "await " : "")
    let conforming = "\(access.prefix)func \(baseName)\(genericDecl)\(function.signature.trimmedDescription)\(whereClause)"
        + " { \(callPrefix)\(stored)(\(forwardArgs)) }"

    return MockMember(
        storedVar: "\(access.prefix)var \(stored): \(closureType)",
        initParams: ["\(name): @escaping \(closureType) = fail(\"\(notImplementedMessage)\")"],
        assignments: ["self.\(stored) = \(name)"],
        conforming: conforming
    )
}

private func mockProperty(_ variable: VariableDeclSyntax, access: AccessLevel) -> MockMember? {
    guard let binding = variable.bindings.first,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmedDescription
    else { return nil }

    var isSettable = false
    if case let .accessors(accessors) = binding.accessorBlock?.accessors {
        isSettable = accessors.contains { $0.accessorSpecifier.text == "set" }
    }
    let cap = name.capitalizedFirst
    let getStored = "wrapped\(cap)"

    var storedVars = ["\(access.prefix)var \(getStored): () -> \(type)"]
    var initParams = ["\(name): @escaping () -> \(type) = fail(\"\(notImplementedMessage)\")"]
    var assignments = ["self.\(getStored) = \(name)"]
    var accessor = "{ \(getStored)() }"

    if isSettable {
        let setStored = "wrapped\(cap)Set"
        storedVars.append("\(access.prefix)var \(setStored): (\(type)) -> Void")
        initParams.append("set\(cap): @escaping (\(type)) -> Void = fail(\"\(notImplementedMessage)\")")
        assignments.append("self.\(setStored) = set\(cap)")
        accessor = "{ get { \(getStored)() } set { \(setStored)(newValue) } }"
    }

    return MockMember(
        storedVar: storedVars.joined(separator: "\n    "),
        initParams: initParams,
        assignments: assignments,
        conforming: "\(access.prefix)var \(name): \(type) \(accessor)"
    )
}

// MARK: - Helpers

private func baseNameCollisions(_ functions: [FunctionDeclSyntax]) -> Set<String> {
    var counts: [String: Int] = [:]
    for function in functions {
        counts[function.name.text, default: 0] += 1
    }
    return Set(counts.filter { $0.value > 1 }.keys)
}

// MARK: - Diagnostics

private enum MockDiagnostic: DiagnosticMessage {
    case notAProtocol
    case inheritanceUnsupported
    case staticRequirement
    case mutatingRequirement
    case initRequirement
    case subscriptRequirement
    case unconstrainedGeneric
    case genericInReturn

    var message: String {
        switch self {
        case .notAProtocol:
            "@Mock can only be applied to protocols"

        case .inheritanceUnsupported:
            "@Mock can't mock a protocol that inherits another protocol — the macro can't see the parent's "
                + "requirements to synthesise them. Flatten the protocol or conform the inherited part by hand."

        case .staticRequirement:
            "@Mock can't mock `static` requirements"

        case .mutatingRequirement:
            "@Mock can't mock `mutating` requirements"

        case .initRequirement:
            "@Mock can't mock `init` requirements"

        case .subscriptRequirement:
            "@Mock can't mock `subscript` requirements"

        case .unconstrainedGeneric:
            "@Mock can't mock a method with an unconstrained generic parameter "
                + "(no protocol/class constraint to erase to `any`)."

        case .genericInReturn:
            "@Mock can't mock a method whose generic parameter appears in the return type "
                + "(e.g. `decode<T>(_: T.Type) -> T`)."
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "Mock.\(self)") }
    var severity: DiagnosticSeverity { .error }
}
