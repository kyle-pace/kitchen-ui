import StoreKit
import SwiftUI
import UIKit

// A developer menu shared by the kitchen apps: onboarding and analytics tools, build details,
// and a slot for each app's own sections. It appears as a "Developer" row in Settings on
// Debug, development-signed and TestFlight builds, never on App Store builds.
//
//     Form { …; DevMenuSection { DevMenu(onboarding: …, analytics: …) { app sections } } }

/// What kind of build this is, which decides whether the dev menu shows.
public enum BuildKind: String, Sendable {
    case debug = "Debug"
    case development = "Development (installed from Xcode or the script)"
    case testFlight = "TestFlight"
    case appStore = "App Store"

    public var showsDevMenu: Bool { self != .appStore }

    /// Debug from the compiler flag; development-signed builds carry a provisioning profile;
    /// TestFlight and App Store builds don't, and StoreKit tells those two apart.
    public static func current() async -> BuildKind {
        #if DEBUG
        return .debug
        #else
        if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil { return .development }
        if let result = try? await AppTransaction.shared {
            switch result {
            case .verified(let t), .unverified(let t, _):
                return t.environment == .production ? .appStore : .testFlight
            }
        }
        return .appStore // unknown: keep it hidden
        #endif
    }
}

/// The build kind, worked out once and observable, so a view can show or hide itself when the
/// answer arrives. (A `.task` on a view with nothing in it never runs.)
@MainActor @Observable
public final class BuildInfo {
    public static let shared = BuildInfo()
    public private(set) var kind: BuildKind?
    @ObservationIgnored private var started = false

    public func resolve() {
        guard !started else { return }
        started = true
        Task { kind = await BuildKind.current() }
    }
}

/// A Settings section with a "Developer" row, shown only on builds that allow it.
public struct DevMenuSection<Menu: View>: View {
    let menu: () -> Menu

    public init(@ViewBuilder menu: @escaping () -> Menu) { self.menu = menu }

    public var body: some View {
        let info = BuildInfo.shared
        let _ = info.resolve()
        if let kind = info.kind, kind.showsDevMenu {
            Section {
                NavigationLink { menu() } label: {
                    Label("Developer", systemImage: "hammer")
                }
            } footer: {
                Text("\(kind.rawValue) build. Not in the App Store version.")
            }
        }
    }
}

/// What the dev menu needs from the app's onboarding.
public struct DevOnboarding {
    /// Present onboarding from the start, or from the usage question.
    public let present: (Onboarding.Start) -> Void
    /// Forget the saved answer, so the next launch starts onboarding again.
    public let forget: () -> Void

    public init(present: @escaping (Onboarding.Start) -> Void, forget: @escaping () -> Void) {
        self.present = present
        self.forget = forget
    }
}

/// What the dev menu shows and does for the app's analytics.
public struct DevAnalytics {
    /// `nil` until asked.
    public let sharing: Bool?
    public let hasKey: Bool
    public let deviceID: String?
    public let flush: () -> Void

    public init(sharing: Bool?, hasKey: Bool, deviceID: String?, flush: @escaping () -> Void) {
        self.sharing = sharing
        self.hasKey = hasKey
        self.deviceID = deviceID
        self.flush = flush
    }
}

public struct DevMenu<AppSections: View>: View {
    let onboarding: DevOnboarding
    let analytics: () -> DevAnalytics
    /// Clears the app's own saved state (its UserDefaults keys and files). The menu adds the
    /// "quit and reopen" step.
    let resetAll: (() -> Void)?
    let appSections: AppSections

    @State private var info: DevAnalytics?
    @State private var note: String?
    @State private var confirmReset = false
    @State private var bubble = DevBubble.isEnabled

    public init(onboarding: DevOnboarding, analytics: @escaping () -> DevAnalytics,
                resetAll: (() -> Void)? = nil, @ViewBuilder appSections: () -> AppSections) {
        self.onboarding = onboarding
        self.analytics = analytics
        self.resetAll = resetAll
        self.appSections = appSections()
    }

    public var body: some View {
        Form {
            if let note {
                Section { Label(note, systemImage: "checkmark.circle").foregroundStyle(Palette.text(.good)) }
            }

            Section {
                Toggle("Floating button", isOn: $bubble)
                    .tint(Palette.accent)
                    .onChange(of: bubble) { _, on in DevBubble.isEnabled = on }
            } footer: {
                Text("The hammer dot on every screen. Drag it to either edge; long-press it to hide it until the app opens again.")
            }

            Section {
                Button("Show onboarding from the start") { onboarding.present(.welcome) }
                Button("Show the usage question") { onboarding.present(.question) }
                Button("Forget the usage answer") {
                    onboarding.forget()
                    refresh("Forgotten. Onboarding shows the next time the app opens.")
                }
            } header: { Text("Onboarding") } footer: {
                Text("Answering again from here saves the new answer.")
            }

            Section {
                let a = info ?? analytics()
                LabeledContent("Sharing", value: a.sharing.map { $0 ? "Yes" : "No" } ?? "Not asked")
                LabeledContent("API key", value: a.hasKey ? "Set" : "Missing")
                if let id = a.deviceID {
                    Button { copy(id, "Device ID copied.") } label: {
                        LabeledContent("Device ID") { Text(id).lineLimit(1).truncationMode(.middle) }
                    }
                    .accessibilityHint("Copies it")
                }
                Button("Send queued events now") { a.flush(); refresh("Sent anything that was waiting.") }
                    .disabled(a.deviceID == nil)
            } header: { Text("Analytics") } footer: {
                Text("Paste the device ID into Amplitude's User Lookup to watch events arrive.")
            }

            appSections

            Section {
                LabeledContent("Version", value: Self.version)
                LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "")
                LabeledContent("Build type", value: build?.rawValue ?? "…")
                LabeledContent("iOS", value: UIDevice.current.systemVersion)
                Button("Copy these details") { copy(details, "Details copied.") }
            } header: { Text("This build") }

            if resetAll != nil {
                Section {
                    Button("Reset everything", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Clears this app's saved settings and data on this iPhone, like a new install. Quit and reopen the app afterward.")
                }
            }
        }
        .font(.app(.body))
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset everything?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                resetAll?()
                refresh("Reset. Quit and reopen the app.")
            }
        } message: {
            Text("This app's settings and data on this iPhone are cleared. Reminders lists and calendars aren't touched.")
        }
    }

    private var build: BuildKind? { BuildInfo.shared.kind }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }

    private var details: String {
        let a = info ?? analytics()
        return [
            "\(Bundle.main.bundleIdentifier ?? "") \(Self.version)",
            "Build: \(build?.rawValue ?? "unknown")",
            "iOS \(UIDevice.current.systemVersion), \(UIDevice.current.model)",
            "Analytics: \(a.sharing.map { $0 ? "sharing" : "not sharing" } ?? "not asked"), key \(a.hasKey ? "set" : "missing")",
            "Device ID: \(a.deviceID ?? "none")",
        ].joined(separator: "\n")
    }

    private func copy(_ text: String, _ message: String) {
        UIPasteboard.general.string = text
        refresh(message)
    }

    private func refresh(_ message: String) {
        info = analytics()
        note = message
        Announce.say(message)
    }
}

/// A row for an app's dev section: a button with a short line under it saying what it does.
public struct DevAction: View {
    let title: String
    let detail: String?
    let role: ButtonRole?
    let action: () -> Void

    public init(_ title: String, detail: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail).font(.app(.footnote)).foregroundStyle(Palette.muted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
    }
}
