import Testing

/// The probes inserted into a node's modifier chain.
struct ModifierProbeTests {
    @Test func probesEachPaddingCall() {
        assertMacro(
            """
            #Keyline {
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
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(Text("A")
                    ._keylineProbe(.paddingInner(0))
                    .padding()
                    ._keylineProbe(.paddingOuter(0, declared: "default"))
                    ._keylineProbe(.paddingInner(1))
                    .padding(.horizontal, 20)
                    ._keylineProbe(.paddingOuter(1, declared: "20"))
                    ._keylineProbe(.paddingInner(2))
                    .padding([.top, .leading], 8)
                    ._keylineProbe(.paddingOuter(2, declared: "8"))
                    ._keylineProbe(.paddingInner(3))
                    .padding(.top)
                    ._keylineProbe(.paddingOuter(3, declared: "default"))
                    ._keylineProbe(.paddingInner(4))
                    .padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
                    ._keylineProbe(.paddingOuter(4, declared: nil))
                    ._keylineProbe(.paddingInner(5))
                    .padding(Theme.spacing)
                    ._keylineProbe(.paddingOuter(5, declared: "Theme.spacing")), _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    @Test func probesCornerRadiusModifiers() {
        assertMacro(
            """
            #Keyline {
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
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(Text("A")
                    .background(.blue, in: RoundedRectangle(cornerRadius: 24))
                    ._keylineProbe(.corner(0, declared: "24", radius: Double(24)))
                    .clipShape(.rect(cornerRadius: Theme.radius))
                    ._keylineProbe(.corner(1, declared: "Theme.radius", radius: Double(Theme.radius)))
                    .cornerRadius(8)
                    ._keylineProbe(.corner(2, declared: "8", radius: Double(8)))
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                    }, _KeylineDeclaration("Text"))
                    }))
            """
        )
    }

    /// Xcode's Canvas wraps literals in `__designTime…` calls; labels show
    /// the fallback value while the code keeps the live literal.
    @Test func stripsDesignTimeLiteralsFromLabels() {
        assertMacro(
            #"""
            #Keyline {
                VStack(spacing: __designTimeInteger("#1", fallback: 12)) {
                    Text("A")
                }
                .padding(CGFloat(__designTimeInteger("#2", fallback: 24)))
            }
            """#,
            expandsTo: #"""
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(VStack(spacing: __designTimeInteger("#1", fallback: 12)) {
                    _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                }
                ._keylineProbe(.paddingInner(0))
                .padding(CGFloat(__designTimeInteger("#2", fallback: 24)))
                ._keylineProbe(.paddingOuter(0, declared: "CGFloat(24)")), _KeylineDeclaration("VStack", stack: .vertical, spacing: "12"))
                    }))
            """#
        )
    }
}
