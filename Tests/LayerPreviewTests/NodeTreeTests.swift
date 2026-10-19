import CoreGraphics
@testable import LayerPreview
import Testing

struct NodeTreeTests {
    @Test func mergesNodesThatShareAFrame() {
        var nodes = TestNodes()
        let frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let profile = nodes.add("ProfileView", frame: frame)
        let stack = nodes.add("VStack", frame: frame, parent: profile)
        nodes.add("Text", frame: CGRect(x: 10, y: 10, width: 50, height: 20), parent: stack)

        let tree = NodeTree(nodes.records)

        #expect(tree.labelGroups.map(\.title) == ["ProfileView › VStack", "Text"])
    }

    @Test func ignoresNodesWithoutFrame() {
        var nodes = TestNodes()
        let root = nodes.add("VStack", frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        var unmeasured = NodeRecord(id: LayerPreviewNodeID(), order: 1)
        unmeasured.parent = root

        let tree = NodeTree(nodes.records + [unmeasured])

        #expect(tree.nodes.count == 1)
        #expect(tree.children(of: root).isEmpty)
    }
}
