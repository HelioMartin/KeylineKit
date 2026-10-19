import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// How `#Keyline` forwards its arguments to `_KeylineSurface`.
struct KeylineMacroTests {
    @Test func expandsTrailingClosureWithDefaultArguments() {
        assertMacro(
            """
            #Keyline {
                VStack {
                    ProfileView()
                }
                .padding(24)
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(VStack {
                    _KeylineNode(ProfileView(), _KeylineDeclaration("ProfileView"))
                }
                ._keylineProbe(.paddingInner(0))
                .padding(24)
                ._keylineProbe(.paddingOuter(0, declared: "24")), _KeylineDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    @Test func forwardsAnnotations() {
        assertMacro(
            """
            #Keyline(.layers, .padding) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([.layers, .padding], showContainerLines: true, content: {
                _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    /// Regression: without annotations, `false` used to be dropped.
    @Test func forwardsDisabledContainerLines() {
        assertMacro(
            """
            #Keyline(showContainerLines: false) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: false, content: {
                _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func forwardsNoneAnnotation() {
        assertMacro(
            """
            #Keyline(.none) {
                Text("A")
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([.none], showContainerLines: true, content: {
                _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    /// Regression: the first annotation used to be taken as the content.
    @Test func findsLabeledBodyArgument() {
        assertMacro(
            """
            #Keyline(.padding, body: { Text("A") })
            """,
            expandsTo: """
            AnyView(_KeylineSurface([.padding], showContainerLines: true, content: {
                        _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func requiresClosure() {
        assertMacro(
            """
            #Keyline()
            """,
            expandsTo: """
            ()
            """,
            diagnostics: [
                DiagnosticSpec(message: "#Keyline requires a view closure", line: 1, column: 1),
            ]
        )
    }
}
