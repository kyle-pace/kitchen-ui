import SwiftUI
import UIKit

// The floating dev button: a small dot that stays above every screen, sheets and full-screen
// covers included, on Debug, development and TestFlight builds (never App Store builds).
// It rests as a see-through tab on the left edge. Tap it for the dev menu, drag it to either
// edge, long-press to hide it until the app reopens.
// The dev menu has a switch to turn it off for good.
//
//     RootView().devMenuButton { AppDevMenu().environment(store) }
//
// It lives in its own small window, so it floats over whatever the app is showing without
// taking touches anywhere else.

extension View {
    /// Adds the floating dev button for this scene. `menu` builds the app's dev menu; give it
    /// the environment it needs, since it's shown outside the app's view tree.
    public func devMenuButton<Menu: View>(@ViewBuilder menu: @escaping () -> Menu) -> some View {
        background(DevBubbleInstaller(menu: { AnyView(menu()) }))
    }
}

private struct DevBubbleInstaller: UIViewRepresentable {
    let menu: () -> AnyView

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.menu = menu
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: InstallerView, context: Context) {
        view.menu = menu
        DevBubble.shared.menu = menu
    }

    final class InstallerView: UIView {
        var menu: (() -> AnyView)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene, let menu else { return }
            DevBubble.shared.install(in: scene, menu: menu)
        }
    }
}

@MainActor
public final class DevBubble {
    public static let shared = DevBubble()
    private static let enabledKey = "kitchen.dev.bubble"
    // v2 keys (Oct 28): the dot moved from over the right-hand + buttons to a tab on the left
    // edge, so old saved spots start over.
    private static let sideKey = "kitchen.dev.bubbleSide.v2"     // "left" or "right"
    private static let heightKey = "kitchen.dev.bubbleY.v2"      // 0 at the top to 1 at the bottom
    private static let size: CGFloat = 40
    private static let margin: CGFloat = 8
    /// How much of the dot tucks past the screen edge, so it covers the side margin, not content.
    private static let tuck: CGFloat = 0.4

