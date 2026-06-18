// SPDX-License-Identifier: Apache-2.0
import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Access levels

enum AccessLevel: Int, Comparable {
    case `private` = 0, `fileprivate`, `internal`, package, `public`, open

    var keyword: String {
        switch self {
        case .private:
            "private"

        case .fileprivate:
            "fileprivate"

        case .internal:
            "internal"

        case .package:
            "package"

        case .public:
            "public"

        case .open:
            "open"
        }
    }

    /// Emit the keyword followed by a space, except for `.internal` which is the
    /// implicit default and should be omitted to avoid noise.
    var prefix: String { self == .internal ? "" : "\(keyword) " }

    static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

private func explicitAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel? {
    for modifier in modifiers {
        switch modifier.name.text {
        case "open":
            return .open

        case "public":
            return .public

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
    return nil
}

private func declaredAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel {
    explicitAccessLevel(from: modifiers) ?? .internal
}

// MARK: - Property model

struct StoredProperty {
    let name: String
    let type: String
    let isLet: Bool
    let defaultValue: String?
    /// `nil` when the property has no explicit access modifier.
    let explicitAccess: AccessLevel?

    /// `let x = v` → immutable constant, excluded from init and lens
    var isConstant: Bool { isLet && defaultValue != nil }
    var isInitParam: Bool { !isConstant }
    var hasLens: Bool { !isConstant }
}

// MARK: - Option parsing

private func parseEmit(from node: AttributeSyntax) -> LensesEmitFlags {
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        let firstArg = args.first,
        firstArg.label == nil,
        let member = firstArg.expression.as(MemberAccessExprSyntax.self)
    else {
        return .all
    }
    switch member.declName.baseName.text {
    case "initOnly":
        return LensesEmitFlags(emitInit: true, emitLenses: false)

    case "lensesOnly":
        return LensesEmitFlags(emitInit: false, emitLenses: true)

    case "all":
        return .all

    default:
        return .all
    }
}

struct LensesEmitFlags {
    var emitInit: Bool
    var emitLenses: Bool

    static var all: LensesEmitFlags { LensesEmitFlags(emitInit: true, emitLenses: true) }
}

private func parseInitAccess(from node: AttributeSyntax) -> AccessLevel {
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        let arg = args.first(where: { $0.label?.text == "init" }),
        let member = arg.expression.as(MemberAccessExprSyntax.self)
    else { return .internal }

    switch member.declName.baseName.text {
    case "private":
        return .private

    case "internal":
        return .internal

    case "package":
        return .package

    case "public":
        return .public

    default:
        return .internal
    }
}

// MARK: - Macro

public struct LensesMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: LensesDiagnostic.notAStruct))
            return []
        }

        let structAccess = declaredAccessLevel(from: structDecl.modifiers)

        // Reject `private` hosts. `private` is the only declared access where Swift's
        // type-reference rules block the struct namespace from being constructed and read
        // outside the host's body. `fileprivate` is functionally equivalent at file scope.
        guard structAccess != .private else {
            context.diagnose(Diagnostic(node: node, message: LensesDiagnostic.privateHostUnsupported))
            return []
        }

        let structName = structDecl.name.trimmed.text
        let isGeneric = structDecl.genericParameterClause != nil
        let initAccess = parseInitAccess(from: node)
        let flags = parseEmit(from: node)
        let properties = collectProperties(from: structDecl, context: context)
        let initParams = properties.filter(\.isInitParam)
        let lensProps = properties
            .filter(\.hasLens)
            .filter { prop in
                // Skip only when property has an *explicit* access modifier that is lower
                // than the struct's. Unmarked properties (no modifier) mirror the struct
                // and are kept.
                guard let explicit = prop.explicitAccess else { return true }
                return !(explicit < structAccess)
            }
        let skippedProps = properties
            .filter(\.hasLens)
            .filter { prop in !lensProps.contains(where: { $0.name == prop.name }) }

        for skipped in skippedProps {
            context.diagnose(Diagnostic(
                node: node,
                message: LensesDiagnostic.skippedProperty(
                    name: skipped.name,
                    propertyAccess: (skipped.explicitAccess ?? .internal).keyword,
                    structAccess: structAccess.keyword
                )
            ))
        }

        var members: [DeclSyntax] = []

        if flags.emitInit,
           !hasConflictingInit(in: structDecl, params: initParams) {
            members.append(makeInit(access: initAccess, structAccess: structAccess, params: initParams))
        }

        if flags.emitLenses {
            members.append(makeLensesStruct(
                structName: structName,
                access: structAccess,
                lensProps: lensProps
            ))
            members.append(makeStaticLens(
                access: structAccess,
                isGeneric: isGeneric
            ))
            members.append(makeWithFunc(
                structName: structName,
                access: structAccess,
                initParams: initParams,
                withProps: lensProps
            ))
        }

        return members
    }
}

