import SwiftSyntax

/// The length a `.padding(...)` call declares, as written in source: `"24"`,
/// `"Theme.spacing"`, `"default"` when SwiftUI picks the length, or `nil`
/// for `EdgeInsets`, whose length differs per edge.
struct PaddingArguments {
    let declaredLength: String?

    init(_ arguments: LabeledExprListSyntax) {
        let expressions = arguments.map(\.expression)
        switch expressions.count {
        case 0:
            declaredLength = "default"
        case 1 where Self.isEdgeSet(expressions[0]):
            declaredLength = "default"
        case 1 where Self.isEdgeInsets(expressions[0]):
            declaredLength = nil
        case 1:
            declaredLength = DesignTimeLiterals.text(of: expressions[0])
        default:
            let length = expressions[1]
            declaredLength = length.is(NilLiteralExprSyntax.self) ? "default" : DesignTimeLiterals.text(of: length)
        }
    }

    private static let edgeNames: Set<String> = ["all", "top", "bottom", "leading", "trailing", "horizontal", "vertical"]

    /// `.horizontal`, `Edge.Set.top` or `[.top, .leading]`.
    private static func isEdgeSet(_ expr: ExprSyntax) -> Bool {
        if let member = expr.as(MemberAccessExprSyntax.self) {
            let base = member.base?.trimmedDescription
            return (base == nil || base == "Edge.Set") && edgeNames.contains(member.declName.baseName.text)
        }
        if let array = expr.as(ArrayExprSyntax.self) {
            return array.elements.allSatisfy { isEdgeSet($0.expression) }
        }
        return false
    }

    private static func isEdgeInsets(_ expr: ExprSyntax) -> Bool {
        guard let call = expr.as(FunctionCallExprSyntax.self) else { return false }
        let callee = call.calledExpression.trimmedDescription
        return callee == "EdgeInsets" || callee == ".init" || callee == "EdgeInsets.init"
    }
}
