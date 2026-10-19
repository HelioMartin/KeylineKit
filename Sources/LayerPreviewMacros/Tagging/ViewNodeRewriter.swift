import SwiftSyntax
import SwiftSyntaxBuilder

/// Wraps one view expression in `_LayerPreviewNode`, recursing into the
/// content closures of its root initializer and inserting measurement probes
/// around the modifiers whose geometry the overlay draws:
///
///     VStack { ... }
///         ._layerPreviewProbe(.paddingInner(0))
///         .padding(24)
///         ._layerPreviewProbe(.paddingOuter(0, declared: "24"))
enum ViewNodeRewriter {
    static func rewrite(_ expr: ExprSyntax) -> ExprSyntax {
        let chain = ModifierChain(expr)
        let name = chain.rootName
        let root = rewriteContent(of: chain.root, name: name)

        if chain.modifiers.isEmpty, ContainerRules.transparentContainers.contains(name) {
            return root
        }

        let instrumented = instrument(chain.modifiers, on: root)
        let node: ExprSyntax = "_LayerPreviewNode(\(instrumented.trimmed), \(raw: declaration(name: name, root: chain.root)))"
        return node
            .with(\.leadingTrivia, expr.leadingTrivia)
            .with(\.trailingTrivia, expr.trailingTrivia)
    }

    private static func rewriteContent(of root: ExprSyntax, name: String) -> ExprSyntax {
        guard ContainerRules.hasViewContent(name), var call = root.as(FunctionCallExprSyntax.self) else {
            return root
        }
        if let trailingClosure = call.trailingClosure,
           ContainerRules.trailingClosureIsContent(name, arguments: call.arguments) {
            call.trailingClosure = ViewTreeTagger.tag(trailingClosure)
        }
        let additionalClosures = call.additionalTrailingClosures.map { element in
            guard ContainerRules.contentClosureLabels.contains(element.label.text) else { return element }
            return element.with(\.closure, ViewTreeTagger.tag(element.closure))
        }
        call.additionalTrailingClosures = MultipleTrailingClosureElementListSyntax(additionalClosures)
        return ExprSyntax(call)
    }

    private static func instrument(_ modifiers: [FunctionCallExprSyntax], on root: ExprSyntax) -> ExprSyntax {
        var result = root
        var paddingIndex = 0
        var cornerIndex = 0

        for call in modifiers {
            guard let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { continue }
            // Probes sit on their own line when the modifier does.
            let lineBreak = member.period.leadingTrivia

            if member.declName.baseName.text == "padding" {
                let declared = PaddingArguments(call.arguments).declaredLength.map { String(reflecting: $0) } ?? "nil"
                result = probe(result, ".paddingInner(\(raw: paddingIndex))", lineBreak: lineBreak)
                result = apply(call, member, to: result)
                result = probe(result, ".paddingOuter(\(raw: paddingIndex), declared: \(raw: declared))", lineBreak: lineBreak)
                paddingIndex += 1
                continue
            }

            result = apply(call, member, to: result)
            if let radius = CornerRadius(modifier: call) {
                let declared = String(reflecting: radius.declared)
                result = probe(
                    result,
                    ".corner(\(raw: cornerIndex), declared: \(raw: declared), radius: Double(\(radius.expression.trimmed)))",
                    lineBreak: lineBreak
                )
                cornerIndex += 1
            }
        }
        return result
    }

    private static func apply(_ call: FunctionCallExprSyntax, _ member: MemberAccessExprSyntax, to base: ExprSyntax) -> ExprSyntax {
        ExprSyntax(call.with(\.calledExpression, ExprSyntax(member.with(\.base, base))))
    }

    /// `base._layerPreviewProbe(argument)`, built as nodes so the original
    /// trivia of `base` is kept untouched.
    private static func probe(_ base: ExprSyntax, _ argument: ExprSyntax, lineBreak: Trivia) -> ExprSyntax {
        let member = MemberAccessExprSyntax(
            base: base,
            period: .periodToken(leadingTrivia: lineBreak),
            declName: DeclReferenceExprSyntax(baseName: .identifier("_layerPreviewProbe"))
        )
        return ExprSyntax(FunctionCallExprSyntax(
            calledExpression: ExprSyntax(member),
            leftParen: .leftParenToken(),
            arguments: [LabeledExprSyntax(expression: argument)],
            rightParen: .rightParenToken()
        ))
    }

    private static func declaration(name: String, root: ExprSyntax) -> String {
        let quotedName = String(reflecting: name)
        guard let axis = ContainerRules.stackAxis(name), let call = root.as(FunctionCallExprSyntax.self) else {
            return "_LayerPreviewDeclaration(\(quotedName))"
        }
        let spacing = call.arguments
            .first { $0.label?.text == "spacing" }
            .flatMap { $0.expression.is(NilLiteralExprSyntax.self) ? nil : DesignTimeLiterals.text(of: $0.expression) }
        return "_LayerPreviewDeclaration(\(quotedName), stack: \(axis), spacing: \(String(reflecting: spacing ?? "default")))"
    }
}
