import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#Keyline(...) { ... }` into a `_KeylineSurface` whose
/// content closure has every view node instrumented by `ViewTreeTagger`.
public struct KeylineMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let content = node.trailingClosure.map(ExprSyntax.init)
            ?? node.arguments.first { $0.label?.text == "body" }?.expression
        guard let content else {
            context.diagnose(Diagnostic(node: Syntax(node), message: KeylineDiagnostic.missingClosure))
            return "()"
        }

        let tagged = content.as(ClosureExprSyntax.self).map { ExprSyntax(ViewTreeTagger.tag($0)) } ?? content
        let annotations = node.arguments
            .filter { $0.label == nil }
            .map(\.expression.trimmedDescription)
            .joined(separator: ", ")
        let showContainerLines = node.arguments
            .first { $0.label?.text == "showContainerLines" }?
            .expression.trimmedDescription ?? "true"

        return "AnyView(_KeylineSurface([\(raw: annotations)], showContainerLines: \(raw: showContainerLines), content: \(tagged)))"
    }
}
