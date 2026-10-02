// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// Requirement parsing shared by `@Witness` and `@Mock`: both turn each protocol requirement into a
// closure, so they agree on how a parameter list becomes a closure type and how a call is forwarded.

// MARK: - Model

enum ProtocolMacro: String {
    case witness = "Witness"
    case mock = "Mock"
}

/// How a requirement throws.
enum ThrowsKind {
    case none
    case untyped
    case typed(String)
    case `rethrows`

    /// The effect as spelled on a closure type. `rethrows` can't be spelled there, so it becomes `throws`.
    var closureSpelling: String {
        switch self {
        case .none:
            ""

        case .untyped,
             .rethrows:
            " throws"

        case let .typed(error):
            " throws(\(error))"
        }
    }

    var isThrowing: Bool {
        if case .none = self { return false }
        return true
    }

    /// The thrown error type when it's typed, which a closure literal must spell out to adopt it.
    var typedError: String? {
        if case let .typed(error) = self { return error }
        return nil
    }
}

struct RequirementParam {
    /// The argument label, `nil` for `_`.
    let label: String?
    /// The parameter's own name — synthesised (`p0`, `p1`, …) when the requirement leaves it unnamed.
    let internalName: String
    /// The parameter as it appears in the requirement (`label name: Type...`), with `internalName`.
    let signature: String
    /// The parameter's type inside the closure type: generics/`some` erased to `any`, variadics as arrays.
    let closureType: String
    let isInout: Bool
    let isAutoclosure: Bool

    /// The argument expression that passes `reference` on to a call taking this parameter.
    func argument(_ reference: String, labelled: Bool) -> String {
        let label = labelled ? (label.map { "\($0): " } ?? "") : ""
        return label + (isInout ? "&" : "") + reference + (isAutoclosure ? "()" : "")
    }
}

struct RequirementMethod {
    let baseName: String
    let params: [RequirementParam]
    let returnType: String
    let isAsync: Bool
    let throwsKind: ThrowsKind
    let function: FunctionDeclSyntax

    /// `(A, B) async throws(E) -> R` — the closure type for this requirement, without attributes.
    var closureType: String {
        "(\(params.map(\.closureType).joined(separator: ", ")))\(effects) -> \(returnType)"
    }

    var effects: String { (isAsync ? " async" : "") + throwsKind.closureSpelling }

    /// `try await ` / `try ` / `await ` / `` — the markers a call to this requirement needs.
    var callMarkers: String { (throwsKind.isThrowing ? "try " : "") + (isAsync ? "await " : "") }
}

struct RequirementProperty {
    let name: String
    let type: String
    let isSettable: Bool
    let isAsync: Bool
    let throwsKind: ThrowsKind

    var effects: String { (isAsync ? " async" : "") + throwsKind.closureSpelling }
    var callMarkers: String { (throwsKind.isThrowing ? "try " : "") + (isAsync ? "await " : "") }

