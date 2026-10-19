import SwiftUI

/// The device safe area around the preview, in global coordinates.
struct SafeAreaSnapshot: Equatable, Sendable {
    var safeFrame: CGRect
    var insets: EdgeInsets
    /// Active reserved regions that occlude content, such as the Dynamic Island.
    var occlusions: [CGRect]

    var screenFrame: CGRect {
        CGRect(
            x: safeFrame.minX - insets.leading,
            y: safeFrame.minY - insets.top,
            width: safeFrame.width + insets.leading + insets.trailing,
            height: safeFrame.height + insets.top + insets.bottom
        )
    }
}

extension SafeAreaSnapshot {
    init(_ proxy: GeometryProxy) {
        let frame = proxy.frame(in: .global)
        self.init(safeFrame: frame, insets: proxy.safeAreaInsets, occlusions: Self.occlusions(in: proxy, at: frame.origin))
    }

    private static func occlusions(in proxy: GeometryProxy, at origin: CGPoint) -> [CGRect] {
        // Reserved regions need the iOS 27.1 SDK (SwiftUI 8.0.85) at build time.
        #if os(iOS) && canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            return proxy.reservedRegions(kind: .occlusion)
                .filter(\.isActive)
                .map { $0.frame.offsetBy(dx: origin.x, dy: origin.y) }
        }
        #endif
        return []
    }
}
