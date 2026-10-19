import SwiftUI

/// Turns measured nodes into the regions, dimension lines and badges the
/// canvas draws. Pure geometry: colors come from each element's role.
struct AnnotationLayout {
    var annotations: Set<LayerPreviewAnnotation>
    var showsOutlines: Bool
    /// The canvas bounds in global coordinates; badges are kept inside.
    var bounds: CGRect
    var measureText: (String) -> CGSize

    static let badgeHeight: CGFloat = 15
    static let badgeInset: CGFloat = 4
    static let tickLength: CGFloat = 9
    static let dimensionOffset: CGFloat = 8
    /// Positions tried, in order, for a badge along an edge or gap.
    static let candidateFractions: [CGFloat] = [0.5, 0.3, 0.7, 0.15, 0.85]

    func scene(for records: some Collection<NodeRecord>, safeArea: SafeAreaSnapshot?) -> AnnotationScene {
        var builder = SceneBuilder(layout: self, tree: NodeTree(records))
        // Badges placed first win contested space, so geometry-bound values
        // go before the more movable layer names.
        if annotations.contains(.safeArea), let safeArea { builder.addSafeArea(safeArea) }
        if showsOutlines { builder.addOutlines() }
        if annotations.contains(.padding) { builder.addPadding() }
        if annotations.contains(.spacing) { builder.addSpacing() }
        if annotations.contains(.corners) { builder.addCorners() }
        if annotations.contains(.size) { builder.addSizes() }
        if annotations.contains(.layers) { builder.addNames() }
        return builder.scene
    }
}

private struct SceneBuilder {
    let layout: AnnotationLayout
    let tree: NodeTree
    var scene = AnnotationScene()
    var placer: LabelPlacer

    init(layout: AnnotationLayout, tree: NodeTree) {
        self.layout = layout
        self.tree = tree
        self.placer = LabelPlacer(bounds: layout.bounds.insetBy(dx: 2, dy: 2))
    }

    // MARK: Annotations

    mutating func addOutlines() {
        for node in tree.nodes {
            scene.strokes.append(.init(path: Path(node.frame!), role: .layers))
        }
    }

    mutating func addPadding() {
        for node in tree.nodes {
            for index in node.paddings.keys.sorted() {
                guard let padding = node.paddings[index], let inner = padding.inner, let outer = padding.outer else { continue }
                addBand(outer: outer, inner: inner, role: .padding, declared: padding.declared)
            }
        }
    }

    mutating func addSpacing() {
        for stack in tree.nodes {
            guard let declaration = stack.declaration, let axis = declaration.stackAxis else { continue }
            let frames = tree.children(of: stack.id).compactMap(\.frame).sorted {
                axis == .vertical ? $0.minY < $1.minY : $0.minX < $1.minX
            }
            for (leading, trailing) in zip(frames, frames.dropFirst()) {
                addGap(between: leading, and: trailing, axis: axis, declared: declaration.declaredSpacing)
            }
        }
    }

    mutating func addCorners() {
        for node in tree.nodes {
            for index in node.corners.keys.sorted() {
                addCorner(node.corners[index]!)
            }
        }
    }

    mutating func addSizes() {
        for group in tree.labelGroups {
            addSize(of: group.frame)
        }
    }

    mutating func addNames() {
        for group in tree.labelGroups {
            let frame = group.frame
            let size = badgeSize(group.title)
            let (width, height) = (size.width, size.height)
            let candidates = [
                CGPoint(x: frame.minX + width / 2, y: frame.minY - height / 2 - 1),
                CGPoint(x: frame.minX + width / 2 + 2, y: frame.minY + height / 2 + 2),
                CGPoint(x: frame.maxX - width / 2, y: frame.minY - height / 2 - 1),
                CGPoint(x: frame.maxX - width / 2 - 2, y: frame.minY + height / 2 + 2),
                CGPoint(x: frame.minX + width / 2, y: frame.maxY + height / 2 + 1),
                CGPoint(x: frame.minX + width / 2 + 2, y: frame.maxY - height / 2 - 2),
            ]
            let (badgeFrame, _) = placer.place(size, around: candidates)
            scene.badges.append(.init(text: group.title, frame: badgeFrame, role: .layers))
        }
    }

