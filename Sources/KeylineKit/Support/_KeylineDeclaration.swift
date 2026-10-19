/// What the macro knows about a node from source: its name and, for stacks,
/// the axis and spacing written in the initializer.
@_documentation(visibility: internal)
public struct _KeylineDeclaration: Hashable, Sendable {
    public enum Axis: Hashable, Sendable {
        case horizontal, vertical
    }

    let name: String
    let stackAxis: Axis?
    /// The `spacing:` argument as written, or `"default"`.
    let declaredSpacing: String?

    public init(_ name: String) {
        self.name = name
        self.stackAxis = nil
        self.declaredSpacing = nil
    }

    public init(_ name: String, stack axis: Axis, spacing: String) {
        self.name = name
        self.stackAxis = axis
        self.declaredSpacing = spacing
    }
}
