import SwiftUI

/// Collects the frames every node and probe of one `#Keyline` surface
/// reports. Nodes only write to it; the annotation canvas observes it.
@MainActor
final class KeylineRegistry: ObservableObject {
    @Published private(set) var nodes: [KeylineNodeID: NodeRecord] = [:]
    @Published var safeArea: SafeAreaSnapshot?
    private var nextOrder = 0

    func register(_ id: KeylineNodeID, parent: KeylineNodeID?, declaration: _KeylineDeclaration) {
        update(id) { record in
            record.parent = parent
            record.declaration = declaration
        }
    }

    func updateFrame(_ frame: CGRect, for id: KeylineNodeID) {
        update(id) { $0.frame = frame }
    }

    func record(_ probe: _KeylineProbe, frame: CGRect, for owner: KeylineNodeID) {
        update(owner) { record in
            switch probe {
            case .paddingInner(let index):
                record.paddings[index, default: PaddingMeasurement()].inner = frame
            case .paddingOuter(let index, let declared):
                record.paddings[index, default: PaddingMeasurement()].outer = frame
                record.paddings[index]?.declared = declared
            case .corner(let index, let declared, let radius):
                record.corners[index] = CornerMeasurement(frame: frame, declared: declared, radius: CGFloat(radius))
            }
        }
    }

    func remove(_ id: KeylineNodeID) {
        nodes[id] = nil
    }

    /// Frames and probes can report before `onAppear` registers the node, so
    /// every update creates the record if needed. Unchanged records are not
    /// reassigned, to avoid publishing redundant changes.
    private func update(_ id: KeylineNodeID, _ change: (inout NodeRecord) -> Void) {
        var record = nodes[id] ?? makeRecord(id)
        change(&record)
        if nodes[id] != record {
            nodes[id] = record
        }
    }

    private func makeRecord(_ id: KeylineNodeID) -> NodeRecord {
        defer { nextOrder += 1 }
        return NodeRecord(id: id, order: nextOrder)
    }
}
