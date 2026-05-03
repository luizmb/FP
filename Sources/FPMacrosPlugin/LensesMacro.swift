import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Property model

struct StoredProperty {
    let name: String
    let type: String
    let isLet: Bool
    let defaultValue: String?

    // `let x = v` → immutable constant, excluded from init and lens
    var isConstant: Bool { isLet && defaultValue != nil }
    var isInitParam: Bool { !isConstant }
    var hasLens: Bool { !isConstant }
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
        let access = parseAccess(from: node)
        let properties = collectProperties(from: structDecl, context: context)
        let initParams = properties.filter(\.isInitParam)
        let lensProps = properties.filter(\.hasLens)

        return [
            makeInit(access: access, params: initParams),
            makeLensEnum(structName: structName, access: access, initParams: initParams, lensProps: lensProps)
        ]
    }
}

// MARK: - Parsing

private func parseAccess(from node: AttributeSyntax) -> String {
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        let arg = args.first(where: { $0.label?.text == "init" }),
        let member = arg.expression.as(MemberAccessExprSyntax.self)
    else { return "" }

    let name = member.declName.baseName.text
    return name == "internal" ? "" : name
}

private func collectProperties(
    from structDecl: StructDeclSyntax,
    context: some MacroExpansionContext
) -> [StoredProperty] {
    structDecl.memberBlock.members.flatMap { member -> [StoredProperty] in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return [] }

        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) }) {
            return []
        }

        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)

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

            return StoredProperty(name: name, type: type, isLet: isLet, defaultValue: defaultValue)
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

private func makeInit(access: String, params: [StoredProperty]) -> DeclSyntax {
    let keyword = access.isEmpty ? "" : "\(access) "
    let paramList = params
        .map { p in p.defaultValue.map { "\(p.name): \(p.type) = \($0)" } ?? "\(p.name): \(p.type)" }
        .joined(separator: ", ")
    let body = params.map { "self.\($0.name) = \($0.name)" }.joined(separator: "; ")

    return DeclSyntax(stringLiteral: "\(keyword)init(\(paramList)) { \(body) }")
}

private func makeLensEnum(
    structName: String,
    access: String,
    initParams: [StoredProperty],
    lensProps: [StoredProperty]
) -> DeclSyntax {
    let keyword = access.isEmpty ? "" : "\(access) "

    let decls = lensProps
        .map { prop -> String in
            if prop.isLet {
                let args = initParams
                    .map { p in p.name == prop.name ? "\(p.name): a" : "\(p.name): s.\(p.name)" }
                    .joined(separator: ", ")
                return "\(keyword)static let \(prop.name) = CoreFP.lens(\\\(structName).\(prop.name)) { s, a in \(structName)(\(args)) }"
            } else {
                return "\(keyword)static let \(prop.name) = CoreFP.lens(\\\(structName).\(prop.name))"
            }
        }
        .joined(separator: "; ")

    return DeclSyntax(stringLiteral: "\(keyword)enum lens { \(decls) }")
}

// MARK: - Diagnostics

private enum LensesDiagnostic: DiagnosticMessage {
    case notAStruct
    case cannotInferType(name: String)

    var message: String {
        switch self {
        case .notAStruct:
            "@Lenses can only be applied to structs"
        case .cannotInferType(let name):
            "Cannot infer type of '\(name)' — add an explicit type annotation (e.g., var \(name): SomeType = ...)"
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }
    var severity: DiagnosticSeverity { .warning }
}
