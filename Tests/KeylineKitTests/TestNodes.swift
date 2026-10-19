import CoreGraphics
@testable import KeylineKit

/// Builds measured node records for layout tests.
struct TestNodes {
    private(set) var records: [NodeRecord] = []

    @discardableResult
    mutating func add(
        _ name: String,
        frame: CGRect,
        parent: KeylineNodeID? = nil,
        stack: _KeylineDeclaration.Axis? = nil,
        spacing: String = "default",
        paddings: [Int: PaddingMeasurement] = [:]
    ) -> KeylineNodeID {
        let id = KeylineNodeID()
        let declaration = stack.map { _KeylineDeclaration(name, stack: $0, spacing: spacing) } ?? _KeylineDeclaration(name)
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
