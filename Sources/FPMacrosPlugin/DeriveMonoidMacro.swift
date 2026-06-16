import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Shared struct-field parsing

struct StoredField {
    let name: String
    let type: String
}

/// Stored (name, type) properties of a struct — skips `static`/`lazy`/computed and any binding
/// without an explicit type annotation.
func storedFields(of structDecl: StructDeclSyntax) -> [StoredField] {
    structDecl.memberBlock.members.flatMap { member -> [StoredField] in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return [] }
        let modifiers = Set(varDecl.modifiers.map(\.name.text))
        if modifiers.contains("static") || modifiers.contains("lazy") { return [] }
        return varDecl.bindings.compactMap { binding -> StoredField? in
            guard binding.accessorBlock == nil,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = binding.typeAnnotation?.type.trimmedDescription
            else { return nil }
            return StoredField(name: name, type: type)
        }
    }
}

// MARK: - @DeriveMonoid

public struct DeriveMonoidMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.notAStruct("@DeriveMonoid")))
            return []
        }
        let fields = storedFields(of: structDecl)
        guard !fields.isEmpty else {
            context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.noStoredFields("@DeriveMonoid")))
            return []
        }

        let access = witnessAccess(structDecl.modifiers)
        let name = type.trimmedDescription
        let genericParams = structDecl.genericParameterClause?.parameters.map(\.name.text) ?? []
        let whereClause = genericParams.isEmpty
            ? ""
            : " where " + genericParams.map { "\($0): CoreFP.Monoid" }.joined(separator: ", ")

        let combineArgs = fields
            .map { "\($0.name): \($0.type).combine(lhs.\($0.name), rhs.\($0.name))" }
            .joined(separator: ", ")
        let identityArgs = fields
            .map { "\($0.name): \($0.type).identity" }
            .joined(separator: ", ")

        let ext: DeclSyntax = """
        extension \(raw: name): CoreFP.Monoid\(raw: whereClause) {
            \(raw: access.prefix)static func combine(_ lhs: \(raw: name), _ rhs: \(raw: name)) -> \(raw: name) {
                \(raw: name)(\(raw: combineArgs))
            }
            \(raw: access.prefix)static var identity: \(raw: name) { \(raw: name)(\(raw: identityArgs)) }
        }
        """
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

// MARK: - Diagnostics

enum ProductMacroDiagnostic: DiagnosticMessage {
    case notAStruct(String)
    case noStoredFields(String)

    var message: String {
        switch self {
        case .notAStruct(let macro):    "\(macro) can only be applied to structs"
        case .noStoredFields(let macro): "\(macro) needs at least one stored property with an explicit type"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .notAStruct:     .init(domain: "FPMacrosPlugin", id: "Product.notAStruct")
        case .noStoredFields: .init(domain: "FPMacrosPlugin", id: "Product.noStoredFields")
        }
    }

    var severity: DiagnosticSeverity { .error }
}
