// SPDX-License-Identifier: Apache-2.0
import FPMacrosPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Expansion-level helpers for checks a compiling fixture can't express: diagnostics, and the
// visibility of generated members (a fixture can only prove what *is* reachable).

let macroSpecs: [String: MacroSpec] = [
    "Lenses": MacroSpec(type: LensesMacro.self, conformances: ["Sendable"]),
    "Prisms": MacroSpec(type: PrismsMacro.self, conformances: ["Prismatic"]),
    "Iso": MacroSpec(type: IsoMacro.self),
    "DeriveMonoid": MacroSpec(type: DeriveMonoidMacro.self, conformances: ["Monoid"]),
    "Witness": MacroSpec(type: WitnessMacro.self),
    "Mock": MacroSpec(type: MockMacro.self)
]

struct Expansion {
    let source: String
    let diagnostics: [String]
}

/// Expands every FP macro in `source`, returning the expanded text and the diagnostic messages.
func expand(_ source: String) -> Expansion {
    let file = Parser.parse(source: source)
    let context = BasicMacroExpansionContext(sourceFiles: [file: .init(moduleName: "TestModule", fullFilePath: "test.swift")])
    let expanded = file.expand(
        macroSpecs: macroSpecs,
        contextGenerator: { BasicMacroExpansionContext(sharingWith: context, lexicalContext: $0.allMacroLexicalContexts()) },
        indentationWidth: .spaces(4)
    )
    return Expansion(source: expanded.description, diagnostics: context.diagnostics.map(\.message))
}

/// Asserts that expanding `source` emits nothing but exactly the one error `message`, anchored at
/// `line`/`column`.
func assertDiagnostic(
    _ source: String,
    expandsTo expanded: String,
    message: String,
    line: Int = 1,
    column: Int = 1,
    sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
    assertMacroExpansion(
        source,
        expandedSource: expanded,
        diagnostics: [DiagnosticSpec(message: message, line: line, column: column)],
        macroSpecs: macroSpecs,
        failureHandler: { Issue.record(Comment(rawValue: $0.message), sourceLocation: sourceLocation) }
    )
}
