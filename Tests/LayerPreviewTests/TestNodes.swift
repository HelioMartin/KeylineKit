import CoreGraphics
@testable import LayerPreview

/// Builds measured node records for layout tests.
struct TestNodes {
    private(set) var records: [NodeRecord] = []

    @discardableResult
    mutating func add(
        _ name: String,
        frame: CGRect,
        parent: LayerPreviewNodeID? = nil,
        stack: _LayerPreviewDeclaration.Axis? = nil,
        spacing: String = "default",
        paddings: [Int: PaddingMeasurement] = [:]
    ) -> LayerPreviewNodeID {
        let id = LayerPreviewNodeID()
        let declaration = stack.map { _LayerPreviewDeclaration(name, stack: $0, spacing: spacing) } ?? _LayerPreviewDeclaration(name)
        var record = NodeRecord(id: id, order: records.count)
        record.parent = parent
        record.declaration = declaration
        record.frame = frame
        record.paddings = paddings
        records.append(record)
        return id
    }
}

/// A predictable stand-in for text measurement: 6 pt per character.
func measureText(_ text: String) -> CGSize {
    CGSize(width: CGFloat(text.count) * 6, height: 12)
}