    /// The accessor effects as written in a `get` (`async throws(E)`), empty when there are none.
    var accessorEffects: String {
        let throwsText = switch throwsKind {
        case .none:
            ""

        case .untyped,
             .rethrows:
            "throws"

        case let .typed(error):
            "throws(\(error))"
        }
        return [isAsync ? "async" : "", throwsText].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// MARK: - Inheritance

/// The inheritance clause flattened: `P: Sendable & AnyObject, Parent` → `[Sendable, AnyObject, Parent]`.
func inheritedTypeNames(of proto: ProtocolDeclSyntax) -> [String] {
    (proto.inheritanceClause?.inheritedTypes ?? []).flatMap { inherited -> [String] in
        if let composition = inherited.type.as(CompositionTypeSyntax.self) {
            return composition.elements.map(\.type.trimmedDescription)
        }
        return [inherited.type.trimmedDescription]
    }
}

/// Drops a `Swift.` qualifier so stdlib protocols match by their bare name.
func unqualified(_ name: String) -> String {
    name.hasPrefix("Swift.") ? String(name.dropFirst("Swift.".count)) : name
}

func isClassBound(_ inherited: [String]) -> Bool {
    inherited.map(unqualified).contains { $0 == "AnyObject" || $0 == "class" }
}

func isSendableProtocol(_ inherited: [String]) -> Bool {
    inherited.map(unqualified).contains("Sendable")
}

// MARK: - Method parsing

/// Parses a method requirement into the closure-shaped model, or diagnoses why it can't be one.
func parseRequirementMethod(
    _ function: FunctionDeclSyntax,
    macro: ProtocolMacro,
    diagnose: (ProtocolMacroDiagnostic.Kind, Syntax) -> Void
) -> RequirementMethod? {
    let modifiers = Set(function.modifiers.map(\.name.text))
    if modifiers.contains("static") { diagnose(.staticRequirement, Syntax(function)); return nil }
    if modifiers.contains("mutating") { diagnose(.mutatingRequirement, Syntax(function)); return nil }

    let throwsKind = parseThrows(function.signature.effectSpecifiers?.throwsClause)
    if case .rethrows = throwsKind, macro == .witness {
        diagnose(.rethrowsRequirement, Syntax(function)); return nil
    }

    let returnType = function.signature.returnClause?.type.trimmedDescription ?? "Void"
    var params: [RequirementParam] = []
    for (index, param) in function.signature.parameterClause.parameters.enumerated() {
        guard let parsed = parseParam(param, index: index, macro: macro, diagnose: diagnose) else { return nil }
        params.append(parsed)
    }

    if macro == .witness,
       appears("Self", in: returnType) || params.contains(where: { appears("Self", in: $0.closureType) }) {
        diagnose(.selfRequirement, Syntax(function)); return nil
    }

    let erased: [RequirementParam]
    switch eraseGenerics(of: function, params: params, returnType: returnType) {
    case let .success(params):
        erased = params

    case let .failure(rejection):
        diagnose(rejection.kind, Syntax(function)); return nil
    }

    return RequirementMethod(
        baseName: function.name.text,
        params: erased,
        returnType: returnType,
        isAsync: function.signature.effectSpecifiers?.asyncSpecifier != nil,
        throwsKind: throwsKind,
        function: function
    )
}

private func parseParam(
    _ param: FunctionParameterSyntax,
    index: Int,
    macro: ProtocolMacro,
    diagnose: (ProtocolMacroDiagnostic.Kind, Syntax) -> Void
) -> RequirementParam? {
    let firstName = param.firstName.text
    let declaredInternal = (param.secondName ?? param.firstName).text
    let internalName = declaredInternal == "_" ? "p\(index)" : declaredInternal
    let typeText = param.type.trimmedDescription
    let isVariadic = param.ellipsis != nil

    if isVariadic, macro == .witness {
        diagnose(.variadicRequirement, Syntax(param)); return nil
    }

    var closureType = typeText
    if let opaque = param.type.as(SomeOrAnyTypeSyntax.self), opaque.someOrAnySpecifier.tokenKind == .keyword(.some) {
        // A single top-level `some P` is an anonymous generic parameter used exactly once: erase it.
        closureType = "any \(opaque.constraint.trimmedDescription)"
    }
    if containsOpaqueType(closureType) {
        diagnose(.nestedOpaqueParameter, Syntax(param)); return nil
    }
    if isVariadic { closureType = "[\(closureType)]" }

    let attributed = param.type.as(AttributedTypeSyntax.self)
    let isInout = attributed?.specifiers.contains { $0.trimmedDescription == "inout" } ?? false
    let isAutoclosure = attributed?.attributes.contains {
        $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "autoclosure"
    } ?? false

    let names = firstName == internalName ? firstName : "\(firstName) \(internalName)"
    return RequirementParam(
        label: firstName == "_" ? nil : firstName,
        internalName: internalName,
        signature: "\(names): \(typeText)\(isVariadic ? "..." : "")",
        closureType: closureType,
        isInout: isInout,
        isAutoclosure: isAutoclosure
    )
}

private func containsOpaqueType(_ type: String) -> Bool {
    appears("some", in: type)
}

/// Lowers each method generic parameter to its existential constraint. Only sound when the parameter
/// is constrained, absent from the return type, and is the whole type of exactly one parameter (so a
/// forwarded existential can be implicitly opened back into it).
private func eraseGenerics(
    of function: FunctionDeclSyntax,
    params: [RequirementParam],
    returnType: String
) -> Result<[RequirementParam], RequirementRejection> {
    guard let genericClause = function.genericParameterClause else { return .success(params) }
    var params = params
    let requirements = function.genericWhereClause?.requirements.map(\.requirement) ?? []

    for genericParam in genericClause.parameters {
        let name = genericParam.name.text
        var constraints = genericParam.inheritedType.map { [$0.trimmedDescription] } ?? []
        for requirement in requirements {
            if case let .conformanceRequirement(conformance) = requirement,
               conformance.leftType.trimmedDescription == name {
                constraints.append(conformance.rightType.trimmedDescription)
            } else if appears(name, in: requirement.trimmedDescription) {
                return .failure(RequirementRejection(kind: .nonErasableGeneric(name)))
            }
        }
        guard !constraints.isEmpty else { return .failure(RequirementRejection(kind: .unconstrainedGeneric)) }
        if appears(name, in: returnType) { return .failure(RequirementRejection(kind: .genericInReturn)) }

        let occurrences = params.map { occurrenceCount(of: name, in: $0.closureType) }.reduce(0, +)
        guard occurrences == 1,
              let index = params.firstIndex(where: { $0.closureType == name })
        else { return .failure(RequirementRejection(kind: .nonErasableGeneric(name))) }

        let param = params[index]
        params[index] = RequirementParam(
            label: param.label,
            internalName: param.internalName,
            signature: param.signature,
            closureType: "any \(constraints.joined(separator: " & "))",
            isInout: param.isInout,
            isAutoclosure: param.isAutoclosure
        )
    }
    return .success(params)
}

/// Why a requirement can't become a closure.
struct RequirementRejection: Error {
    let kind: ProtocolMacroDiagnostic.Kind
}

func parseThrows(_ clause: ThrowsClauseSyntax?) -> ThrowsKind {
    guard let clause else { return .none }
    if clause.throwsSpecifier.tokenKind == .keyword(.rethrows) { return .rethrows }
    return clause.type.map { .typed($0.trimmedDescription) } ?? .untyped
}

// MARK: - Property parsing

/// Parses a property requirement (`var x: T { get }`, `{ get set }`, `{ get async throws }`).
func parseRequirementProperty(
    _ variable: VariableDeclSyntax,
    macro: ProtocolMacro,
    diagnose: (ProtocolMacroDiagnostic.Kind, Syntax) -> Void
) -> RequirementProperty? {
    if variable.modifiers.contains(where: { $0.name.text == "static" }) {
        diagnose(.staticRequirement, Syntax(variable)); return nil
    }
    guard let binding = variable.bindings.first,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmedDescription
    else { return nil }

    if macro == .witness, appears("Self", in: type) {
        diagnose(.selfRequirement, Syntax(variable)); return nil
    }

    var accessors: [AccessorDeclSyntax] = []
    if case let .accessors(list) = binding.accessorBlock?.accessors { accessors = Array(list) }
    let getter = accessors.first { $0.accessorSpecifier.text == "get" }
    return RequirementProperty(
        name: name,
        type: type,
        isSettable: accessors.contains { $0.accessorSpecifier.text == "set" },
        isAsync: getter?.effectSpecifiers?.asyncSpecifier != nil,
        throwsKind: parseThrows(getter?.effectSpecifiers?.throwsClause)
    )
}

// MARK: - Overload disambiguation

/// One field name per method: the base name when it's unique, else the base name plus the argument
/// labels (`fetchWithId`), else plus the labels and parameter types (`fetchWithIdInt`). `nil` marks a
/// method still indistinguishable after that (e.g. overloads differing only in return type).
func disambiguatedNames(_ methods: [RequirementMethod]) -> [String?] {
    let byLabels = resolveCollisions(methods.map(\.baseName), methods) { method in
        method.baseName + "With" + method.params.map { ($0.label ?? typeToken($0.closureType)).capitalizedFirst }.joined(separator: "And")
    }
    let byTypes = resolveCollisions(byLabels, methods) { method in
        method.baseName + "With" + method.params
            .map { ($0.label ?? "").capitalizedFirst + typeToken($0.closureType).capitalizedFirst }
            .joined(separator: "And")
    }
    let counts = Dictionary(byTypes.map { ($0, 1) }, uniquingKeysWith: +)
    return byTypes.map { counts[$0, default: 0] > 1 ? nil : $0 }
}

private func resolveCollisions(
    _ names: [String],
    _ methods: [RequirementMethod],
    rename: (RequirementMethod) -> String
) -> [String] {
    let counts = Dictionary(names.map { ($0, 1) }, uniquingKeysWith: +)
    return zip(names, methods).map { name, method in counts[name, default: 0] > 1 ? rename(method) : name }
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

func associatedTypes(of proto: ProtocolDeclSyntax) -> [(name: String, constraint: String?)] {
    proto.memberBlock.members.compactMap { member in
        guard let assoc = member.decl.as(AssociatedTypeDeclSyntax.self) else { return nil }
        let constraint = assoc.inheritanceClause?.inheritedTypes
            .map(\.type.trimmedDescription).joined(separator: " & ")
        return (assoc.name.text, constraint)
    }
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

/// The access of a generated witness/mock: the protocol's own (`open` → `public`, as structs can't be `open`).
func witnessAccess(_ modifiers: DeclModifierListSyntax) -> AccessLevel {
    let access = declaredAccessLevel(from: modifiers)
    return access == .open ? .public : access
}

/// Whole-identifier check: does `name` appear as a standalone token in `text`?
func appears(_ name: String, in text: String) -> Bool {
    occurrenceCount(of: name, in: text) > 0
}

/// How many times identifier `name` appears as a standalone token in `text`.
func occurrenceCount(of name: String, in text: String) -> Int {
    let chars = Array(text)
    let target = Array(name)
    var count = 0
    var index = 0
    while index < chars.count {
        if isIdentifierToken(target, in: chars, at: index) {
            count += 1
            index += target.count
        } else {
            index += 1
        }
    }
    return count
}

/// Replace standalone occurrences of identifier `name` with `replacement`, respecting
/// identifier boundaries so `T` doesn't match inside `Tally`.
func substitute(_ name: String, with replacement: String, in text: String) -> String {
    let chars = Array(text)
    let target = Array(name)
    var result = ""
    var index = 0
    while index < chars.count {
        if isIdentifierToken(target, in: chars, at: index) {
            result += replacement
            index += target.count
        } else {
            result.append(chars[index])
            index += 1
        }
    }
    return result
}

private func isIdentifierToken(_ target: [Character], in chars: [Character], at index: Int) -> Bool {
    func isIdentifierChar(_ char: Character) -> Bool { char.isLetter || char.isNumber || char == "_" }
    guard !target.isEmpty, index + target.count <= chars.count, Array(chars[index..<(index + target.count)]) == target else {
        return false
    }
    let leftBoundary = index == 0 || !isIdentifierChar(chars[index - 1])
    let rightBoundary = index + target.count == chars.count || !isIdentifierChar(chars[index + target.count])
    return leftBoundary && rightBoundary
}

extension String {
    var capitalizedFirst: String { isEmpty ? self : prefix(1).uppercased() + dropFirst() }
    var lowercasedFirst: String { isEmpty ? self : prefix(1).lowercased() + dropFirst() }
}

// MARK: - Diagnostics

struct ProtocolMacroDiagnostic: DiagnosticMessage {
    enum Kind {
        case notAProtocol
        case staticRequirement
        case mutatingRequirement
        case initRequirement
        case subscriptRequirement
        case unconstrainedGeneric
        case genericInReturn
        case nonErasableGeneric(String)
        case nestedOpaqueParameter
        case selfRequirement
        case variadicRequirement
        case rethrowsRequirement
        case overloadCollision(String)
        case inheritanceUnsupported
        case unsupportedParent(String)
    }

    let macro: ProtocolMacro
    let kind: Kind

    var message: String {
        let name = "@\(macro.rawValue)"
        return switch kind {
        case .notAProtocol:
            "\(name) can only be applied to protocols"

        case .staticRequirement:
            "\(name) can't handle `static` requirements (a value witness has no Self)"

        case .mutatingRequirement:
            "\(name) can't handle `mutating` requirements"

        case .initRequirement:
            "\(name) can't handle `init` requirements"

        case .subscriptRequirement:
            "\(name) can't handle `subscript` requirements"

        case .unconstrainedGeneric:
            "\(name) can't handle a method with an unconstrained generic parameter "
                + "(no protocol/class constraint to erase to `any`). Add a constraint or remove the requirement."

        case .genericInReturn:
            "\(name) can't handle a method whose generic parameter appears in the return type "
                + "(e.g. `decode<T>(_: T.Type) -> T`) — it can't be lowered to an existential."

        case let .nonErasableGeneric(generic):
            "\(name) can only erase generic parameter '\(generic)' to `any` when it is the whole type of exactly "
                + "one parameter (not nested like `[\(generic)]`, repeated, or constrained by a `where` same-type requirement)."

        case .nestedOpaqueParameter:
            "\(name) can only erase `some P` when it is the parameter's whole type; a nested `some` "
                + "(e.g. `[some P]`, `(some P) -> Void`) can't be lowered to an existential."

        case .selfRequirement:
            "\(name) can't handle requirements that mention `Self` — inside the generated struct `Self` "
                + "would mean the witness, not the conforming type."

        case .variadicRequirement:
            "\(name) can't handle variadic parameters — a closure can't forward an array back into a variadic call. "
                + "Take an array parameter instead."

        case .rethrowsRequirement:
            "\(name) can't handle `rethrows` requirements — a stored closure can't be `rethrows`. "
                + "Declare the requirement `throws` (or with a typed `throws(E)`)."

        case let .overloadCollision(method):
            "\(name) can't give '\(method)' a unique name: its overloads have the same argument labels and "
                + "parameter types (they differ only in return type or effects). Rename one of them."

        case .inheritanceUnsupported:
            "\(name) can't mock a protocol that inherits another protocol — the macro can't see the parent's "
                + "requirements to synthesise them. Flatten the protocol or conform the inherited part by hand."

        case let .unsupportedParent(parent):
            "\(name) can't compose parent protocol '\(parent)': it is generic or has associated types, so its "
                + "witness can't be named here. Flatten the requirements you need into this protocol."
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(macro.rawValue).\(kind)") }
    var severity: DiagnosticSeverity { .error }
}
