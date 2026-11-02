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
    // Neutrals
    public static let ground = Color(light: 0xF4F4F1, dark: 0x121413)
    public static let surface = Color(light: 0xFFFFFF, dark: 0x1D201E)
    public static let raised = Color(light: 0xE9EAE6, dark: 0x2A2E2B)     // chips, placeholders
    public static let ink = Color(light: 0x1B1F1D, dark: 0xEEF1EE)
    public static let body = Color(light: 0x4A514D, dark: 0xC9CFCB)       // long-form text
    public static let muted = Color(light: 0x5E6661, dark: 0xA3ABA6)
    public static let line = Color(light: 0xD5D7D1, dark: 0x3A3F3C)
    public static let divider = Color(light: 0xECECE8, dark: 0x2A2E2B)

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

        /// Maitake: the sprout and lid green of the jar. 6.3:1 on white, 5.7:1 on ground;
        /// dark 9.0:1 on ground. White on it 6.3:1; the dark ink on the dark green 8.4:1.
        public static let herb = Accent(accent: Color(light: 0x2F6B4F, dark: 0x7CC4A0),
                                        onAccent: Color(light: 0xFFFFFF, dark: 0x0E1F17),
                                        inverseAccent: Color(light: 0xA8D5BC, dark: 0x2F6B4F))

        /// Deals: a deep persimmon, the fruit on its icon, cooked down far enough to carry text.
        /// 5.7:1 on white, 5.2:1 on ground; dark 8.9:1 on ground, 7.9:1 on surface. White on
        /// it 5.7:1; the dark ink on the dark persimmon 8.5:1.
        public static let persimmon = Accent(accent: Color(light: 0xB04418, dark: 0xF5A06A),
                                             onAccent: Color(light: 0xFFFFFF, dark: 0x2A1208),
                                             inverseAccent: Color(light: 0xF5A06A, dark: 0xB04418))
    }

    /// Call once in the App's `init`, before the first view, to give the app its accent.
    /// Without a call, everything is Maitake's herb green.
    public static func use(_ choice: Accent) {
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
