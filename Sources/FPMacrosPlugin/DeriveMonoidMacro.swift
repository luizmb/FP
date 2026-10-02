// SPDX-License-Identifier: Apache-2.0
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Shared struct-field parsing

/// The fields of the struct's memberwise initialiser, for the product macros (`@DeriveMonoid`, `@Iso`).
/// Skips `static`/`lazy`/computed properties and initialised `let` constants (they aren't memberwise
/// parameters). Diagnoses — and returns `nil` for — non-struct and `private` hosts, stored properties
/// whose type can't be read off the declaration, and structs with no fields at all.
func productFields(
    of declaration: some DeclGroupSyntax,
    macro: String,
    node: AttributeSyntax,
    context: some MacroExpansionContext
) -> (structDecl: StructDeclSyntax, fields: [StoredProperty])? {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
        context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.notAStruct(macro)))
        return nil
    }
    if rejectPrivateHost(structDecl.modifiers, macro: macro, kind: "structs", node: node, context: context) {
        return nil
    }
    let scan = scanStoredProperties(of: structDecl)
    for untyped in scan.untyped {
        context.diagnose(Diagnostic(
            node: untyped.binding,
            message: ProductMacroDiagnostic.cannotInferType(macro, name: untyped.name)
        ))
    }
    guard scan.untyped.isEmpty else { return nil }
    let fields = scan.properties.filter(\.isInitParam)
    guard !fields.isEmpty else {
        context.diagnose(Diagnostic(node: node, message: ProductMacroDiagnostic.noStoredFields(macro)))
        return nil
    }
    return (structDecl, fields)
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
        guard let (structDecl, fields) = productFields(of: declaration, macro: "@DeriveMonoid", node: node, context: context)
        else { return [] }

        let access = witnessAccess(structDecl.modifiers)
        let name = type.trimmedDescription
        let genericParams = structDecl.genericParameterClause?.parameters.map(\.name.text) ?? []
        let whereClause = genericParams.isEmpty
            ? ""
            : " where " + genericParams.map { "\($0): CoreFP.Monoid" }.joined(separator: ", ")

        let combineArgs = fields
            .map { "\($0.name): \(metatypeSpelling($0.type)).combine(lhs.\($0.name), rhs.\($0.name))" }
            .joined(separator: ", ")
        let identityArgs = fields
            .map { "\($0.name): \(metatypeSpelling($0.type)).identity" }
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

/// A type spelled so `.combine` / `.identity` can follow it: sugared types (`T?`, `[T]`) are fine as
/// they are, anything else that isn't a plain nominal path is parenthesised.
private func metatypeSpelling(_ type: String) -> String {
    let isPlainPath = type.allSatisfy { $0.isLetter || $0.isNumber || "_.<>, ".contains($0) }
    return isPlainPath ? type : "(\(type))"
}

// MARK: - Diagnostics

enum ProductMacroDiagnostic: DiagnosticMessage {
    case notAStruct(String)
    case noStoredFields(String)
    case cannotInferType(String, name: String)

    var message: String {
        switch self {
        case let .notAStruct(macro):
            "\(macro) can only be applied to structs"

        case let .noStoredFields(macro):
            "\(macro) needs at least one stored property with an explicit type"

        case let .cannotInferType(macro, name):
            "\(macro) can't read the type of stored property '\(name)'. "
                + "Add an explicit type annotation (e.g. `var \(name): SomeType = ...`)."
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .notAStruct:
            .init(domain: "FPMacrosPlugin", id: "Product.notAStruct")

        case .noStoredFields:
            .init(domain: "FPMacrosPlugin", id: "Product.noStoredFields")

        case .cannotInferType:
            .init(domain: "FPMacrosPlugin", id: "Product.cannotInferType")
        }
    }

    var severity: DiagnosticSeverity { .error }
}
