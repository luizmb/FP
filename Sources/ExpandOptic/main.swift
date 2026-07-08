// SPDX-License-Identifier: Apache-2.0
import Foundation
import FPMacrosExpander
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - stderr

/// Writes to standard error via `FileHandle`, not the raw C `stderr` global — the latter
/// is not concurrency-safe under Swift 6 on Linux/Android (only silently tolerated by the
/// Darwin toolchain).
func eprint(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

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
        eprint("error: \(d.message)")
    }
    let name = structDecl.name.trimmedDescription
    let body = members.map { "    \($0.trimmedDescription)" }.joined(separator: "\n\n")
    return "extension \(name) {\n\(body)\n}"
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
        eprint("error: \(d.message)")
    }
    let name = enumDecl.name.trimmedDescription
    let body = members.map { "    \($0.trimmedDescription)" }.joined(separator: "\n\n")
    return "extension \(name) {\n\(body)\n}"
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
    eprint("Usage: swift run ExpandOptic <file.swift> [file2.swift ...]")
    eprint("  Prints the manual equivalents of @Lenses/@Prisms expansions.")
    exit(1)
}

var allOutputs: [String] = []

for path in CommandLine.arguments.dropFirst() {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        eprint("Cannot read: \(path)")
        continue
    }
    let tree = Parser.parse(source: source)
    let walker = OpticWalker(viewMode: .sourceAccurate)
    walker.walk(tree)
    allOutputs.append(contentsOf: walker.outputs)
}

if allOutputs.isEmpty {
    eprint("No @Lenses or @Prisms annotations found.")
    exit(1)
}

print(allOutputs.joined(separator: "\n\n"))
