import Testing

/// Which expressions of a ViewBuilder body become `_LayerPreviewNode`s.
struct ViewTreeTaggerTests {
    @Test func declaresStackAxisAndSpacing() {
        assertMacro(
            """
            #LayerPreview {
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
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(VStack(alignment: .leading, spacing: 16) {
                    _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    _LayerPreviewNode(HStack {
                        _LayerPreviewNode(Text("B"), _LayerPreviewDeclaration("Text"))
                    }, _LayerPreviewDeclaration("HStack", stack: .horizontal, spacing: "default"))
                    _LayerPreviewNode(LazyVStack(spacing: nil) {
                        _LayerPreviewNode(Text("C"), _LayerPreviewDeclaration("Text"))
                    }, _LayerPreviewDeclaration("LazyVStack", stack: .vertical, spacing: "default"))
                }, _LayerPreviewDeclaration("VStack", stack: .vertical, spacing: "16"))
                    }))
            """
        )
    }

    @Test func recursesIntoControlFlow() {
        assertMacro(
            """
            #LayerPreview {
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
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(VStack {
                    if isOn {
                        _LayerPreviewNode(Text("On"), _LayerPreviewDeclaration("Text"))
                    } else if isIdle {
                        _LayerPreviewNode(Text("Idle"), _LayerPreviewDeclaration("Text"))
                    } else {
                        _LayerPreviewNode(Text("Off"), _LayerPreviewDeclaration("Text"))
                    }
                    switch state {
                    case .loading:
                        _LayerPreviewNode(ProgressView(), _LayerPreviewDeclaration("ProgressView"))
                    default:
                        _LayerPreviewNode(EmptyView(), _LayerPreviewDeclaration("EmptyView"))
                    }
                }, _LayerPreviewDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    /// `ForEach` and `Group` children stay siblings of the enclosing stack.
    @Test func treatsForEachAndGroupAsTransparent() {
        assertMacro(
            """
            #LayerPreview {
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
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(VStack {
                    ForEach(items) { item in
                        _LayerPreviewNode(Row(item), _LayerPreviewDeclaration("Row"))
                    }
                    Group {
                        _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                    }
                    _LayerPreviewNode(Group {
                        _LayerPreviewNode(Text("B"), _LayerPreviewDeclaration("Text"))
                    }
                    ._layerPreviewProbe(.paddingInner(0))
                    .padding()
                    ._layerPreviewProbe(.paddingOuter(0, declared: "default")), _LayerPreviewDeclaration("Group"))
                }, _LayerPreviewDeclaration("VStack", stack: .vertical, spacing: "default"))
                    }))
            """
        )
    }

    /// Capitalized initializers are containers unless their closure is an
    /// action or builds non-view content.
    @Test func recursesOnlyIntoViewContentClosures() {
        assertMacro(
            """
            #LayerPreview {
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
            AnyView(_LayerPreviewSurface([], showContainerLines: true, content: {
                _LayerPreviewNode(CustomCard {
                    _LayerPreviewNode(Text("A"), _LayerPreviewDeclaration("Text"))
                }, _LayerPreviewDeclaration("CustomCard"))
                _LayerPreviewNode(Button("Save") {
                    save()
                }, _LayerPreviewDeclaration("Button"))
                _LayerPreviewNode(Button(action: save) {
                    _LayerPreviewNode(Text("Save"), _LayerPreviewDeclaration("Text"))
                }, _LayerPreviewDeclaration("Button"))
                _LayerPreviewNode(Button {
                    save()
                } label: {
                    _LayerPreviewNode(Label("Save", systemImage: "tray"), _LayerPreviewDeclaration("Label"))
                }, _LayerPreviewDeclaration("Button"))
                _LayerPreviewNode(Canvas { context, size in
                    context.fill(path, with: .color(.red))
                }, _LayerPreviewDeclaration("Canvas"))
                    }))
            """
        )
    }
}
