import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Option parsing

struct PrismsEmitFlags {
    var prisms: Bool
    var properties: Bool
    var cases: Bool

    static var all: PrismsEmitFlags { PrismsEmitFlags(prisms: true, properties: true, cases: true) }

    var emitsPrismStruct: Bool { prisms || properties }
}

private func parseOptions(from node: AttributeSyntax) -> PrismsEmitFlags {
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        let firstArg = args.first
    else {
        return .all
    }

    let names = collectOptionNames(from: firstArg.expression)

    if names.contains("all") || names.isEmpty {
        return .all
    }

    let flags = PrismsEmitFlags(
        prisms: names.contains("prisms"),
        properties: names.contains("properties"),
        cases: names.contains("cases")
    )

    return flags
}

private func collectOptionNames(from expr: ExprSyntax) -> Set<String> {
    if let array = expr.as(ArrayExprSyntax.self) {
        return Set(array.elements.compactMap { element in
            element.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        })
    }
    if let member = expr.as(MemberAccessExprSyntax.self) {
        return [member.declName.baseName.text]
    }
    return []
}

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
        case 0: "Void"
        case 1: params[0].type
        default: "(\(params.map(\.type).joined(separator: ", ")))"
        }
    }

    private var bindings: String { (0..<params.count).map { "let v\($0)" }.joined(separator: ", ") }
    private var tuple: String    { (0..<params.count).map { "v\($0)" }.joined(separator: ", ") }
    private var reviewArgs: String {
        params
            .enumerated()
            .map { i, p in "\(p.label.map { "\($0): " } ?? "")t.\(i)" }
            .joined(separator: ", ")
    }

    func previewBody(enumName: String) -> String {
        switch params.count {
        case 0:
            "(_ s: \(enumName)) in guard case .\(name) = s else { return nil }; return ()"
        case 1:
            "(_ s: \(enumName)) in guard case .\(name)(let a) = s else { return nil }; return a"
        default:
            "(_ s: \(enumName)) in guard case .\(name)(\(bindings)) = s else { return nil }; return (\(tuple))"
        }
    }

    func reviewExpr(enumName: String) -> String {
        switch params.count {
        case 0:
            "{ (_: Void) in \(enumName).\(name) }"
        case 1:
            "\(enumName).\(name)"
        default:
            "{ (t: \(focusType)) in \(enumName).\(name)(\(reviewArgs)) }"
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
        let access = accessKeyword(from: enumDecl.modifiers)
        let cases = collectCases(from: enumDecl)
        let flags = parseOptions(from: node)

        var members: [DeclSyntax] = []

        if flags.emitsPrismStruct {
            members.append(makePrismNamespace(enumName: enumName, access: access, cases: cases))
        }

        if flags.properties {
            members.append(contentsOf: cases.map { makeComputedProperty(info: $0, access: access) })
        }

        if flags.cases {
            members.append(makeCasesEnum(enumName: enumName, access: access, cases: cases))
            members.append(makeIsFunc(access: access, hasCases: !cases.isEmpty))
        }

        return members
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

private func accessKeyword(from modifiers: DeclModifierListSyntax) -> String {
    for modifier in modifiers {
        let text = modifier.name.text
        switch text {
        case "open", "public", "package", "internal", "fileprivate", "private":
            return text
        default:
            continue
        }
    }
    return ""
}

private func accessPrefix(_ access: String) -> String {
    access.isEmpty ? "" : "\(access) "
}

/// Access prefix for inner members (fields, methods, typealiases) of a nested namespace.
///
/// For `private` / `fileprivate` enclosing types, omit the prefix — Swift caps the
/// effective access via containment, and an explicit `private` would be stricter (scoped
/// to the inner type) while `fileprivate` over-exposes types-referencing-host.
/// Internal-default + containment-capping is the unique level that compiles cleanly.
///
/// For `internal` (no modifier) or higher, mirror the host's prefix so external module
/// callers can access the generated members.
private func memberPrefix(for hostAccess: String) -> String {
    switch hostAccess {
    case "private", "fileprivate": ""
    default: accessPrefix(hostAccess)
    }
}

// MARK: - Code generation

/// Emit the prism namespace as an `enum` with `static let` members.
///
/// We use `enum` (a namespace, no instances) instead of a `struct` value because Swift
/// forbids properties whose type references a less-accessible type — so a `static let
/// prism: Prisms` would fail when the host is `private`. `static let` inside an `enum`
/// namespace bypasses property-access rules and works at every access level.
///
/// We deliberately omit the explicit type annotation on each `static let` — letting
/// Swift infer the type avoids access-level checks against the declared annotation
/// that would otherwise reject internal-default static lets whose inferred type
/// references a private host.
private func makePrismNamespace(enumName: String, access: String, cases: [CaseInfo]) -> DeclSyntax {
    let prefix = memberPrefix(for: access)
    let decls = cases
        .map { info in
            let preview = "{ \(info.previewBody(enumName: enumName)) }"
            let review = info.reviewExpr(enumName: enumName)
            return "\(prefix)static let \(info.name) = CoreFP.prism(preview: \(preview), review: \(review)) as CoreFP.Prism<\(enumName), \(info.focusType)>"
        }
        .joined(separator: "; ")
    return DeclSyntax(stringLiteral: "\(prefix)enum prism { \(decls) }")
}

private func makeComputedProperty(info: CaseInfo, access: String) -> DeclSyntax {
    let prefix = memberPrefix(for: access)
    return DeclSyntax(stringLiteral:
        "\(prefix)var \(info.name): \(info.focusType)? { Self.prism.\(info.name).preview(self) }"
    )
}

private func makeIsFunc(access: String, hasCases: Bool) -> DeclSyntax {
    let prefix = memberPrefix(for: access)
    if !hasCases {
        return DeclSyntax(stringLiteral: "\(prefix)func `is`(_ c: cases) -> Bool { false }")
    }
    return DeclSyntax(stringLiteral: "\(prefix)func `is`(_ c: cases) -> Bool { c.matches(self) }")
}

private func makeCasesEnum(enumName: String, access: String, cases: [CaseInfo]) -> DeclSyntax {
    let prefix = memberPrefix(for: access)
    // For private/fileprivate hosts, conform to plain `CaseIterable` only — Swift's
    // access rules forbid declaring a `typealias Subject = Host` (or a `matches` method
    // taking `Host`) at a high enough level to satisfy `CaseMatchable` when `Host` is
    // private. Public/internal hosts get the full `CaseMatchable` conformance, which
    // enables the polymorphic `HasCases` extension.
    let conformsToMatchable = !(access == "private" || access == "fileprivate")
    let protocolConformance = conformsToMatchable ? "CoreFP.CaseMatchable" : "CaseIterable"
    let typealiasDecl = conformsToMatchable ? "\(prefix)typealias Subject = \(enumName); " : ""

    guard !cases.isEmpty else {
        return DeclSyntax(stringLiteral: """
            \(prefix)enum cases: \(protocolConformance) { \
            \(typealiasDecl)\
            \(prefix)func matches(_ value: \(enumName)) -> Bool { false } \
            }
            """)
    }
    let caseDeclarations = "case " + cases.map(\.name).joined(separator: ", ")
    let matchClauses = cases
        .map { info in "case (.\(info.name), .\(info.name)): return true" }
        .joined(separator: "; ")
    let defaultClause = cases.count == 1 ? "" : "; default: return false"
    return DeclSyntax(stringLiteral: """
        \(prefix)enum cases: \(protocolConformance) { \
        \(typealiasDecl)\
        \(caseDeclarations); \
        \(prefix)func matches(_ value: \(enumName)) -> Bool { switch (self, value) { \(matchClauses)\(defaultClause) } } \
        }
        """)
}

// MARK: - Diagnostics

private enum PrismsDiagnostic: DiagnosticMessage {
    case notAnEnum

    var message: String {
        switch self {
        case .notAnEnum: "@Prisms can only be applied to enums"
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }
    var severity: DiagnosticSeverity { .error }
}
