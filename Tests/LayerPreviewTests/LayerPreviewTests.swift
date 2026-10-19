import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(LayerPreviewMacros)
import LayerPreviewMacros

let testMacros: [String: Macro.Type] = [
    "LayerPreview": LayerPreviewMacro.self,
    "LayerPreviewInspectable": LayerPreviewInspectableMacro.self,
]
#endif

final class LayerPreviewTests: XCTestCase {
    func testLayerPreviewExpansion() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview {
                VStack {
                    ProfileView()
                }
                .padding(24)
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            VStack {
                                LayerPreviewInspectorBridge(
                                        ProfileView(), name: "ProfileView", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }
                            .padding(24), name: "VStack", edges: LayerPreviewEdgePadding(top: "24", bottom: "24", leading: "24", trailing: "24"), labelLevel: 0, isContainer: true).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewAnnotationSelection() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview(.layers, .padding) {
                Text("A")
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([.layers, .padding], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            Text("A"), name: "Text", edges: nil, labelLevel: 0, isContainer: false).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewContainerLinesCanBeEnabled() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview(showContainerLines: true) {
                VStack {
                    Text("A")
                }
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            VStack {
                                LayerPreviewInspectorBridge(
                                        Text("A"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }, name: "VStack", edges: nil, labelLevel: 0, isContainer: true).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewNoneAnnotation() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview(.none) {
                Text("A")
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([.none], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            Text("A"), name: "Text", edges: nil, labelLevel: 0, isContainer: false).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Xcode's Canvas rewrites literals to `__designTimeInteger(...)` for live
    /// editing; the fallback value must be shown instead of the wrapper call.
    func testLayerPreviewStripsDesignTimeLiterals() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            #"""
            #LayerPreview {
                VStack {
                    Text("A")
                }
                .padding(__designTimeInteger("#123", fallback: 24))
            }
            """#,
            expandedSource: #"""
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            VStack {
                                LayerPreviewInspectorBridge(
                                        Text("A"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }
                            .padding(__designTimeInteger("#123", fallback: 24)), name: "VStack", edges: LayerPreviewEdgePadding(top: "24", bottom: "24", leading: "24", trailing: "24"), labelLevel: 0, isContainer: true).zIndex(1)
                    }))
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    /// Any capitalized container works, not just a hardcoded list, while
    /// `Button`'s action closure is still left untouched.
    func testLayerPreviewRecursesIntoAnyCapitalizedContainer() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview {
                CustomCard {
                    Text("A")
                }
                Button("Save") {
                    save()
                }
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            CustomCard {
                                LayerPreviewInspectorBridge(
                                        Text("A"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }, name: "CustomCard", edges: nil, labelLevel: 0, isContainer: true).zIndex(2)
                        LayerPreviewInspectorBridge(
                            Button("Save") {
                                save()
                            }, name: "Button", edges: nil, labelLevel: 0, isContainer: false).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewSpacingBetweenSiblings() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview {
                VStack(spacing: 16) {
                    Text("A")
                    Text("B")
                }
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            VStack(spacing: 16) {
                                LayerPreviewInspectorBridge(
                                        Text("A"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).layerPreviewSpacing(axis: .vertical, label: "↕︎ 16", distance: 16).zIndex(2)
                                LayerPreviewInspectorBridge(
                                        Text("B"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }, name: "VStack", edges: nil, labelLevel: 0, isContainer: true).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testZStackIsRecognizedAsContainer() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview {
                ZStack {
                    Text("A")
                }
            }
            """,
            expandedSource: """
            AnyView(LayerPreviewSurface([], showContainerLines: true, content: {
                        LayerPreviewInspectorBridge(
                            ZStack {
                                LayerPreviewInspectorBridge(
                                        Text("A"), name: "Text", edges: nil, labelLevel: 1, isContainer: false).zIndex(1)
                            }, name: "ZStack", edges: nil, labelLevel: 0, isContainer: true).zIndex(1)
                    }))
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewInspectableExpansion() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            @LayerPreviewInspectable
            struct ProfileView: View {
                var body: some View {
                    Text("Hi")
                        .padding(24)
                }
            }
            """,
            expandedSource: """
            struct ProfileView: View {
                var body: some View {
                    Text("Hi")
                        .padding(24)
                }

                @ViewBuilder private var __layerPreviewTaggedBody: some View {
                    LayerPreviewInspectorBridge(
                            Text("Hi")
                                .padding(24), name: "Text", edges: LayerPreviewEdgePadding(top: "24", bottom: "24", leading: "24", trailing: "24"), labelLevel: 0, isContainer: false).zIndex(1)
                }

                var layerPreviewContent: AnyView {
                    AnyView(__layerPreviewTaggedBody)
                }

                var layerPreviewContentEdges: LayerPreviewEdgePadding? {
                    LayerPreviewEdgePadding(top: "24", bottom: "24", leading: "24", trailing: "24")
                }
            }

            extension ProfileView: LayerPreviewInspectable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLayerPreviewRequiresClosure() throws {
        #if canImport(LayerPreviewMacros)
        assertMacroExpansion(
            """
            #LayerPreview()
            """,
            expandedSource: """
            ()
            """,
            diagnostics: [
                DiagnosticSpec(message: "#LayerPreview requires a view closure", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
