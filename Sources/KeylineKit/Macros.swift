import SwiftUI

/// Renders a SwiftUI view with every node it declares measured and annotated
/// on the Canvas: layer bounds and names, padding, stack spacing, sizes,
/// corner radii and the device safe area.
///
///     #Preview {
///         #Keyline(.padding, .spacing) {
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
public macro Keyline(
    _ annotations: KeylineAnnotation...,
    showContainerLines: Bool = true,
    @ViewBuilder body: @escaping @MainActor () -> any View
) -> AnyView = #externalMacro(module: "KeylineKitMacros", type: "KeylineMacro")

/// Lets `#Keyline` expand the contents of a custom view's `body`
/// instead of drawing the view as a single opaque node.
///
///     @Keylined
///     struct ProfileView: View {
///         var body: some View { ... }
///     }
@attached(member, names: named(_keylineTaggedBody), named(_keylineBody))
@attached(extension, conformances: KeylineInspectable)
public macro Keylined() = #externalMacro(module: "KeylineKitMacros", type: "KeylinedMacro")
