import SwiftUI

private nonisolated func rgb(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let i = UInt64(h, radix: 16) ?? 0
    return (CGFloat((i >> 16) & 0xFF) / 255,
            CGFloat((i >> 8)  & 0xFF) / 255,
            CGFloat(i         & 0xFF) / 255)
}

extension Color {
    // MARK: — Stormcrest palette (dark mode, eye-soothing, breathable)
    // Backgrounds at 15–25% lightness — deliberate dark, not pitch-black

    static let swBackground      = Color(hex: "#1C1A35")   // deep indigo — breathable floor
    static let swSurface         = Color(hex: "#26234A")   // card bg — pops off background
    static let swSurfaceRaised   = Color(hex: "#322E5E")   // raised card / picker

    static let swAccentPrimary   = Color(hex: "#7C5CE8")   // brand violet
    static let swAccentPressed   = Color(hex: "#6B4FD0")
    static let swAccentMuted     = Color(hex: "#5A42B8")
    static let swAccentLight     = Color(hex: "#C4B0FF")   // ≥4.5:1 on swBackground
    static let swAccentDeep      = Color(hex: "#1F1C45")

    static let swAccentSecondary = Color(hex: "#E07070")   // dragon red — alerts only
    static let swAccentHighlight = Color(hex: "#50C9A0")   // elven teal — success only

    // Gold/amber RPG accent
    static let swGold            = Color(hex: "#D4A840")
    static let swGoldLight       = Color(hex: "#F0CC70")
    static let swGoldDeep        = Color(hex: "#2A2010")

    static let swTextPrimary     = Color(hex: "#EEE9FF")   // warm lavender white
    static let swTextSecondary   = Color(hex: "#9C90CC")   // ≥3:1 on swBackground

    static let swDanger          = Color(hex: "#E07070")
    static let swSuccess         = Color(hex: "#50C9A0")
    static let swWarning         = Color(hex: "#F0C040")

    // MARK: — Hex initialiser (nonisolated so it is usable in static property defaults)

    nonisolated init(hex: String) {
        let (r, g, b) = rgb(hex)
        self.init(red: r, green: g, blue: b)
    }

    // MARK: — Contextual gradient helpers

    nonisolated func swGradientCard() -> LinearGradient {
        LinearGradient(colors: [opacity(0.25), opacity(0.06)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    nonisolated func swGradientGlow(radius: CGFloat = 60) -> RadialGradient {
        RadialGradient(colors: [opacity(0.30), opacity(0.0)],
                       center: .center, startRadius: 0, endRadius: radius)
    }

    nonisolated func swGradientTopEdge() -> LinearGradient {
        LinearGradient(colors: [opacity(0.55), opacity(0.0)],
                       startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: — Named gradient constants
// nonisolated(unsafe) because static stored property defaults are evaluated outside the main actor

extension LinearGradient {
    static let swGradientPrimary = LinearGradient(
        colors: [Color(hex: "#9070F0"), Color(hex: "#5A38C0")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let swGradientGold = LinearGradient(
        colors: [Color(hex: "#F0CC70"), Color(hex: "#B07820")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let swGradientSurface = LinearGradient(
        colors: [Color(hex: "#2E2A56"), Color(hex: "#201D42")],
        startPoint: .top, endPoint: .bottom)

    static let swGradientSurfaceRaised = LinearGradient(
        colors: [Color(hex: "#3C3668"), Color(hex: "#28244E")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let swGradientDanger = LinearGradient(
        colors: [Color(hex: "#E88080"), Color(hex: "#B04040")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let swGradientSuccess = LinearGradient(
        colors: [Color(hex: "#60D9B0"), Color(hex: "#2A9870")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let swGradientBackground = LinearGradient(
        colors: [Color(hex: "#211F40"), Color(hex: "#181630")],
        startPoint: .top, endPoint: .bottom)
}

// MARK: — Typography

extension Font {
    static let swDisplay  = Font.system(.largeTitle, design: .serif).bold()
    static let swTitle    = Font.system(.title2,     design: .serif).bold()
    static let swHeadline = Font.system(.headline,   design: .rounded).weight(.semibold)
    static let swBody     = Font.system(.body,       design: .default)
    static let swCaption  = Font.system(.caption,    design: .default)
}

let swSpacing: CGFloat = 8
