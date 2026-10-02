// SPDX-License-Identifier: Apache-2.0
import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Access levels

enum AccessLevel: Int, Comparable {
    case `private` = 0
    case `fileprivate`
    case `internal`
    case package
    case `public`
    case open

    init?(keyword: String) {
        switch keyword {
        case "private":
            self = .private

        case "fileprivate":
            self = .fileprivate

        case "internal":
            self = .internal

        case "package":
            self = .package

        case "public":
            self = .public

        case "open":
            self = .open

        default:
            return nil
        }
    }

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

/// The declaration's own access modifier. Modifiers with a detail (`private(set)`) restrict only the
/// setter, so they are not the declaration's access.
func explicitAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel? {
    modifiers
        .lazy
        .filter { $0.detail == nil }
        .compactMap { AccessLevel(keyword: $0.name.text) }
        .first
}

/// The setter restriction of a `private(set)` / `internal(set)` / … modifier, when present.
func setterAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel? {
    modifiers
        .lazy
        .filter { $0.detail?.detail.text == "set" }
        .compactMap { AccessLevel(keyword: $0.name.text) }
        .first
}

func declaredAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel {
    explicitAccessLevel(from: modifiers) ?? .internal
}

// MARK: - Stored property model

struct StoredProperty {
    let name: String
    let type: String
    let isLet: Bool
    let defaultValue: String?
    /// `nil` when the property has no explicit access modifier.
    let explicitAccess: AccessLevel?
    /// `nil` unless the property restricts its setter (`private(set)` etc.).
    let setterAccess: AccessLevel?

    /// `let x = v` → immutable constant, excluded from init and lens
    var isConstant: Bool { isLet && defaultValue != nil }
    var isInitParam: Bool { !isConstant }
    var hasLens: Bool { !isConstant }
}

/// A stored `var` whose type is neither annotated nor inferable from a literal default.
struct UntypedStoredProperty {
    let name: String
    let binding: PatternBindingSyntax
}

struct StoredPropertyScan {
    let properties: [StoredProperty]
    let untyped: [UntypedStoredProperty]
}

/// Every stored instance property of `structDecl`, in declaration order. Skips `static`, `lazy`, and
/// computed properties; property observers (`willSet`/`didSet`) still count as stored. In a multi-binding
/// declaration (`var a, b: Int`) an un-annotated, un-initialised binding takes the type of the next
/// annotated one, like Swift does. `T!` is spelled `T?`.
func scanStoredProperties(of structDecl: StructDeclSyntax) -> StoredPropertyScan {
    var properties: [StoredProperty] = []
    var untyped: [UntypedStoredProperty] = []

    for member in structDecl.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
              !varDecl.modifiers.contains(where: { [.keyword(.lazy), .keyword(.static), .keyword(.class)].contains($0.name.tokenKind) })
        else { continue }

        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
        let explicitAccess = explicitAccessLevel(from: varDecl.modifiers)
        let setterAccess = setterAccessLevel(from: varDecl.modifiers)
        let bindings = Array(varDecl.bindings)

        for (index, binding) in bindings.enumerated() {
            guard isStored(binding),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            let defaultValue = binding.initializer?.value.trimmedDescription

            // `let x = v` with no explicit type annotation → immutable constant, skip
            if isLet, defaultValue != nil, binding.typeAnnotation == nil { continue }

            guard let type = resolvedType(of: index, in: bindings) else {
                untyped.append(UntypedStoredProperty(name: name, binding: binding))
                continue
            }

            properties.append(StoredProperty(
                name: name,
                type: type,
                isLet: isLet,
                defaultValue: defaultValue,
                explicitAccess: explicitAccess,
                setterAccess: setterAccess
            ))
        }
    }
    return StoredPropertyScan(properties: properties, untyped: untyped)
}

/// `true` for a binding with no accessor block, or one made only of `willSet`/`didSet` observers.
func isStored(_ binding: PatternBindingSyntax) -> Bool {
    guard let accessorBlock = binding.accessorBlock else { return true }
    guard case let .accessors(accessors) = accessorBlock.accessors else { return false }
    return accessors.allSatisfy { ["willSet", "didSet"].contains($0.accessorSpecifier.text) }
}

private func resolvedType(of index: Int, in bindings: [PatternBindingSyntax]) -> String? {
    let binding = bindings[index]
    if let annotated = binding.typeAnnotation?.type {
        return normalizedType(annotated)
    }
    if let initializer = binding.initializer?.value {
        return inferLiteralType(from: initializer)
    }
    // `var a, b: Int` — `a` shares the type of the next annotated binding.
    return bindings[(index + 1)...]
        .lazy
        .compactMap { $0.typeAnnotation?.type }
        .first
        .map(normalizedType)
}

