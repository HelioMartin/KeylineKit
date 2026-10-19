import SwiftSyntax

/// The corner radius a modifier applies: `.cornerRadius(12)`,
/// `.clipShape(.rect(cornerRadius: 12))` or
/// `.background(.blue, in: RoundedRectangle(cornerRadius: 12))`.
struct CornerRadius {
    /// The radius expression, re-evaluated by the probe to draw the arc.
    let expression: ExprSyntax

    var declared: String { DesignTimeLiterals.text(of: expression) }

    init?(modifier call: FunctionCallExprSyntax) {
        let method = call.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        if method == "cornerRadius", let radius = call.arguments.first?.expression {
            expression = radius
            return
        }
        let finder = Finder(viewMode: .sourceAccurate)
        finder.walk(call.arguments)
        guard let radius = finder.expression else { return nil }
        expression = radius
    }

    /// Finds the first `cornerRadius:` argument. Closures are skipped: names
    /// declared inside them would not resolve where the probe is evaluated.
    private final class Finder: SyntaxVisitor {
        var expression: ExprSyntax?

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
            guard expression == nil else { return .skipChildren }
            if node.label?.text == "cornerRadius" {
                expression = node.expression
                return .skipChildren
            }
            return .visitChildren
        }
    }
}
