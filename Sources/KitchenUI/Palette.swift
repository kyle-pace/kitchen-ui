import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Color tokens, each with a light and a dark value. All text pairs meet WCAG AA (4.5:1)
/// on `ground` and `surface` in both modes. The neutrals and tones are shared by both apps;
/// each app picks its accent with `Palette.use(_:)`.
public enum Palette {
    // Neutrals: the paper and ink colors. Each app picks a set with `use(_:neutrals:)`.
    nonisolated(unsafe) public static var ground = Neutrals.stone.ground
    nonisolated(unsafe) public static var surface = Neutrals.stone.surface
    nonisolated(unsafe) public static var raised = Neutrals.stone.raised
    nonisolated(unsafe) public static var ink = Neutrals.stone.ink
    nonisolated(unsafe) public static var body = Neutrals.stone.body
    nonisolated(unsafe) public static var muted = Neutrals.stone.muted
    nonisolated(unsafe) public static var line = Neutrals.stone.line
    nonisolated(unsafe) public static var divider = Neutrals.stone.divider

    /// Backgrounds, text and lines, light and dark. Grocery Deals uses the harbor blues of its
    /// "Puget evening" palette (it used the cool `stone` before); Henwood uses the warm `oat`
    /// from its brand guide. Every text color meets AA on ground,
    /// surface and raised in both modes.
    public struct Neutrals: Sendable {
        public let ground: Color
        public let surface: Color
        public let raised: Color
        public let ink: Color
        public let body: Color
        public let muted: Color
        public let line: Color
        public let divider: Color

        public init(ground: Color, surface: Color, raised: Color, ink: Color, body: Color, muted: Color, line: Color, divider: Color) {
            self.ground = ground
            self.surface = surface
            self.raised = raised
            self.ink = ink
            self.body = body
            self.muted = muted
            self.line = line
            self.divider = divider
        }

        public static let stone = Neutrals(
            ground: Color(light: 0xF4F4F1, dark: 0x121413),
            surface: Color(light: 0xFFFFFF, dark: 0x1D201E),
            raised: Color(light: 0xE9EAE6, dark: 0x2A2E2B),
            ink: Color(light: 0x1B1F1D, dark: 0xEEF1EE),
            body: Color(light: 0x4A514D, dark: 0xC9CFCB),
            muted: Color(light: 0x5E6661, dark: 0xA3ABA6),
            line: Color(light: 0xD5D7D1, dark: 0x3A3F3C),
            divider: Color(light: 0xECECE8, dark: 0x2A2E2B))

        /// Grocery Deals, "Puget evening": mist paper and harbor ink, harbor blue at night.
        /// Ink 15.7:1, body 8.2:1, muted 5.5:1 on ground (5.0:1 on raised); dark ink 15.7:1,
        /// body 11.7:1, muted 8.7:1 on ground (6.3:1 on raised).
        public static let harbor = Neutrals(
            ground: Color(light: 0xEEF3F6, dark: 0x0F1A24),
            surface: Color(light: 0xFFFFFF, dark: 0x172633),
            raised: Color(light: 0xE1E9EF, dark: 0x223445),
            ink: Color(light: 0x0F1A24, dark: 0xEEF3F6),
            body: Color(light: 0x3A4A57, dark: 0xC9D4DC),
            muted: Color(light: 0x536472, dark: 0xA9B8C4),
            line: Color(light: 0xCCD7E0, dark: 0x2A3D4E),
            divider: Color(light: 0xE3EAF0, dark: 0x1E2F3E))

        /// Henwood: oat paper and bark ink. Ink 13.9:1, body 8.5:1, muted 5.5:1 on ground;
        /// dark ink 16.0:1, body 11.6:1, muted 7.5:1.
        public static let oat = Neutrals(
            ground: Color(light: 0xF6F0E4, dark: 0x16120E),
            surface: Color(light: 0xFFFCF6, dark: 0x211C17),
            raised: Color(light: 0xECE3D2, dark: 0x2F2822),
            ink: Color(light: 0x2A211B, dark: 0xF4EDE2),
            body: Color(light: 0x4E4338, dark: 0xD6CBBB),
            muted: Color(light: 0x6B5F52, dark: 0xAFA292),
            line: Color(light: 0xDCD1BD, dark: 0x433A31),
            divider: Color(light: 0xEEE6D8, dark: 0x2F2822))
    }

    /// An app's brand color and the two colors that go with it. Both apps share the neutrals,
    /// the tones and the type; the accent is where they differ, so they read as siblings.
    public struct Accent: Sendable {
        /// Buttons, links, selection, the current tab.
        public let accent: Color
        /// Text and icons on an accent fill.
        public let onAccent: Color
        /// The accent on an inverted (ink) surface, like a toast's Undo.
        public let inverseAccent: Color

        public init(accent: Color, onAccent: Color, inverseAccent: Color) {
            self.accent = accent
            self.onAccent = onAccent
            self.inverseAccent = inverseAccent
        }

