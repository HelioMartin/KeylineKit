import AppKit
import SwiftUI

// Renders the KeylineKit README banner (light and dark), the website button, and the website favicons and Open Graph image to PNG.
// Usage: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift .github/assets/RenderBanner.swift .github/assets docs

struct Palette {
    let background: Color
    let ink: Color
    let slate: Color
    let markFill: Color
    let markInner: Color
    let spacingFill: Color
    let border: Color

    static let light = Palette(background: .white, ink: Color(hex: 0x0F172B), slate: Color(hex: 0x62748E),
                               markFill: Color(hex: 0xFFD6A7), markInner: .white,
                               spacingFill: Color(hex: 0xE9D4FF).opacity(0.7), border: Color(hex: 0xD1D9E0))
    static let dark = Palette(background: Color(hex: 0x0D1117), ink: Color(hex: 0xF0F6FC), slate: Color(hex: 0x9198A1),
                              markFill: Color(hex: 0xCA3500).opacity(0.45), markInner: Color(hex: 0x0D1117),
                              spacingFill: Color(hex: 0x8200DB).opacity(0.45), border: Color(hex: 0x3D444D))
}

let blue = Color(hex: 0x1447E6)
let orange = Color(hex: 0xCA3500)
let green = Color(hex: 0x008236)
let purple = Color(hex: 0x8200DB)

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

struct Badge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .frame(height: 19)
            .background(color, in: RoundedRectangle(cornerRadius: 3.5))
            .fixedSize()
    }
}

/// The padding band of KeylineKit as a mark: a layer outline, the orange
/// band, the content outline and one dimension line across the band.
struct Mark: View {
    let palette: Palette
    var body: some View {
        let size: CGFloat = 112
        let inset: CGFloat = 26
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.markFill)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(blue, lineWidth: 5)
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(palette.markInner)
                .padding(inset)
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(green, lineWidth: 3.5)
                .padding(inset)
            Path { path in
                // Dimension lines across the top and leading bands, with end ticks.
                let mid = size / 2
                let near: CGFloat = 7
                let far = inset - 2
                let tick: CGFloat = 7
                path.move(to: CGPoint(x: mid, y: near)); path.addLine(to: CGPoint(x: mid, y: far))
                path.move(to: CGPoint(x: mid - tick, y: near)); path.addLine(to: CGPoint(x: mid + tick, y: near))
                path.move(to: CGPoint(x: mid - tick, y: far)); path.addLine(to: CGPoint(x: mid + tick, y: far))
                path.move(to: CGPoint(x: near, y: mid)); path.addLine(to: CGPoint(x: far, y: mid))
                path.move(to: CGPoint(x: near, y: mid - tick)); path.addLine(to: CGPoint(x: near, y: mid + tick))
                path.move(to: CGPoint(x: far, y: mid - tick)); path.addLine(to: CGPoint(x: far, y: mid + tick))
            }
            .stroke(orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct Banner: View {
    let palette: Palette
    var body: some View {
        HStack(alignment: .center, spacing: 40) {
            Mark(palette: palette)
            VStack(alignment: .leading, spacing: 18) {
                Text("KeylineKit")
                    .font(.system(size: 76, weight: .bold))
                    .tracking(-1.5)
                    .foregroundStyle(palette.ink)
                    .padding(.horizontal, 2)
                    .overlay { Rectangle().stroke(blue, lineWidth: 1.5) }
                    .overlay(alignment: .topLeading) { Badge(text: "Text", color: blue).offset(y: -21) }
                    .overlay(alignment: .bottom) {
                        // The stack spacing below the name, drawn the way #Keyline draws it.
                        ZStack {
                            Rectangle().fill(palette.spacingFill)
                            Badge(text: "18", color: purple)
                        }
                        .frame(height: 18)
                        .offset(y: 18)
                    }
                Text("Measured layout annotations for SwiftUI previews")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(palette.slate)
            }
        }
        .frame(width: 1080, height: 360)
        .background(palette.background)
    }
}

/// The website's Open Graph image: the light banner centered on the 1200 × 630
/// card that link previews use, so cropping to 1.91:1 or 2:1 keeps it whole.
/// It is enlarged to stay legible in small previews.
struct SocialCard: View {
    var body: some View {
        Banner(palette: .light)
            .scaleEffect(1.35)
            .frame(width: 1200, height: 630)
            .background(Palette.light.background)
    }
}

/// The link to the website under the README banner: a small outlined pill
/// in the page's own colors, one image per theme.
struct WebsiteButton: View {
    let palette: Palette
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "safari")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.slate)
            Text("Website")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.ink)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(palette.slate)
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(palette.background, in: Capsule())
        .overlay { Capsule().strokeBorder(palette.border, lineWidth: 1) }
        .fixedSize()
    }
}

@MainActor
func render(_ view: some View, to url: URL, scale: CGFloat = 2) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    try data?.write(to: url)
    print("wrote", url.path, image.width, "x", image.height)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let website = URL(fileURLWithPath: CommandLine.arguments[2])
try MainActor.assumeIsolated {
    try render(Banner(palette: .light), to: output.appendingPathComponent("keylinekit-banner-light.png"))
    try render(Banner(palette: .dark), to: output.appendingPathComponent("keylinekit-banner-dark.png"))
    try render(WebsiteButton(palette: .light), to: output.appendingPathComponent("keylinekit-website-light.png"))
    try render(WebsiteButton(palette: .dark), to: output.appendingPathComponent("keylinekit-website-dark.png"))
    // Safari ignores SVG favicons, so the website also links 64 px PNGs of the mark, one per appearance.
    try render(Mark(palette: .light), to: website.appendingPathComponent("favicon.png"), scale: 64 / 112)
    try render(Mark(palette: .dark), to: website.appendingPathComponent("favicon-dark.png"), scale: 64 / 112)
    try render(SocialCard(), to: website.appendingPathComponent("images/og-image.png"), scale: 1)
}
