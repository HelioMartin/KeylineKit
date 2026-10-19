import SwiftUI

extension EnvironmentValues {
    /// The registry of the enclosing `#Keyline` surface.
    @Entry var keylineRegistry: KeylineRegistry? = nil
    /// The nearest enclosing node: the parent of nested nodes and the owner of probes.
    @Entry var keylineNode: KeylineNodeID? = nil
}