/// The type as written, except an implicitly-unwrapped `T!` becomes `T?` (IUO is only legal on a
/// declaration, not inside `Lens<S, T!>` or a tuple).
func normalizedType(_ type: TypeSyntax) -> String {
    if let iuo = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
        return optionalTypeString(iuo.wrappedType.trimmedDescription)
    }
    return type.trimmedDescription
}

private func inferLiteralType(from expr: ExprSyntax) -> String? {
    if expr.is(IntegerLiteralExprSyntax.self) { return "Int" }
    if expr.is(FloatLiteralExprSyntax.self) { return "Double" }
    if expr.is(StringLiteralExprSyntax.self) { return "String" }
    if expr.is(BooleanLiteralExprSyntax.self) { return "Bool" }
    return nil
}

// MARK: - Type-string helpers

/// The characters of `type` that sit outside any `()`, `[]` or `<>` nesting. The `>` of a
/// function arrow is not a closing bracket, so `->` survives at whatever level it appears.
func topLevelSkeleton(of type: String) -> String {
    var depth = 0
    var previous: Character = " "
    var skeleton = ""
    for char in type {
        let isArrowHead = char == ">" && previous == "-"
        if "([<".contains(char) {
            depth += 1
        } else if ")]>".contains(char), !isArrowHead {
            depth -= 1
        } else if depth == 0 {
            skeleton.append(char)
        }
        previous = char
    }
    return skeleton
}

/// `true` when `type` is a function type at the top level (`(A) -> B`, `@Sendable () -> B?`).
func isFunctionType(_ type: String) -> Bool {
    topLevelSkeleton(of: type).contains("->")
}

/// Spells `type` wrapped in `Optional` using the `?` sugar, parenthesising when appending `?`
/// directly would bind to the wrong part of the type: function types (`() -> Void?` returns an
/// optional), attributed types (`@Sendable ...`), existentials/opaque types (`any P?` is rejected)
/// and protocol compositions (`A & B?` makes only `B` optional).
func optionalTypeString(_ type: String) -> String {
    let trimmed = type.trimmingCharacters(in: .whitespaces)
    let skeleton = topLevelSkeleton(of: trimmed)
    let needsParentheses = skeleton.contains("->")
        || skeleton.contains("&")
        || trimmed.hasPrefix("@")
        || trimmed.hasPrefix("any ")
        || trimmed.hasPrefix("some ")
    return needsParentheses ? "(\(trimmed))?" : "\(trimmed)?"
}

/// Whether the macro should treat the property's type as `Optional`. Detected
/// syntactically: `T?`, `Optional<T>`, and `Swift.Optional<T>` all qualify.
func isOptionalType(_ type: String) -> Bool {
    let trimmed = type.trimmingCharacters(in: .whitespaces)
    // `() -> Int?` ends in `?` but is a function returning an Optional, not an Optional.
    if isFunctionType(trimmed) { return false }
    if trimmed.hasSuffix("?") { return true }
    if trimmed.hasPrefix("Optional<") { return true }
    if trimmed.hasPrefix("Swift.Optional<") { return true }
    return false
}

// MARK: - Shared diagnostics

/// Diagnostics shared by every macro that attaches to a host type.
enum HostDiagnostic: DiagnosticMessage {
    case privateHostUnsupported(macro: String, kind: String)

    var message: String {
        switch self {
        case let .privateHostUnsupported(macro, kind):
            "\(macro) cannot be applied to `private` \(kind). Change the declaration to `fileprivate`, "
                + "`internal`, or higher. (`private` is the only access level whose type-scope semantics "
                + "block the generated declarations; `fileprivate` is functionally identical at file scope.)"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .privateHostUnsupported:
            .init(domain: "FPMacrosPlugin", id: "Host.privateHostUnsupported")
        }
    }

    var severity: DiagnosticSeverity { .error }
}

/// `true` (after diagnosing) when `modifiers` declare the host `private`.
func rejectPrivateHost(
    _ modifiers: DeclModifierListSyntax,
    macro: String,
    kind: String,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> Bool {
    guard explicitAccessLevel(from: modifiers) == .private else { return false }
    context.diagnose(Diagnostic(node: node, message: HostDiagnostic.privateHostUnsupported(macro: macro, kind: kind)))
    return true
}
