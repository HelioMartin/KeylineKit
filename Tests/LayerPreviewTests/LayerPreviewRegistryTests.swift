import CoreGraphics
@testable import LayerPreview
import Testing

@MainActor
struct LayerPreviewRegistryTests {
    @Test func collectsFramesAndProbesBeforeRegistration() throws {
        let registry = LayerPreviewRegistry()
        let id = LayerPreviewNodeID()
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = outer.insetBy(dx: 10, dy: 10)

        registry.record(.paddingInner(0), frame: inner, for: id)
        registry.updateFrame(outer, for: id)
        registry.record(.paddingOuter(0, declared: "10"), frame: outer, for: id)
        registry.register(id, parent: nil, declaration: _LayerPreviewDeclaration("Text"))

        let record = try #require(registry.nodes[id])
        #expect(record.frame == outer)
        #expect(record.declaration?.name == "Text")
        #expect(record.paddings[0] == PaddingMeasurement(inner: inner, outer: outer, declared: "10"))
    }

    @Test func removesNodesThatDisappear() {
        let registry = LayerPreviewRegistry()
        let id = LayerPreviewNodeID()
        registry.updateFrame(.zero, for: id)

        registry.remove(id)

        #expect(registry.nodes.isEmpty)
    }
}
