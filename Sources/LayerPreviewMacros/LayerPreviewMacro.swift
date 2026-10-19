import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LayerPreviewMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let rawContent: ExprSyntax?
        if let trailingClosure = node.trailingClosure {
            rawContent = ExprSyntax(trailingClosure)
        } else {
            rawContent = node.arguments.first?.expression
        }
        guard let rawContent else {
            context.diagnose(Diagnostic(node: Syntax(node), message: LayerPreviewDiagnostic()))
            return "()"
        }

        let content: ExprSyntax
        if let closure = rawContent.as(ClosureExprSyntax.self) {
            content = ExprSyntax(LayerTagger.tagBody(closure))
        } else {
            content = rawContent
        }

        let annotationExpressions = node.arguments
            .filter { $0.label?.text == nil }
            .map(\.expression.description)
        let annotations = annotationExpressions.joined(separator: ", ")
        let showContainerLines = node.arguments
            .first { $0.label?.text == "showContainerLines" }?.expression.description ?? "true"
        if !annotationExpressions.isEmpty || showContainerLines == "true" {
            return "AnyView(LayerPreviewSurface([\(raw: annotations)], showContainerLines: \(raw: showContainerLines), content: \(content)))"
        }
        return "AnyView(LayerPreviewSurface(content: \(content)))"
    }
}

@main
struct LayerPreviewPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LayerPreviewMacro.self,
        LayerPreviewInspectableMacro.self,
    ]
}

public struct LayerPreviewInspectableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let bodyStatements = bodyStatements(in: declaration) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: LayerPreviewInspectableDiagnostic()))
            return []
        }

        let tagged = LayerTagger.tagStatements(bodyStatements)
        let bodyEdges = LayerTagger.bodyEdgesLiteral(bodyStatements)
        return [
            """
            @ViewBuilder private var __layerPreviewTaggedBody: some View {
                \(tagged)
            }
            """,
            """
            var layerPreviewContent: AnyView {
                AnyView(__layerPreviewTaggedBody)
            }
            """,
            """
            var layerPreviewContentEdges: LayerPreviewEdgePadding? {
                \(raw: bodyEdges)
            }
            """,
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let extensionDecl: DeclSyntax = "extension \(type.trimmed): LayerPreviewInspectable {}"
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }

    private static func bodyStatements(in declaration: some DeclGroupSyntax) -> CodeBlockItemListSyntax? {
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            for binding in varDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      pattern.identifier.text == "body",
                      let accessorBlock = binding.accessorBlock else { continue }

                switch accessorBlock.accessors {
                case .getter(let statements):
                    return statements
                case .accessors(let accessors):
                    for accessor in accessors where accessor.accessorSpecifier.tokenKind == .keyword(.get) {
                        if let body = accessor.body {
                            return body.statements
                        }
                    }
                }
            }
        }
        return nil
    }
}

private struct LayerPreviewDiagnostic: DiagnosticMessage {
    var message: String { "#LayerPreview requires a view closure" }
    var diagnosticID: MessageID { MessageID(domain: "LayerPreview", id: "missingClosure") }
    var severity: DiagnosticSeverity { .error }
}

private struct LayerPreviewInspectableDiagnostic: DiagnosticMessage {
    var message: String { "@LayerPreviewInspectable requires a 'body' property" }
    var diagnosticID: MessageID { MessageID(domain: "LayerPreview", id: "missingBody") }
    var severity: DiagnosticSeverity { .error }
}

/// Rewrites a ViewBuilder closure so every node it declares reports its own
/// type name and padding value via `.layerPreviewTagged`. Recursion into a
/// call's trailing closure happens for any type-like (capitalized) initializer
/// call, which covers every SwiftUI container and custom view; a small
/// denylist excludes controls whose trailing closure is an action, not
/// content (e.g. `Button("Save") { save() }`).
private enum LayerTagger {
    /// Capitalized initializers whose trailing closure is known to be an
    /// action rather than view content, so it must never be tagged.
    static let actionOnlyInitializers: Set<String> = ["Button"]

