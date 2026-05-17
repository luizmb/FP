import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Access levels

enum AccessLevel: Int, Comparable {
    case `private` = 0, `fileprivate`, `internal`, `package`, `public`, open

    var keyword: String {
        switch self {
        case .private:     "private"
        case .fileprivate: "fileprivate"
        case .internal:    "internal"
        case .package:     "package"
        case .public:      "public"
        case .open:        "open"
        }
    }

    /// Emit the keyword followed by a space, except for `.internal` which is the
    /// implicit default and should be omitted to avoid noise.
    var prefix: String { self == .internal ? "" : "\(keyword) " }

    /// Prefix for inner members (static lets inside a namespace enum, conformance methods)
    /// of a nested namespace inside a host of this access level.
    ///
    /// For `private` / `fileprivate` hosts, omit the prefix — Swift caps the effective
    /// access via containment, and an explicit `private` would be stricter (scoped to the
    /// inner type) while `fileprivate` over-exposes types-referencing-host. Internal-
    /// default + containment-capping is the unique level that compiles cleanly.
    ///
    /// For `internal` and above, mirror the host's prefix so external module access works.
    var memberPrefix: String {
        switch self {
        case .private, .fileprivate: ""
        default:                     prefix
        }
    }

    static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

private func explicitAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel? {
    for modifier in modifiers {
        switch modifier.name.text {
        case "open":        return .open
        case "public":      return .public
        case "package":     return .package
        case "internal":    return .internal
        case "fileprivate": return .fileprivate
        case "private":     return .private
        default:            continue
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
    case "initOnly":   return LensesEmitFlags(emitInit: true, emitLenses: false)
    case "lensesOnly": return LensesEmitFlags(emitInit: false, emitLenses: true)
    case "all":        return .all
    default:           return .all
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
    case "private":  return .private
    case "internal": return .internal
    case "package":  return .package
    case "public":   return .public
    default:         return .internal
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

        let structName = structDecl.name.trimmed.text
        let structAccess = declaredAccessLevel(from: structDecl.modifiers)
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
            members.append(makeLensNamespace(
                structName: structName,
                access: structAccess,
                lensProps: lensProps
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
        let gotLabels = initDecl.signature.parameterClause.parameters.map { $0.firstName.text }
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
            if isLet && defaultValue != nil && binding.typeAnnotation == nil { return nil }

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
    if expr.is(FloatLiteralExprSyntax.self)   { return "Double" }
    if expr.is(StringLiteralExprSyntax.self)  { return "String" }
    if expr.is(BooleanLiteralExprSyntax.self) { return "Bool" }
    return nil
}

// MARK: - Code generation

private func makeInit(access: AccessLevel, structAccess: AccessLevel, params: [StoredProperty]) -> DeclSyntax {
    // Init parameters reference the struct's properties (and thus the struct itself); the
    // init can't be declared more visible than the struct. Cap requested access to the
    // struct's access level. Also use `memberPrefix` semantics for private/fileprivate
    // hosts so siblings inside the same scope can call the init.
    let effective = min(access, structAccess)
    let prefix: String
    switch effective {
    case .private, .fileprivate: prefix = ""
    default:                     prefix = effective.prefix
    }
    let paramList = params
        .map { p in p.defaultValue.map { "\(p.name): \(p.type) = \($0)" } ?? "\(p.name): \(p.type)" }
        .joined(separator: ", ")
    let body = params.map { "self.\($0.name) = \($0.name)" }.joined(separator: "; ")

    return DeclSyntax(stringLiteral: "\(prefix)init(\(paramList)) { \(body) }")
}

/// Emit the lens namespace as an `enum` with `static let` members.
///
/// We use `enum` (a namespace, no instances) instead of a `struct` value because Swift
/// forbids properties whose type references a less-accessible type — so a `static let
/// lens: Lenses` would fail when the host is `private`. `static let` inside an `enum`
/// namespace bypasses property-access rules and works at every access level.
///
/// We deliberately omit the explicit type annotation on each `static let` — letting
/// Swift infer the type avoids access-level checks against the declared annotation
/// that would otherwise reject internal-default static lets whose inferred type
/// references a private host.
private func makeLensNamespace(
    structName: String,
    access: AccessLevel,
    lensProps: [StoredProperty]
) -> DeclSyntax {
    let prefix = access.memberPrefix
    let decls = lensProps
        .map { prop -> String in
            if prop.isLet {
                return "\(prefix)static let \(prop.name) = CoreFP.lens(\\\(structName).\(prop.name)) { s, a in s.with(\(prop.name): a) }"
            } else {
                return "\(prefix)static let \(prop.name) = CoreFP.lens(\\\(structName).\(prop.name))"
            }
        }
        .joined(separator: "; ")
    return DeclSyntax(stringLiteral: "\(prefix)enum lens { \(decls) }")
}

private func makeWithFunc(
    structName: String,
    access: AccessLevel,
    initParams: [StoredProperty],
    withProps: [StoredProperty]
) -> DeclSyntax {
    let prefix = access.memberPrefix
    let params = withProps
        .map { p in "\(p.name): \(p.type)? = nil" }
        .joined(separator: ", ")
    let withNames = Set(withProps.map(\.name))
    let callArgs = initParams
        .map { p -> String in
            if withNames.contains(p.name) {
                return "\(p.name): \(p.name) ?? self.\(p.name)"
            }
            return "\(p.name): self.\(p.name)"
        }
        .joined(separator: ", ")
    return DeclSyntax(stringLiteral:
        "\(prefix)func with(\(params)) -> \(structName) { \(structName)(\(callArgs)) }"
    )
}

// MARK: - Diagnostics

private enum LensesDiagnostic: DiagnosticMessage {
    case notAStruct
    case cannotInferType(name: String)
    case skippedProperty(name: String, propertyAccess: String, structAccess: String)

    var message: String {
        switch self {
        case .notAStruct:
            "@Lenses can only be applied to structs"
        case .cannotInferType(let name):
            "Cannot infer type of '\(name)' — add an explicit type annotation (e.g., var \(name): SomeType = ...)"
        case .skippedProperty(let name, let propAccess, let structAccess):
            "Property '\(name)' excluded from lens namespace and with(...) because its visibility (\(propAccess)) is lower than the struct's (\(structAccess))"
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }

    var severity: DiagnosticSeverity {
        switch self {
        case .notAStruct, .cannotInferType: .warning
        case .skippedProperty:              .note
        }
    }
}
