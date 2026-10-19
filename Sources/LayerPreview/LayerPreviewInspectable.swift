import SwiftUI

/// A view whose `body` `#LayerPreview` can expand. Adopt it with
/// `@LayerPreviewInspectable` rather than conforming manually.
@MainActor
public protocol LayerPreviewInspectable {
    /// The view's `body` with every node instrumented for `#LayerPreview`.
    var _layerPreviewBody: AnyView { get }
}
