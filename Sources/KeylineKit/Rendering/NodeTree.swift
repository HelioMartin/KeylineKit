import CoreGraphics

/// The measured nodes of a surface as a tree.
struct NodeTree {
    /// A label for one node, or for a chain of nodes that share a frame,
    /// such as an inspectable view and the root of its body.
    struct LabelGroup: Equatable {
        let frame: CGRect
        let title: String
    }

    /// Nodes that are registered and measured, in registration order.
    let nodes: [NodeRecord]
    let labelGroups: [LabelGroup]
    private let childrenByParent: [KeylineNodeID: [NodeRecord]]

    init(_ records: some Collection<NodeRecord>) {
        let nodes = records
            .filter { $0.declaration != nil && $0.frame != nil }
            .sorted { $0.order < $1.order }
        let ids = Set(nodes.map(\.id))
        let childrenByParent = Dictionary(grouping: nodes.filter { $0.parent.map(ids.contains) == true }) { $0.parent! }
        let roots = nodes.filter { $0.parent.map(ids.contains) != true }

        var groups: [LabelGroup] = []
        func visit(_ node: NodeRecord) {
            var chain = [node]
            while let children = childrenByParent[chain[chain.count - 1].id],
                  children.count == 1,
                  Self.sameFrame(children[0].frame, chain[chain.count - 1].frame) {
                chain.append(children[0])
            }
            groups.append(LabelGroup(
                frame: node.frame!,
                title: chain.compactMap(\.declaration?.name).joined(separator: " › ")
            ))
            childrenByParent[chain[chain.count - 1].id]?.forEach(visit)
        }
        roots.forEach(visit)

        self.nodes = nodes
        self.labelGroups = groups
        self.childrenByParent = childrenByParent
    }

    func children(of id: KeylineNodeID) -> [NodeRecord] {
        childrenByParent[id] ?? []
    }

    private static func sameFrame(_ lhs: CGRect?, _ rhs: CGRect?) -> Bool {
        guard let lhs, let rhs else { return false }
        return abs(lhs.minX - rhs.minX) < 0.5 && abs(lhs.minY - rhs.minY) < 0.5
            && abs(lhs.width - rhs.width) < 0.5 && abs(lhs.height - rhs.height) < 0.5
    }
}
