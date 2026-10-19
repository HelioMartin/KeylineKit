import CoreGraphics

/// Places badges so they never overlap each other: each badge takes the first
/// candidate position that is free and inside the bounds.
struct LabelPlacer {
    let bounds: CGRect
    private(set) var occupied: [CGRect] = []

    init(bounds: CGRect) {
        self.bounds = bounds
    }

    /// Returns the frame for a badge of `size` centered on one of `centers`,
    /// and the index of the chosen center. When no candidate is free, the
    /// first one is used, moved inside the bounds.
    mutating func place(_ size: CGSize, around centers: [CGPoint]) -> (frame: CGRect, index: Int) {
        let frames = centers.map { center in
            CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
        }
        let placement = frames.firstIndex(where: isFree).map { (frames[$0], $0) } ?? (clamped(frames[0]), 0)
        occupied.append(placement.0)
        return placement
    }

    private func isFree(_ frame: CGRect) -> Bool {
        bounds.contains(frame) && !occupied.contains { $0.insetBy(dx: -1, dy: -1).intersects(frame) }
    }

    private func clamped(_ frame: CGRect) -> CGRect {
        var result = frame
        result.origin.x = min(max(frame.minX, bounds.minX), max(bounds.maxX - frame.width, bounds.minX))
        result.origin.y = min(max(frame.minY, bounds.minY), max(bounds.maxY - frame.height, bounds.minY))
        return result
    }
}
