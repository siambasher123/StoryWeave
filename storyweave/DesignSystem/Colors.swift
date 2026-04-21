import SwiftUI

private nonisolated func rgb(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let i = UInt64(h, radix: 16) ?? 0
    return (CGFloat((i >> 16) & 0xFF) / 255,
            CGFloat((i >> 8)  & 0xFF) / 255,
            CGFloat(i         & 0xFF) / 255)
}

extension Color {
    // MARK: — Royal Purple palette (dark mode only)

    static let swBackground      = Color(hex: "#2E1F80")
    static let swSurface         = Color(hex: "#3D2D9A")
    static let swSurfaceRaised   = Color(hex: "#4E3BB8")

    static let swAccentPrimary   = Color(hex: "#8B5CF6")
    static let swAccentPressed   = Color(hex: "#7C3AED")
    static let swAccentMuted     = Color(hex: "#6D28D9")
    static let swAccentLight     = Color(hex: "#C4B5FD")
    static let swAccentDeep      = Color(hex: "#3730A3")

    static let swAccentSecondary = Color(hex: "#F87171")
    static let swAccentHighlight = Color(hex: "#34D399")

    static let swTextPrimary     = Color(hex: "#F5F3FF")
    static let swTextSecondary   = Color(hex: "#A78BFA")

    static let swDanger          = Color(hex: "#F87171")
    static let swSuccess         = Color(hex: "#34D399")
    static let swWarning         = Color(hex: "#FCD34D")

    // MARK: — Hex initialiser

    init(hex: String) {
        let (r, g, b) = rgb(hex)
        self.init(red: r, green: g, blue: b)
    }
}

extension Font {
    static let swDisplay  = Font.system(.largeTitle, design: .serif).bold()
    static let swTitle    = Font.system(.title2,     design: .serif).bold()
    static let swHeadline = Font.system(.headline,   design: .default)
    static let swBody     = Font.system(.body,       design: .default)
    static let swCaption  = Font.system(.caption,    design: .default)
}

let swSpacing: CGFloat = 8