    mutating func addSafeArea(_ safeArea: SafeAreaSnapshot) {
        let insets = safeArea.insets
        guard max(insets.top, insets.bottom, insets.leading, insets.trailing) >= 0.5 else { return }
        let safe = safeArea.safeFrame
        let screen = safeArea.screenFrame

        scene.regions.append(.init(path: Path { $0.addRect(screen); $0.addRect(safe) }, role: .padding, isEvenOdd: true))
        scene.strokes.append(.init(path: Path(safe), role: .content, width: 2))

        for occlusion in safeArea.occlusions {
            let shape = Path(roundedRect: occlusion, cornerRadius: min(occlusion.width, occlusion.height) / 2)
            scene.regions.append(.init(path: shape, role: .reserved))
            scene.strokes.append(.init(path: shape, role: .reserved))
            addBadge("OCCLUSION \(MetricFormat.size(occlusion.size))", role: .reserved, around: [
                CGPoint(x: occlusion.midX, y: occlusion.maxY + AnnotationLayout.badgeHeight / 2 + 4),
                CGPoint(x: occlusion.midX, y: occlusion.minY - AnnotationLayout.badgeHeight / 2 - 4),
            ])
        }

        let insetFractions: [CGFloat] = [0.82, 0.18, 0.5]
        if insets.top >= 0.5 {
            addDimension("TOP \(MetricFormat.points(insets.top))", role: .padding, axis: .vertical,
                         span: screen.minY...safe.minY,
                         candidates: insetFractions.map { (screen.minX + screen.width * $0, (screen.minY + safe.minY) / 2) })
        }
        if insets.bottom >= 0.5 {
            addDimension("BOTTOM \(MetricFormat.points(insets.bottom))", role: .padding, axis: .vertical,
                         span: safe.maxY...screen.maxY,
                         candidates: insetFractions.map { (screen.minX + screen.width * $0, (safe.maxY + screen.maxY) / 2) })
        }
        if insets.leading >= 0.5 {
            addDimension("LEADING \(MetricFormat.points(insets.leading))", role: .padding, axis: .horizontal,
                         span: screen.minX...safe.minX,
                         candidates: insetFractions.map { (screen.minY + screen.height * $0, (screen.minX + safe.minX) / 2) })
        }
        if insets.trailing >= 0.5 {
            addDimension("TRAILING \(MetricFormat.points(insets.trailing))", role: .padding, axis: .horizontal,
                         span: safe.maxX...screen.maxX,
                         candidates: insetFractions.map { (screen.minY + screen.height * $0, (safe.maxX + screen.maxX) / 2) })
        }

        let offset = AnnotationLayout.badgeHeight / 2 + 6
        addBadge("SAFE AREA \(MetricFormat.size(safe.size))", role: .content, around: [
            CGPoint(x: safe.midX, y: safe.maxY - offset),
            CGPoint(x: safe.midX, y: safe.minY + offset),
        ])
    }

    // MARK: Elements

