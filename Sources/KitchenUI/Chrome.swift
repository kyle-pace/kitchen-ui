import SwiftUI

extension View {
    /// Filter chips pinned under the navigation bar, with the soft Liquid Glass scroll edge
    /// so content fades under them. Use KitchenUI's `FilterChip`s inside.
    ///
    /// Built on `safeAreaBar`, not `safeAreaInset`: with an inset the scroll edge effect stops
    /// at the navigation bar, so rows showed through under the chips and the inline title
    /// (seen in Deals on the phone, Oct 28).
    public func pinnedChips<Chips: View>(@ViewBuilder _ chips: () -> Chips) -> some View {
        modifier(PinnedChips(chips: chips()))
    }
}

private struct PinnedChips<Chips: View>: ViewModifier {
    let chips: Chips
    func body(content: Content) -> some View {
        content
            .safeAreaBar(edge: .top, spacing: 0) {
                ChipRow { chips }
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.xs)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

/// The slim "Shopping list · 6 of 14" bar for `.tabViewBottomAccessory`. Tap to open the list.
/// The count ticks over with each change.
public struct ListProgressBar: View {
    let title: String
    let done: Int
    let total: Int
    let open: () -> Void
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    public init(_ title: String = "Shopping list", done: Int, total: Int, open: @escaping () -> Void) {
        self.title = title
        self.done = done
        self.total = total
        self.open = open
    }

    public var body: some View {
        Button(action: open) {
            HStack(spacing: Space.s) {
                Image(systemName: done == total && total > 0 ? "checkmark.circle.fill" : "checklist")
                    .foregroundStyle(Palette.accent)
                    .contentTransition(.symbolEffect(.replace))
                if placement != .inline {
                    Text(title).font(.app(.subheadline, .semibold)).foregroundStyle(Palette.ink)
                }
                Spacer(minLength: Space.s)
                Text(done == 0 ? "\(total) to get" : "\(done) of \(total)")
                    .font(.app(.subheadline, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: done)
                    .animation(.snappy, value: total)
            }
            .padding(.horizontal, Space.l)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(done) of \(total) done")
        .accessibilityHint("Opens the list")
    }
}
