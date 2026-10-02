// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

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
        return generateLensMembers(
            structDecl: structDecl,
            flags: parseEmit(from: node),
            initAccess: parseInitAccess(from: node),
            node: node,
            context: context
        )
    }
}

// MARK: - Sendable conformance

extension LensesMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        return try sendableExtensionDecls(
            structDecl: structDecl,
            type: type,
            flags: parseEmit(from: node),
            protocols: protocols
        )
    }
}

/// `CoreFP.lens` needs a `Sendable` host, which a `public` struct never gets implicitly. When the
/// compiler reports the host doesn't declare `Sendable` yet (it's in `protocols`) and lenses are
/// emitted, add `extension Host: Sendable {}` — for a generic host, conditional on the generic parameters
/// its stored properties mention (the same requirement Swift would infer implicitly).
func sendableExtensionDecls(
    structDecl: StructDeclSyntax,
    type: some TypeSyntaxProtocol,
    flags: LensesEmitFlags,
    protocols: [TypeSyntax]
) throws -> [ExtensionDeclSyntax] {
    guard explicitAccessLevel(from: structDecl.modifiers) != .private,
          flags.emitLenses,
          protocols.contains(where: { isProtocol("Sendable", $0) })
    else { return [] }
    let storedTypes = scanStoredProperties(of: structDecl).properties.map(\.type)
    let genericNames = (structDecl.genericParameterClause?.parameters.map(\.name.text) ?? [])
        .filter { name in storedTypes.contains { appears(name, in: $0) } }
    let whereClause = genericNames.isEmpty
        ? ""
        : " where " + genericNames.map { "\($0): Sendable" }.joined(separator: ", ")
    return [try ExtensionDeclSyntax("extension \(type.trimmed): Sendable\(raw: whereClause) {}")]
}

/// Whether a `conformingTo` entry names `name` (bare or `Swift.`-qualified).
func isProtocol(_ name: String, _ type: TypeSyntax) -> Bool {
    let text = type.trimmedDescription
    return text == name || text.hasSuffix(".\(name)")
}

/// The member-generation core of `@Lenses`, factored out so `@ApplyOptics` can drive it with its own
/// parsed options. Diagnostics anchor to `node`.
func generateLensMembers(
    structDecl: StructDeclSyntax,
    flags: LensesEmitFlags,
    initAccess: AccessLevel,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> [DeclSyntax] {
    let structAccess = declaredAccessLevel(from: structDecl.modifiers)

    // Reject `private` hosts. `private` is the only declared access where Swift's
    // type-reference rules block the struct namespace from being constructed and read
    // outside the host's body. `fileprivate` is functionally equivalent at file scope.
    guard structAccess != .private else {
        context.diagnose(Diagnostic(node: node, message: LensesDiagnostic.privateHostUnsupported))
        return []
    }

    let structName = structDecl.name.trimmed.text
    let scan = scanStoredProperties(of: structDecl)
    for untyped in scan.untyped {
        context.diagnose(Diagnostic(node: untyped.binding, message: LensesDiagnostic.cannotInferType(name: untyped.name)))
    }
    let properties = scan.properties
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
        members.append(DeclSyntax(stringLiteral: "\(structAccess.prefix)static var lens: Lenses { Lenses() }"))
        members.append(makeWithFunc(
            structName: structName,
            access: structAccess,
            initParams: initParams,
            // A `private(set)` property must not become writable through a `with(...)` that is more
            // visible than its setter.
            withProps: lensProps.filter { lensAccess(of: $0, structAccess: structAccess) >= structAccess }
        ))
    }

    return members
}

/// The access of a property's lens: the host's, capped by a restricted setter (`private(set)` →
/// `fileprivate`, the lowest level a `Lenses` member is still usable from the host's file).
private func lensAccess(of prop: StoredProperty, structAccess: AccessLevel) -> AccessLevel {
    guard let setter = prop.setterAccess else { return structAccess }
    return min(structAccess, max(setter, .fileprivate))
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

// MARK: - Code generation

private func makeInit(access: AccessLevel, structAccess: AccessLevel, params: [StoredProperty]) -> DeclSyntax {
    // Init parameters reference the struct's properties (and thus the struct itself); the
    // init can't be declared more visible than the struct. Cap requested access to the
    // struct's access level.
    let effective = min(access, structAccess)
    let prefix = effective.prefix
    let paramList = params
        .map { p -> String in
            // A function-typed parameter is stored, so it must be `@escaping` (Optional-wrapped
            // functions already escape implicitly).
            let type = isFunctionType(p.type) ? "@escaping \(p.type)" : p.type
            if let value = p.defaultValue { return "\(p.name): \(type) = \(value)" }
            // Optionals get an implicit `= nil` (matching Swift's own memberwise init, SE-0242), so a
            // caller can omit them without writing `= nil` on the property — which SwiftLint flags.
            if isOptionalType(p.type) { return "\(p.name): \(type) = nil" }
            return "\(p.name): \(type)"
        }
        .joined(separator: ", ")
    let body = params.map { "self.\($0.name) = \($0.name)" }.joined(separator: "; ")

    return DeclSyntax(stringLiteral: "\(prefix)init(\(paramList)) { \(body) }")
}

/// The `Lenses` struct holds one `Lens` per stored property as a stored field with a
/// default value. Using default values lets `Lenses()` work as a no-arg init regardless
/// of the host's access level (Swift synthesises `init()` for structs whose stored
/// properties all have defaults). The host's access propagates to the struct and its
/// fields so external callers can read `Host.lens.propertyName` at the appropriate level;
/// a field whose property restricts its setter is capped to that setter's access.
private func makeLensesStruct(
    structName: String,
    access: AccessLevel,
    lensProps: [StoredProperty]
) -> DeclSyntax {
    let fields = lensProps
        .map { prop -> String in
            let typeAnn = "CoreFP.Lens<\(structName), \(prop.type)>"
            let body = prop.isLet
                ? "CoreFP.lens(\\\(structName).\(prop.name)) { s, a in s.with(\(prop.name): a) }"
                : "CoreFP.lens(\\\(structName).\(prop.name))"
            return "\(lensAccess(of: prop, structAccess: access).prefix)let \(prop.name): \(typeAnn) = \(body)"
        }
        .joined(separator: "; ")
    return DeclSyntax(stringLiteral: "\(access.prefix)struct Lenses: Sendable { \(fields) }")
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
                return "\(p.name): \(optionalTypeString(p.type)) = .some(nil)"
            }
            return "\(p.name): \(optionalTypeString(p.type)) = nil"
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