        /// Henwood: the sprout and lid green of the jar. 6.3:1 on white, 5.7:1 on ground;
        /// dark 9.0:1 on ground. White on it 6.3:1; the dark ink on the dark green 8.4:1.
        public static let herb = Accent(accent: Color(light: 0x2F6B4F, dark: 0x7CC4A0),
                                        onAccent: Color(light: 0xFFFFFF, dark: 0x0E1F17),
                                        inverseAccent: Color(light: 0xA8D5BC, dark: 0x2F6B4F))

        /// Henwood: moss, a shade deeper than the icon's so text on it passes. 5.7:1 on oat,
        /// 6.3:1 on surface; dark 10.1:1 on ground. White on it 6.5:1; the dark ink on dark moss 9.2:1.
        public static let moss = Accent(accent: Color(light: 0x4A6636, dark: 0xA9C98C),
                                        onAccent: Color(light: 0xFFFFFF, dark: 0x15200E),
                                        inverseAccent: Color(light: 0xB9D39E, dark: 0x4A6636))

        /// Deals, "Puget evening": rain blue. 6.9:1 on ground, 7.7:1 on white; dark 9.0:1 on
        /// ground, 7.9:1 on surface. White on it 7.7:1; the harbor ink on the dark rain blue 9.0:1.
        public static let rain = Accent(accent: Color(light: 0x24577A, dark: 0x6CC4E8),
                                        onAccent: Color(light: 0xFFFFFF, dark: 0x0F1A24),
                                        inverseAccent: Color(light: 0x6CC4E8, dark: 0x24577A))

        /// Deals until 2026-11-06: a deep persimmon, the fruit on its old icon, cooked down far enough to carry text.
        /// 5.7:1 on white, 5.2:1 on ground; dark 8.9:1 on ground, 7.9:1 on surface. White on
        /// it 5.7:1; the dark ink on the dark persimmon 8.5:1.
        public static let persimmon = Accent(accent: Color(light: 0xB04418, dark: 0xF5A06A),
                                             onAccent: Color(light: 0xFFFFFF, dark: 0x2A1208),
                                             inverseAccent: Color(light: 0xF5A06A, dark: 0xB04418))
    }

    /// Call once in the App's `init`, before the first view, to give the app its accent.
    /// Without a call, everything is Henwood's herb green.
    public static func use(_ choice: Accent, neutrals: Neutrals = .stone) {
        ground = neutrals.ground
        surface = neutrals.surface
        raised = neutrals.raised
        ink = neutrals.ink
        body = neutrals.body
        muted = neutrals.muted
        line = neutrals.line
        divider = neutrals.divider
        accent = choice.accent
        onAccent = choice.onAccent
        inverseAccent = choice.inverseAccent
    }

    /// The brand color: buttons, links, selection. See `use(_:)`.
    nonisolated(unsafe) public static var accent = Accent.herb.accent
    /// The accent on an inverted (ink) surface, like a toast's Undo.
    nonisolated(unsafe) public static var inverseAccent = Accent.herb.inverseAccent
    /// Text and icons on an accent fill.
    nonisolated(unsafe) public static var onAccent = Accent.herb.onAccent

    // Tones: fills behind text, and the text/icon color on them.
    public enum Tone: Sendable { case good, warn, bad, neutral, info }

    public static func fill(_ tone: Tone) -> Color {
        switch tone {
        case .good: Color(light: 0xE3EFE8, dark: 0x1C3529)
        case .warn: Color(light: 0xFBEED0, dark: 0x3A2E12)
        case .bad: Color(light: 0xFADFD6, dark: 0x3D1F17)
        case .neutral: Color(light: 0xE9EAE6, dark: 0x2A2E2B)
        case .info: Color(light: 0xE1ECF7, dark: 0x1A2A3A)
        }
    }

    public static func text(_ tone: Tone) -> Color {
        switch tone {
        case .good: Color(light: 0x1F4D37, dark: 0xA6DCBF)
        case .warn: Color(light: 0x6E4700, dark: 0xF2C66D)
        case .bad: Color(light: 0x85290F, dark: 0xFFAD94)
        case .neutral: Color(light: 0x454C48, dark: 0xC9CFCB)
        case .info: Color(light: 0x1E4A73, dark: 0xA8CCF0)
        }
    }

    /// A stronger mark (dots, rings) for each tone, readable on `surface`. These stay the same
    /// in both apps whatever the accent: "good" is always this green.
    public static func mark(_ tone: Tone) -> Color {
        switch tone {
        case .good: Color(light: 0x2F6B4F, dark: 0x7CC4A0)
        case .warn: Color(light: 0x8A5A00, dark: 0xE8B44F)
        case .bad: Color(light: 0xA3361A, dark: 0xFF8C6E)
        case .neutral: muted
        case .info: Color(light: 0x2C639A, dark: 0x8DBCE8)
        }
    }
}

public enum Radius {
    public static let small: CGFloat = 10    // thumbnails, small fills
    public static let medium: CGFloat = 14   // buttons, fields
    public static let large: CGFloat = 18    // cards
}

public enum Space {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
}

extension Color {
    public init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    public init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
        #else
        self.init(NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
        #endif
    }
}
