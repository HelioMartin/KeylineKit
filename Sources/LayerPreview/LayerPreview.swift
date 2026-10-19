import SwiftUI

/// Renders a SwiftUI view with every node's type name and padding value
/// labeled directly on its own frame in the Canvas.
///
///     #LayerPreview {
///         VStack {
///             ProfileView()
///         }
///         .padding(24)
///     }
///
/// Container bounds are hidden by default. Enable them explicitly with
/// `showContainerLines: true` when the yellow outlines are needed.
@freestanding(expression)
public macro LayerPreview(
	_ annotations: LayerPreviewAnnotation...,
	showContainerLines: Bool = true,
	body: @escaping @MainActor @Sendable () -> any View
) -> AnyView = #externalMacro(module: "LayerPreviewMacros", type: "LayerPreviewMacro")

/// Attach to a custom `View` to let `#LayerPreview` expand the contents of its
/// own `body` instead of treating it as a single opaque node.
///
///     @LayerPreviewInspectable
///     struct ProfileView: View {
///         var body: some View { ... }
///     }
@attached(member, names: named(__layerPreviewTaggedBody), named(layerPreviewContent), named(layerPreviewContentEdges))
@attached(extension, conformances: LayerPreviewInspectable)
public macro LayerPreviewInspectable() = #externalMacro(module: "LayerPreviewMacros", type: "LayerPreviewInspectableMacro")

/// Lets a view expose an already-tagged version of its own `body` so
/// `#LayerPreview` can render its internals instead of a single opaque node.
public protocol LayerPreviewInspectable {
	@MainActor var layerPreviewContent: AnyView { get }
	@MainActor var layerPreviewContentEdges: LayerPreviewEdgePadding? { get }
}

/// Renders `view`'s own tagged body when it conforms to
/// `LayerPreviewInspectable`; otherwise tags `view` itself as one leaf node.
public struct LayerPreviewInspectorBridge<V: View>: View {
	private let view: V
	private let name: String
	private let edges: LayerPreviewEdgePadding?
	private let labelLevel: Int
	private let isContainer: Bool

	public init(_ view: V, name: String, edges: LayerPreviewEdgePadding?, labelLevel: Int = 0, isContainer: Bool = false) {
		self.view = view
		self.name = name
		self.edges = edges
		self.labelLevel = labelLevel
		self.isContainer = isContainer
	}

	public var body: some View {
		if let inspectable = view as? any LayerPreviewInspectable {
			inspectable.layerPreviewContent
				.layerPreviewTagged(name: name, edges: edges ?? inspectable.layerPreviewContentEdges, labelLevel: labelLevel, isContainer: isContainer, showsName: false)
				.environment(\.layerPreviewLabelLevel, labelLevel + 1)
		} else {
			view
				.layerPreviewTagged(name: name, edges: edges, labelLevel: labelLevel, isContainer: isContainer)
		}
	}
}

public struct LayerPreviewSurface<Content: View>: View {
	private let content: () -> Content
	private let annotations: Set<LayerPreviewAnnotation>
	private let showContainerLines: Bool

	public init(_ annotations: [LayerPreviewAnnotation] = [], showContainerLines: Bool = true, @ViewBuilder content: @escaping () -> Content) {
		self.content = content
		self.annotations = annotations.contains(.none)
			? []
			: annotations.isEmpty ? Set([.layers]) : Set(annotations)
		self.showContainerLines = showContainerLines
	}

	public var body: some View {
		content()
			.environment(\.layerPreviewAnnotations, annotations)
			.environment(\.layerPreviewShowsContainerLines, showContainerLines)
	}
}


/// Controls which diagnostic annotations `#LayerPreview` renders.
///
/// Pass one or more values directly to the macro:
///
///     #LayerPreview(.layers, .padding) {
///         MyView()
///     }
///
/// With no values, the default annotation configuration is used.
public enum LayerPreviewAnnotation: CaseIterable, Hashable, Sendable {
	/// Hides all annotation labels.
	case none
	/// Shows the bounds and names of the inspected layers.
	case layers
	/// Shows padding values on the edges where padding is declared.
	case padding
	/// Shows spacing values between siblings in supported containers.
	case spacing
}

private struct LayerPreviewAnnotationSetKey: EnvironmentKey {
	static let defaultValue: Set<LayerPreviewAnnotation> = [.layers]
}

private extension EnvironmentValues {
	var layerPreviewAnnotations: Set<LayerPreviewAnnotation> {
		get { self[LayerPreviewAnnotationSetKey.self] }
		set { self[LayerPreviewAnnotationSetKey.self] = newValue }
	}
}

private struct LayerPreviewContainerLinesKey: EnvironmentKey {
	static let defaultValue = true
}

private extension EnvironmentValues {
	var layerPreviewShowsContainerLines: Bool {
		get { self[LayerPreviewContainerLinesKey.self] }
		set { self[LayerPreviewContainerLinesKey.self] = newValue }
	}
}

private struct LayerPreviewLabelLevelKey: EnvironmentKey {
	static let defaultValue = 0
}

private extension EnvironmentValues {
	var layerPreviewLabelLevel: Int {
		get { self[LayerPreviewLabelLevelKey.self] }
		set { self[LayerPreviewLabelLevelKey.self] = newValue }
	}
}

