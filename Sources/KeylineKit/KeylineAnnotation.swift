/// The annotations `#Keyline` draws.
///
///     #Keyline(.layers, .padding, .safeArea) {
///         MyView()
///     }
///
/// With no values, `.layers`, `.padding` and `.spacing` are drawn.
public enum KeylineAnnotation: CaseIterable, Hashable, Sendable {
    /// Hides every annotation; layer outlines follow `showContainerLines`.
    case none
    /// Names each layer next to its bounds.
    case layers
    /// Fills the measured padding of each `.padding(...)` call and labels each edge.
    case padding
    /// Fills the measured gap between siblings of a `VStack` or `HStack`.
    case spacing
    /// Draws width and height dimension lines for each layer.
    case size
    /// Draws the corner radius declared with `cornerRadius:` or `.cornerRadius(_:)`.
    case corners
    /// Draws the device safe-area insets and the reserved regions that cover content, such as camera housings.
    case safeArea

    static let defaults: Set<Self> = [.layers, .padding, .spacing]

    static func resolved(_ annotations: [Self]) -> Set<Self> {
        if annotations.contains(.none) { return [] }
        return annotations.isEmpty ? defaults : Set(annotations)
    }
}