// MARK: - Helpers

private func hasConflictingInit(in structDecl: StructDeclSyntax, params: [StoredProperty]) -> Bool {
    let wantLabels = params.map(\.name)
    return structDecl.memberBlock.members.contains { member in
        guard let initDecl = member.decl.as(InitializerDeclSyntax.self) else { return false }
        let gotLabels = initDecl.signature.parameterClause.parameters.map(\.firstName.text)
        return gotLabels == wantLabels
    }
}

// MARK: - Parsing

private func collectProperties(
    from structDecl: StructDeclSyntax,
    context: some MacroExpansionContext
) -> [StoredProperty] {
    structDecl.memberBlock.members.flatMap { member -> [StoredProperty] in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return [] }

        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) }) {
            return []
        }

        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
            return []
        }

        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
        let explicitAccess = explicitAccessLevel(from: varDecl.modifiers)

        return varDecl.bindings.compactMap { binding -> StoredProperty? in
            guard binding.accessorBlock == nil else { return nil }
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }

            let defaultValue = binding.initializer?.value.trimmedDescription

            // `let x = v` with no explicit type annotation → immutable constant, skip
            if isLet, defaultValue != nil, binding.typeAnnotation == nil { return nil }

            // Resolve type: explicit annotation, or inferred from a simple literal default
            let type: String
            if let annotated = binding.typeAnnotation?.type.trimmedDescription {
                type = annotated
            } else if let initializer = binding.initializer?.value,
                      let inferred = inferLiteralType(from: initializer) {
                type = inferred
            } else {
                if defaultValue != nil {
                    context.diagnose(Diagnostic(
                        node: binding,
                        message: LensesDiagnostic.cannotInferType(name: name)
                    ))
                }
                return nil
            }

            return StoredProperty(
                name: name,
                type: type,
                isLet: isLet,
                defaultValue: defaultValue,
                explicitAccess: explicitAccess
            )
        }
    }
}

private func inferLiteralType(from expr: ExprSyntax) -> String? {
    if expr.is(IntegerLiteralExprSyntax.self) { return "Int" }
    if expr.is(FloatLiteralExprSyntax.self) { return "Double" }
    if expr.is(StringLiteralExprSyntax.self) { return "String" }
    if expr.is(BooleanLiteralExprSyntax.self) { return "Bool" }
    return nil
}

// MARK: - Code generation

private func makeInit(access: AccessLevel, structAccess: AccessLevel, params: [StoredProperty]) -> DeclSyntax {
    // Init parameters reference the struct's properties (and thus the struct itself); the
    // init can't be declared more visible than the struct. Cap requested access to the
    // struct's access level.
    let effective = min(access, structAccess)
    let prefix = effective.prefix
    let paramList = params
        .map { p in p.defaultValue.map { "\(p.name): \(p.type) = \($0)" } ?? "\(p.name): \(p.type)" }
        .joined(separator: ", ")
    let body = params.map { "self.\($0.name) = \($0.name)" }.joined(separator: "; ")

    return DeclSyntax(stringLiteral: "\(prefix)init(\(paramList)) { \(body) }")
}

/// The `Lenses` struct holds one `Lens` per stored property as a stored field with a
/// default value. Using default values lets `Lenses()` work as a no-arg init regardless
/// of the host's access level (Swift synthesises `init()` for structs whose stored
/// properties all have defaults). The host's access propagates to the struct and its
/// fields so external callers can read `Host.lens.propertyName` at the appropriate level.
private func makeLensesStruct(
    structName: String,
    access: AccessLevel,
    lensProps: [StoredProperty]
) -> DeclSyntax {
    let prefix = access.prefix
    let fields = lensProps
        .map { prop -> String in
            let typeAnn = "CoreFP.Lens<\(structName), \(prop.type)>"
            let body = prop.isLet
                ? "CoreFP.lens(\\\(structName).\(prop.name)) { s, a in s.with(\(prop.name): a) }"
                : "CoreFP.lens(\\\(structName).\(prop.name))"
            return "\(prefix)let \(prop.name): \(typeAnn) = \(body)"
        }
        .joined(separator: "; ")
    return DeclSyntax(stringLiteral: "\(prefix)struct Lenses: Sendable { \(fields) }")
}

