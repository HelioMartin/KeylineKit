import SwiftUI

/// A point in a node's modifier chain whose frame the overlay needs, inserted
/// by the macro around `.padding(...)` and after modifiers with a corner radius.
@_documentation(visibility: internal)
public enum _KeylineProbe: Hashable, Sendable {
    /// The frame before the node's `index`-th `.padding(...)` call.
    case paddingInner(Int)
    /// The frame after the node's `index`-th `.padding(...)` call.
    case paddingOuter(Int, declared: String?)
    /// The frame a corner radius applies to.
    case corner(Int, declared: String, radius: Double)
}

extension View {
    @_documentation(visibility: internal)
    public func _keylineProbe(_ probe: _KeylineProbe) -> some View {
        modifier(KeylineProbeModifier(probe: probe))
    }
}

private struct KeylineProbeModifier: ViewModifier {
    let probe: _KeylineProbe
    @Environment(\.keylineRegistry) private var registry
    @Environment(\.keylineNode) private var owner

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            guard let owner else { return }
            registry?.record(probe, frame: frame, for: owner)
        }
    }
}
