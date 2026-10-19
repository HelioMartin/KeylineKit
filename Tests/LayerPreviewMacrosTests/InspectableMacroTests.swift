import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct InspectableMacroTests {
    @Test func addsInstrumentedBody() {
        assertMacro(
            """
            @LayerPreviewInspectable
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

                @ViewBuilder private var _layerPreviewTaggedBody: some View {
                    _LayerPreviewNode(Text("Hi")
                                ._layerPreviewProbe(.paddingInner(0))
                                .padding(24)
                                ._layerPreviewProbe(.paddingOuter(0, declared: "24")), _LayerPreviewDeclaration("Text"))
                }

                var _layerPreviewBody: AnyView {
                    AnyView(_layerPreviewTaggedBody)
                }
            }

            extension ProfileView: LayerPreviewInspectable {
            }
            """
        )
    }

    /// A public view needs a public protocol witness.
    @Test func matchesPublicAccessLevel() {
        assertMacro(
            """
            @LayerPreviewInspectable
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

                @ViewBuilder private var _layerPreviewTaggedBody: some View {
                    _LayerPreviewNode(Text("Hi"), _LayerPreviewDeclaration("Text"))
                }

                public var _layerPreviewBody: AnyView {
                    AnyView(_layerPreviewTaggedBody)
                }
            }

            extension ProfileView: LayerPreviewInspectable {
            }
            """
        )
    }

    @Test func requiresBody() {
        assertMacro(
            """
            @LayerPreviewInspectable
            struct Empty: View {
            }
            """,
            expandsTo: """
            struct Empty: View {
            }

            extension Empty: LayerPreviewInspectable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@LayerPreviewInspectable requires a 'body' property", line: 1, column: 1),
            ]
        )
    }
}
