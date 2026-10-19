import SwiftUI
@testable import LayerPreview
import Testing

struct AnnotationLayoutTests {
    private func scene(
        _ annotations: Set<LayerPreviewAnnotation>,
        nodes: TestNodes,
        safeArea: SafeAreaSnapshot? = nil
    ) -> AnnotationScene {
        let layout = AnnotationLayout(
            annotations: annotations,
            showsOutlines: false,
            bounds: CGRect(x: -50, y: -50, width: 600, height: 1000),
            measureText: measureText
        )
        return layout.scene(for: nodes.records, safeArea: safeArea)
    }

    @Test func labelsEveryPaddedEdgeWithItsMeasuredValue() {
        var nodes = TestNodes()
        nodes.add("VStack", frame: CGRect(x: 0, y: 0, width: 200, height: 200), paddings: [
            0: PaddingMeasurement(
                inner: CGRect(x: 24, y: 24, width: 152, height: 152),
                outer: CGRect(x: 0, y: 0, width: 200, height: 200),
                declared: "24"
            ),
        ])

        let result = scene([.padding], nodes: nodes)

        #expect(result.badges.map(\.text) == ["24", "24", "24", "24"])
        #expect(result.badges.allSatisfy { $0.role == .padding })
        #expect(result.regions.count == 1)
    }

    @Test func labelsOnlyEdgesWithPadding() {
        var nodes = TestNodes()
        nodes.add("Text", frame: CGRect(x: 0, y: 0, width: 100, height: 40), paddings: [
            0: PaddingMeasurement(
                inner: CGRect(x: 16, y: 0, width: 68, height: 40),
                outer: CGRect(x: 0, y: 0, width: 100, height: 40),
                declared: "default"
            ),
        ])

        let result = scene([.padding], nodes: nodes)

        #expect(result.badges.map(\.text) == ["16 · default", "16 · default"])
    }

    @Test func measuresGapsBetweenStackChildren() {
        var nodes = TestNodes()
        let stack = nodes.add("VStack", frame: CGRect(x: 0, y: 0, width: 100, height: 100), stack: .vertical, spacing: "default")
        // Registered out of order: gaps follow position, not registration.
        nodes.add("Text", frame: CGRect(x: 0, y: 60, width: 100, height: 40), parent: stack)
        nodes.add("Text", frame: CGRect(x: 0, y: 0, width: 100, height: 52), parent: stack)

        let result = scene([.spacing], nodes: nodes)

        #expect(result.badges.map(\.text) == ["8 · default"])
        #expect(result.regions.count == 1)
    }

    @Test func drawsSafeAreaInsetsAndLabel() {
        let safeArea = SafeAreaSnapshot(
            safeFrame: CGRect(x: 0, y: 59, width: 393, height: 759),
            insets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            occlusions: [CGRect(x: 134, y: 11.33, width: 125, height: 36.67)]
        )

        let result = scene([.safeArea], nodes: TestNodes(), safeArea: safeArea)

        #expect(result.badges.map(\.text) == ["OCCLUSION 125 × 36.67", "TOP 59", "BOTTOM 34", "SAFE AREA 393 × 759"])
    }

    @Test func placesLayerNameAboveTopLeadingCorner() throws {
        var nodes = TestNodes()
        nodes.add("VStack", frame: CGRect(x: 100, y: 100, width: 200, height: 100))

        let result = scene([.layers], nodes: nodes)
        let badge = try #require(result.badges.first)

        #expect(badge.text == "VStack")
        #expect(badge.frame.maxY <= 100)
        #expect(badge.frame.minX == 100)
    }

    @Test func drawsWidthAndRotatedHeightForSizes() {
        var nodes = TestNodes()
        nodes.add("Text", frame: CGRect(x: 100, y: 100, width: 120, height: 40))

        let result = scene([.size], nodes: nodes)

        #expect(result.badges.map(\.text) == ["120", "40"])
        #expect(result.badges.map(\.isRotated) == [false, true])
    }
}