/// For non-generic hosts emit `static let lens = Lenses()` — a one-time allocation,
/// cached for the program's lifetime. For generic hosts Swift forbids `static let` in a
/// generic context, so we fall back to a computed `static var lens: Lenses { Lenses() }`
/// which allocates per access. Same call-site syntax in both cases.
private func makeStaticLens(access: AccessLevel, isGeneric: Bool) -> DeclSyntax {
    let prefix = access.prefix
    if isGeneric {
        return DeclSyntax(stringLiteral: "\(prefix)static var lens: Lenses { Lenses() }")
    }
    return DeclSyntax(stringLiteral: "\(prefix)static let lens = Lenses()")
}

/// Whether the macro should treat the property's type as `Optional`. Detected
/// syntactically: `T?`, `Optional<T>`, and `Swift.Optional<T>` all qualify.
private func isOptionalType(_ type: String) -> Bool {
    let trimmed = type.trimmingCharacters(in: .whitespaces)
    if trimmed.hasSuffix("?") { return true }
    if trimmed.hasPrefix("Optional<") { return true }
    if trimmed.hasPrefix("Swift.Optional<") { return true }
    return false
}

/// Generates the `with(...)` helper.
///
/// For non-Optional properties the parameter is `T? = nil` and the body uses `??` to
/// keep the current value when the caller omits the argument.
///
/// For Optional properties (`T?`), naive `T? = nil + ??` can't distinguish "caller
/// passed nil to clear" from "caller didn't pass anything". The helper instead uses a
/// double-Optional parameter (`T?? = .some(nil)`) with flipped semantics:
///
/// - default (omitted)               → parameter is `.some(.none)` → keep current
/// - `nil` literal at call site      → parameter is `.none`        → set to nil
/// - any explicit value `v`          → parameter is `.some(.some(v))` → set to v
///
/// This makes the common ergonomic cases — `with()`, `with(port: nil)`, `with(port: 7)`
/// — all do the obvious thing.
private func makeWithFunc(
    structName: String,
    access: AccessLevel,
    initParams: [StoredProperty],
    withProps: [StoredProperty]
) -> DeclSyntax {
    let prefix = access.prefix
    let params = withProps
        .map { p -> String in
            if isOptionalType(p.type) {
                return "\(p.name): \(p.type)? = .some(nil)"
            }
            return "\(p.name): \(p.type)? = nil"
        }
        .joined(separator: ", ")

    let withNames = Set(withProps.map(\.name))

    // For Optional properties we need a local `let newProp: T?` resolved via switch
    // (cannot be expressed inline with `??`); for non-Optional we keep the inline
    // `name ?? self.name`.
    let optionalProps = withProps.filter { isOptionalType($0.type) }
    let localBindings = optionalProps
        .map { p -> String in
            let local = "__new_\(p.name)"
            return """
            let \(local): \(p.type); switch \(p.name) { \
            case .none: \(local) = nil; \
            case .some(.none): \(local) = self.\(p.name); \
            case .some(.some(let v)): \(local) = v \
            }
            """
        }
        .joined(separator: "; ")
    let optionalNames = Set(optionalProps.map(\.name))

    let callArgs = initParams
        .map { p -> String in
            if optionalNames.contains(p.name) {
                return "\(p.name): __new_\(p.name)"
            }
            if withNames.contains(p.name) {
                return "\(p.name): \(p.name) ?? self.\(p.name)"
            }
            return "\(p.name): self.\(p.name)"
        }
        .joined(separator: ", ")

    let body = localBindings.isEmpty
        ? "\(structName)(\(callArgs))"
        : "\(localBindings); return \(structName)(\(callArgs))"

    return DeclSyntax(stringLiteral:
        "\(prefix)func with(\(params)) -> \(structName) { \(body) }")
}

// MARK: - Diagnostics

private enum LensesDiagnostic: DiagnosticMessage {
    case notAStruct
    case privateHostUnsupported
    case cannotInferType(name: String)
    case skippedProperty(name: String, propertyAccess: String, structAccess: String)

    var message: String {
        switch self {
        case .notAStruct:
            "@Lenses can only be applied to structs"

        case .privateHostUnsupported:
            "@Lenses cannot be applied to `private` structs. Change the declaration to `fileprivate`, "
                + "`internal`, or higher. (`private` is the only access level whose type-scope semantics "
                + "block the generated namespace; `fileprivate` is functionally identical at file scope.)"

        case let .cannotInferType(name):
            "Cannot infer type of '\(name)' — add an explicit type annotation (e.g., var \(name): SomeType = ...)"

        case let .skippedProperty(name, propAccess, structAccess):
            "Property '\(name)' excluded from lens namespace and with(...) because "
                + "its visibility (\(propAccess)) is lower than the struct's (\(structAccess))"
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }

    var severity: DiagnosticSeverity {
        switch self {
        case .notAStruct,
             .privateHostUnsupported:
            .error

        case .cannotInferType:
            .warning

        case .skippedProperty:
            .note
        }
    }
}
