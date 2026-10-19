import KeylineKit
import SwiftUI

@main
struct KeylineDemoIOSApp: App {
    var body: some Scene {
        WindowGroup {
            DemoOverlay.fromLaunchArguments.view
        }
    }
}

/// Shows the annotated screens at runtime, e.g. for simulator screenshots:
/// `xcrun simctl launch booted com.keylinekit.demo.ios -KeylineOverlay safeArea`.
private enum DemoOverlay: String {
    case none, defaults, safeArea, details

    static var fromLaunchArguments: Self {
        UserDefaults.standard.string(forKey: "KeylineOverlay").flatMap(Self.init) ?? .none
    }

    @MainActor @ViewBuilder
    var view: some View {
        switch self {
        case .none:
            AccountScreen()
        case .defaults:
            #Keyline {
                AccountScreen()
            }
        case .safeArea:
            #Keyline(.safeArea, .layers) {
                AccountScreen()
            }
        case .details:
            #Keyline(.layers, .corners, .size) {
                ProfileView()
            }
        }
    }
}
