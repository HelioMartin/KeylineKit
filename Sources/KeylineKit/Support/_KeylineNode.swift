import SwiftUI

/// Registers one view of a `#Keyline` tree and its measured frame.
/// A `KeylineInspectable` view is replaced by its instrumented body.
@_documentation(visibility: internal)
public struct _KeylineNode<Content: View>: View {
    private let content: Content
    private let declaration: _KeylineDeclaration
    @State private var id = KeylineNodeID()
    @Environment(\.keylineRegistry) private var registry
    @Environment(\.keylineNode) private var parent

    public init(_ content: Content, _ declaration: _KeylineDeclaration) {
        self.content = content
        self.declaration = declaration
    }

    public var body: some View {
        resolvedContent
            .environment(\.keylineNode, id)
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
        if let inspectable = content as? any KeylineInspectable {
            inspectable._keylineBody
        } else {
            content
        }
    }
}
