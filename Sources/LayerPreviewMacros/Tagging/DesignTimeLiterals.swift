import SwiftSyntax

/// Xcode previews rewrite literals as `__designTimeInteger("#id", fallback: 24)`
/// so the Canvas can hot-patch them; labels show the fallback value instead.
enum DesignTimeLiterals {
    static func text(of node: some SyntaxProtocol) -> String {
        Stripper(viewMode: .sourceAccurate).rewrite(node).trimmedDescription
    }

    private final class Stripper: SyntaxRewriter {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
                  callee.baseName.text.hasPrefix("__designTime"),
                  let fallback = node.arguments.first(where: { $0.label?.text == "fallback" })?.expression
            else { return super.visit(node) }
            return visit(fallback)
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}
