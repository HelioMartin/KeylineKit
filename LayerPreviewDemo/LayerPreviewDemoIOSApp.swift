import LayerPreview
import SwiftUI

@main
struct LayerPreviewDemoIOSApp: App {
    var body: some Scene {
        WindowGroup {
            IOSDemoView()
        }
    }
}

@LayerPreviewInspectable
private struct IOSDemoView: View {
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
            .navigationTitle("LayerPreview")
        }
    }
}

#Preview("iOS view") {
    IOSDemoView()
}

#Preview("iOS layers") {
    #LayerPreview {
        IOSDemoView()
    }
}
