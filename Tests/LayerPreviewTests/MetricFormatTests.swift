import CoreGraphics
@testable import LayerPreview
import Testing

struct MetricFormatTests {
    @Test(arguments: [
        (CGFloat(24), "24"),
        (36.666, "36.67"),
        (0.5, "0.5"),
        (12.1, "12.1"),
        (0, "0"),
    ])
    func formatsPoints(value: CGFloat, expected: String) {
        #expect(MetricFormat.points(value) == expected)
    }

    @Test func formatsSize() {
        #expect(MetricFormat.size(CGSize(width: 393, height: 759)) == "393 × 759")
    }

    @Test(arguments: [
        (CGFloat(24), "24" as String?, "24"),
        (24, nil, "24"),
        (23.99, "24", "23.99"),
        (16, "default", "16 · default"),
        (12, "Theme.spacing", "12 · Theme.spacing"),
        (12, "Theme.Spacing.extraLarge.value", "12 · Theme.Spacing.ext…"),
    ])
    func appendsDeclaredValueOnlyWhenItAddsInformation(value: CGFloat, declared: String?, expected: String) {
        #expect(MetricFormat.measured(value, declared: declared) == expected)
    }
}
