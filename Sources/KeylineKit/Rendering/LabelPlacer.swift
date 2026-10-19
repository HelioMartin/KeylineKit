import CoreGraphics

/// Places badges so they never overlap each other: each badge takes the first
/// candidate position that is free and inside the bounds.
struct LabelPlacer {
    let bounds: CGRect
    private(set) var occupied: [CGRect] = []

    init(bounds: CGRect) {
        self.bounds = bounds
    }

    /// The frame for a badge of `size` centered on the first free candidate,
    /// and the candidate's index, or `nil` when every candidate is taken.
    mutating func placeIfFree(_ size: CGSize, around centers: [CGPoint]) -> (frame: CGRect, index: Int)? {
        for (index, center) in centers.enumerated() {
            let frame = Self.frame(of: size, centeredAt: center)
            if isFree(frame) {
                occupied.append(frame)
                return (frame, index)
            }
        }
        return nil
    }

    /// Like `placeIfFree`, but always places the badge: when no candidate is
    /// free it searches outward from the first one a badge at a time, and as
    /// a last resort moves the first candidate inside the bounds.
    mutating func place(_ size: CGSize, around centers: [CGPoint]) -> (frame: CGRect, index: Int) {
        if let placement = placeIfFree(size, around: centers) {
            return placement
        }
        let origin = centers[0]
        for step in 1...6 {
            let dx = CGFloat(step) * (size.width / 2 + 2)
            let dy = CGFloat(step) * (size.height + 2)
            for (x, y) in [(0, -dy), (0, dy), (-dx, 0), (dx, 0)] {
                let frame = Self.frame(of: size, centeredAt: CGPoint(x: origin.x + x, y: origin.y + y))
                if isFree(frame) {
                    occupied.append(frame)
                    return (frame, 0)
                }
            }
        }
        let frame = clamped(Self.frame(of: size, centeredAt: origin))
        occupied.append(frame)
        return (frame, 0)
    }

    private static func frame(of size: CGSize, centeredAt center: CGPoint) -> CGRect {
        CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
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
