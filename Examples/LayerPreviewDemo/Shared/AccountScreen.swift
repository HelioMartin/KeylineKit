import LayerPreview
import SwiftUI

@LayerPreviewInspectable
struct AccountScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Taylor Morgan", systemImage: "person.crop.circle.fill")
                        Label("Product designer", systemImage: "briefcase.fill")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 24))

                    Text("Actions")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button("Follow") {}
                            .buttonStyle(.borderedProminent)
                        Button("Message") {}
                            .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.12))
            .navigationTitle("LayerPreview")
        }
    }
}

#Preview("Plain") {
    AccountScreen()
}

#Preview("Default annotations") {
    #LayerPreview {
        AccountScreen()
    }
}

#Preview("Safe area") {
    #LayerPreview(.safeArea, .layers) {
        AccountScreen()
    }
}
