import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Adds an instrumented copy of a view's `body` so `#Keyline` can draw
/// its internals instead of treating the view as one opaque node.
public struct KeylinedMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let statements = bodyStatements(in: declaration) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: KeylineDiagnostic.missingBody))
            return []
        }

        // A public view must expose the protocol witness at its own access level.
        let access = accessModifier(of: declaration).map { "\($0) " } ?? ""
        return [
            """
            @ViewBuilder private var _keylineTaggedBody: some View {
                \(ViewTreeTagger.tag(statements).trimmed)
            }
            """,
            """
            \(raw: access)var _keylineBody: AnyView {
                AnyView(_keylineTaggedBody)
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
        guard !protocols.isEmpty else { return [] }
        let extensionDecl: DeclSyntax = "extension \(type.trimmed): KeylineInspectable {}"
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }

    private static func bodyStatements(in declaration: some DeclGroupSyntax) -> CodeBlockItemListSyntax? {
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            for binding in variable.bindings {
                guard binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
                      let accessorBlock = binding.accessorBlock else { continue }

                switch accessorBlock.accessors {
                case .getter(let statements):
                    return statements
                case .accessors(let accessors):
                    if let getter = accessors.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }) {
                        return getter.body?.statements
                    }
                }
            }
        }
        return nil
    }

    private static func accessModifier(of declaration: some DeclGroupSyntax) -> String? {
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open): return "public"
            case .keyword(.package): return "package"
            default: continue
            }
        }
        return nil
    }
}
