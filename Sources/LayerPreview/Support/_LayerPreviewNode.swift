import SwiftUI

/// Registers one view of a `#LayerPreview` tree and its measured frame.
/// A `LayerPreviewInspectable` view is replaced by its instrumented body.
@_documentation(visibility: internal)
public struct _LayerPreviewNode<Content: View>: View {
    private let content: Content
    private let declaration: _LayerPreviewDeclaration
    @State private var id = LayerPreviewNodeID()
    @Environment(\.layerPreviewRegistry) private var registry
    @Environment(\.layerPreviewNode) private var parent

    public init(_ content: Content, _ declaration: _LayerPreviewDeclaration) {
        self.content = content
        self.declaration = declaration
    }

    public var body: some View {
        resolvedContent
            .environment(\.layerPreviewNode, id)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                registry?.updateFrame(frame, for: id)
            }
            .onAppear {
                registry?.register(id, parent: parent, declaration: declaration)
            }
            .onDisappear {
                registry?.remove(id)
            }
    }

    @ViewBuilder
    private var resolvedContent: some View {
        if let inspectable = content as? any LayerPreviewInspectable {
            inspectable._layerPreviewBody
        } else {
            content
        }
    }
}
