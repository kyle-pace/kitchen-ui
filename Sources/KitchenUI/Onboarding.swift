import SwiftUI

// First-run onboarding shared by the kitchen apps: a welcome, a short feature tour, and the
// one question nobody can skip, whether to share anonymous usage. Each app brings its own
// words, pages and Buddy; this file owns the layout, the skipping and the accessibility.
//
// Rules it keeps:
// - Everything except the usage question can be skipped, from every screen.
// - The question has two equal buttons, nothing chosen ahead of time, and says what is and
//   isn't shared. The app must not send anything until it has an answer.
// - No system permission prompts here. Apps ask for Reminders, notifications and the rest at
//   the moment someone uses that feature.
// - Readable at the largest text sizes (content scrolls, buttons stay at the bottom), 44-point
//   targets, VoiceOver lands on each new screen's title, Reduce Motion turns off the slides.

/// One card in the feature tour.
public struct TourPage: Identifiable, Sendable {
    public let id: String
    public let systemImage: String
    public let title: String
    public let message: String

    /// `id` is a short stable name ("list", "alerts") the app can use in its own analytics.
    public init(_ id: String, systemImage: String, title: String, message: String) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }
}

/// The words on the usage question.
public struct UsageQuestion: Sendable {
    public let title: String
    public let message: String
    /// Plain-language list of what goes to analytics.
    public let shared: [String]
    /// What never does. Put the things people worry about here.
    public let neverShared: [String]
    public let shareButton: String
    public let declineButton: String
    public let footnote: String

    public init(title: String, message: String, shared: [String], neverShared: [String],
                shareButton: String = "Share anonymous usage", declineButton: String = "Don't share",
                footnote: String = "You can change this anytime in Settings.") {
        self.title = title
        self.message = message
        self.shared = shared
        self.neverShared = neverShared
        self.shareButton = shareButton
        self.declineButton = declineButton
        self.footnote = footnote
    }
}

/// What happened, for the app to save and (once it may) log.
public struct OnboardingResult: Sendable {
    public enum Tour: String, Sendable { case finished, skipped, notShown }
    /// `nil` when the question wasn't asked (`.tourOnly`).
    public let shareUsage: Bool?
    public let tour: Tour
    /// How many tour pages were on screen at least once.
    public let pagesSeen: Int
}

public struct Onboarding: View {
    /// `.welcome` for a new install; `.question` for someone who already uses the app and only
    /// needs to answer; `.tourOnly` to replay the tour from Settings (no question at the end).
    public enum Start: Sendable { case welcome, question, tourOnly }

    private enum Step: Hashable { case welcome, tour, question }

    let buddy: Buddy.Kind
    let appName: String
    let tagline: String
    let pages: [TourPage]
    let question: UsageQuestion
    let start: Start
    let onFinish: (OnboardingResult) -> Void

    @State private var step: Step
    @State private var page = 0
    @State private var seen: Set<Int> = []
    @State private var tour: OnboardingResult.Tour = .notShown
    @State private var hop = 0
    @AccessibilityFocusState private var titleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize

    public init(buddy: Buddy.Kind, appName: String, tagline: String, pages: [TourPage],
                question: UsageQuestion, start: Start = .welcome,
                onFinish: @escaping (OnboardingResult) -> Void) {
        self.buddy = buddy
        self.appName = appName
        self.tagline = tagline
        self.pages = pages
        self.question = question
        self.start = start
        self.onFinish = onFinish
        let first: Step = switch start {
        case .welcome: .welcome
        case .question: .question
        case .tourOnly: .tour
        }
        _step = State(initialValue: first)
    }

