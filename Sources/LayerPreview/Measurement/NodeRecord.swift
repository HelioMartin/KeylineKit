import CoreGraphics
import Foundation

struct LayerPreviewNodeID: Hashable, Sendable {
    private let rawValue = UUID()
}

/// Everything measured for one node, in global coordinates.
struct NodeRecord: Equatable {
    let id: LayerPreviewNodeID
    /// Registration order, used to draw and place labels deterministically.
    let order: Int
    var parent: LayerPreviewNodeID?
    var declaration: _LayerPreviewDeclaration?
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
