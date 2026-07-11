// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - @ApplyOptics — recursive optics via a two-macro cycle

//
// `@ApplyOptics(recursively: true)` applies `@Lenses` (structs) / `@Prisms` (enums) to a type AND every
// nested struct/enum at any depth, from a single annotation. Each level's optics come from that level's
// own `member` role — in its own primary declaration — so output is identical to hand-writing
// `@Lenses`/`@Prisms` (proper memberwise inits, simple names, no nested-type extensions).
//
// Recursion mechanism: Swift refuses to re-run a memberAttribute macro on an attribute IT added — but
// only checks the *immediate* adder. So two macros that stamp EACH OTHER (`ApplyOptics` ⇄ the hidden
// `_ApplyOpticsRelay`) recurse to arbitrary depth: at every hop the applied macro differs from the one
// that added it. The two share one implementation (`CyclicOpticsMacro`) and differ only in which
// attribute they relay next.
//
// Per-node rules: `@NoOptics` cuts a subtree; a nested `@ApplyOptics` re-roots one (its own cycle takes
// over); a manual `@Lenses`/`@Prisms` overrides generation for that node while the cycle still recurses
// past it; a caseless namespace enum gets no prisms but is still recursed into; `private` types skip.

protocol CyclicOpticsMacro: MemberMacro, ExtensionMacro, MemberAttributeMacro {
    /// The attribute this macro stamps on nested types to continue the cycle (the *other* macro's name).
    static var relayAttributeName: String { get }
}

extension CyclicOpticsMacro {
    /// Generates this type's own optics (struct → lenses, enum → prisms).
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let config = ApplyOpticsConfig(node: node)
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            guard !hasAttribute("Lenses", on: structDecl.attributes) else { return [] } // manual override owns it
            return generateLensMembers(
                structDecl: structDecl,
                flags: config.lensFlags,
                initAccess: config.initAccess,
                node: node,
                context: context
            )
        }
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            guard !collectCases(from: enumDecl).isEmpty else { return [] } // caseless namespace enum: no prisms
            guard !hasAttribute("Prisms", on: enumDecl.attributes) else { return [] }
            return generatePrismMembers(enumDecl: enumDecl, flags: config.prismFlags, node: node, context: context)
        }
        return []
    }

    /// The enum `Prismatic` conformance — a self-extension of the attached type (the compiler supplies
    /// its qualified name), never an extension of a nested type.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self),
              !collectCases(from: enumDecl).isEmpty,
              !hasAttribute("Prisms", on: enumDecl.attributes)
        else { return [] }
        return try prismaticExtensionDecls(
            enumDecl: enumDecl,
            type: type,
            flags: ApplyOpticsConfig(node: node).prismFlags,
            protocols: protocols
        )
    }

    /// Relays the cycle's other macro onto nested struct/enum members, carrying the same options.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard ApplyOpticsConfig(node: node).recursively else { return [] }

        let attributes: AttributeListSyntax
        let modifiers: DeclModifierListSyntax
        if let structDecl = member.as(StructDeclSyntax.self) {
            attributes = structDecl.attributes
            modifiers = structDecl.modifiers
        } else if let enumDecl = member.as(EnumDeclSyntax.self) {
            attributes = enumDecl.attributes
            modifiers = enumDecl.modifiers
        } else {
            return []
        }

        // Opt-outs / re-roots / unusable types are left alone; a manual `@Lenses`/`@Prisms` is NOT — the
        // cycle must relay past it (generation is skipped there by the member role above).
        if hasAttribute("NoOptics", on: attributes) { return [] }
        if hasAttribute("ApplyOptics", on: attributes) { return [] }
        if hasAttribute(relayAttributeName, on: attributes) { return [] }
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) }) { return [] }

        // Relay the SAME options to the next macro in the cycle — swap only the attribute name.
        let relay = node
            .with(\.attributeName, TypeSyntax(IdentifierTypeSyntax(name: .identifier(relayAttributeName))))
            .trimmed
        return [relay]
    }
}

/// The user-facing macro. Stamps the hidden relay on nested types.
public struct ApplyOpticsMacro: CyclicOpticsMacro {
    public static let relayAttributeName = "_ApplyOpticsRelay"
}

/// The hidden partner. Stamps `@ApplyOptics` back — the two alternate to defeat memberAttribute
/// cycle-suppression and recurse to any depth. Not meant to be written by hand.
public struct ApplyOpticsRelayMacro: CyclicOpticsMacro {
    public static let relayAttributeName = "ApplyOptics"
}

// MARK: - @NoOptics (marker)

/// A pure marker — emits nothing. Its presence tells the cycle to skip a subtree entirely.
public struct NoOpticsMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] { [] }
}

// MARK: - Helpers

private func hasAttribute(_ name: String, on attributes: AttributeListSyntax) -> Bool {
    attributes.contains { element in
        guard let attribute = element.as(AttributeSyntax.self) else { return false }
        let attributeName = attribute.attributeName.trimmedDescription
        return attributeName == name || attributeName.hasSuffix(".\(name)")
    }
}

// MARK: - Option parsing

private struct ApplyOpticsConfig {
    let lensFlags: LensesEmitFlags
    let initAccess: AccessLevel
    let prismFlags: PrismsEmitFlags
    let recursively: Bool

    init(node: AttributeSyntax) {
        var emit = ".all"
        var initAccess = ".internal"
        var prisms = ".all"
        var recursively = false

        if let args = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in args {
                let expr = arg.expression.trimmedDescription
                switch arg.label?.text {
                case nil:
                    emit = expr // the single unlabeled positional = `emit`

                case "init":
                    initAccess = expr

                case "prisms":
                    prisms = expr

                case "recursively":
                    recursively = (expr == "true")

                default:
                    break
                }
            }
        }

        lensFlags = Self.lensFlags(fromEmit: emit)
        self.initAccess = Self.access(fromExpr: initAccess)
        prismFlags = Self.prismFlags(fromOptions: prisms)
        self.recursively = recursively
    }

    private static func lensFlags(fromEmit raw: String) -> LensesEmitFlags {
        switch raw {
        case ".initOnly":
            LensesEmitFlags(emitInit: true, emitLenses: false)

        case ".lensesOnly":
            LensesEmitFlags(emitInit: false, emitLenses: true)

        default:
            .all
        }
    }

    private static func access(fromExpr raw: String) -> AccessLevel {
        switch raw {
        case ".private":
            .private

        case ".package":
            .package

        case ".public":
            .public

        default:
            .internal
        }
    }

    private static func prismFlags(fromOptions raw: String) -> PrismsEmitFlags {
        if raw.contains("all") { return .all }
        let prisms = raw.contains("prisms")
        let cases = raw.contains("cases")
        guard prisms || cases else { return .all }
        return PrismsEmitFlags(prisms: prisms, cases: cases)
    }
}
