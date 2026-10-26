import SwiftUI

/// Light or dark, and text size, chosen in the app. Both follow the iPhone unless someone picks
/// otherwise. Apply `.kitchenAppearance()` once at the root (sheets inherit it) and put
/// `AppearanceSettings()` in a Settings section.
public enum AppearanceChoice: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "Match iPhone"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppearanceKeys {
    static let appearance = "kitchen.appearance"
    /// 0 follows the iPhone; 1 and up are `DynamicTypeSize.allCases[n - 1]`.
    static let textSize = "kitchen.textSize"
}

extension DynamicTypeSize {
    /// "Large (default)", "Accessibility 3".
    public var title: String {
        switch self {
        case .xSmall: "Extra small"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large (default)"
        case .xLarge: "Extra large"
        case .xxLarge: "Extra extra large"
        case .xxxLarge: "Extra extra extra large"
        case .accessibility1: "Accessibility 1"
        case .accessibility2: "Accessibility 2"
        case .accessibility3: "Accessibility 3"
        case .accessibility4: "Accessibility 4"
        case .accessibility5: "Accessibility 5"
        @unknown default: "Custom"
        }
    }
}

extension View {
    /// Applies the appearance and text size chosen in Settings. Use once, at the root view.
    public func kitchenAppearance() -> some View { modifier(KitchenAppearance()) }
}

private struct KitchenAppearance: ViewModifier {
    @AppStorage(AppearanceKeys.appearance) private var appearance = AppearanceChoice.system
    @AppStorage(AppearanceKeys.textSize) private var textSize = 0

    func body(content: Content) -> some View {
        let sizes = DynamicTypeSize.allCases
        // A range rather than an if/else, so changing the setting never rebuilds the screens.
        let range = textSize > 0 && textSize <= sizes.count
            ? sizes[textSize - 1]...sizes[textSize - 1]
            : sizes.first!...sizes.last!
        content
            .preferredColorScheme(appearance.colorScheme)
            .dynamicTypeSize(range)
    }
}

/// The rows for a Settings section: Appearance, and text size that follows the iPhone or is set
/// here. Wrap it in the app's own `Section` and header.
public struct AppearanceSettings: View {
    @AppStorage(AppearanceKeys.appearance) private var appearance = AppearanceChoice.system
    @AppStorage(AppearanceKeys.textSize) private var textSize = 0
    @Environment(\.dynamicTypeSize) private var current

    public init() {}

    private let sizes = DynamicTypeSize.allCases

    public var body: some View {
        Picker(selection: $appearance) {
            ForEach(AppearanceChoice.allCases) { Text($0.title).tag($0) }
        } label: {
            Label("Appearance", systemImage: "circle.lefthalf.filled")
        }
        .font(.app(.body))

        Toggle(isOn: Binding(
            get: { textSize == 0 },
            set: { follow in
                // Start from the size in use now, so turning this off changes nothing yet.
                textSize = follow ? 0 : (sizes.firstIndex(of: current) ?? sizes.firstIndex(of: .large)!) + 1
            })) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Match iPhone text size").font(.app(.body))
                    Text("Turn off to choose a size just for this app.").font(.app(.footnote)).foregroundStyle(Palette.muted)
                }
            } icon: {
                Image(systemName: "textformat.size")
            }
        }
        .frame(minHeight: 44)

        if textSize > 0 {
            VStack(alignment: .leading, spacing: Space.s) {
                Slider(value: Binding(get: { Double(textSize) }, set: { textSize = Int($0.rounded()) }),
                       in: 1...Double(sizes.count), step: 1) {
                    Text("Text size")
                } minimumValueLabel: {
                    Image(systemName: "textformat.size.smaller").accessibilityHidden(true)
                } maximumValueLabel: {
                    Image(systemName: "textformat.size.larger").accessibilityHidden(true)
                }
                .accessibilityValue(sizes[textSize - 1].title)
                Text(sizes[textSize - 1].title).font(.app(.footnote)).foregroundStyle(Palette.muted)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
        }
    }
}
