import Testing

/// The probes inserted into a node's modifier chain.
struct ModifierProbeTests {
    @Test func probesEachPaddingCall() {
        assertMacro(
            """
            #LayerPreview {
                Text("A")
                    .padding()
                    .padding(.horizontal, 20)
                    .padding([.top, .leading], 8)
                    .padding(.top)
                    .padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
                    .padding(Theme.spacing)
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(Text("A")
                    ._layerPreviewProbe(.paddingInner(0))
                    .padding()
                    ._layerPreviewProbe(.paddingOuter(0, declared: "default"))
                    ._layerPreviewProbe(.paddingInner(1))
                    .padding(.horizontal, 20)
                    ._layerPreviewProbe(.paddingOuter(1, declared: "20"))
                    ._layerPreviewProbe(.paddingInner(2))
                    .padding([.top, .leading], 8)
                    ._layerPreviewProbe(.paddingOuter(2, declared: "8"))
                    ._layerPreviewProbe(.paddingInner(3))
                    .padding(.top)
                    ._layerPreviewProbe(.paddingOuter(3, declared: "default"))
                    ._layerPreviewProbe(.paddingInner(4))
                    .padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
                    ._layerPreviewProbe(.paddingOuter(4, declared: nil))
                    ._layerPreviewProbe(.paddingInner(5))
                    .padding(Theme.spacing)
                    ._layerPreviewProbe(.paddingOuter(5, declared: "Theme.spacing")), _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func probesCornerRadiusModifiers() {
        assertMacro(
            """
            #LayerPreview {
                Text("A")
                    .background(.blue, in: RoundedRectangle(cornerRadius: 24))
                    .clipShape(.rect(cornerRadius: Theme.radius))
                    .cornerRadius(8)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                    }
            }
            """,
            expandsTo: """
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(Text("A")
                    .background(.blue, in: RoundedRectangle(cornerRadius: 24))
                    ._layerPreviewProbe(.corner(0, declared: "24", radius: Double(24)))
                    .clipShape(.rect(cornerRadius: Theme.radius))
                    ._layerPreviewProbe(.corner(1, declared: "Theme.radius", radius: Double(Theme.radius)))
                    .cornerRadius(8)
                    ._layerPreviewProbe(.corner(2, declared: "8", radius: Double(8)))
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                    }, _LayerPreviewDeclaration("Text"))
                    }))
            """
        )
    }

    /// Xcode's Canvas wraps literals in `__designTime…` calls; labels show
    /// the fallback value while the code keeps the live literal.
    @Test func stripsDesignTimeLiteralsFromLabels() {
        assertMacro(
            #"""
            #LayerPreview {
                VStack(spacing: __designTimeInteger("#1", fallback: 12)) {
                    Text("A")
                }
                .padding(CGFloat(__designTimeInteger("#2", fallback: 24)))
            }
            """#,
            expandsTo: #"""
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(VStack(spacing: __designTimeInteger("#1", fallback: 12)) {
                    _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                }
                ._layerPreviewProbe(.paddingInner(0))
                .padding(CGFloat(__designTimeInteger("#2", fallback: 24)))
                ._layerPreviewProbe(.paddingOuter(0, declared: "CGFloat(24)")), _LayerPreviewDeclaration("VStack", stack: .vertical, spacing: "12"))
                    }))
            """#
        )
    }
}
