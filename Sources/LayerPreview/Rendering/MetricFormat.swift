import CoreGraphics
import Foundation

/// Formats measured points the way safearea.info does: up to two decimals,
/// without trailing zeros (`24`, `36.67`).
enum MetricFormat {
    static func points(_ value: CGFloat) -> String {
        let hundredths = (value * 100).rounded()
        if hundredths.truncatingRemainder(dividingBy: 100) == 0 {
            return String(Int(hundredths / 100))
        }
        var text = String(format: "%.2f", Double(hundredths / 100))
        while text.hasSuffix("0") {
            text.removeLast()
        }
        return text
    }

    static func size(_ size: CGSize) -> String {
        "\(points(size.width)) × \(points(size.height))"
    }

    /// The measured value, followed by the declared one when the source does
    /// not already say it: `16 · default`, `12 · Theme.spacing`.
    static func measured(_ value: CGFloat, declared: String?) -> String {
        let measured = points(value)
        guard let declared, !declared.isEmpty else { return measured }
        if let number = Double(declared), abs(CGFloat(number) - value) < 0.05 {
            return measured
        }
        return "\(measured) · \(abbreviated(declared))"
    }

    private static func abbreviated(_ text: String, limit: Int = 18) -> String {
        let singleLine = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard singleLine.count > limit else { return singleLine }
        return singleLine.prefix(limit - 1) + "…"
    }
}
