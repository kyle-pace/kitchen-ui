import SwiftUI

/// A filter you can turn on and off: "Low 10", "Soups 4", "Favorites". At least 44 points tall,
/// reads as "Low, 10, selected" to VoiceOver.
public struct FilterChip: View {
    let title: String
    var count: Int?
    var systemImage: String?
    let isOn: Bool
    let action: () -> Void

    public init(_ title: String, count: Int? = nil, systemImage: String? = nil, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.count = count
        self.systemImage = systemImage
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
                Text(title)
                if let count { Text("\(count)").opacity(0.65) }
            }
            .font(.app(.subheadline, .semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(minHeight: 44)
            .foregroundStyle(isOn ? Palette.onAccent : Palette.ink)
            .background(isOn ? Palette.accent : Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? .clear : Palette.line))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A row of chips that scrolls sideways, and wraps onto lines at the accessibility text sizes.
public struct ChipRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var size
    var content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        if size.isAccessibilitySize {
            FlowLayout(spacing: Space.s) { content }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Space.s) { content }.padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }
}

/// A shape and a label for a state ("● Have", "◐ Low"). Never color alone.
public struct Badge<Mark: View>: View {
    let title: String
    let tone: Palette.Tone
    var compact: Bool
    let mark: Mark

    public init(_ title: String, tone: Palette.Tone, compact: Bool = false, @ViewBuilder mark: () -> Mark) {
        self.title = title
        self.tone = tone
        self.compact = compact
        self.mark = mark()
    }

    public var body: some View {
        HStack(spacing: compact ? 5 : 6) {
            mark
            Text(title).font(.app(compact ? 13 : 14, .semibold, relativeTo: .subheadline))
        }
        .foregroundStyle(Palette.text(tone))
        .padding(.leading, compact ? 8 : 11).padding(.trailing, compact ? 10 : 14)
        .padding(.vertical, 4)
        .frame(minHeight: compact ? 28 : 36)
        .background(Palette.fill(tone), in: Capsule())
        .fixedSize()
    }
}

/// A surface for a group of content outside a List.
public struct Card<Content: View>: View {
    var padding: CGFloat
    var content: Content

    public init(padding: CGFloat = Space.l, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .overlay(RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.line.opacity(0.7)))
    }
}

/// An uppercase section header with an optional count: "FRIDGE · 91".
public struct SectionHeader: View {
    let text: String
    var trailing: String?

    public init(_ text: String, trailing: String? = nil) {
        self.text = text
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased()).font(.app(13, .bold, relativeTo: .caption)).tracking(0.8)
            Spacer()
            if let trailing { Text(trailing).font(.app(13, relativeTo: .caption)) }
        }
        .foregroundStyle(Palette.muted)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Wraps its children onto as many lines as they need, like words in a paragraph.
public struct FlowLayout: Layout {
    var spacing: CGFloat

    public init(spacing: CGFloat = Space.s) { self.spacing = spacing }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(proposal.width ?? .infinity, subviews)
        let height = rows.map { $0.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +)
        return CGSize(width: proposal.width ?? 0, height: height + spacing * CGFloat(max(rows.count - 1, 0)))
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(bounds.width, subviews) {
            var x = bounds.minX
            let height = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            for i in row {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += height + spacing
        }
    }

    private func rows(_ width: CGFloat, _ subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var x: CGFloat = 0
        for i in subviews.indices {
            let w = min(subviews[i].sizeThatFits(.unspecified).width, width)
            if x + w > width, !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(i)
            x += w + spacing
        }
        return rows
    }
}

extension View {
    /// Fills a box of this size and crops to it, without pushing the layout wider. (A
    /// `.scaledToFill()` image on its own takes the photo's width and breaks grids and rows.)
    public func fillFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : width)
            .overlay { self }
            .clipped()
    }
}
