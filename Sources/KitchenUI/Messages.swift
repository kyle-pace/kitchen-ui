import SwiftUI

// In-app messages, drawn the same way in every kitchen app. Each app fetches the message itself
// (Firebase Remote Config, parameter `in_app_message`) and hands it here; KitchenUI never talks to
// Firebase. The message is JSON:
//
//   {"id": "2026-11-ipad", "title": "Maitake on iPad", "body": "…",
//    "button": "Show me", "link": "maitake://tab/plan",
//    "button2": "Read more", "link2": "https://…",
//    "tone": "new", "image": "https://…/ipad.png", "imageAlt": "Maitake on an iPad",
//    "style": "card", "place": "home", "until": "2026-11-30", "audience": "all"}
//
// - id: change it for every new message. A closed message never comes back.
// - style: "card" (default) or "sheet" (shown once, over everything).
// - place: which screen a card sits on. The app names its own places; empty is its main screen.
// - tone: "tip", "new" or "heads-up" for a colored label; leave it out for a plain card.
// - image: an https picture shown above the text (decorative unless imageAlt is set).
// - until: the last day to show it (yyyy-MM-dd). audience: "dev" for development builds only.

public struct InAppMessage: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public var button: String?
    public var link: String?
    public var button2: String?
    public var link2: String?
    public var tone: String?
    public var image: String?
    public var imageAlt: String?
    public var style: String?
    public var place: String?
    public var until: String?
    public var audience: String?

    public var isSheet: Bool { style == "sheet" }
    public var styleName: String { isSheet ? "sheet" : "card" }

    /// The message in a Remote Config value, or nil for empty or malformed JSON.
    public static func decode(_ text: String) -> InAppMessage? {
        guard !text.isEmpty, let m = try? JSONDecoder().decode(InAppMessage.self, from: Data(text.utf8)), !m.title.isEmpty else { return nil }
        return m
    }

    /// Whether to show it now: not closed, within its dates, and for this kind of build.
    public func isShowable(dismissed: Set<String>, devBuild: Bool, now: Date = .now) -> Bool {
        if dismissed.contains(id) { return false }
        if audience == "dev" && !devBuild { return false }
        if let until, let last = Self.day.date(from: until), Calendar.current.startOfDay(for: now) > last { return false }
        return true
    }

    /// Whether a card belongs on `place`. Cards with no place go on the app's main screen.
    public func belongs(on place: String, main: String) -> Bool {
        guard !isSheet else { return false }
        let mine = place.isEmpty ? main : place
        let theirs = self.place.flatMap { $0.isEmpty ? nil : $0 } ?? main
        return theirs == mine
    }

    var toneLabel: (text: String, tone: Palette.Tone, symbol: String)? {
        switch tone?.lowercased() {
        case "tip": ("Tip", .good, "lightbulb")
        case "new": ("New", .info, "sparkles")
        case "heads-up", "headsup", "warning": ("Heads up", .warn, "exclamationmark.circle")
        default: nil
        }
    }

    var imageURL: URL? { image.flatMap(URL.init(string:)).flatMap { $0.scheme == "https" ? $0 : nil } }

    private static let day: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

/// What a person did with a message, so the app can act and count it.
public enum InAppMessageAction: Sendable {
    /// Tapped a button; open this link (the app decides how).
    case open(String)
    case close
}

/// The card: a small panel at the top of a screen.
public struct InAppMessageCard: View {
    let message: InAppMessage
    let act: (InAppMessageAction) -> Void

    public init(_ message: InAppMessage, act: @escaping (InAppMessageAction) -> Void) {
        self.message = message
        self.act = act
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            MessageImage(message: message, height: 120)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    ToneLabel(message: message)
                    Text(message.title).font(.app(17, .bold, relativeTo: .headline)).foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: Space.s)
                Button { act(.close) } label: {
                    Image(systemName: "xmark").font(.app(13, .bold)).foregroundStyle(Palette.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .padding(.trailing, -12).padding(.vertical, -12)
                .accessibilityLabel("Close")
            }
            Text(message.body).font(.app(15)).foregroundStyle(Palette.body).fixedSize(horizontal: false, vertical: true)
            MessageButtons(message: message, prominent: false, act: act).padding(.top, 2)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        .overlay(RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.line))
    }
}

/// The sheet's content: bigger, with the buttons stacked at the bottom.
public struct InAppMessageSheet: View {
    let message: InAppMessage
    let act: (InAppMessageAction) -> Void

    public init(_ message: InAppMessage, act: @escaping (InAppMessageAction) -> Void) {
        self.message = message
        self.act = act
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                if message.imageURL != nil {
                    MessageImage(message: message, height: 180)
                } else {
                    Buddy(.jar, mood: .happy, size: 64, hop: 1).hiddenWhenTextIsLarge()
                }
                VStack(alignment: .leading, spacing: Space.s) {
                    ToneLabel(message: message)
                    Text(message.title).font(.app(26, .heavy, relativeTo: .title)).foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                Text(message.body).font(.app(17)).foregroundStyle(Palette.body).fixedSize(horizontal: false, vertical: true)
            }
            .padding(Space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Space.s) {
                MessageButtons(message: message, prominent: true, act: act)
                Button { act(.close) } label: {
                    Text(message.link == nil ? "OK" : "Not now").font(.app(16, .semibold)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain).foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, Space.xl).padding(.bottom, Space.l)
        }
        .background(Palette.ground)
        .presentationDetents([.medium, .large])
    }
}

private struct ToneLabel: View {
    let message: InAppMessage
    var body: some View {
        if let label = message.toneLabel {
            Label(label.text.uppercased(), systemImage: label.symbol)
                .font(.app(11, .bold, relativeTo: .caption2)).tracking(0.6)
                .foregroundStyle(Palette.text(label.tone))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Palette.fill(label.tone), in: Capsule())
        }
    }
}

private struct MessageImage: View {
    let message: InAppMessage
    let height: CGFloat
    var body: some View {
        if let url = message.imageURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Palette.raised
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            .accessibilityHidden(message.imageAlt == nil)
            .accessibilityLabel(message.imageAlt ?? "")
        }
    }
}

private struct MessageButtons: View {
    let message: InAppMessage
    let prominent: Bool
    let act: (InAppMessageAction) -> Void

    var body: some View {
        let first = message.button.flatMap { b in message.link.map { (title: b, link: $0) } }
        let second = message.button2.flatMap { b in message.link2.map { (title: b, link: $0) } }
        if first != nil || second != nil {
            AdaptiveStack(spacing: Space.s) {
                if let first {
                    Button { act(.open(first.link)) } label: {
                        Text(first.title).font(.app(prominent ? 17 : 15, .bold)).padding(.horizontal, 6)
                            .frame(maxWidth: prominent ? .infinity : nil, minHeight: prominent ? 50 : 36)
                    }
                    .buttonStyle(.borderedProminent).tint(Palette.accent)
                    .buttonBorderShape(prominent ? .roundedRectangle(radius: Radius.medium) : .capsule)
                }
                if let second {
                    Button { act(.open(second.link)) } label: {
                        Text(second.title).font(.app(prominent ? 17 : 15, .semibold)).padding(.horizontal, 6)
                            .frame(maxWidth: prominent ? .infinity : nil, minHeight: prominent ? 50 : 36)
                    }
                    .buttonStyle(.bordered).tint(Palette.ink)
                    .buttonBorderShape(prominent ? .roundedRectangle(radius: Radius.medium) : .capsule)
                }
            }
        }
    }
}
