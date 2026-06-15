import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Option parsing

struct PrismsEmitFlags {
    var prisms: Bool
    var properties: Bool
    var cases: Bool

    static var all: PrismsEmitFlags { PrismsEmitFlags(prisms: true, properties: true, cases: true) }

    /// `.properties` requires `.prisms` (the per-case accessor or DML subscript reads
    /// from `Self.prism`), so we auto-promote silently.
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

    return PrismsEmitFlags(
        prisms: names.contains("prisms"),
        properties: names.contains("properties"),
        cases: names.contains("cases")
    )
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
    private var tuple: String { (0..<params.count).map { "v\($0)" }.joined(separator: ", ") }
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

        let access = accessKeyword(from: enumDecl.modifiers)

        // Reject `private` hosts. `private` is the only declared access where Swift's
        // type-reference rules block both the struct namespace and the dynamic-member
        // subscript. `fileprivate` is functionally equivalent at file scope and works
        // everywhere we need.
        guard access != "private" else {
            context.diagnose(Diagnostic(node: node, message: PrismsDiagnostic.privateHostUnsupported))
            return []
        }

        let enumName = enumDecl.name.trimmed.text
        let isGeneric = enumDecl.genericParameterClause != nil
        let hasDynamicMemberLookup = hasDynamicMemberLookupAttribute(on: enumDecl)
        let cases = collectCases(from: enumDecl)
        let flags = parseOptions(from: node)

        var members: [DeclSyntax] = []

        if flags.emitsPrismStruct {
            members.append(makePrismsStruct(enumName: enumName, access: access, cases: cases))
            members.append(makeStaticPrism(enumName: enumName, access: access, isGeneric: isGeneric))
        }

        if flags.properties {
            if hasDynamicMemberLookup {
                members.append(makeDynamicSubscript(enumName: enumName, access: access))
            } else {
                if !cases.isEmpty {
                    context.diagnose(Diagnostic(
                        node: node,
                        message: PrismsDiagnostic.missingDynamicMemberLookup
                    ))
                }
                members.append(contentsOf: cases.map { makeComputedProperty(info: $0, access: access) })
            }
        }

        if flags.cases {
            members.append(makeCasesEnum(enumName: enumName, access: access, cases: cases))
            members.append(makeIsFunc(access: access, hasCases: !cases.isEmpty))
        }

        return members
    }
}

// MARK: - Prismatic conformance

