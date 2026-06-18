// SPDX-License-Identifier: Apache-2.0
import Foundation
import FPMacrosExpander
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - Minimal context

final class ExpandContext: MacroExpansionContext {
    var diagnostics: [Diagnostic] = []

    func makeUniqueName(_ name: String) -> TokenSyntax { .identifier("__\(name)__") }
    func diagnose(_ diagnostic: Diagnostic) { diagnostics.append(diagnostic) }
    func location(
        of node: some SyntaxProtocol,
        at position: PositionInSyntaxNode,
        filePathMode: SourceLocationFilePathMode
    ) -> AbstractSourceLocation? { nil }
    var lexicalContext: [Syntax] { [] }
}

// MARK: - Expansion helpers

func expand(lenses structDecl: StructDeclSyntax, attribute: AttributeSyntax) -> String {
    let ctx = ExpandContext()
    let members: [DeclSyntax]
    do {
        members = try LensesMacro.expansion(of: attribute, providingMembersOf: structDecl, conformingTo: [], in: ctx)
    } catch {
        return "// @Lenses expansion error: \(error)"
    }
    for d in ctx.diagnostics where d.diagMessage.severity == .error {
        fputs("error: \(d.message)
", stderr)
    }
    let name = structDecl.name.trimmedDescription
    let body = members.map { "    \($0.trimmedDescription)" }.joined(separator: "

")
    return "extension \(name) {
\(body)
}"
}

func expand(prisms enumDecl: EnumDeclSyntax, attribute: AttributeSyntax) -> String {
    let ctx = ExpandContext()
    let members: [DeclSyntax]
    do {
        members = try PrismsMacro.expansion(of: attribute, providingMembersOf: enumDecl, conformingTo: [], in: ctx)
    } catch {
        return "// @Prisms expansion error: \(error)"
    }
    for d in ctx.diagnostics where d.diagMessage.severity == .error {
        fputs("error: \(d.message)
", stderr)
    }
    let name = enumDecl.name.trimmedDescription
    let body = members.map { "    \($0.trimmedDescription)" }.joined(separator: "

")
    return "extension \(name) {
\(body)
}"
}

// MARK: - Syntax walker

final class OpticWalker: SyntaxVisitor {
    var outputs: [String] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        for attr in node.attributes {
            guard let a = attr.as(AttributeSyntax.self),
                a.attributeName.trimmedDescription == "Lenses" else { continue }
            outputs.append("// MARK: - @Lenses → \(node.name.trimmedDescription)\n")
            outputs.append(expand(lenses: node, attribute: a))
        }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        for attr in node.attributes {
            guard let a = attr.as(AttributeSyntax.self),
                a.attributeName.trimmedDescription == "Prisms" else { continue }
            outputs.append("// MARK: - @Prisms → \(node.name.trimmedDescription)\n")
            outputs.append(expand(prisms: node, attribute: a))
        }
        return .visitChildren
    }
}

// MARK: - Entry point

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: swift run ExpandOptic <file.swift> [file2.swift ...]
", stderr)
    fputs("  Prints the manual equivalents of @Lenses/@Prisms expansions.
", stderr)
    exit(1)
}

var allOutputs: [String] = []

for path in CommandLine.arguments.dropFirst() {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        fputs("Cannot read: \(path)\n", stderr)
        continue
    }
    let tree = Parser.parse(source: source)
    let walker = OpticWalker(viewMode: .sourceAccurate)
    walker.walk(tree)
    allOutputs.append(contentsOf: walker.outputs)
}

if allOutputs.isEmpty {
    fputs("No @Lenses or @Prisms annotations found.
", stderr)
    exit(1)
}

print(allOutputs.joined(separator: "

"))
