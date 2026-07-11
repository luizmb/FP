// SPDX-License-Identifier: Apache-2.0
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FPMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        LensesMacro.self,
        PrismsMacro.self,
        ApplyOpticsMacro.self,
        ApplyOpticsRelayMacro.self,
        NoOpticsMacro.self,
        WitnessMacro.self,
        MockMacro.self,
        DeriveMonoidMacro.self,
        IsoMacro.self
    ]
}
