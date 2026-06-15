import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FPMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        LensesMacro.self,
        PrismsMacro.self,
        WitnessMacro.self
    ]
}
