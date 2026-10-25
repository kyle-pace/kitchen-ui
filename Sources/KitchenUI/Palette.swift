import SwiftUI
import UIKit

/// Color tokens, each with a light and a dark value. All text pairs meet WCAG AA (4.5:1)
/// on `ground` and `surface` in both modes.
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

    /// The brand color: buttons, links, selection. One for both apps for now.
    nonisolated(unsafe) public static var accent = Color(light: 0x2F6B4F, dark: 0x7CC4A0)
    /// The accent on an inverted (ink) surface, like a toast's Undo.
    public static let inverseAccent = Color(light: 0xA8D5BC, dark: 0x2F6B4F)
    /// Text and icons on an accent fill.
    public static let onAccent = Color(light: 0xFFFFFF, dark: 0x0E1F17)

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

    /// A stronger mark (dots, rings) for each tone, readable on `surface`.
    public static func mark(_ tone: Tone) -> Color {
        switch tone {
        case .good: accent
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
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}
