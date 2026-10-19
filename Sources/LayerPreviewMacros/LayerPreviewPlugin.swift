import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct LayerPreviewPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LayerPreviewMacro.self,
        LayerPreviewInspectableMacro.self,
    ]
}
