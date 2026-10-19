import CoreGraphics
import Foundation

struct KeylineNodeID: Hashable, Sendable {
    private let rawValue = UUID()
}

/// Everything measured for one node, in global coordinates.
struct NodeRecord: Equatable {
    let id: KeylineNodeID
    /// Registration order, used to draw and place labels deterministically.
    let order: Int
    var parent: KeylineNodeID?
    var declaration: _KeylineDeclaration?
    var frame: CGRect?
    /// Keyed by the index of the `.padding(...)` call in the modifier chain.
    var paddings: [Int: PaddingMeasurement] = [:]
    var corners: [Int: CornerMeasurement] = [:]
}

struct PaddingMeasurement: Equatable {
    var inner: CGRect?
    var outer: CGRect?
    var declared: String?
}

struct CornerMeasurement: Equatable {
    var frame: CGRect
    var declared: String
    var radius: CGFloat
}
