import SwiftUI

/// The apps' small characters: an everyday kitchen object with two eyes and a mouth. Deals has
/// the persimmon from its icon; Pantry has the jar with a sprout. Drawn with shapes, so they
/// scale, recolor for dark mode and animate. Use them for rare moments (waits, empty screens,
/// errors, finishing something), never on routine taps.
public struct Buddy: View {
    public enum Kind: Sendable { case persimmon, jar }
    public enum Mood: Sendable { case neutral, happy, thinking, sleepy, sad, surprised }

    let kind: Kind
    let mood: Mood
    let size: CGFloat
    /// Change this to make the buddy hop once (a wave hello, a little cheer).
    var hop: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ kind: Kind, mood: Mood = .neutral, size: CGFloat = 96, hop: Int = 0) {
        self.kind = kind
        self.mood = mood
        self.size = size
        self.hop = hop
    }

    public var body: some View {
        ZStack {
            BuddyBody(kind: kind)
            BuddyFace(mood: mood, size: size, animate: !reduceMotion)
                .frame(width: size * 0.56, height: size * 0.3)
                .offset(y: faceOffset)
        }
        .frame(width: size, height: size)
        .modifier(Wobble(active: mood == .thinking && !reduceMotion))
        .keyframeAnimator(initialValue: HopValues(), trigger: hop) { content, v in
            content
                .offset(y: v.lift * size)
                .scaleEffect(x: v.squash, y: 2 - v.squash, anchor: .bottom)
        } keyframes: { _ in
            KeyframeTrack(\.lift) {
                CubicKeyframe(0, duration: 0.08)
                SpringKeyframe(reduceMotion ? 0 : -0.14, duration: 0.18, spring: .snappy)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            }
            KeyframeTrack(\.squash) {
                CubicKeyframe(reduceMotion ? 1 : 1.08, duration: 0.08)
                CubicKeyframe(reduceMotion ? 1 : 0.94, duration: 0.18)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
        }
        .accessibilityHidden(true)
    }

    private var faceOffset: CGFloat {
        switch kind {
        case .persimmon: size * 0.12
        case .jar: size * 0.14
        }
    }
}

private struct HopValues {
    var lift: CGFloat = 0
    var squash: CGFloat = 1
}

/// A slow side-to-side tilt while thinking.
private struct Wobble: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([-4.0, 4.0]) { view, angle in
                view.rotationEffect(.degrees(angle), anchor: .bottom)
            } animation: { _ in .easeInOut(duration: 1.1) }
        } else {
            content
        }
    }
}

// MARK: Bodies

/// Persimmon orange and leaf green, readable in light and dark.
enum BuddyColors {
    static let persimmon = Color(light: 0xE8743B, dark: 0xF08A4B)
    static let persimmonShade = Color(light: 0xC85A24, dark: 0xD8692D)
    static let leaf = Color(light: 0x2F6B4F, dark: 0x5FAF86)
    static let stem = Color(light: 0x5B4632, dark: 0x8A7058)
    static let glass = Color(light: 0xDCEBE3, dark: 0x2A3A33)
    static let glassEdge = Color(light: 0x8FB5A2, dark: 0x5E8574)
    static let lid = Color(light: 0x2F6B4F, dark: 0x4E9A75)
    static let face = Color(light: 0x1B1F1D, dark: 0x111412)
}

struct BuddyBody: View {
    let kind: Buddy.Kind

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            switch kind {
            case .persimmon:
                ZStack {
                    // Fruit: a squat, slightly square persimmon (not a round tomato).
                    RoundedRectangle(cornerRadius: s * 0.34, style: .continuous)
                        .fill(BuddyColors.persimmon)
                        .frame(width: s * 0.86, height: s * 0.7)
                        .overlay(alignment: .topLeading) {
                            // A soft shine on the upper left.
                            Ellipse().fill(.white.opacity(0.28))
                                .frame(width: s * 0.16, height: s * 0.1)
                                .rotationEffect(.degrees(-30))
                                .offset(x: s * 0.1, y: s * 0.12)
                        }
                        .offset(y: s * 0.1)
                    // Calyx: four broad leaves lying flat on top, like a square green cap.
                    ForEach(0..<4, id: \.self) { i in
                        Ellipse().fill(BuddyColors.leaf)
                            .frame(width: s * 0.21, height: s * 0.11)
                            .offset(x: s * 0.09)
                            .rotationEffect(.degrees(Double(i) * 90 + 45))
                            .scaleEffect(x: 1.25, y: 0.42)
                            .offset(y: -s * 0.23)
                    }
                    Capsule().fill(BuddyColors.stem)
                        .frame(width: s * 0.045, height: s * 0.09)
                        .offset(y: -s * 0.28)
                }
                .frame(width: s, height: s)
            case .jar:
                ZStack {
                    // Sprout: two leaves on a stem.
                    Capsule().fill(BuddyColors.leaf).frame(width: s * 0.035, height: s * 0.16).offset(y: -s * 0.38)
                    Ellipse().fill(BuddyColors.leaf).frame(width: s * 0.16, height: s * 0.08)
                        .rotationEffect(.degrees(-25)).offset(x: -s * 0.07, y: -s * 0.45)
                    Ellipse().fill(BuddyColors.leaf).frame(width: s * 0.16, height: s * 0.08)
                        .rotationEffect(.degrees(25)).offset(x: s * 0.07, y: -s * 0.43)
                    // Lid
                    RoundedRectangle(cornerRadius: s * 0.04).fill(BuddyColors.lid)
                        .frame(width: s * 0.56, height: s * 0.12).offset(y: -s * 0.25)
                    // Glass body
                    RoundedRectangle(cornerRadius: s * 0.16).fill(BuddyColors.glass)
                        .overlay(RoundedRectangle(cornerRadius: s * 0.16).strokeBorder(BuddyColors.glassEdge, lineWidth: max(1.5, s * 0.025)))
                        .frame(width: s * 0.66, height: s * 0.62).offset(y: s * 0.13)
                    // A glint
                    Capsule().fill(.white.opacity(0.55))
                        .frame(width: s * 0.05, height: s * 0.2).offset(x: -s * 0.22, y: s * 0.05)
                }
                .frame(width: s, height: s)
            }
        }
    }
}

