import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct IsoMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.notAStruct("@Iso")))
            return []
        }
        let fields = storedFields(of: structDecl)
        guard !fields.isEmpty else {
            context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.noStoredFields("@Iso")))
            return []
        }

        let name = structDecl.name.trimmed.text
        let prefix = witnessAccess(structDecl.modifiers).prefix

        // `@Iso(Other.self)` — map field-by-field through both memberwise inits.
        if let target = targetTypeName(from: node) {
            let toOther = fields.map { "\($0.name): value.\($0.name)" }.joined(separator: ", ")
            let toSelf = fields.map { "\($0.name): value.\($0.name)" }.joined(separator: ", ")
            let decl = "\(prefix)static var iso: CoreFP.Iso<\(name), \(target)> { "
                + "CoreFP.iso(get: { value in \(target)(\(toOther)) }, reverseGet: { value in \(name)(\(toSelf)) }) }"
            return [DeclSyntax(stringLiteral: decl)]
        }

        // `@Iso` — single field collapses to its type; otherwise a tuple of the field types.
        if fields.count == 1 {
            let field = fields[0]
            let decl = "\(prefix)static var iso: CoreFP.Iso<\(name), \(field.type)> { "
                + "CoreFP.iso(get: { $0.\(field.name) }, reverseGet: { \(name)(\(field.name): $0) }) }"
            return [DeclSyntax(stringLiteral: decl)]
        }
        let tuple = "(" + fields.map(\.type).joined(separator: ", ") + ")"
        let getTuple = "(" + fields.map { "$0.\($0.name)" }.joined(separator: ", ") + ")"
        let reverseArgs = fields.enumerated().map { index, field in "\(field.name): $0.\(index)" }.joined(separator: ", ")
        let decl = "\(prefix)static var iso: CoreFP.Iso<\(name), \(tuple)> { "
            + "CoreFP.iso(get: { \(getTuple) }, reverseGet: { \(name)(\(reverseArgs)) }) }"
        return [DeclSyntax(stringLiteral: decl)]
    }
}

/// Extracts `Other` from an `@Iso(Other.self)` argument; `nil` for the no-argument form.
private func targetTypeName(from node: AttributeSyntax) -> String? {
    guard let args = node.arguments?.as(LabeledExprListSyntax.self), let first = args.first else { return nil }
    if let member = first.expression.as(MemberAccessExprSyntax.self), member.declName.baseName.text == "self" {
        return member.base?.trimmedDescription
    }
    return first.expression.trimmedDescription
}
