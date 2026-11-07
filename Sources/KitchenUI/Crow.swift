import SwiftUI

/// Seattle Grocery Deals' crow: a round Seattle crow with a little tuft, who remembers where the
/// good stuff is. Drawn from the same shapes as the app icon and the website (scripts/buddy.mjs
/// in seattle-grocery-deals), on a 200-point grid like Henwood's hen, so the two read as
/// siblings. It acts out `Buddy.Mood` itself (bob, blink, tuft sway, a head tilt while thinking)
/// and freezes on its resting pose with Reduce Motion.
///
/// Tap him and he hops and flaps. Five taps in a row and he drops a shiny coin, the way real
/// crows leave gifts. Taps do nothing with Reduce Motion or when `interactive` is off (the mark).
public struct CrowBuddy: View {
    let mood: Buddy.Mood
    let size: CGFloat
    let animate: Bool
    let interactive: Bool

    @State private var tappedAt: Date?
    @State private var recentTaps: [Date] = []
    @State private var coinAt: Date?

    public init(mood: Buddy.Mood = .neutral, size: CGFloat = 96, animate: Bool = true, interactive: Bool = true) {
        self.mood = mood
        self.size = size
        self.animate = animate
        self.interactive = interactive
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animate)) { timeline in
            let now = timeline.date
            let time = animate ? now.timeIntervalSinceReferenceDate : 0
            let tap = tappedAt.map { now.timeIntervalSince($0) }.flatMap { $0 < 1.0 ? $0 : nil }
            let coin = coinAt.map { now.timeIntervalSince($0) }.flatMap { $0 < 4.5 ? $0 : nil }
            Canvas { ctx, canvas in
                CrowArt.draw(in: ctx, size: canvas, mood: mood, time: time, tap: tap, coin: coin,
                             frame: interactive && animate ? CrowArt.roomy : CrowArt.frame)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive && animate else { return }
            let now = Date()
            tappedAt = now
            recentTaps = recentTaps.filter { now.timeIntervalSince($0) < 2.5 } + [now]
            if recentTaps.count >= 5 {
                coinAt = now
                recentTaps = []
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tappedAt)
        .sensoryFeedback(.success, trigger: coinAt)
        .accessibilityHidden(true)
    }
}

/// The "Puget evening" crow. The dark-mode feathers are a step lighter so he still reads on the
/// harbor-blue ground; the eye stays white in both.
enum CrowColors {
    static let body = Color(light: 0x23272E, dark: 0x38444F)
    static let sheen = Color(light: 0x3A4250, dark: 0x4D5D72)
    static let wing = Color(light: 0x303846, dark: 0x445162)
    static let beak = Color(light: 0x5A6270, dark: 0xA3AFBD)
    static let pupil = Color(hex: 0x111418)
    static let blush = Color(hex: 0xF29A9A)
    /// The icon's background.
    static let evening = Color(hex: 0x345A78)
    static let coin = Color(hex: 0xF2C14E)
    static let coinEdge = Color(hex: 0xB8862A)
}

enum CrowArt {
    // The crow sits in x 6...192, y 34...188 of a 200 grid; this square frames him.
    static let frame = CGRect(x: 4, y: 14, width: 190, height: 190)
    /// The same crow with room above him for a hop, so nothing gets cut off. Used whenever he
    /// can be tapped.
    static let roomy = CGRect(x: -8, y: -12, width: 214, height: 214)

    static func draw(in context: GraphicsContext, size: CGSize, mood: Buddy.Mood, time t: Double,
                     tap: Double? = nil, coin: Double? = nil, frame: CGRect = CrowArt.frame) {
        let s = min(size.width, size.height) / frame.width
        var c = context
        c.translateBy(x: (size.width - frame.width * s) / 2, y: (size.height - frame.height * s) / 2)
        c.scaleBy(x: s, y: s)
        c.translateBy(x: -frame.minX, y: -frame.minY)

        // A tap: a hop with a squash on landing and a flap.
        let tapped = tap.map { $0 < 0.8 } ?? false
        if let r = tap, r < 0.6 {
            c.translateBy(x: 0, y: -24 * sin(.pi * r / 0.6))
        } else if let r = tap, r < 0.8 {
            let squash = 1 - 0.08 * sin(.pi * (r - 0.6) / 0.2)
            c.translateBy(x: 100, y: 186); c.scaleBy(x: 2 - squash, y: squash); c.translateBy(x: -100, y: -186)
        }
        let mood = tapped ? .happy : mood
        if let age = coin { drawCoin(in: c, age: age) }

        // Feet stay planted while the rest moves.
        var feet = Path()
        for x in [88.0, 117.0] {
            feet.move(to: CGPoint(x: x, y: 172)); feet.addLine(to: CGPoint(x: x, y: 184))
            feet.move(to: CGPoint(x: x - 7, y: 186)); feet.addLine(to: CGPoint(x: x + 7, y: 186))
        }
        c.stroke(feet, with: .color(CrowColors.beak), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))

