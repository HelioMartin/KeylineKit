import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// How `#LayerPreview` forwards its arguments to `_LayerPreviewSurface`.
struct LayerPreviewMacroTests {
    @Test func expandsTrailingClosureWithDefaultArguments() {
        assertMacro(
            """
            #LayerPreview {
                VStack {
                    ProfileView()
                }
                .padding(24)
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(VStack {
                    _LayerPreviewNode(ProfileView(), _LayerPreviewDeclaration("ProfileView"))
                }
                ._layerPreviewProbe(.paddingInner(0))
                .padding(24)
                ._layerPreviewProbe(.paddingOuter(0, declared: "24")), _LayerPreviewDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    @Test func forwardsAnnotations() {
        assertMacro(
            """
            #LayerPreview(.layers, .padding) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([.layers, .padding], showContainerLines: true, content: {
                _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    /// Regression: without annotations, `false` used to be dropped.
    @Test func forwardsDisabledContainerLines() {
        assertMacro(
            """
            #LayerPreview(showContainerLines: false) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([], showContainerLines: false, content: {
                _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func forwardsNoneAnnotation() {
        assertMacro(
            """
            #LayerPreview(.none) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([.none], showContainerLines: true, content: {
                _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    /// Regression: the first annotation used to be taken as the content.
    @Test func findsLabeledBodyArgument() {
        assertMacro(
            """
            #LayerPreview(.padding, body: { Text("A") })
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([.padding], showContainerLines: true, content: {
                        _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func requiresClosure() {
        assertMacro(
            """
            #LayerPreview()
            """,
            expandsTo: """
            ()
            """,
            diagnostics: [
                DiagnosticSpec(message: "#LayerPreview requires a view closure", line: 1, column: 1),
            ]
        )
    }
}
