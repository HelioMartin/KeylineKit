import SwiftSyntax

/// Which initializer closures hold view content that should be instrumented.
enum ContainerRules {
    /// Initializers whose closures build something other than views
    /// (drawing commands, chart marks, map content, table columns).
    static let nonViewContentInitializers: Set<String> = ["Canvas", "Chart", "Map", "Table"]

    /// Controls whose trailing closure is an action rather than content,
    /// e.g. `Button("Save") { save() }`.
    static let actionClosureInitializers: Set<String> = ["Button", "PasteButton", "SecureField", "TextField"]

    /// Containers that lay their children out directly in the parent, so they
    /// get no node of their own and their children stay siblings in the stack.
    static let transparentContainers: Set<String> = ["ForEach", "Group"]

    /// Labels of additional trailing closures that hold view content.
    static let contentClosureLabels: Set<String> = [
        "content", "label", "header", "footer", "icon", "title",
        "placeholder", "sidebar", "detail", "destination",
    ]

    /// Any capitalized (type-like) initializer is a container candidate, so
    /// custom views and SwiftUI containers work without being listed.
    static func hasViewContent(_ name: String) -> Bool {
        guard let first = name.first, first.isUppercase else { return false }
        return !nonViewContentInitializers.contains(name)
    }

    static func trailingClosureIsContent(_ name: String, arguments: LabeledExprListSyntax) -> Bool {
        guard actionClosureInitializers.contains(name) else { return true }
        // `Button(action: save) { Text("Save") }` passes its label as the trailing closure.
        return name == "Button" && arguments.contains { $0.label?.text == "action" }
    }

    /// The `_LayerPreviewDeclaration.Axis` literal for stacks whose spacing is measured.
    static func stackAxis(_ name: String) -> String? {
        switch name {
        case "VStack", "LazyVStack": ".vertical"
        case "HStack", "LazyHStack": ".horizontal"
        default: nil
        }
    }
}
