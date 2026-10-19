import CoreGraphics
@testable import LayerPreview
import Testing

struct LabelPlacerTests {
    private let size = CGSize(width: 20, height: 10)

    @Test func usesFirstFreeCandidate() {
        var placer = LabelPlacer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
        let first = placer.place(size, around: [CGPoint(x: 50, y: 50)])
        let second = placer.place(size, around: [CGPoint(x: 50, y: 50), CGPoint(x: 50, y: 80)])

        #expect(first.index == 0)
        #expect(second.index == 1)
        #expect(second.frame == CGRect(x: 40, y: 75, width: 20, height: 10))
    }

    @Test func skipsCandidatesOutsideBounds() {
        var placer = LabelPlacer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
        let placement = placer.place(size, around: [CGPoint(x: 50, y: -2), CGPoint(x: 50, y: 10)])

        #expect(placement.index == 1)
    }

    @Test func clampsFirstCandidateWhenNoneIsFree() {
        var placer = LabelPlacer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
        let placement = placer.place(size, around: [CGPoint(x: 98, y: -2)])

        #expect(placement.index == 0)
        #expect(placement.frame == CGRect(x: 80, y: 0, width: 20, height: 10))
    }
}