    /// Fills the band between `outer` and `inner` and labels each edge that
    /// has an inset with a dimension line across the band.
    private mutating func addBand(outer: CGRect, inner: CGRect, role: AnnotationRole, declared: String?) {
        let top = inner.minY - outer.minY
        let bottom = outer.maxY - inner.maxY
        let leading = inner.minX - outer.minX
        let trailing = outer.maxX - inner.maxX
        guard max(top, bottom, leading, trailing) >= 0.5 else { return }

        scene.regions.append(.init(path: Path { $0.addRect(outer); $0.addRect(inner) }, role: role, isEvenOdd: true))
        scene.strokes.append(.init(path: Path(inner), role: .content))

        let xs = AnnotationLayout.candidateFractions.map { inner.minX + inner.width * $0 }
        let ys = AnnotationLayout.candidateFractions.map { inner.minY + inner.height * $0 }
        if top >= 0.5 {
            addDimension(MetricFormat.measured(top, declared: declared), role: role, axis: .vertical,
                         span: outer.minY...inner.minY, candidates: xs.map { ($0, (outer.minY + inner.minY) / 2) })
        }
        if bottom >= 0.5 {
            addDimension(MetricFormat.measured(bottom, declared: declared), role: role, axis: .vertical,
                         span: inner.maxY...outer.maxY, candidates: xs.map { ($0, (inner.maxY + outer.maxY) / 2) })
        }
        if leading >= 0.5 {
            addDimension(MetricFormat.measured(leading, declared: declared), role: role, axis: .horizontal,
                         span: outer.minX...inner.minX, candidates: ys.map { ($0, (outer.minX + inner.minX) / 2) })
        }
        if trailing >= 0.5 {
            addDimension(MetricFormat.measured(trailing, declared: declared), role: role, axis: .horizontal,
                         span: inner.maxX...outer.maxX, candidates: ys.map { ($0, (inner.maxX + outer.maxX) / 2) })
        }
    }

    private mutating func addGap(between first: CGRect, and second: CGRect, axis: _LayerPreviewDeclaration.Axis, declared: String?) {
        let fractions = AnnotationLayout.candidateFractions
        switch axis {
        case .vertical:
            let gap = second.minY - first.maxY
            guard gap >= 0.5 else { return }
            let minX = min(first.minX, second.minX)
            let region = CGRect(x: minX, y: first.maxY, width: max(first.maxX, second.maxX) - minX, height: gap)
            scene.regions.append(.init(path: Path(region), role: .spacing))
            addDimension(MetricFormat.measured(gap, declared: declared), role: .spacing, axis: .vertical,
                         span: region.minY...region.maxY,
                         candidates: fractions.map { (region.minX + region.width * $0, region.midY) })
        case .horizontal:
            let gap = second.minX - first.maxX
            guard gap >= 0.5 else { return }
            let minY = min(first.minY, second.minY)
            let region = CGRect(x: first.maxX, y: minY, width: gap, height: max(first.maxY, second.maxY) - minY)
            scene.regions.append(.init(path: Path(region), role: .spacing))
            addDimension(MetricFormat.measured(gap, declared: declared), role: .spacing, axis: .horizontal,
                         span: region.minX...region.maxX,
                         candidates: fractions.map { (region.minY + region.height * $0, region.midX) })
        }
    }

    /// A quarter arc on the top-leading corner with dashed radius lines.
    private mutating func addCorner(_ corner: CornerMeasurement) {
        let frame = corner.frame
        let radius = min(corner.radius, frame.width / 2, frame.height / 2)
        guard radius >= 0.5 else { return }
        let center = CGPoint(x: frame.minX + radius, y: frame.minY + radius)

        scene.strokes.append(.init(path: Path { path in
            path.move(to: CGPoint(x: frame.minX, y: center.y))
            path.addArc(tangent1End: CGPoint(x: frame.minX, y: frame.minY), tangent2End: CGPoint(x: center.x, y: frame.minY), radius: radius)
        }, role: .corners, width: 1.5))
        scene.strokes.append(.init(path: Path { path in
            path.move(to: CGPoint(x: frame.minX, y: center.y))
            path.addLine(to: center)
            path.addLine(to: CGPoint(x: center.x, y: frame.minY))
        }, role: .corners, isDashed: true))

        let text = "r \(MetricFormat.measured(corner.radius, declared: corner.declared))"
        let width = badgeSize(text).width
        addBadge(text, role: .corners, around: [
            center,
            CGPoint(x: center.x + width / 2 + 2, y: center.y),
            CGPoint(x: frame.minX + width / 2 + 2, y: frame.minY + radius + AnnotationLayout.badgeHeight),
        ])
    }

