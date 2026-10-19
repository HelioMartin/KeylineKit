import SwiftUI

/// Draws every annotation of a surface in one canvas, so badges are laid out
/// together and never hide behind sibling views.
struct AnnotationCanvas: View {
    @ObservedObject var registry: KeylineRegistry
    let annotations: Set<KeylineAnnotation>
    let showsOutlines: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let records = Array(registry.nodes.values)
        let safeArea = registry.safeArea
        let theme = KeylineTheme(colorScheme: colorScheme)
        let annotations = annotations
        let showsOutlines = showsOutlines

        GeometryReader { proxy in
            // Nodes report global frames; drawing is shifted into this canvas.
            let bounds = proxy.frame(in: .global)
            Canvas { context, _ in
                let measuringContext = context
                let layout = AnnotationLayout(annotations: annotations, showsOutlines: showsOutlines, bounds: bounds) { text in
                    measuringContext.resolve(Self.label(text)).measure(in: CGSize(width: CGFloat.infinity, height: .infinity))
                }
                let scene = layout.scene(for: records, safeArea: safeArea)
                context.translateBy(x: -bounds.minX, y: -bounds.minY)
                Self.draw(scene, theme: theme, in: &context)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func label(_ text: String) -> Text {
        Text(verbatim: text).font(.system(size: 10, weight: .semibold, design: .monospaced))
    }

    private static func draw(_ scene: AnnotationScene, theme: KeylineTheme, in context: inout GraphicsContext) {
        for region in scene.regions {
            context.fill(region.path, with: .color(theme.fill(region.role)), style: FillStyle(eoFill: region.isEvenOdd))
        }
        for stroke in scene.strokes {
            let style = StrokeStyle(lineWidth: stroke.width, dash: stroke.isDashed ? [2, 3] : [])
            context.stroke(stroke.path, with: .color(theme.line(stroke.role).opacity(stroke.isDashed ? 0.7 : 1)), style: style)
        }
        for badge in scene.badges {
            context.fill(Path(roundedRect: badge.frame, cornerRadius: 3), with: .color(theme.line(badge.role)))
            var text = context.resolve(label(badge.text))
            text.shading = .color(theme.labelForeground(badge.role))
            let center = CGPoint(x: badge.frame.midX, y: badge.frame.midY)
            if badge.isRotated {
                var rotated = context
                rotated.translateBy(x: center.x, y: center.y)
                rotated.rotate(by: .degrees(-90))
                rotated.draw(text, at: .zero)
            } else {
                context.draw(text, at: center)
            }
        }
    }
}
