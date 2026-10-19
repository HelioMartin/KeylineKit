import SwiftUI

/// Reports the safe area of the surface it is placed behind.
struct SafeAreaReader: View {
    let registry: LayerPreviewRegistry

    var body: some View {
        Color.clear.onGeometryChange(for: SafeAreaSnapshot.self) { proxy in
            SafeAreaSnapshot(proxy)
        } action: { snapshot in
            registry.safeArea = snapshot
        }
    }
}
