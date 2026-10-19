@testable import LayerPreview
import Testing

struct LayerPreviewAnnotationTests {
    @Test func defaultsToLayersPaddingAndSpacing() {
        #expect(LayerPreviewAnnotation.resolved([]) == [.layers, .padding, .spacing])
    }

    @Test func noneHidesEverything() {
        #expect(LayerPreviewAnnotation.resolved([.none, .padding]).isEmpty)
    }

    @Test func keepsExplicitSelection() {
        #expect(LayerPreviewAnnotation.resolved([.safeArea, .size]) == [.safeArea, .size])
    }
}
