import LayerPreview
import SwiftUI

@main
struct LayerPreviewDemoIOSApp: App {
    var body: some Scene {
        WindowGroup {
            DemoOverlay.fromLaunchArguments.view
        }
    }
}

/// Shows the annotated screens at runtime, e.g. for simulator screenshots:
/// `xcrun simctl launch booted com.layerpreview.demo.ios -LayerPreviewOverlay safeArea`.
private enum DemoOverlay: String {
    case none, defaults, safeArea, details

    static var fromLaunchArguments: Self {
        UserDefaults.standard.string(forKey: "LayerPreviewOverlay").flatMap(Self.init) ?? .none
    }

    @MainActor @ViewBuilder
    var view: some View {
        switch self {
        case .none:
            AccountScreen()
        case .defaults:
            #LayerPreview {
                AccountScreen()
            }
        case .safeArea:
            #LayerPreview(.safeArea, .layers) {
                AccountScreen()
            }
        case .details:
            #LayerPreview(.layers, .corners, .size) {
                ProfileView()
            }
        }
    }
}
