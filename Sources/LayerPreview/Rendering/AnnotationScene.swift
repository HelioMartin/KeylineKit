import SwiftUI

/// What an annotation element represents; the theme maps it to a color.
enum AnnotationRole: Hashable, Sendable {
    case layers, padding, content, spacing, reserved, corners, size
}

/// Everything the canvas draws, in global coordinates, back to front:
/// filled regions, then strokes, then badges.
struct AnnotationScene {
    struct Region {
        var path: Path
        var role: AnnotationRole
        /// Fills the area between the path's outer and inner rectangles.
        var isEvenOdd = false
    }

    struct Stroke {
        var path: Path
        var role: AnnotationRole
        var width: CGFloat = 1
        var isDashed = false
    }

    struct Badge: Equatable {
        var text: String
        var frame: CGRect
        var role: AnnotationRole
        /// Drawn rotated −90° along a vertical dimension line.
        var isRotated = false
    }

    var regions: [Region] = []
    var strokes: [Stroke] = []
    var badges: [Badge] = []
}
