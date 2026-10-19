import SwiftSyntax

/// A view expression split into its root (`VStack { ... }`, `Text("A")`,
/// `Color.red`) and the modifier calls applied to it.
struct ModifierChain {
    let root: ExprSyntax
    /// Modifier calls ordered from the root outwards.
    let modifiers: [FunctionCallExprSyntax]

    init(_ expr: ExprSyntax) {
        var modifiers: [FunctionCallExprSyntax] = []
        var current = expr
        while let call = current.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              let base = member.base {
            modifiers.append(call)
            current = base
        }
        root = current
        self.modifiers = modifiers.reversed()
    }

    /// The type-like name shown on the node's label, e.g. `VStack`.
    var rootName: String {
        if let call = root.as(FunctionCallExprSyntax.self) {
            return Self.name(of: call.calledExpression)
        }
        return Self.name(of: root)
    }

    private static func name(of expr: ExprSyntax) -> String {
        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text
        }
        if let specialization = expr.as(GenericSpecializationExprSyntax.self) {
            return name(of: specialization.expression)
        }
        return DesignTimeLiterals.text(of: expr)
    }
}