    /// The dev menu's "Floating button" switch. On unless turned off.
    public static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue { shared.hiddenThisLaunch = false; shared.show() } else { shared.hide() }
        }
    }

    var menu: (() -> AnyView)?
    private weak var scene: UIWindowScene?
    private var window: UIWindow?
    private var allowed = false
    private var hiddenThisLaunch = false
    private weak var presented: UIViewController?

    func install(in scene: UIWindowScene, menu: @escaping () -> AnyView) {
        self.menu = menu
        guard self.scene == nil else { return }
        self.scene = scene
        Task {
            allowed = await BuildKind.current().showsDevMenu
            show()
        }
    }

    private func show() {
        guard allowed, Self.isEnabled, !hiddenThisLaunch, window == nil, let scene else { return }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .normal + 1   // above the app's sheets and covers, below alerts
        window.backgroundColor = .clear
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        let bubble = BubbleView(frame: CGRect(x: 0, y: 0, width: Self.size, height: Self.size))
        bubble.onTap = { [weak self] in self?.openMenu() }
        bubble.onHide = { [weak self] in
            self?.hiddenThisLaunch = true
            self?.hide()
            Announce.say("Developer button hidden until the app opens again.")
        }
        bubble.onDrag = { [weak self] delta, state in self?.drag(delta, state) }
        controller.view.addSubview(bubble)
        window.rootViewController = controller
        window.frame = CGRect(origin: savedOrigin(), size: CGSize(width: Self.size, height: Self.size))
        window.alpha = Self.restingAlpha
        window.isHidden = false
        self.window = window
    }

    private func hide() {
        window?.isHidden = true
        window = nil
    }

    // MARK: dragging

    private var dragStart: CGPoint = .zero

    private func drag(_ delta: CGPoint, _ state: UIGestureRecognizer.State) {
        guard let window else { return }
        switch state {
        case .began:
            dragStart = window.frame.origin
            window.alpha = 1
        case .changed:
            window.frame.origin = CGPoint(x: dragStart.x + delta.x, y: dragStart.y + delta.y)
        default:
            let snapped = snap(window.frame.origin)
            UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.25) {
                window.frame.origin = snapped
                window.alpha = Self.restingAlpha
            }
        }
    }

    /// The area the dot may sit in: the screen minus the safe area and a margin.
    private var area: CGRect {
        guard let scene else { return .zero }
        let insets = scene.windows.first { $0.windowLevel == .normal }?.safeAreaInsets ?? .zero
        return scene.screen.bounds.inset(by: insets).insetBy(dx: Self.margin, dy: Self.margin)
    }

    private func snap(_ origin: CGPoint) -> CGPoint {
        let a = area
        let right = origin.x + Self.size / 2 > a.midX
        let y = min(max(origin.y, a.minY), a.maxY - Self.size)
        UserDefaults.standard.set(right ? "right" : "left", forKey: Self.sideKey)
        UserDefaults.standard.set(a.height > Self.size ? (y - a.minY) / (a.height - Self.size) : 0, forKey: Self.heightKey)
        return CGPoint(x: dockedX(right: right), y: y)
    }

    /// Tucked partly past the screen edge, like a tab, so it sits over the margin.
    private func dockedX(right: Bool) -> CGFloat {
        guard let scene else { return 0 }
        let screen = scene.screen.bounds
        return right ? screen.maxX - Self.size * (1 - Self.tuck) : screen.minX - Self.size * Self.tuck
    }

    /// See-through while resting so rows show through; solid while it's being moved.
    private static let restingAlpha: CGFloat = 0.6

    private func savedOrigin() -> CGPoint {
        let a = area
        // Default: the left edge, low, away from the + buttons on the right of every row.
        let right = (UserDefaults.standard.string(forKey: Self.sideKey) ?? "left") == "right"
        let fraction = UserDefaults.standard.object(forKey: Self.heightKey) as? Double ?? 0.78
        return CGPoint(x: dockedX(right: right), y: a.minY + (a.height - Self.size) * fraction)
    }

    // MARK: the menu

    private func openMenu() {
        guard presented?.presentingViewController == nil, let menu, let top = topController() else { return }
        let host = UIHostingController<AnyView>(rootView: AnyView(EmptyView()))
        host.rootView = AnyView(DevMenuSheet(content: menu()) { [weak host] in host?.dismiss(animated: true) })
        presented = host
        top.present(host, animated: true)
    }

    /// The app's frontmost screen: its main window's top presented controller.
    private func topController() -> UIViewController? {
        guard let scene else { return nil }
        let main = scene.windows.first { $0.isKeyWindow && $0 !== window } ?? scene.windows.first { $0.windowLevel == .normal }
        var top = main?.rootViewController
        while let next = top?.presentedViewController, !next.isBeingDismissed { top = next }
        return top
    }
}

private struct DevMenuSheet: View {
    let content: AnyView
    let close: () -> Void

    var body: some View {
        NavigationStack {
            content.toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", action: close) }
            }
        }
        .kitchenAppearance()
        .tint(Palette.accent)
    }
}

/// The dot itself: 40 points, ink with a hammer. The window around it is see-through at rest.
private final class BubbleView: UIView {
    var onTap: (() -> Void)?
    var onHide: (() -> Void)?
    var onDrag: ((CGPoint, UIGestureRecognizer.State) -> Void)?
    private var touchStart: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(Palette.ink).withAlphaComponent(0.82)
        layer.cornerRadius = frame.width / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let icon = UIImageView(image: UIImage(systemName: "hammer.fill",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        icon.tintColor = UIColor(Palette.ground)
        icon.contentMode = .center
        icon.frame = bounds
        icon.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(icon)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressed(_:)))
        press.minimumPressDuration = 0.6
        addGestureRecognizer(press)
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))

        isAccessibilityElement = true
        accessibilityLabel = "Developer menu"
        accessibilityTraits = .button
        accessibilityHint = "Opens the developer menu. Drag to move it."
        accessibilityCustomActions = [UIAccessibilityCustomAction(name: "Hide until the app opens again", target: self, selector: #selector(hideAction))]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func tapped() { onTap?() }

    @objc private func hideAction() -> Bool { onHide?(); return true }

    @objc private func pressed(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onHide?()
    }

    /// Measured in screen points, since the window moves along with the finger.
    @objc private func panned(_ g: UIPanGestureRecognizer) {
        guard let window else { return }
        let point = window.convert(g.location(in: window), to: window.screen.coordinateSpace)
        if g.state == .began { touchStart = point }
        onDrag?(CGPoint(x: point.x - touchStart.x, y: point.y - touchStart.y), g.state)
    }
}