    public var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()
            switch step {
            case .welcome: welcome.transition(slide)
            case .tour: tourView.transition(slide)
            case .question: questionView.transition(slide)
            }
        }
        .tint(Palette.accent)
        .interactiveDismissDisabled()
        .onChange(of: step) { focusTitle() }
        .onChange(of: page) { seen.insert(page); focusTitle() }
        .onAppear { if step == .tour { seen.insert(0) } }
    }

    // MARK: welcome

    private var welcome: some View {
        Screen {
            VStack(spacing: Space.xl) {
                Buddy(buddy, mood: .happy, size: textSize.isAccessibilitySize ? 88 : 132, hop: hop)
                    .padding(.top, Space.xl)
                    .task { try? await Task.sleep(for: .milliseconds(350)); hop += 1 }
                VStack(spacing: Space.m) {
                    Text("Welcome to \(appName)")
                        .font(.app(.largeTitle))
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titleFocused)
                    Text(tagline)
                        .font(.app(.title3, .regular))
                        .foregroundStyle(Palette.body)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Space.xl)
            .frame(maxWidth: .infinity)
        } buttons: {
            Button { go(.tour) } label: { wide("Take the tour", prominent: true) }
                .buttonStyle(.borderedProminent)
            Button { tour = .skipped; go(.question) } label: { wide("Skip the tour") }
                .buttonStyle(.bordered)
                .accessibilityHint("Goes straight to the last step")
        }
    }

    // MARK: tour

    private var tourView: some View {
        Screen(scrolls: false) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                    ScrollView {
                        TourCard(page: p, focused: $titleFocused, isCurrent: i == page)
                            .padding(.horizontal, Space.xl)
                            .padding(.vertical, Space.l)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .smooth, value: page)
        } top: {
            HStack {
                PageDots(count: pages.count, current: page)
                Spacer()
                Button("Skip") { skipTour() }
                    .font(.app(.body, .semibold))
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityHint(start == .tourOnly ? "Closes the tour" : "Goes straight to the last step")
            }
        } buttons: {
            AdaptiveStack(spacing: Space.m) {
                if page > 0 {
                    Button { page -= 1 } label: { wide("Back") }
                        .buttonStyle(.bordered)
                }
                Button { next() } label: { wide(isLastPage ? (start == .tourOnly ? "Done" : "Continue") : "Next", prominent: true) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var isLastPage: Bool { page >= pages.count - 1 }

    private func next() {
        if isLastPage {
            tour = .finished
            if start == .tourOnly { finish(nil) } else { go(.question) }
        } else {
            page += 1
        }
    }

    private func skipTour() {
        tour = .skipped
        if start == .tourOnly { finish(nil) } else { go(.question) }
    }

    // MARK: the usage question

    private var questionView: some View {
        Screen {
            VStack(alignment: .leading, spacing: Space.l) {
                HStack {
                    Spacer()
                    Buddy(buddy, mood: .neutral, size: textSize.isAccessibilitySize ? 64 : 88)
                    Spacer()
                }
                Text(question.title)
                    .font(.app(.title))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
                Text(question.message)
                    .font(.app(.body))
                    .foregroundStyle(Palette.body)
                Card {
                    VStack(alignment: .leading, spacing: Space.l) {
                        UsageList(title: "What's shared", systemImage: "checkmark.circle", tone: .good, items: question.shared)
                        Divider().overlay(Palette.divider)
                        UsageList(title: "Never shared", systemImage: "xmark.circle", tone: .bad, items: question.neverShared)
                    }
                }
                Text(question.footnote)
                    .font(.app(.footnote))
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.l)
        } buttons: {
            // Same style and size on purpose: neither answer is the "right" one.
            Button { finish(true) } label: { wide(question.shareButton) }
                .buttonStyle(.bordered)
            Button { finish(false) } label: { wide(question.declineButton) }
                .buttonStyle(.bordered)
        }
    }

    // MARK: helpers

    private var slide: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity))
    }

    private func go(_ next: Step) {
        if next == .tour { seen.insert(page) }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth) { step = next }
    }

    /// Moves VoiceOver to the new screen's title once it's on screen.
    private func focusTitle() {
        titleFocused = false
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            titleFocused = true
        }
    }

    private func finish(_ share: Bool?) {
        onFinish(OnboardingResult(shareUsage: share, tour: tour, pagesSeen: seen.count))
    }

    /// A full-width button label. `prominent` labels sit on the accent fill, so they take
    /// `onAccent`: white on the light-mode green, dark on the brighter dark-mode green.
    private func wide(_ title: String, prominent: Bool = false) -> some View {
        Text(title)
            .font(.app(.headline))
            .foregroundStyle(prominent ? AnyShapeStyle(Palette.onAccent) : AnyShapeStyle(.tint))
            .frame(maxWidth: .infinity, minHeight: 44)
    }
}

/// Content (centered when it fits, scrolling when it doesn't), an optional top row, and
/// buttons pinned to the bottom so they never scroll away at large text sizes.
private struct Screen<Content: View, Top: View, Buttons: View>: View {
    let scrolls: Bool
    let content: Content
    let top: Top
    let buttons: Buttons

    init(scrolls: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder top: () -> Top,
         @ViewBuilder buttons: () -> Buttons) {
        self.scrolls = scrolls
        self.content = content()
        self.top = top()
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: 0) {
            top.padding(.horizontal, Space.l).padding(.top, Space.s)
            if scrolls {
                ViewThatFits(in: .vertical) {
                    content.frame(maxHeight: .infinity)
                    ScrollView { content }.scrollBounceBehavior(.basedOnSize)
                }
            } else {
                content.frame(maxHeight: .infinity)
            }
            VStack(spacing: Space.m) { buttons }
                .controlSize(.large)
                .padding(.horizontal, Space.xl)
                .padding(.top, Space.m)
                .padding(.bottom, Space.l)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

extension Screen where Top == EmptyView {
    init(scrolls: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder buttons: () -> Buttons) {
        self.init(scrolls: scrolls, content: content, top: { EmptyView() }, buttons: buttons)
    }
}

/// One tour card: a big symbol, a title and a sentence or two.
private struct TourCard: View {
    let page: TourPage
    var focused: AccessibilityFocusState<Bool>.Binding
    let isCurrent: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        VStack(spacing: Space.xl) {
            Image(systemName: page.systemImage)
                .font(.system(size: textSize.isAccessibilitySize ? 44 : 64, weight: .regular))
                .foregroundStyle(Palette.accent)
                .frame(width: textSize.isAccessibilitySize ? 96 : 140, height: textSize.isAccessibilitySize ? 96 : 140)
                .background(Palette.fill(.good), in: Circle())
                .accessibilityHidden(true)
                .padding(.top, Space.xl)
            VStack(spacing: Space.m) {
                Text(page.title)
                    .font(.app(.title))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                    .modifier(FocusIf(active: isCurrent, focused: focused))
                Text(page.message)
                    .font(.app(.title3, .regular))
                    .foregroundStyle(Palette.body)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FocusIf: ViewModifier {
    let active: Bool
    var focused: AccessibilityFocusState<Bool>.Binding
    func body(content: Content) -> some View {
        if active { content.accessibilityFocused(focused) } else { content }
    }
}

/// "● ○ ○ ○", read as "Page 1 of 4".
private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Space.s) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Palette.accent : Palette.line)
                    .frame(width: i == current ? 20 : 8, height: 8)
            }
        }
        .animation(.smooth, value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

/// A heading with a symbol (never color alone) and a list of plain lines.
private struct UsageList: View {
    let title: String
    let systemImage: String
    let tone: Palette.Tone
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Label {
                Text(title).font(.app(.headline)).foregroundStyle(Palette.ink)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(Palette.mark(tone))
            }
            .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.app(.subheadline))
                    .foregroundStyle(Palette.body)
                    .padding(.leading, 30)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
