import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct KeylinedMacroTests {
    @Test func addsInstrumentedBody() {
        assertMacro(
            """
            @Keylined
            struct ProfileView: View {
                var body: some View {
                    Text("Hi")
                        .padding(24)
                }
            }
            """,
            expandsTo: """
            struct ProfileView: View {
                var body: some View {
                    Text("Hi")
                        .padding(24)
                }

                @ViewBuilder private var _keylineTaggedBody: some View {
                    _KeylineNode(Text("Hi")
                                ._keylineProbe(.paddingInner(0))
                                .padding(24)
                                ._keylineProbe(.paddingOuter(0, declared: "24")), _KeylineDeclaration("Text"))
                }

                var _keylineBody: AnyView {
                    AnyView(_keylineTaggedBody)
                }
            }

            extension ProfileView: KeylineInspectable {
            }
            """
        )
    }

    /// A public view needs a public protocol witness.
    @Test func matchesPublicAccessLevel() {
        assertMacro(
            """
            @Keylined
            public struct ProfileView: View {
                public var body: some View {
                    Text("Hi")
                }
            }
            """,
            expandsTo: """
            public struct ProfileView: View {
                public var body: some View {
                    Text("Hi")
                }

                @ViewBuilder private var _keylineTaggedBody: some View {
                    _KeylineNode(Text("Hi"), _KeylineDeclaration("Text"))
                }

                public var _keylineBody: AnyView {
                    AnyView(_keylineTaggedBody)
                }
            }

            extension ProfileView: KeylineInspectable {
            }
            """
        )
    }

    @Test func requiresBody() {
        assertMacro(
            """
            @Keylined
            struct Empty: View {
            }
            """,
            expandsTo: """
            struct Empty: View {
            }

            extension Empty: KeylineInspectable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Keylined requires a 'body' property", line: 1, column: 1),
            ]
        )
    }
}
