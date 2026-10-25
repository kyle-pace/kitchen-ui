import SwiftUI
import UIKit

/// Accessibility first: every screen should work with VoiceOver, at the largest text sizes,
/// with Voice Control and Switch Control, and by voice.
public enum Announce {
    /// Tells VoiceOver what just happened, without moving focus.
    @MainActor
    public static func say(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning, !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }
}

/// Side by side normally; stacked at the accessibility text sizes, so long names and big text
/// never get squeezed or clipped.
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var size
    var spacing: CGFloat
    var content: Content

    public init(spacing: CGFloat = Space.s, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        let layout = size.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        layout { content }
    }
}

extension View {
    /// Wrap freely at the accessibility text sizes instead of cutting text off.
    public func lineLimitUnlessLarge(_ limit: Int) -> some View { modifier(LineLimitUnlessLarge(limit: limit)) }

    /// Decorative icons give their room back to the words at the accessibility text sizes.
    public func hiddenWhenTextIsLarge() -> some View { modifier(HiddenWhenLarge()) }
}

private struct LineLimitUnlessLarge: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size
    let limit: Int
    func body(content: Content) -> some View { content.lineLimit(size.isAccessibilitySize ? nil : limit) }
}

private struct HiddenWhenLarge: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size
    func body(content: Content) -> some View {
        if !size.isAccessibilitySize { content.accessibilityHidden(true) }
    }
}
