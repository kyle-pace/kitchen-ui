import SwiftUI

// MARK: Working

/// One step of a longer job, shown as a checklist line that ticks off when done.
public struct WorkingStep: Identifiable, Hashable, Sendable {
    public enum State: Sendable { case waiting, working, done }
    public let id: String
    public var title: String
    public var state: State

    public init(_ title: String, state: State = .waiting, id: String? = nil) {
        self.id = id ?? title
        self.title = title
        self.state = state
    }
}

/// What to show while something takes more than a second: the buddy thinking, a line that says
/// what's actually happening, and optionally a checklist that ticks off as steps finish.
/// Replaces a bare spinner. Announces the title to VoiceOver once.
public struct WorkingView: View {
    let kind: Buddy.Kind
    let title: String
    var detail: String?
    var steps: [WorkingStep]
    var compact: Bool

    public init(_ kind: Buddy.Kind, title: String, detail: String? = nil, steps: [WorkingStep] = [], compact: Bool = false) {
        self.kind = kind
        self.title = title
        self.detail = detail
        self.steps = steps
        self.compact = compact
    }

    public var body: some View {
        Group {
            if compact {
                HStack(spacing: Space.m) {
                    Buddy(kind, mood: .thinking, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.app(.callout, .semibold)).foregroundStyle(Palette.ink)
                        if let detail { Text(detail).font(.app(.footnote)).foregroundStyle(Palette.muted) }
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: Space.l) {
                    Buddy(kind, mood: .thinking, size: 104)
                    VStack(spacing: Space.xs) {
                        Text(title).font(.app(.title3, .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                        if let detail {
                            Text(detail).font(.app(.subheadline)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                        }
                    }
                    if !steps.isEmpty {
                        VStack(alignment: .leading, spacing: Space.s) {
                            ForEach(steps) { step in StepLine(step: step) }
                        }
                        .padding(Space.l)
                        .frame(maxWidth: 360, alignment: .leading)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
                        .overlay(RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.line.opacity(0.7)))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Space.xl)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel([title, detail].compactMap { $0 }.joined(separator: ". "))
        .onAppear { Announce.say(title) }
    }
}

private struct StepLine: View {
    let step: WorkingStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Space.s) {
            Image(systemName: symbol)
                .foregroundStyle(step.state == .done ? Palette.accent : Palette.muted)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.pulse, isActive: step.state == .working && !reduceMotion)
                .frame(width: 22)
            Text(step.title)
                .font(.app(.callout, step.state == .working ? .semibold : .regular))
                .foregroundStyle(step.state == .waiting ? Palette.muted : Palette.ink)
        }
        .animation(reduceMotion ? nil : .snappy, value: step.state)
        .accessibilityElement(children: .combine)
        .accessibilityValue(step.state == .done ? "done" : step.state == .working ? "in progress" : "waiting")
    }

    private var symbol: String {
        switch step.state {
        case .waiting: "circle"
        case .working: "circle.dotted"
        case .done: "checkmark.circle.fill"
        }
    }
}

// MARK: Empty states

/// An empty screen with a point of view: the buddy, one line, and one way forward.
/// Built on ContentUnavailableView, so it sizes and reads like the system's own.
public struct EmptyState: View {
    let kind: Buddy.Kind
    let mood: Buddy.Mood
    let title: String
    var message: String?
    var actionTitle: String?
    var actionImage: String?
    var action: (() -> Void)?

    public init(_ kind: Buddy.Kind, mood: Buddy.Mood = .neutral, title: String, message: String? = nil,
                actionTitle: String? = nil, actionImage: String? = nil, action: (() -> Void)? = nil) {
        self.kind = kind
        self.mood = mood
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionImage = actionImage
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            VStack(spacing: Space.m) {
                Buddy(kind, mood: mood, size: 88).hiddenWhenTextIsLarge()
                Text(title).font(.app(.title3, .bold)).foregroundStyle(Palette.ink)
            }
        } description: {
            if let message { Text(message).font(.app(.callout)).foregroundStyle(Palette.muted) }
        } actions: {
            if let actionTitle, let action {
                Button(action: action) {
                    if let actionImage { Label(actionTitle, systemImage: actionImage) } else { Text(actionTitle) }
                }
                .font(.app(.headline))
                .buttonStyle(.glassProminent)
                .tint(Palette.accent)
            }
        }
    }
}

// MARK: Effects

extension View {
    /// A soft light that sweeps across placeholder content. Pair with
    /// `.redacted(reason: .placeholder)`. Still under Reduce Motion.
    public func shimmer(_ active: Bool = true) -> some View { modifier(Shimmer(active: active)) }