        let wave = { (period: Double) in sin(t * 2 * .pi / period) }

        // The whole bird: a bob, or a slow head tilt while thinking (crows are curious).
        var bob = 0.0, tilt = 0.0
        switch mood {
        case .neutral: bob = -3 * (wave(2.6) + 1) / 2
        case .happy: bob = -4 * abs(wave(1.4))
        case .thinking: tilt = 5 * wave(2.2)
        case .sleepy: bob = 1.5 * wave(4)
        case .sad: bob = 3
        case .surprised: bob = -2
        }
        var bird = c
        bird.translateBy(x: 0, y: bob)
        rotate(&bird, degrees: tilt, around: CGPoint(x: 100, y: 176))

        // Tail and beak sit behind the body.
        bird.fill(HenArt.path("M148 118 L190 132 L186 142 L192 150 L150 146 Z"), with: .color(CrowColors.wing))
        bird.fill(HenArt.path("M62 78 C42 76 22 84 10 100 C9 102 10 104 13 103 C28 100 46 100 64 102 Z"),
                  with: .color(CrowColors.beak))
        var beakLine = bird
        beakLine.opacity = 0.45
        beakLine.stroke(HenArt.path("M56 92 C42 93 28 96 14 101"), with: .color(CrowColors.body),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Body and belly.
        bird.fill(HenArt.path("M40 120 C40 78 70 56 102 56 C138 56 162 84 162 122 C162 156 136 176 100 176 C64 176 40 156 40 120 Z"),
                  with: .color(CrowColors.body))
        bird.fill(Path(ellipseIn: CGRect(x: 58, y: 114, width: 76, height: 56)), with: .color(CrowColors.sheen))

        // Wing: a flap on a tap, a little flutter when happy.
        var wing = bird
        if let r = tap, r < 0.8 {
            rotate(&wing, degrees: -24 * abs(sin(r * .pi * 7)), around: CGPoint(x: 122, y: 112))
        } else if mood == .happy {
            rotate(&wing, degrees: -8 * abs(wave(0.7)), around: CGPoint(x: 122, y: 112))
        }
        wing.fill(HenArt.path("M126 110 C150 110 160 132 150 152 C140 142 126 138 116 138 C114 124 118 112 126 110 Z"),
                  with: .color(CrowColors.wing))
        wing.stroke(HenArt.path("M130 118 C140 122 146 130 147 140"), with: .color(CrowColors.sheen),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // Tuft: sways on its base, droops when sleepy or sad, stands up when surprised.
        var tuft = bird
        let tuftAngle: Double = switch mood {
        case .neutral, .happy: 6 * wave(3.4)
        case .thinking: 9 * wave(1.1)
        case .sleepy: 14 + 2 * wave(4)
        case .sad: 18
        case .surprised: -8
        }
        rotate(&tuft, degrees: tuftAngle, around: CGPoint(x: 108, y: 60))
        if tapped || mood == .surprised {
            tuft.translateBy(x: 108, y: 60); tuft.scaleBy(x: 1.06, y: 1.18); tuft.translateBy(x: -108, y: -60)
        }
        tuft.fill(HenArt.path("M96 60 C94 46 102 38 114 40 C108 44 106 50 108 58 Z M110 58 C112 48 120 44 128 48 C122 50 119 54 120 60 Z"),
                  with: .color(CrowColors.body))

        // Face.
        drawEye(in: bird, mood: mood, time: t)
        var cheek = bird
        cheek.opacity = 0.55
        cheek.fill(Path(ellipseIn: CGRect(x: 73, y: 101, width: 14, height: 14)), with: .color(CrowColors.blush))
    }

    /// The eye carries the mood: open (with a blink), a happy squint, looking up, closed, low, wide.
    private static func drawEye(in c: GraphicsContext, mood: Buddy.Mood, time t: Double) {
        let lid = StrokeStyle(lineWidth: 4, lineCap: .round)
        switch mood {
        case .happy:
            var smile = Path()
            smile.move(to: CGPoint(x: 71, y: 86))
            smile.addQuadCurve(to: CGPoint(x: 89, y: 86), control: CGPoint(x: 80, y: 76))
            c.stroke(smile, with: .color(.white), style: lid)
            return
        case .sleepy:
            var closed = Path()
            closed.move(to: CGPoint(x: 71, y: 82))
            closed.addQuadCurve(to: CGPoint(x: 89, y: 82), control: CGPoint(x: 80, y: 88))
            c.stroke(closed, with: .color(.white), style: lid)
            return
        default:
            break
        }
        let (r, pupil, pr): (CGFloat, CGPoint, CGFloat) = switch mood {
        case .thinking: (10, CGPoint(x: 78, y: 79), 6)
        case .sad: (9, CGPoint(x: 77, y: 86), 5.5)
        case .surprised: (12, CGPoint(x: 79, y: 82), 4.5)
        default: (10, CGPoint(x: 77, y: 83), 6)
        }
        let blinks = mood == .neutral || mood == .thinking || mood == .surprised
        let phase = t.truncatingRemainder(dividingBy: 4.6)
        let open: CGFloat = blinks && phase > 4.38 && phase < 4.52 ? 0.12 : 1
        var eye = c
        eye.translateBy(x: 80, y: 82); eye.scaleBy(x: 1, y: open); eye.translateBy(x: -80, y: -82)
        eye.fill(Path(ellipseIn: CGRect(x: 80 - r, y: 82 - r, width: r * 2, height: r * 2)), with: .color(.white))
        eye.fill(Path(ellipseIn: CGRect(x: pupil.x - pr, y: pupil.y - pr, width: pr * 2, height: pr * 2)),
                 with: .color(CrowColors.pupil))
        if open == 1 {
            c.fill(Path(ellipseIn: CGRect(x: pupil.x + 0.3, y: pupil.y - 4.7, width: 4.4, height: 4.4)), with: .color(.white))
        }
    }

    /// The coin: rolls out from under him, wobbles, glints, then fades.
    private static func drawCoin(in context: GraphicsContext, age e: Double) {
        var c = context
        c.opacity = e > 3.6 ? max(0, 1 - (e - 3.6) / 0.9) : 1
        let x = 100 - 60 * min(e / 0.45, 1)
        c.translateBy(x: x, y: 178)
        if e < 1.6 { c.rotate(by: .degrees(14 * sin(e * 14) * (1 - e / 1.6))) }
        let face = Path(ellipseIn: CGRect(x: -15, y: -15, width: 30, height: 30))
        c.fill(face, with: .color(CrowColors.coin))
        c.stroke(face, with: .color(CrowColors.coinEdge), lineWidth: 3.5)
        var shine = Path()
        shine.move(to: CGPoint(x: -7, y: -7))
        shine.addQuadCurve(to: CGPoint(x: 2, y: -10.5), control: CGPoint(x: -4, y: -11))
        var lit = c
        lit.opacity *= 0.85
        lit.stroke(shine, with: .color(.white), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        guard e > 0.35 && e < 2.4 else { return }
        for (dx, dy, delay) in [(18.0, -22.0, 0.0), (-16.0, -18.0, 0.25), (20.0, 2.0, 0.5)] {
            let a = max(0, sin(.pi * min(max((e - 0.35 - delay) / 0.9, 0), 1)))
            guard a > 0 else { continue }
            var star = Path()
            let r = 6 * a
            star.move(to: CGPoint(x: dx, y: dy - r))
            star.addQuadCurve(to: CGPoint(x: dx + r, y: dy), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx, y: dy + r), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx - r, y: dy), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx, y: dy - r), control: CGPoint(x: dx, y: dy))
            c.fill(star, with: .color(CrowColors.coin))
        }
    }

    private static func rotate(_ c: inout GraphicsContext, degrees: Double, around p: CGPoint) {
        guard degrees != 0 else { return }
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(degrees))
        c.translateBy(x: -p.x, y: -p.y)
    }
}

/// The app icon in SwiftUI: the crow on evening blue, for the top of the app and anywhere the
/// icon shows.
public struct CrowMark: View {
    var size: CGFloat
    public init(size: CGFloat = 30) { self.size = size }
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous).fill(CrowColors.evening)
            CrowBuddy(mood: .neutral, size: size * 0.84, animate: false, interactive: false).offset(y: size * 0.01)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Crow") {
    VStack(spacing: 24) {
        HStack { ForEach([Buddy.Mood.neutral, .happy, .thinking], id: \.self) { CrowBuddy(mood: $0) } }
        HStack { ForEach([Buddy.Mood.sleepy, .sad, .surprised], id: \.self) { CrowBuddy(mood: $0) } }
        CrowMark(size: 60)
    }
    .padding()
}