    static let verticalStackNames: Set<String> = ["VStack", "LazyVStack"]
    static let horizontalStackNames: Set<String> = ["HStack", "LazyHStack"]

    private struct SpacingInfo {
        let axisExpr: String
        let label: String
        let distanceExpr: String
    }

    static func tagBody(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        closure.with(\.statements, tagStatements(closure.statements, spacing: nil, depth: 0))
    }

    /// Entry point for `@LayerPreviewInspectable`, tagging a `body` property's
    /// statements the same way a `#LayerPreview` closure's are tagged.
    static func tagStatements(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        tagStatements(statements, spacing: nil, depth: 0)
    }

    static func bodyEdgesLiteral(_ statements: CodeBlockItemListSyntax) -> String {
        guard let lastExpression = statements.last(where: { item in
            if case .expr = item.item { return true }
            return false
        })?.item.as(ExprSyntax.self) else {
            return "nil"
        }

        let (_, _, paddings) = rewriteChain(lastExpression, depth: 0)
        return edgePaddingLiteral(from: paddings)
    }

    private static func tagBody(_ closure: ClosureExprSyntax, spacing: SpacingInfo?, depth: Int) -> ClosureExprSyntax {
        closure.with(\.statements, tagStatements(closure.statements, spacing: spacing, depth: depth))
    }

    private static func tagStatements(_ statements: CodeBlockItemListSyntax, spacing: SpacingInfo?, depth: Int) -> CodeBlockItemListSyntax {
        let items = Array(statements)
        let lastExprIndex = items.lastIndex { if case .expr = $0.item { return true }; return false }

        let newItems = items.enumerated().map { index, item -> CodeBlockItemSyntax in
            guard case let .expr(expr) = item.item else { return item }
            let gap = (spacing != nil && index != lastExprIndex) ? spacing : nil
            // Earlier siblings get a higher zIndex so their edge/spacing
            // badges, which are drawn past their own bounds, paint above
            // later siblings instead of being hidden behind them.
            return item.with(\.item, .expr(tag(expr, spacing: gap, zIndex: items.count - index, depth: depth)))
        }
        return CodeBlockItemListSyntax(newItems)
    }

    private static func tag(_ expr: ExprSyntax, spacing: SpacingInfo?, zIndex: Int, depth: Int) -> ExprSyntax {
        let (rewritten, name, paddings) = rewriteChain(expr, depth: depth)
        let edgesLiteral = edgePaddingLiteral(from: paddings)
        let isContainer = isContainerExpression(expr)
        var tagged: ExprSyntax = "LayerPreviewInspectorBridge(\(rewritten), name: \(raw: String(reflecting: name)), edges: \(raw: edgesLiteral), labelLevel: \(raw: depth), isContainer: \(raw: isContainer))"
        if let spacing {
            tagged = "\(tagged).layerPreviewSpacing(axis: \(raw: spacing.axisExpr), label: \(raw: String(reflecting: spacing.label)), distance: \(raw: spacing.distanceExpr))"
        }
        return "\(tagged).zIndex(\(raw: zIndex))"
    }

    /// Resolves which edges each `.padding(...)` call affects, in source
    /// order, so a later call overrides an earlier one on the same edge.
    private static func edgePaddingLiteral(from paddings: [String]) -> String {
        guard !paddings.isEmpty else { return "nil" }

        var top: String?
        var bottom: String?
        var leading: String?
        var trailing: String?

        for raw in paddings {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != "default" else {
                top = "default"; bottom = "default"; leading = "default"; trailing = "default"
                continue
            }

            guard trimmed.hasPrefix(".") else {
                top = trimmed; bottom = trimmed; leading = trimmed; trailing = trimmed
                continue
            }

            let parts = trimmed.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            let value = parts.count > 1 ? parts[1] : "default"
            switch parts[0] {
            case ".horizontal": leading = value; trailing = value
            case ".vertical": top = value; bottom = value
            case ".top": top = value
            case ".bottom": bottom = value
            case ".leading": leading = value
            case ".trailing": trailing = value
            default: top = trimmed; bottom = trimmed; leading = trimmed; trailing = trimmed
            }
        }

        func literal(_ value: String?) -> String {
            value.map { String(reflecting: $0) } ?? "nil"
        }
        return "LayerPreviewEdgePadding(top: \(literal(top)), bottom: \(literal(bottom)), leading: \(literal(leading)), trailing: \(literal(trailing)))"
    }

