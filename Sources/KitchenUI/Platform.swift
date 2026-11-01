import SwiftUI

// iPhone modifiers with no Mac version, so screens don't need an #if each time. On the Mac they
// do nothing.
extension View {
    /// The title in the bar, not the large one above the content.
    public func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// For links, codes and amounts: no capital at the start of the field.
    public func plainTextEntry() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never).autocorrectionDisabled()
        #else
        autocorrectionDisabled()
        #endif
    }

    public func linkKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.URL)
        #else
        self
        #endif
    }

    public func numberKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }
}

extension ToolbarItemPlacement {
    /// Top right on iPhone, the window's toolbar on the Mac.
    public static var trailingBar: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }

    /// Top left on iPhone; on the Mac the window's toolbar puts it at the leading end.
    public static var leadingBar: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .navigation
        #endif
    }
}
