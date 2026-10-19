import SwiftUI

/// A point in a node's modifier chain whose frame the overlay needs, inserted
/// by the macro around `.padding(...)` and after modifiers with a corner radius.
@_documentation(visibility: internal)
public enum _LayerPreviewProbe: Hashable, Sendable {
    /// The frame before the node's `index`-th `.padding(...)` call.
    case paddingInner(Int)
    /// The frame after the node's `index`-th `.padding(...)` call.
    case paddingOuter(Int, declared: String?)
    /// The frame a corner radius applies to.
    case corner(Int, declared: String, radius: Double)
}

extension View {
    @_documentation(visibility: internal)
    public func _layerPreviewProbe(_ probe: _LayerPreviewProbe) -> some View {
        modifier(LayerPreviewProbeModifier(probe: probe))
    }
}

private struct LayerPreviewProbeModifier: ViewModifier {
    let probe: _LayerPreviewProbe
    @Environment(\.layerPreviewRegistry) private var registry
    @Environment(\.layerPreviewNode) private var owner

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            guard let owner else { return }
            registry?.record(probe, frame: frame, for: owner)
        }
    }
}
