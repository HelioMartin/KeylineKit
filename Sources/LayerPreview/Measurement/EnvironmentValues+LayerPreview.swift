import SwiftUI

extension EnvironmentValues {
    /// The registry of the enclosing `#LayerPreview` surface.
    @Entry var layerPreviewRegistry: LayerPreviewRegistry? = nil
    /// The nearest enclosing node: the parent of nested nodes and the owner of probes.
    @Entry var layerPreviewNode: LayerPreviewNodeID? = nil
}