    /// Peels a modifier chain down to its root initializer call, recursing
    /// into container children, then rebuilds the chain bottom-up.
    private static func rewriteChain(_ expr: ExprSyntax, depth: Int) -> (rewritten: ExprSyntax, name: String, paddings: [String]) {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            if let member = call.calledExpression.as(MemberAccessExprSyntax.self), let base = member.base {
                let methodName = member.declName.baseName.text
                let (rewrittenBase, name, paddings) = rewriteChain(base, depth: depth)
                var newPaddings = paddings
                if methodName == "padding" {
                    let arguments = stripDesignTimeLiterals(call.arguments.description.trimmingCharacters(in: .whitespacesAndNewlines))
                    newPaddings.append(arguments.isEmpty ? "default" : arguments)
                }
                let newCall = call.with(\.calledExpression, ExprSyntax(member.with(\.base, rewrittenBase)))
                return (ExprSyntax(newCall), name, newPaddings)
            }

            let name = baseName(of: call.calledExpression)
            var newCall = call
            if isRecursableContainer(name), let trailingClosure = call.trailingClosure {
                let spacing = spacingInfo(for: name, arguments: call.arguments)
                newCall = newCall.with(\.trailingClosure, tagBody(trailingClosure, spacing: spacing, depth: depth + 1))
            }
            return (ExprSyntax(newCall), name, [])
        }

        if let member = expr.as(MemberAccessExprSyntax.self), member.base == nil {
            return (expr, member.declName.baseName.text, [])
        }

        let description = expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return (expr, description, [])
    }

    private static func spacingInfo(for containerName: String, arguments: LabeledExprListSyntax) -> SpacingInfo? {
        let axisExpr: String
        let arrow: String
        if verticalStackNames.contains(containerName) {
            axisExpr = ".vertical"
            arrow = "\u{2195}\u{FE0E}"
        } else if horizontalStackNames.contains(containerName) {
            axisExpr = ".horizontal"
            arrow = "\u{2194}"
        } else {
            return nil
        }

        let rawValue = arguments.first { $0.label?.text == "spacing" }?.expression.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let value = rawValue.map(stripDesignTimeLiterals)
        return SpacingInfo(axisExpr: axisExpr, label: "\(arrow) \(value ?? "default")", distanceExpr: value ?? "8")
    }

    private static func isContainerExpression(_ expr: ExprSyntax) -> Bool {
        guard let call = expr.as(FunctionCallExprSyntax.self) else { return false }

        if let member = call.calledExpression.as(MemberAccessExprSyntax.self), let base = member.base {
            return isContainerExpression(base)
        }

        return call.trailingClosure != nil && isRecursableContainer(baseName(of: call.calledExpression))
    }

    /// Xcode wraps literals in previews (e.g. `__designTimeInteger("id", fallback: 24)`)
    /// so it can hot-patch them from the Canvas; show the fallback value instead.
    private static func stripDesignTimeLiterals(_ text: String) -> String {
        guard text.contains("__designTime") else { return text }
        guard let regex = try? NSRegularExpression(
            pattern: #"__designTime(?:Integer|Float|String|Boolean)\("[^"]*",\s*fallback:\s*(.*?)\)"#
        ) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "$1")
    }

    /// Any capitalized (type-like) initializer is treated as a recursable
    /// container unless it's a known action-only control, so custom views
    /// and SwiftUI containers work without needing to be named explicitly.
    private static func isRecursableContainer(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return !actionOnlyInitializers.contains(name)
    }

    private static func baseName(of expr: ExprSyntax) -> String {
        if let decl = expr.as(DeclReferenceExprSyntax.self) {
            return decl.baseName.text
        }
        if let member = expr.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }
        return expr.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
