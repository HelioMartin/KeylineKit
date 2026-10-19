@testable import KeylineKit
import Testing

struct KeylineAnnotationTests {
    @Test func defaultsToLayersPaddingAndSpacing() {
        #expect(KeylineAnnotation.resolved([]) == [.layers, .padding, .spacing])
    }

    @Test func noneHidesEverything() {
        #expect(KeylineAnnotation.resolved([.none, .padding]).isEmpty)
    }

    @Test func keepsExplicitSelection() {
        #expect(KeylineAnnotation.resolved([.safeArea, .size]) == [.safeArea, .size])
    }
}