extension PrismsMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Only enums, only when the prism namespace is emitted (`static var prism` is the
        // conformance witness), and only when the compiler actually asked for the conformance
        // (`protocols` is empty when the type already conforms).
        guard let enumDecl = declaration.as(EnumDeclSyntax.self),
              accessKeyword(from: enumDecl.modifiers) != "private",
              parseOptions(from: node).emitsPrismStruct,
              !protocols.isEmpty
        else { return [] }

        return [try ExtensionDeclSyntax("extension \(type.trimmed): Prismatic {}")]
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

private func hasDynamicMemberLookupAttribute(on enumDecl: EnumDeclSyntax) -> Bool {
    enumDecl.attributes.contains { attr in
        guard case let .attribute(attribute) = attr else { return false }
        return attribute.attributeName.trimmedDescription == "dynamicMemberLookup"
    }
}

// MARK: - Code generation

/// The `Prisms` struct holds one `Prism` per case as a stored property with a default
/// value. Using default values lets `Prisms()` work as a no-arg init regardless of the
/// host's access level (Swift synthesises `init()` for structs whose stored properties
/// all have defaults). The host's access propagates to the struct and its fields so
/// external callers can read `Host.prism.caseName` at the appropriate level.
private func makePrismsStruct(enumName: String, access: String, cases: [CaseInfo]) -> DeclSyntax {
    let prefix = accessPrefix(access)
    let fields = cases
        .map { info in
            let preview = "{ \(info.previewBody(enumName: enumName)) }"
            let review = info.reviewExpr(enumName: enumName)
            let typeAnn = "CoreFP.Prism<\(enumName), \(info.focusType)>"
            return "\(prefix)let \(info.name): \(typeAnn) = CoreFP.prism(preview: \(preview), review: \(review))"
        }
        .joined(separator: "; ")
    return DeclSyntax(stringLiteral: "\(prefix)struct Prisms: Sendable { \(fields) }")
}

/// For non-generic hosts emit `static let prism = Prisms()` — a one-time allocation,
/// cached for the program's lifetime. For generic hosts Swift forbids `static let` in a
/// generic context, so we fall back to a computed `static var prism: Prisms { Prisms() }`
/// which allocates per access. Same call-site syntax in both cases.
private func makeStaticPrism(enumName: String, access: String, isGeneric: Bool) -> DeclSyntax {
    let prefix = accessPrefix(access)
    if isGeneric {
        return DeclSyntax(stringLiteral: "\(prefix)static var prism: Prisms { Prisms() }")
    }
    return DeclSyntax(stringLiteral: "\(prefix)static let prism = Prisms()")
}

/// The dynamic-member subscript lights up when the user adds `@dynamicMemberLookup` to
/// the host enum. Each `\\Prisms.caseName` keypath has type `KeyPath<Prisms, Prism<Self, PrismFocus>>`
/// for the concrete focus type of that case, so Swift binds `PrismFocus` correctly per
/// call site.
///
/// We use the unusual name `PrismFocus` rather than a one-letter name so the generic
/// parameter never shadows a host enum's own generic parameter.
private func makeDynamicSubscript(enumName: String, access: String) -> DeclSyntax {
    let prefix = accessPrefix(access)
    let body = "Self.prism[keyPath: keyPath].preview(self)"
    let kpType = "KeyPath<Prisms, CoreFP.Prism<\(enumName), PrismFocus>>"
    return DeclSyntax(stringLiteral:
        "\(prefix)subscript<PrismFocus>(dynamicMember keyPath: \(kpType)) -> PrismFocus? { \(body) }"
    )
}

private func makeComputedProperty(info: CaseInfo, access: String) -> DeclSyntax {
    let prefix = accessPrefix(access)
    return DeclSyntax(stringLiteral:
        "\(prefix)var \(info.name): \(info.focusType)? { Self.prism.\(info.name).preview(self) }"
    )
}

private func makeIsFunc(access: String, hasCases: Bool) -> DeclSyntax {
    let prefix = accessPrefix(access)
    if !hasCases {
        return DeclSyntax(stringLiteral: "\(prefix)func `is`(_ c: Cases) -> Bool { false }")
    }
    return DeclSyntax(stringLiteral: "\(prefix)func `is`(_ c: Cases) -> Bool { c.matches(self) }")
}

private func makeCasesEnum(enumName: String, access: String, cases: [CaseInfo]) -> DeclSyntax {
    let prefix = accessPrefix(access)

    guard !cases.isEmpty else {
        return DeclSyntax(stringLiteral: """
            \(prefix)enum Cases: CoreFP.CaseMatchable { \
            \(prefix)typealias Subject = \(enumName) \
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
        \(prefix)enum Cases: CoreFP.CaseMatchable { \
        \(prefix)typealias Subject = \(enumName); \
        \(caseDeclarations); \
        \(prefix)func matches(_ value: \(enumName)) -> Bool { switch (self, value) { \(matchClauses)\(defaultClause) } } \
        }
        """)
}

// MARK: - Diagnostics

private enum PrismsDiagnostic: DiagnosticMessage {
    case notAnEnum
    case privateHostUnsupported
    case missingDynamicMemberLookup

    var message: String {
        switch self {
        case .notAnEnum:
            "@Prisms can only be applied to enums"
        case .privateHostUnsupported:
            "@Prisms cannot be applied to `private` enums. Change the declaration to `fileprivate`, "
                + "`internal`, or higher. (`private` is the only access level whose type-scope semantics "
                + "block the generated namespace; `fileprivate` is functionally identical at file scope.)"
        case .missingDynamicMemberLookup:
            "@Prisms is emitting one computed property per case. To collapse them into a single "
                + "subscript, add `@dynamicMemberLookup` to this enum's declaration."
        }
    }

    var diagnosticID: MessageID { .init(domain: "FPMacrosPlugin", id: "\(self)") }

    var severity: DiagnosticSeverity {
        switch self {
        case .notAnEnum, .privateHostUnsupported: .error
        case .missingDynamicMemberLookup:         .warning
        }
    }
}
