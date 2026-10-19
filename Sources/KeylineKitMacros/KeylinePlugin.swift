import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct KeylinePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        KeylineMacro.self,
        KeylinedMacro.self,
    ]
}
