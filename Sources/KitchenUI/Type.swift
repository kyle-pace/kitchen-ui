import CoreText
import SwiftUI

public enum KitchenUI {
    /// Registers the bundled fonts. Call once at launch, before the first view.
    public static func registerFonts() {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else { return }
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }

    /// One static file per weight, named directly. (Asking a variable font for weights makes
    /// CoreText re-resolve it for every piece of text, which froze the app.)
    static func face(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "AtkinsonHyperlegibleNext-Light"
        case .medium: "AtkinsonHyperlegibleNext-Medium"
        case .semibold: "AtkinsonHyperlegibleNext-SemiBold"
        case .bold: "AtkinsonHyperlegibleNext-Bold"
        case .heavy, .black: "AtkinsonHyperlegibleNext-ExtraBold"
        default: "AtkinsonHyperlegibleNext-Regular"
        }
    }
}

extension Font {
    /// The app font at a text style's usual size, scaling with Dynamic Type.
    public static func app(_ style: Font.TextStyle, _ weight: Font.Weight? = nil) -> Font {
        let (size, defaultWeight) = metrics(style)
        return .custom(KitchenUI.face(weight ?? defaultWeight), size: size, relativeTo: style)
    }

    /// The app font at a specific size, scaling with Dynamic Type relative to `style`.
    public static func app(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(KitchenUI.face(weight), size: size, relativeTo: style)
    }

    /// Apple's sizes for each text style at the default text size.
    private static func metrics(_ style: Font.TextStyle) -> (CGFloat, Font.Weight) {
        switch style {
        case .largeTitle: (34, .bold)
        case .title: (28, .bold)
        case .title2: (22, .bold)
        case .title3: (20, .semibold)
        case .headline: (17, .semibold)
        case .subheadline: (15, .regular)
        case .callout: (16, .regular)
        case .footnote: (13, .regular)
        case .caption: (12, .regular)
        case .caption2: (11, .regular)
        default: (17, .regular)
        }
    }
}
