import SwiftUI

/// The annotation palette (Tailwind 700 lines, 200 fills): blue for
/// layers, orange for insets, green for content, purple for spacing and
/// reserved regions, pink for corners and slate for sizes. Each color set
/// in `colors` replaces its role's.
struct KeylineTheme {
    var colorScheme: ColorScheme
    var colors = KeylineColors()

    /// Fills stay translucent so the UI underneath remains readable.
    private static let fillOpacity = 0.45
    /// A custom color has no pale tint, so its light fill is fainter: a 700
    /// line at this opacity is about as pale over white as a 200 fill.
    private static let customLightFillOpacity = 0.2

    func line(_ role: AnnotationRole) -> Color {
        if let custom = colors[role] { return custom }
        return switch role {
        case .layers: Color(hex: 0x1447E6)
        case .padding: Color(hex: 0xCA3500)
        case .content: Color(hex: 0x008236)
        case .spacing, .reserved: Color(hex: 0x8200DB)
        case .corners: Color(hex: 0xC6005C)
        case .size: colorScheme == .dark ? .white : Color(hex: 0x314158)
        }
    }

    func fill(_ role: AnnotationRole) -> Color {
        if let custom = colors[role] {
            return custom.opacity(colorScheme == .dark ? Self.fillOpacity : Self.customLightFillOpacity)
        }
        // The pale 200 fills turn gray over dark UI; the 700 lines keep their hue.
        if colorScheme == .dark, role != .size {
            return line(role).opacity(Self.fillOpacity)
        }
        let base = switch role {
        case .layers: Color(hex: 0xBEDBFF)
        case .padding: Color(hex: 0xFFD6A7)
        case .content: Color(hex: 0xB9F8CF)
        case .spacing, .reserved: Color(hex: 0xE9D4FF)
        case .corners: Color(hex: 0xFCCEE8)
        case .size: Color(hex: 0xE2E8F0)
        }
        return base.opacity(Self.fillOpacity)
    }

    func labelForeground(_ role: AnnotationRole) -> Color {
        // Only the default size badge is white in dark mode and needs dark text.
        role == .size && colorScheme == .dark && colors.size == nil ? Color(hex: 0x0F172B) : .white
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
