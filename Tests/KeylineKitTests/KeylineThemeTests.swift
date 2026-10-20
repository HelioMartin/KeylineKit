import SwiftUI
@testable import KeylineKit
import Testing

struct KeylineThemeTests {
    private static let roles: [AnnotationRole] = [.layers, .padding, .content, .spacing, .reserved, .corners, .size]
    private static let schemes: [ColorScheme] = [.light, .dark]

    /// A distinct color per role, to catch a role read from the wrong property.
    private static let custom = KeylineColors(
        layers: .red, padding: .orange, content: .yellow, spacing: .green,
        reserved: .mint, corners: .teal, size: .indigo
    )

    @Test func keepsTheDefaultPaletteWithoutCustomColors() {
        let dark = KeylineTheme(colorScheme: .dark)

        #expect(dark.line(.size) == .white)
        #expect(dark.labelForeground(.size) != .white)
        #expect(dark.labelForeground(.padding) == .white)
    }

    @Test(arguments: roles, schemes)
    func drawsLinesWithTheCustomColorOfEachRole(role: AnnotationRole, scheme: ColorScheme) throws {
        let theme = KeylineTheme(colorScheme: scheme, colors: Self.custom)
        let color = try #require(Self.custom[role])

        #expect(theme.line(role) == color)
        #expect(theme.fill(role) == color.opacity(scheme == .dark ? 0.45 : 0.2))
        #expect(theme.labelForeground(role) == .white)
    }

    @Test(arguments: roles, schemes)
    func keepsTheDefaultColorOfUnsetRoles(role: AnnotationRole, scheme: ColorScheme) {
        // Every role but `role` is customized.
        var colors = Self.custom
        switch role {
        case .layers: colors.layers = nil
        case .padding: colors.padding = nil
        case .content: colors.content = nil
        case .spacing: colors.spacing = nil
        case .reserved: colors.reserved = nil
        case .corners: colors.corners = nil
        case .size: colors.size = nil
        }
        let theme = KeylineTheme(colorScheme: scheme, colors: colors)
        let palette = KeylineTheme(colorScheme: scheme)

        #expect(theme.line(role) == palette.line(role))
        #expect(theme.fill(role) == palette.fill(role))
        #expect(theme.labelForeground(role) == palette.labelForeground(role))
    }

    @Test func innerColorsOverrideOuterOnes() {
        let outer = KeylineColors(layers: .red, padding: .orange)
        let inner = KeylineColors(padding: .blue, spacing: .green)

        let combined = outer.overriding(with: inner)

        #expect(combined == KeylineColors(layers: .red, padding: .blue, spacing: .green))
    }
}
