import LayerPreview
import SwiftUI

@main
struct LayerPreviewDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileView()
        }
    }
}

@LayerPreviewInspectable
private struct ProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.teal)

            Text("Taylor Morgan")
                .font(.title2.weight(.semibold))

            Text("Product designer")
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Button("Follow") {}
                    .buttonStyle(.borderedProminent)
                Button("Close") {}
                    .buttonStyle(.borderedProminent)
            }
            
        }
        .padding(24)
    }
}

#Preview("Without LayerPreview") {
    ProfileView()
}

#Preview("Using LayerPreview") {
    #LayerPreview {
        ProfileView()
    }
}