// MARK: Face

struct BuddyFace: View {
    let mood: Buddy.Mood
    let size: CGFloat
    let animate: Bool

    var body: some View {
        VStack(spacing: size * 0.05) {
            HStack(spacing: size * 0.16) {
                eye
                eye
            }
            .offset(y: mood == .thinking ? -size * 0.03 : 0)
            .modifier(Blink(active: animate && (mood == .neutral || mood == .thinking || mood == .surprised)))
            mouth
        }
        .foregroundStyle(BuddyColors.face)
    }

    @ViewBuilder private var eye: some View {
        let w = size * 0.075
        switch mood {
        case .happy:
            HappyEye().stroke(style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
                .frame(width: w * 1.5, height: w)
        case .sleepy:
            Capsule().frame(width: w * 1.3, height: size * 0.022)
        case .sad:
            Capsule().frame(width: w * 0.9, height: w * 1.15)
                .offset(y: size * 0.01)
        case .surprised:
            Circle().frame(width: w * 1.3, height: w * 1.3)
        case .neutral, .thinking:
            Capsule().frame(width: w, height: w * 1.35)
        }
    }

    @ViewBuilder private var mouth: some View {
        let stroke = StrokeStyle(lineWidth: size * 0.03, lineCap: .round)
        switch mood {
        case .happy:
            Mouth(curve: 1).stroke(style: stroke).frame(width: size * 0.18, height: size * 0.07)
        case .neutral:
            Mouth(curve: 0.5).stroke(style: stroke).frame(width: size * 0.12, height: size * 0.04)
        case .thinking:
            Mouth(curve: 0).stroke(style: stroke).frame(width: size * 0.08, height: size * 0.02).offset(x: size * 0.04)
        case .sleepy:
            Ellipse().frame(width: size * 0.05, height: size * 0.04)
        case .sad:
            Mouth(curve: -0.8).stroke(style: stroke).frame(width: size * 0.12, height: size * 0.04)
        case .surprised:
            Ellipse().stroke(style: stroke).frame(width: size * 0.06, height: size * 0.07)
        }
    }
}

/// Closes the eyes for a beat every few seconds.
private struct Blink: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([1.0, 1.0, 0.1, 1.0]) { view, scale in
                view.scaleEffect(y: scale)
            } animation: { scale in
                scale < 0.5 ? .easeIn(duration: 0.07) : .easeOut(duration: scale == 1 ? 1.6 : 0.09)
            }
        } else {
            content
        }
    }
}

/// An upside-down U, for eyes squeezed shut in a smile.
struct HappyEye: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        return p
    }
}

/// A mouth line: curve 1 is a smile, 0 is flat, -1 is a frown.
struct Mouth: Shape {
    var curve: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = curve >= 0 ? rect.minY : rect.maxY
        p.move(to: CGPoint(x: rect.minX, y: y))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: y),
                       control: CGPoint(x: rect.midX, y: y + rect.height * 2 * curve))
        return p
    }
}

#Preview("Buddies") {
    VStack(spacing: 24) {
        HStack { ForEach([Buddy.Mood.neutral, .happy, .thinking], id: \.self) { Buddy(.persimmon, mood: $0) } }
        HStack { ForEach([Buddy.Mood.sleepy, .sad, .surprised], id: \.self) { Buddy(.jar, mood: $0) } }
    }
    .padding()
}