    /// Lands with a small overshoot and tilt when `trigger` changes, like a stamp on paper.
    public func stamp<T: Equatable & Sendable>(trigger: T) -> some View { modifier(Stamp(trigger: trigger)) }

    /// Stamps once, the first time the view appears.
    public func stampOnAppear() -> some View { modifier(StampOnAppear()) }

    /// A once-only celebration over the view: paper scraps (Deals) or herbs (Pantry), plus a line
    /// of text. Announced to VoiceOver; under Reduce Motion only the text shows. Clears itself.
    public func celebration(_ isPresented: Binding<Bool>, style: CelebrationStyle, message: String) -> some View {
        modifier(CelebrationOverlay(isPresented: isPresented, style: style, message: message))
    }
}

private struct Shimmer: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content.overlay {
                GeometryReader { geo in
                    LinearGradient(colors: [.clear, Palette.surface.opacity(0.7), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.5, height: geo.size.height)
                        .phaseAnimator([-0.6, 1.6]) { view, x in
                            view.offset(x: geo.size.width * x)
                        } animation: { _ in .linear(duration: 1.3).delay(0.2) }
                }
                .mask(content)
                .allowsHitTesting(false)
            }
        } else {
            content
        }
    }
}

private struct StampValues {
    var scale: CGFloat = 1
    var angle: Double = 0
}

private struct Stamp<T: Equatable & Sendable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: StampValues(), trigger: trigger) { view, v in
                view.scaleEffect(v.scale).rotationEffect(.degrees(v.angle))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(reduceMotion ? 1 : 1.18, duration: 0.07)
                    SpringKeyframe(1, duration: 0.35, spring: .bouncy(extraBounce: 0.15))
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(reduceMotion ? 0 : -3, duration: 0.07)
                    SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                }
            }
    }
}

private struct StampOnAppear: ViewModifier {
    @State private var landed = false
    func body(content: Content) -> some View {
        content.stamp(trigger: landed).onAppear { landed = true }
    }
}

public enum CelebrationStyle: Sendable {
    /// Torn newsprint scraps and price-tag yellow, for Deals.
    case paper
    /// Herb leaves and a little steam, for Pantry.
    case herbs
}

private struct CelebrationOverlay: ViewModifier {
    @Binding var isPresented: Bool
    let style: CelebrationStyle
    let message: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    if !reduceMotion { Confetti(style: style).allowsHitTesting(false) }
                    Text(message)
                        .font(.app(.title2, .bold))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Space.xl).padding(.vertical, Space.l)
                        .glassEffect(.regular, in: .rect(cornerRadius: Radius.large))
                        .stampOnAppear()
                }
                .transition(.opacity)
                .task {
                    Announce.say(message)
                    try? await Task.sleep(for: .seconds(2.4))
                    withAnimation(.easeOut(duration: 0.4)) { isPresented = false }
                }
                .onTapGesture { isPresented = false }
            }
        }
        .sensoryFeedback(.success, trigger: isPresented) { _, now in now }
    }
}

/// Falling scraps drawn in a Canvas, about two seconds long.
private struct Confetti: View {
    let style: CelebrationStyle
    @State private var start = Date.now
    private let pieces: [Piece] = (0..<46).map { _ in Piece() }

    struct Piece {
        let x = Double.random(in: 0...1)
        let delay = Double.random(in: 0...0.5)
        let speed = Double.random(in: 0.45...0.8)
        let spin = Double.random(in: -6...6)
        let drift = Double.random(in: -0.08...0.08)
        let size = Double.random(in: 7...14)
        let tone = Int.random(in: 0...2)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                for p in pieces {
                    let life = t - p.delay
                    guard life > 0 else { continue }
                    let y = -20 + life * p.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = (p.x + sin(life * 3 + p.x * 9) * p.drift) * size.width
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(life * p.spin))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)
                    switch style {
                    case .paper:
                        let colors = [Color(light: 0xFFE45C, dark: 0xFFE45C), Palette.ink.opacity(0.85), Color(light: 0xF7F5F0, dark: 0xD9D4C8)]
                        c.fill(Path(rect), with: .color(colors[p.tone]))
                        if p.tone == 2 { c.stroke(Path(rect), with: .color(Palette.line), lineWidth: 0.8) }
                    case .herbs:
                        let colors = [BuddyColors.leaf, Palette.accent.opacity(0.7), Color(light: 0x8DBF6A, dark: 0x9BCF78)]
                        c.fill(Path(ellipseIn: rect.insetBy(dx: 0, dy: -p.size / 8)), with: .color(colors[p.tone]))
                    }
                }
            }
        }
        .onAppear { start = .now }
    }
}
