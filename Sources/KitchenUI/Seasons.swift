import SwiftUI

// Seasonal items (KitchenCatalog's seasons.json): the card both apps show while something is in
// season, and the fruit that falls when you tap its buddy. Persimmons are first.

extension Buddy.Kind: CaseIterable {
    public static let allCases: [Buddy.Kind] = [.persimmon, .jar]

    /// The name seasons.json and Grocery Deals' feed use for this character ("persimmon").
    public var name: String {
        switch self {
        case .persimmon: "persimmon"
        case .jar: "jar"
        }
    }

    /// The character's own color, for a season card's wash when the app has no color from a feed
    /// (Maitake). Persimmon orange; the jar's leaf green.
    public var tint: Color {
        switch self {
        case .persimmon: BuddyColors.persimmon
        case .jar: BuddyColors.leaf
        }
    }

    /// The character for a name, or nil when this version doesn't have it yet (a newer feed can
    /// name a buddy an older app hasn't drawn). Callers show `SeasonMark`'s leaf instead.
    public init?(name: String?) {
        guard let name, let kind = Self.allCases.first(where: { $0.name == name.lowercased() }) else { return nil }
        self = kind
    }
}

/// A season's buddy, or a leaf in a tinted circle for items that don't have a character yet.
public struct SeasonMark: View {
    let kind: Buddy.Kind?
    let mood: Buddy.Mood
    let size: CGFloat
    let tint: Color
    var hop: Int

    public init(_ kind: Buddy.Kind?, mood: Buddy.Mood = .happy, size: CGFloat = 56, tint: Color = Palette.accent, hop: Int = 0) {
        self.kind = kind
        self.mood = mood
        self.size = size
        self.tint = tint
        self.hop = hop
    }

    public var body: some View {
        if let kind {
            Buddy(kind, mood: mood, size: size, hop: hop)
        } else {
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size * 0.86, height: size * 0.86)
                .background(tint.opacity(0.16), in: Circle())
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

/// "PERSIMMON SEASON / Fuyu $1.28/lb at T&T / Through Thu · about 17 for $10", with the buddy
/// hopping in on the left and a soft wash of the item's color. Wrap it in a Button; it combines
/// into one VoiceOver element. Text stays ink and muted, so the tint never carries meaning and
/// contrast holds in light and dark.
public struct SeasonCard: View {
    let kind: Buddy.Kind?
    let eyebrow: String
    let title: String
    let detail: String?
    let tint: Color
    let mood: Buddy.Mood
    var hop: Int
    var chevron: Bool

    /// `tint` defaults to the character's own color, or the app's accent for the leaf.
    public init(_ kind: Buddy.Kind?, eyebrow: String, title: String, detail: String? = nil, tint: Color? = nil,
                mood: Buddy.Mood = .happy, hop: Int = 0, chevron: Bool = true) {
        self.kind = kind
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
        self.tint = tint ?? kind?.tint ?? Palette.accent
        self.mood = mood
        self.hop = hop
        self.chevron = chevron
    }

    public var body: some View {
        HStack(spacing: Space.m) {
            SeasonMark(kind, mood: mood, size: 60, tint: tint, hop: hop)
                .hiddenWhenTextIsLarge()
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle().fill(tint).frame(width: 7, height: 7).accessibilityHidden(true)
                    Text(eyebrow.uppercased())
                        .font(.app(.caption, .bold)).tracking(0.6)
                        .foregroundStyle(Palette.muted)
                }
                Text(title)
                    .font(.app(.title3, .heavy))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.app(.subheadline))
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.app(.subheadline, .semibold))
                    .foregroundStyle(Palette.muted)
                    .accessibilityHidden(true)
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.large).fill(Palette.surface)
                RoundedRectangle(cornerRadius: Radius.large)
                    .fill(LinearGradient(colors: [tint.opacity(0.16), tint.opacity(0.03)], startPoint: .leading, endPoint: .trailing))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: Radius.large).strokeBorder(tint.opacity(0.35)))
        .contentShape(RoundedRectangle(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }
}

// MARK: Falling fruit

extension View {
    /// Drops a burst of little buddies (persimmons, say) from the top of the view each time
    /// `trigger` changes, like clicking the persimmon page on the site. Never blocks taps, and
    /// does nothing under Reduce Motion. Pair the trigger with a light haptic.
    public func fallingBuddies(_ kind: Buddy.Kind?, trigger: Int, count: Int = 14) -> some View {
        modifier(FallingBuddies(kind: kind, trigger: trigger, count: count))
    }
}

private struct FallingBuddies: ViewModifier {
    let kind: Buddy.Kind?
    let trigger: Int
    let count: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [Burst] = []

    struct Piece {
        let x = Double.random(in: 0.04...0.96)
        let delay = Double.random(in: 0...0.35)
        let size = Double.random(in: 26...46)
        let spin = Double.random(in: -2.4...2.4)
        let tilt = Double.random(in: -0.5...0.5)
        let push = Double.random(in: 0...0.35)
    }

    struct Burst: Identifiable {
        let id = UUID()
        let start = Date.now
        let pieces: [Piece]
    }

    private static let life = 2.6

    func body(content: Content) -> some View {
        content
            .overlay {
                if let kind, !bursts.isEmpty {
                    TimelineView(.animation) { timeline in
                        Canvas { ctx, size in
                            guard let symbol = ctx.resolveSymbol(id: 0) else { return }
                            for burst in bursts {
                                let t = timeline.date.timeIntervalSince(burst.start)
                                for p in burst.pieces {
                                    let life = t - p.delay
                                    guard life > 0 else { continue }
                                    // Falls under gravity from just above the top.
                                    let g = size.height * 0.9
                                    let y = -p.size + (p.push * size.height) * life + 0.5 * g * life * life
                                    guard y < size.height + p.size else { continue }
                                    var c = ctx
                                    c.translateBy(x: p.x * size.width + sin(life * 2 + p.x * 8) * 10, y: y)
                                    c.rotate(by: .radians(p.tilt + life * p.spin))
                                    c.scaleBy(x: p.size / 48, y: p.size / 48)
                                    c.draw(symbol, at: .zero)
                                }
                            }
                        } symbols: {
                            BuddyBody(kind: kind).frame(width: 48, height: 48).tag(0)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .onChange(of: trigger) {
                guard !reduceMotion, kind != nil else { return }
                let burst = Burst(pieces: (0..<count).map { _ in Piece() })
                bursts.append(burst)
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Self.life + 0.4))
                    bursts.removeAll { $0.id == burst.id }
                }
            }
    }
}

#Preview("Season card") {
    @Previewable @State var hop = 0
    @Previewable @State var drops = 0
    VStack(spacing: 16) {
        SeasonCard(.persimmon, eyebrow: "Persimmon season", title: "Fuyu $1.28/lb at T&T",
                   detail: "Through Thu · about 17 for $10", tint: Color(light: 0xE8743B, dark: 0xF08A4B), hop: hop)
        SeasonCard(nil, eyebrow: "Cherry season", title: "Rainier $3.99/lb at H Mart", detail: "Through Tue",
                   tint: Color(light: 0xC23B4E, dark: 0xE06A7A))
        Button("Drop persimmons") { drops += 1; hop += 1 }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .fallingBuddies(.persimmon, trigger: drops)
}
