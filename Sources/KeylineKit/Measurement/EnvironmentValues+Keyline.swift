import SwiftUI

extension EnvironmentValues {
    /// The registry of the enclosing `#Keyline` surface.
    @Entry var keylineRegistry: KeylineRegistry? = nil
    /// The nearest enclosing node: the parent of nested nodes and the owner of probes.
    @Entry var keylineNode: KeylineNodeID? = nil
    /// The colors set with `keylineColors(_:)` over the default palette.
    @Entry var keylineColors = KeylineColors()
}
