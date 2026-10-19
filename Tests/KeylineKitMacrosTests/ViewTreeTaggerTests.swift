import Testing

/// Which expressions of a ViewBuilder body become `_KeylineNode`s.
struct ViewTreeTaggerTests {
    @Test func declaresStackAxisAndSpacing() {
        assertMacro(
            """
            #Keyline {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A")
                    HStack {
                        Text("B")
                    }
                    LazyVStack(spacing: nil) {
                        Text("C")
                    }
                }
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(VStack(alignment: .leading, spacing: 16) {
                    _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    _KeylineNode(HStack {
                        _KeylineNode(Text("B"), _KeylineDeclaration("Text"))
                    }, _KeylineDeclaration("HStack", stack: .horizontal, spacing: "default"))
                    _KeylineNode(LazyVStack(spacing: nil) {
                        _KeylineNode(Text("C"), _KeylineDeclaration("Text"))
                    }, _KeylineDeclaration("LazyVStack", stack: .vertical, spacing: "default"))
                }, _KeylineDeclaration("VStack", stack: .vertical, spacing: "16"))
                    }))
            """
        )
    }

    @Test func recursesIntoControlFlow() {
        assertMacro(
            """
            #Keyline {
                VStack {
                    if isOn {
                        Text("On")
                    } else if isIdle {
                        Text("Idle")
                    } else {
                        Text("Off")
                    }
                    switch state {
                    case .loading:
                        ProgressView()
                    default:
                        EmptyView()
                    }
                }
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(VStack {
                    if isOn {
                        _KeylineNode(Text("On"), _KeylineDeclaration("Text"))
                    } else if isIdle {
                        _KeylineNode(Text("Idle"), _KeylineDeclaration("Text"))
                    } else {
                        _KeylineNode(Text("Off"), _KeylineDeclaration("Text"))
                    }
                    switch state {
                    case .loading:
                        _KeylineNode(ProgressView(), _KeylineDeclaration("ProgressView"))
                    default:
                        _KeylineNode(EmptyView(), _KeylineDeclaration("EmptyView"))
                    }
                }, _KeylineDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    /// `ForEach` and `Group` children stay siblings of the enclosing stack.
    @Test func treatsForEachAndGroupAsTransparent() {
        assertMacro(
            """
            #Keyline {
                VStack {
                    ForEach(items) { item in
                        Row(item)
                    }
                    Group {
                        Text("A")
                    }
                    Group {
                        Text("B")
                    }
                    .padding()
                }
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(VStack {
                    ForEach(items) { item in
                        _KeylineNode(Row(item), _KeylineDeclaration("Row"))
                    }
                    Group {
                        _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                    }
                    _KeylineNode(Group {
                        _KeylineNode(Text("B"), _KeylineDeclaration("Text"))
                    }
                    ._keylineProbe(.paddingInner(0))
                    .padding()
                    ._keylineProbe(.paddingOuter(0, declared: "default")), _KeylineDeclaration("Group"))
                }, _KeylineDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    /// Capitalized initializers are containers unless their closure is an
    /// action or builds non-view content.
    @Test func recursesOnlyIntoViewContentClosures() {
        assertMacro(
            """
            #Keyline {
                CustomCard {
                    Text("A")
                }
                Button("Save") {
                    save()
                }
                Button(action: save) {
                    Text("Save")
                }
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "tray")
                }
                Canvas { context, size in
                    context.fill(path, with: .color(.red))
                }
            }
            """,
            expandsTo: """
            AnyView(_KeylineSurface([], showContainerLines: true, content: {
                _KeylineNode(CustomCard {
                    _KeylineNode(Text("A"), _KeylineDeclaration("Text"))
                }, _KeylineDeclaration("CustomCard"))
                _KeylineNode(Button("Save") {
                    save()
                }, _KeylineDeclaration("Button"))
                _KeylineNode(Button(action: save) {
                    _KeylineNode(Text("Save"), _KeylineDeclaration("Text"))
                }, _KeylineDeclaration("Button"))
                _KeylineNode(Button {
                    save()
                } label: {
                    _KeylineNode(Label("Save", systemImage: "tray"), _KeylineDeclaration("Label"))
                }, _KeylineDeclaration("Button"))
                _KeylineNode(Canvas { context, size in
                    context.fill(path, with: .color(.red))
                }, _KeylineDeclaration("Canvas"))
                    }))
            """
        )
    }
}
