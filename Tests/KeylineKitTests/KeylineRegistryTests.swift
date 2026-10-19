import CoreGraphics
@testable import KeylineKit
import Testing

@MainActor
struct KeylineRegistryTests {
    @Test func collectsFramesAndProbesBeforeRegistration() throws {
        let registry = KeylineRegistry()
        let id = KeylineNodeID()
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = outer.insetBy(dx: 10, dy: 10)

        registry.record(.paddingInner(0), frame: inner, for: id)
        registry.updateFrame(outer, for: id)
        registry.record(.paddingOuter(0, declared: "10"), frame: outer, for: id)
        registry.register(id, parent: nil, declaration: _KeylineDeclaration("Text"))

        let record = try #require(registry.nodes[id])
        #expect(record.frame == outer)
        #expect(record.declaration?.name == "Text")
        #expect(record.paddings[0] == PaddingMeasurement(inner: inner, outer: outer, declared: "10"))
    }

    @Test func removesNodesThatDisappear() {
        let registry = KeylineRegistry()
        let id = KeylineNodeID()
        registry.updateFrame(.zero, for: id)

        registry.remove(id)

        #expect(registry.nodes.isEmpty)
    }
}
