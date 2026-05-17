import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Case model

struct CaseInfo {
    let name: String
    let params: [ParamInfo]

    struct ParamInfo {
        let label: String?
        let type: String
    }

    var focusType: String {
        switch params.count {
        case 0: return "Void"
        case 1: return params[0].type
        default: return "(\(params.map(\.type).joined(separator: ", ")))"
        }
    }

    func previewBody(enumName: String) -> String {
        switch params.count {
        case 0:
            return "(_ s: \(enumName)) in guard case .\(name) = s else { return nil }; return ()"
        case 1:
            return "(_ s: \(enumName)) in guard case .\(name)(let a) = s else { return nil }; return a"
        default:
            let bindings = (0..<params.count).map { "let v\($0)" }.joined(separator: ", ")
            let tuple    = (0..<params.count).map { "v\($0)" }.joined(separator: ", ")
            return "(_ s: \(enumName)) in guard case .\(name)(\(bindings)) = s else { return nil }; return (\(tuple))"
        }
    }

    func reviewExpr(enumName: String) -> String {
        switch params.count {
        case 0:
            return "{ (_: Void) in \(enumName).\(name) }"
        case 1:
            return "\(enumName).\(name)"
        default:
            let args = params
                .enumerated()
                .map { i, p in "\(p.label.map { "\($0): " } ?? "")t.\(i)" }
                .joined(separator: ", ")
            return "{ (t: \(focusType)) in \(enumName).\(name)(\(args)) }"
        }
    }
}

// MARK: - Macro

public struct PrismsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: PrismsDiagnostic.notAnEnum))
            return []
        }

        let enumName = enumDecl.name.trimmed.text
        let cases = collectCases(from: enumDecl)

        return [makePrismEnum(enumName: enumName, cases: cases)]
            + cases.map { makeComputedProperty(info: $0) }
            + [makeCasesEnum(enumName: enumName, cases: cases), makeIsFunc(cases: cases)]
    }
}

// MARK: - Parsing

private func collectCases(from enumDecl: EnumDeclSyntax) -> [CaseInfo] {
    enumDecl.memberBlock.members.flatMap { member -> [CaseInfo] in
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }
        return caseDecl.elements.map { element in
            let params = element.parameterClause?.parameters.map { param in
                CaseInfo.ParamInfo(
                    label: param.firstName?.text,
                    type: param.type.trimmedDescription
                )
            } ?? []
            return CaseInfo(name: element.name.text, params: params)
        }
    }
}

// MARK: - Code generation

private func makePrismEnum(enumName: String, cases: [CaseInfo]) -> DeclSyntax {
    let decls = cases
        .map { info in
            let typeAnnotation = "CoreFP.Prism<\(enumName), \(info.focusType)>"
            let preview = "{ \(info.previewBody(enumName: enumName)) }"
            let review = info.reviewExpr(enumName: enumName)
            return "static let \(info.name): \(typeAnnotation) = CoreFP.prism(preview: \(preview), review: \(review))"
        }
        .joined(separator: "; ")

    return DeclSyntax(stringLiteral: "enum prism { \(decls) }")
}

private func makeComputedProperty(info: CaseInfo) -> DeclSyntax {
    DeclSyntax(stringLiteral: "var \(info.name): \(info.focusType)? { Self.prism.\(info.name).preview(self) }")
}

private func makeCasesEnum(enumName: String, cases: [CaseInfo]) -> DeclSyntax {
    guard !cases.isEmpty else {
        return DeclSyntax(stringLiteral: """
            enum cases: CaseIterable { \
            func matches(_ value: \(enumName)) -> Bool { false } \
            }
            """)
    }
    let caseDeclarations = "case " + cases.map(\.name).joined(separator: ", ")
    let matchClauses = cases
        .map { info in "case (.\(info.name), .\(info.name)): return true" }
        .joined(separator: "; ")
    let defaultClause = cases.count == 1 ? "" : "; default: return false"
    return DeclSyntax(stringLiteral: """
        enum cases: CaseIterable { \
        \(caseDeclarations); \
        func matches(_ value: \(enumName)) -> Bool { switch (self, value) { \(matchClauses)\(defaultClause) } } \
        }
        """)
}

private func makeIsFunc(cases: [CaseInfo]) -> DeclSyntax {
    if cases.isEmpty {
        return DeclSyntax(stringLiteral: "func `is`(_ c: cases) -> Bool { false }")
    }
    return DeclSyntax(stringLiteral: "func `is`(_ c: cases) -> Bool { c.matches(self) }")
}

// MARK: - Diagnostics

private enum PrismsDiagnostic: DiagnosticMessage {
    case notAnEnum

    var message: String {
        switch self {
        case .notAnEnum: return "@Prisms can only be applied to enums"
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }
    var severity: DiagnosticSeverity { .error }
}