private extension Set where Element == LayerPreviewAnnotation {
	var showsPadding: Bool { contains(.padding) }
	var showsSpacing: Bool { contains(.spacing) }
	var showsLayers: Bool { contains(.layers) }
}

/// The padding value declared on each edge of a node, as written in source.
public struct LayerPreviewEdgePadding: Sendable {
	public let top: String?
	public let bottom: String?
	public let leading: String?
	public let trailing: String?

	public init(top: String? = nil, bottom: String? = nil, leading: String? = nil, trailing: String? = nil) {
		self.top = top
		self.bottom = bottom
		self.leading = leading
		self.trailing = trailing
	}
}

/// Draws a border around a node, its name badge, and an arrow with the
/// padding value on each edge that declares one.
public struct LayerPreviewTag: ViewModifier {
	let name: String
	let edges: LayerPreviewEdgePadding?
	let labelLevel: Int
	let isContainer: Bool
	let showsName: Bool
	@Environment(\.layerPreviewAnnotations) private var annotations
	@Environment(\.layerPreviewLabelLevel) private var environmentLabelLevel
	@Environment(\.layerPreviewShowsContainerLines) private var showsContainerLines

	public func body(content: Content) -> some View {
		content
			.overlay {
				if showsContainerLines {
					Rectangle()
						.stroke(Color.orange.opacity(0.85), lineWidth: 1)
				}
			}
			.overlay(alignment: .topLeading) {
				if annotations.showsLayers && showsName {
				Text(name)
					.font(.system(size: 9, weight: .bold))
					.padding(.horizontal, 3)
					.padding(.vertical, 1)
					.background(Color.blue, in: RoundedRectangle(cornerRadius: 3))
					.foregroundColor(.white)
					.fixedSize()
					.offset(
						x: isContainer ? 2 : 2 + CGFloat(max(labelLevel, environmentLabelLevel)) * 14,
						y: -14
					)
					.zIndex(1000)
				}
			}
			.overlay(alignment: .top) {
				if annotations.showsPadding {
					paddingLabel(edges?.top, side: "top", arrow: "\u{2191}")
						.offset(y: 7)
						.zIndex(1000)
				}
			}
			.overlay(alignment: .bottom) {
				if annotations.showsPadding {
					paddingLabel(edges?.bottom, side: "bottom", arrow: "\u{2193}")
						.offset(y: -7)
						.zIndex(1000)
				}
			}
			.overlay(alignment: .leading) {
				if annotations.showsPadding {
					paddingLabel(edges?.leading, side: "leading", arrow: "\u{2190}")
						.offset(x: 7)
						.zIndex(1000)
				}
			}
			.overlay(alignment: .trailing) {
				if annotations.showsPadding {
					paddingLabel(edges?.trailing, side: "trailing", arrow: "\u{2192}")
						.offset(x: -7)
						.zIndex(1000)
				}
			}
			.compositingGroup()
			.zIndex(10_000)
	}

	@ViewBuilder
	private func paddingLabel(_ value: String?, side: String, arrow: String) -> some View {
		if let value {
			Text("\(side) \(arrow) \(value)")
				.font(.system(size: 8, weight: .semibold))
				.foregroundColor(.white)
				.padding(.horizontal, 3)
				.padding(.vertical, 1)
				.background(Color.orange.opacity(0.9), in: Capsule())
				.fixedSize()
		}
	}
}

extension View {
	public func layerPreviewTagged(name: String, edges: LayerPreviewEdgePadding?, labelLevel: Int = 0, isContainer: Bool = false, showsName: Bool = true) -> some View {
		modifier(LayerPreviewTag(name: name, edges: edges, labelLevel: labelLevel, isContainer: isContainer, showsName: showsName))
	}
}

public enum LayerPreviewAxis {
	case vertical, horizontal
}

/// Marks the spacing declared between two sibling elements of a stack, drawn
/// past the trailing edge of the element that precedes the gap.
public struct LayerPreviewSpacingMark: ViewModifier {
	let axis: LayerPreviewAxis
	let label: String
	let distance: CGFloat
	@Environment(\.layerPreviewAnnotations) private var annotations

	public func body(content: Content) -> some View {
		if annotations.showsSpacing {
			content
			.overlay(alignment: axis == .vertical ? .bottom : .trailing) {
				spacingBadge()
			}
			.compositingGroup()
			.zIndex(10_000)
		} else {
			content
		}
	}

	@ViewBuilder
	private func spacingBadge() -> some View {
		let badge = Text(label)
			.font(.system(size: 8, weight: .semibold))
			.foregroundColor(.white)
			.padding(.horizontal, 4)
			.padding(.vertical, 1)
			.background(Color.purple, in: Capsule())
			.fixedSize()
			.zIndex(1000)

		if axis == .vertical {
			badge
				.alignmentGuide(.bottom) { dimensions in dimensions.height / 2 }
				.offset(y: distance / 2 + 6)
		} else {
			badge
				.alignmentGuide(.trailing) { dimensions in dimensions.width / 2 }
				.offset(x: distance / 2 + 10)
		}
	}
}

extension View {
	public func layerPreviewSpacing(axis: LayerPreviewAxis, label: String, distance: CGFloat) -> some View {
		modifier(LayerPreviewSpacingMark(axis: axis, label: label, distance: distance))
	}
}
