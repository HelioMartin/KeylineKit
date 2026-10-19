import SwiftUI

/// The view `#Keyline` expands to: hosts the instrumented content and
/// draws every annotation in a single overlay.
@_documentation(visibility: internal)
public struct _KeylineSurface<Content: View>: View {
    private let content: Content
    private let annotations: Set<KeylineAnnotation>
    private let showsOutlines: Bool
    // Held in `@State`, not `@StateObject`: observing the registry here would
    // re-render the whole preview on every geometry change. Only the canvas
    // observes it.
    @State private var registry = KeylineRegistry()

    public init(
        _ annotations: [KeylineAnnotation],
        showContainerLines: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.annotations = KeylineAnnotation.resolved(annotations)
        self.showsOutlines = showContainerLines
    }

    public var body: some View {
        // The safe area is measured on the whole screen, so the content is
        // centered in it like a regular preview.
        let fillsScreen = annotations.contains(.safeArea)
        content
            .environment(\.keylineRegistry, registry)
            .frame(maxWidth: fillsScreen ? .infinity : nil, maxHeight: fillsScreen ? .infinity : nil)
            .background {
                if fillsScreen {
                    SafeAreaReader(registry: registry)
                }
            }
            .overlay {
                AnnotationCanvas(registry: registry, annotations: annotations, showsOutlines: showsOutlines)
                    .ignoresSafeArea()
            }
    }
}