    /// Width and height dimension lines just outside the frame (inside when
    /// there is no room), joined to its corners by dashed extension lines.
    private mutating func addSize(of frame: CGRect) {
        let offset = AnnotationLayout.dimensionOffset
        let bounds = layout.bounds
        let fractions = AnnotationLayout.candidateFractions

        let y = frame.minY - offset - AnnotationLayout.badgeHeight / 2 >= bounds.minY ? frame.minY - offset : frame.minY + offset
        addExtensions([CGPoint(x: frame.minX, y: frame.minY), CGPoint(x: frame.maxX, y: frame.minY)], to: { CGPoint(x: $0.x, y: y) })
        addDimension(MetricFormat.points(frame.width), role: .size, axis: .horizontal,
                     span: frame.minX...frame.maxX,
                     candidates: fractions.map { (y, frame.minX + frame.width * $0) })

        let x = frame.minX - offset - AnnotationLayout.badgeHeight / 2 >= bounds.minX ? frame.minX - offset : frame.minX + offset
        addExtensions([CGPoint(x: frame.minX, y: frame.minY), CGPoint(x: frame.minX, y: frame.maxY)], to: { CGPoint(x: x, y: $0.y) })
        addDimension(MetricFormat.points(frame.height), role: .size, axis: .vertical,
                     span: frame.minY...frame.maxY,
                     candidates: fractions.map { (x, frame.minY + frame.height * $0) },
                     isRotated: true)
    }

    // MARK: Primitives

    /// A dimension line along `axis` across `span`, with ticks at both ends
    /// and a centered badge. Each candidate is `(cross, along)`: where the
    /// line sits across the axis and where the badge sits along it.
    private mutating func addDimension(
        _ text: String,
        role: AnnotationRole,
        axis: _LayerPreviewDeclaration.Axis,
        span: ClosedRange<CGFloat>,
        candidates: [(cross: CGFloat, along: CGFloat)],
        isRotated: Bool = false
    ) {
        let size = badgeSize(text, isRotated: isRotated)
        let centers = candidates.map { axis == .vertical ? CGPoint(x: $0.cross, y: $0.along) : CGPoint(x: $0.along, y: $0.cross) }
        let (frame, index) = placer.place(size, around: centers)
        let cross = candidates[index].cross
        let half = AnnotationLayout.tickLength / 2

        scene.strokes.append(.init(path: Path { path in
            switch axis {
            case .vertical:
                path.move(to: CGPoint(x: cross, y: span.lowerBound))
                path.addLine(to: CGPoint(x: cross, y: span.upperBound))
                for y in [span.lowerBound, span.upperBound] {
                    path.move(to: CGPoint(x: cross - half, y: y))
                    path.addLine(to: CGPoint(x: cross + half, y: y))
                }
            case .horizontal:
                path.move(to: CGPoint(x: span.lowerBound, y: cross))
                path.addLine(to: CGPoint(x: span.upperBound, y: cross))
                for x in [span.lowerBound, span.upperBound] {
                    path.move(to: CGPoint(x: x, y: cross - half))
                    path.addLine(to: CGPoint(x: x, y: cross + half))
                }
            }
        }, role: role))
        scene.badges.append(.init(text: text, frame: frame, role: role, isRotated: isRotated))
    }

    private mutating func addExtensions(_ points: [CGPoint], to target: (CGPoint) -> CGPoint) {
        scene.strokes.append(.init(path: Path { path in
            for point in points {
                path.move(to: point)
                path.addLine(to: target(point))
            }
        }, role: .size, isDashed: true))
    }

    private mutating func addBadge(_ text: String, role: AnnotationRole, around centers: [CGPoint]) {
        let (frame, _) = placer.place(badgeSize(text), around: centers)
        scene.badges.append(.init(text: text, frame: frame, role: role))
    }

    private func badgeSize(_ text: String, isRotated: Bool = false) -> CGSize {
        let textSize = layout.measureText(text)
        let width = textSize.width.rounded(.up) + 2 * AnnotationLayout.badgeInset
        let height = max(AnnotationLayout.badgeHeight, textSize.height.rounded(.up) + 2)
        return isRotated ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }
}
