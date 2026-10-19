import LayerPreview
import SwiftUI

@LayerPreviewInspectable
struct ProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 4) {
                Text("Taylor Morgan")
                    .font(.title2.weight(.semibold))
                Text("Product designer")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("Follow") {}
                    .buttonStyle(.borderedProminent)
                Button("Message") {}
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
        .padding()
    }
}

#Preview("Plain") {
    ProfileView()
}

#Preview("Default annotations") {
    #LayerPreview {
        ProfileView()
    }
}

#Preview("Padding") {
    #LayerPreview(.padding) {
        ProfileView()
    }
}

#Preview("Spacing") {
    #LayerPreview(.spacing, showContainerLines: false) {
        ProfileView()
    }
}

#Preview("Corners and sizes") {
    #LayerPreview(.corners, .size) {
        ProfileView()
    }
}
