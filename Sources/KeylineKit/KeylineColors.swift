import SwiftUI

/// Colors that replace the default palette of `#Keyline` annotations.
///
///     #Keyline(.padding, .safeArea) {
///         AccountScreen()
///     }
///     .keylineColors(KeylineColors(padding: .red, content: .blue))
///
/// A color draws the lines and badges of its elements, and a translucent
/// copy fills their regions. Badge text stays white, so pick colors dark
/// enough to read it; a dynamic color adapts to light and dark mode.
/// A `nil` color keeps the default.
public struct KeylineColors: Hashable, Sendable {
    /// Layer outlines and names. Blue by default.
    public var layers: Color?
    /// Padding bands and their values, and the safe-area insets. Orange by default.
    public var padding: Color?
    /// The content outline of each padding band, and the safe area. Green by default.
    public var content: Color?
    /// Gaps between the siblings of a `VStack` or `HStack`. Purple by default.
    public var spacing: Color?
    /// Reserved regions that cover content, such as camera housings. Purple by default.
    public var reserved: Color?
    /// Corner radius arcs and values. Pink by default.
    public var corners: Color?
    /// Width and height dimension lines. Slate by default, white in dark mode.
    public var size: Color?

    public init(
        layers: Color? = nil,
        padding: Color? = nil,
        content: Color? = nil,
        spacing: Color? = nil,
        reserved: Color? = nil,
        corners: Color? = nil,
        size: Color? = nil
    ) {
        self.layers = layers
        self.padding = padding
        self.content = content
        self.spacing = spacing
        self.reserved = reserved
        self.corners = corners
        self.size = size
    }
}

extension KeylineColors {
    subscript(role: AnnotationRole) -> Color? {
        switch role {
        case .layers: layers
        case .padding: padding
        case .content: content
        case .spacing: spacing
        case .reserved: reserved
        case .corners: corners
        case .size: size
        }
    }

    /// These colors with every color `other` sets in their place.
    func overriding(with other: Self) -> Self {
        Self(
            layers: other.layers ?? layers,
            padding: other.padding ?? padding,
            content: other.content ?? content,
            spacing: other.spacing ?? spacing,
            reserved: other.reserved ?? reserved,
            corners: other.corners ?? corners,
            size: other.size ?? size
        )
    }
}

extension View {
    /// Draws the annotations of every `#Keyline` in this view with `colors`.
    ///
    /// Nested calls combine: each color set closer to `#Keyline` wins, and
    /// the rest come from the enclosing calls or the default palette.
    public func keylineColors(_ colors: KeylineColors) -> some View {
        transformEnvironment(\.keylineColors) { $0 = $0.overriding(with: colors) }
    }
}
