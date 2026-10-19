import LayerPreviewMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

private let macroSpecs: [String: MacroSpec] = [
    "LayerPreview": MacroSpec(type: LayerPreviewMacro.self),
    "LayerPreviewInspectable": MacroSpec(
        type: LayerPreviewInspectableMacro.self,
        conformances: [TypeSyntax(IdentifierTypeSyntax(name: .identifier("LayerPreviewInspectable")))]
    ),
]

/// Asserts a macro expansion, reporting mismatches as Swift Testing issues.
func assertMacro(
    _ source: String,
    expandsTo expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
    assertMacroExpansion(
        source,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        failureHandler: { failure in
            Issue.record(Comment(rawValue: failure.message), sourceLocation: sourceLocation)
        }
    )
}
