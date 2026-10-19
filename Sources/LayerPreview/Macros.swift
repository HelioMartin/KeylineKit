import SwiftUI

/// Renders a SwiftUI view with every node it declares measured and annotated
/// on the Canvas: layer bounds and names, padding, stack spacing, sizes,
/// corner radii and the device safe area.
///
///     #Preview {
///         #LayerPreview(.padding, .spacing) {
///             VStack(spacing: 16) {
///                 ProfileView()
///             }
///             .padding(24)
///         }
///     }
///
/// With no annotations, `.layers`, `.padding` and `.spacing` are shown.
/// Layer outlines are drawn unless `showContainerLines` is `false`.
@freestanding(expression)
public macro LayerPreview(
    _ annotations: LayerPreviewAnnotation...,
    showContainerLines: Bool = true,
    @ViewBuilder body: @escaping @MainActor () -> any View
) -> AnyView = #externalMacro(module: "LayerPreviewMacros", type: "LayerPreviewMacro")

/// Lets `#LayerPreview` expand the contents of a custom view's `body`
/// instead of drawing the view as a single opaque node.
///
///     @LayerPreviewInspectable
///     struct ProfileView: View {
///         var body: some View { ... }
///     }
@attached(member, names: named(_layerPreviewTaggedBody), named(_layerPreviewBody))
@attached(extension, conformances: LayerPreviewInspectable)
public macro LayerPreviewInspectable() = #externalMacro(module: "LayerPreviewMacros", type: "LayerPreviewInspectableMacro")
