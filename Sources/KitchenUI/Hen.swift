import SwiftUI

/// Henwood's hen: a round woodland hen with a maitake crest (hen of the woods). Drawn from the
/// same shapes as the app icon, on a 200-point grid, so it stays sharp at any size. It acts out
/// `Buddy.Mood` itself (bob, blink, crest sway, a peck while thinking) instead of wearing
/// `BuddyFace`, and freezes on its resting pose with Reduce Motion.
///
/// Tap her and she hops, flaps and loses a few feathers. Five taps in a row and she lays a golden
/// egg. Taps do nothing with Reduce Motion or when `interactive` is off (the toolbar mark).
public struct HenBuddy: View {
    let mood: Buddy.Mood
    let size: CGFloat
    let animate: Bool
    let interactive: Bool

    @State private var tappedAt: Date?
    @State private var recentTaps: [Date] = []
    @State private var eggAt: Date?

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
            let tap = tappedAt.map { now.timeIntervalSince($0) }.flatMap { $0 < 1.4 ? $0 : nil }
            let egg = eggAt.map { now.timeIntervalSince($0) }.flatMap { $0 < 4.5 ? $0 : nil }
            Canvas { ctx, canvas in
                HenArt.draw(in: ctx, size: canvas, mood: mood, time: time, tap: tap, egg: egg,
                            frame: interactive && animate ? HenArt.roomy : HenArt.frame)
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
                eggAt = now
                recentTaps = []
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tappedAt)
        .sensoryFeedback(.success, trigger: eggAt)
        .accessibilityHidden(true)
    }
}

enum HenColors {
    static let feather = Color(light: 0xC98B4E, dark: 0xD39A5E)
    static let belly = Color(light: 0xE8C79A, dark: 0xE8C79A)
    static let wing = Color(light: 0xA86F3A, dark: 0xB57B44)
    static let crest = Color(light: 0xB89878, dark: 0xC4A684)
    static let gills = Color(light: 0x8A6A4F, dark: 0x8A6A4F)
    static let yolk = Color(light: 0xE8A93B, dark: 0xF0B54A)
    static let eye = Color(light: 0x2A211B, dark: 0x1B1512)
    static let blush = Color(light: 0xE59A7A, dark: 0xE59A7A)
    /// The icon's background.
    static let moss = Color(light: 0x4F6B3A, dark: 0x4F6B3A)
    static let gold = Color(light: 0xF3CF6E, dark: 0xF6D47A)
    static let goldEdge = Color(light: 0xC9922E, dark: 0xD9A23C)
}

enum HenArt {
    // The hen sits in x 40...162, y 12...188 of a 200 grid; this square frames it.
    static let frame = CGRect(x: 12, y: 12, width: 178, height: 178)
    /// The same hen with room above her for a hop and a puffed crest, so nothing gets cut off
    /// at the top of her frame. Used whenever she can be tapped.
    static let roomy = CGRect(x: -6, y: -26, width: 214, height: 214)

    static func draw(in context: GraphicsContext, size: CGSize, mood: Buddy.Mood, time t: Double,
                     tap: Double? = nil, egg: Double? = nil, frame: CGRect = HenArt.frame) {
        let s = min(size.width, size.height) / frame.width
        var c = context
        c.translateBy(x: (size.width - frame.width * s) / 2, y: (size.height - frame.height * s) / 2)
        c.scaleBy(x: s, y: s)
        c.translateBy(x: -frame.minX, y: -frame.minY)

        // A tap: a hop with a squash on landing, a flap and a puffed crest.
        let tapped = tap.map { $0 < 0.8 } ?? false
        if let r = tap, r < 0.6 {
            c.translateBy(x: 0, y: -24 * sin(.pi * r / 0.6))
        } else if let r = tap, r < 0.8 {
            let squash = 1 - 0.08 * sin(.pi * (r - 0.6) / 0.2)
            c.translateBy(x: 100, y: 188); c.scaleBy(x: 2 - squash, y: squash); c.translateBy(x: -100, y: -188)
        }
        let mood = tapped ? .happy : mood
        if let e = egg { drawEgg(in: c, age: e) }

        // Feet stay planted while the rest moves.
        var feet = Path()
        for x in [86.0, 116.0] {
            feet.move(to: CGPoint(x: x, y: 174)); feet.addLine(to: CGPoint(x: x, y: 184))
            feet.move(to: CGPoint(x: x - 6, y: 186)); feet.addLine(to: CGPoint(x: x + 6, y: 186))
        }
        c.stroke(feet, with: .color(HenColors.yolk), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        let wave = { (period: Double) in sin(t * 2 * .pi / period) }

        // The whole bird: a bob, or a peck forward while thinking.
        var bob = 0.0, tilt = 0.0
        switch mood {
        case .neutral: bob = -3 * (wave(2.4) + 1) / 2
        case .happy: bob = -4 * abs(wave(1.4))
        case .thinking:
            let p = t.truncatingRemainder(dividingBy: 1.8)
            for start in [0.0, 0.32] where p >= start && p < start + 0.18 {
                tilt = -12 * sin((p - start) / 0.18 * .pi)
            }
        case .sleepy: bob = 1.5 * wave(4)
        case .sad: bob = 2
        case .surprised: bob = -2
        }
        var bird = c
        bird.translateBy(x: 0, y: bob)
        rotate(&bird, degrees: tilt, around: CGPoint(x: 64, y: 176))

        // Crest: sways on its base, droops when sleepy or sad, stands up when surprised.
        var crest = bird
        let crestAngle: Double = switch mood {
        case .neutral, .happy: 5 * wave(3.2)
        case .thinking: 8 * wave(1.0)
        case .sleepy: 12 + 2 * wave(4)
        case .sad: 16
        case .surprised: 0
        }
        rotate(&crest, degrees: crestAngle, around: CGPoint(x: 100, y: 64))
        if tapped {
            crest.translateBy(x: 100, y: 64); crest.scaleBy(x: 1.08, y: 1.2); crest.translateBy(x: -100, y: -64)
        } else if mood == .surprised {
            crest.translateBy(x: 100, y: 64); crest.scaleBy(x: 1.06, y: 1.14); crest.translateBy(x: -100, y: -64)
        }
        crest.fill(path("M70 62 C58 40 66 22 84 26 C86 14 104 12 108 26 C120 16 138 26 130 44 C142 46 140 64 126 66 Z"),
                   with: .color(HenColors.crest))
        crest.stroke(path("M74 60 C66 44 72 32 86 34 M96 58 C94 40 100 28 108 30 M114 60 C118 46 126 40 132 46"),
                     with: .color(HenColors.gills), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // Body and belly.
        bird.fill(path("M40 120 C40 78 70 56 102 56 C138 56 162 84 162 122 C162 156 136 176 100 176 C64 176 40 156 40 120 Z"),
                  with: .color(HenColors.feather))
        bird.fill(Path(ellipseIn: CGRect(x: 64, y: 106, width: 80, height: 64)), with: .color(HenColors.belly))

        // Wing: a little flap when happy.
        var wing = bird
        if let r = tap, r < 0.8 {
            rotate(&wing, degrees: -28 * abs(sin(r * .pi * 7)), around: CGPoint(x: 124, y: 116))
        } else if mood == .happy {
            rotate(&wing, degrees: -10 * abs(wave(0.7)), around: CGPoint(x: 124, y: 116))
        }
        wing.fill(path("M128 112 C150 112 158 134 146 150 C138 140 126 136 118 136 C116 124 120 114 128 112 Z"),
                  with: .color(HenColors.wing))

        // Face.
        bird.fill(Path(ellipseIn: CGRect(x: 67, y: 103, width: 14, height: 14)), with: .color(HenColors.blush.opacity(0.55)))
        bird.fill(path("M52 98 L32 106 L52 114 Z"), with: .color(HenColors.yolk))
        drawEye(in: bird, mood: mood, time: t)

        // A few feathers float off and fade.
        if let r = tap {
            let feathers: [(dx: Double, dy: Double, spin: Double, color: Color)] = [
                (-70, -110, 200, HenColors.crest), (80, -95, -260, HenColors.feather),
                (-35, -135, 320, HenColors.feather), (45, -125, -180, HenColors.crest),
            ]
            for f in feathers {
                var p = c
                p.opacity = max(0, 1 - r / 1.4)
                p.translateBy(x: 100 + f.dx * r, y: 96 + f.dy * r + 90 * r * r)
                p.rotate(by: .degrees(f.spin * r))
                p.fill(Path(ellipseIn: CGRect(x: -7, y: -3, width: 14, height: 6)), with: .color(f.color))
            }
        }
    }

    /// The golden egg: rolls out from under her, wobbles, sparkles, then fades.
    private static func drawEgg(in context: GraphicsContext, age e: Double) {
        var c = context
        c.opacity = e > 3.6 ? max(0, 1 - (e - 3.6) / 0.9) : 1
        let x = 100 + 46 * min(e / 0.45, 1)
        c.translateBy(x: x, y: 176)
        if e < 1.6 { c.rotate(by: .degrees(14 * sin(e * 14) * (1 - e / 1.6))) }
        let shell = Path(ellipseIn: CGRect(x: -11, y: -26, width: 22, height: 28))
        c.fill(shell, with: .color(HenColors.gold))
        c.stroke(shell, with: .color(HenColors.goldEdge), lineWidth: 2)
        c.fill(Path(ellipseIn: CGRect(x: -6, y: -21, width: 5, height: 8)), with: .color(.white.opacity(0.6)))
        guard e > 0.35 && e < 2.4 else { return }
        for (dx, dy, delay) in [(16.0, -30.0, 0.0), (-14.0, -22.0, 0.25), (20.0, -8.0, 0.5)] {
            let a = max(0, sin(.pi * min(max((e - 0.35 - delay) / 0.9, 0), 1)))
            guard a > 0 else { continue }
            var star = Path()
            let r = 6 * a
            star.move(to: CGPoint(x: dx, y: dy - r))
            star.addQuadCurve(to: CGPoint(x: dx + r, y: dy), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx, y: dy + r), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx - r, y: dy), control: CGPoint(x: dx, y: dy))
            star.addQuadCurve(to: CGPoint(x: dx, y: dy - r), control: CGPoint(x: dx, y: dy))
            c.fill(star, with: .color(HenColors.yolk))
        }
    }

    private static func drawEye(in c: GraphicsContext, mood: Buddy.Mood, time t: Double) {
        let center = CGPoint(x: 86, y: mood == .sad ? 98 : 96)
        if mood == .sleepy {
            var lid = Path()
            lid.move(to: CGPoint(x: 79, y: 96))
            lid.addQuadCurve(to: CGPoint(x: 93, y: 96), control: CGPoint(x: 86, y: 101))
            c.stroke(lid, with: .color(HenColors.eye), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            return
        }
        if mood == .happy {
            var smile = Path()
            smile.move(to: CGPoint(x: 79, y: 98))
            smile.addQuadCurve(to: CGPoint(x: 93, y: 98), control: CGPoint(x: 86, y: 89))
            c.stroke(smile, with: .color(HenColors.eye), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            return
        }
        let r: CGFloat = mood == .surprised ? 8.5 : 7
        let phase = t.truncatingRemainder(dividingBy: 4.2)
        let open: CGFloat = (phase > 3.98 && phase < 4.12) ? 0.12 : 1
        c.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * open, width: r * 2, height: r * 2 * open)),
               with: .color(HenColors.eye))
        if open == 1 {
            c.fill(Path(ellipseIn: CGRect(x: center.x - 0.2, y: center.y - 4.2, width: 4.4, height: 4.4)), with: .color(.white))
        }
    }

    private static func rotate(_ c: inout GraphicsContext, degrees: Double, around p: CGPoint) {
        guard degrees != 0 else { return }
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(degrees))
        c.translateBy(x: -p.x, y: -p.y)
    }

    /// A path from absolute SVG commands (M, L, C, Z), the way the icon was drawn.
    static func path(_ d: String) -> Path {
        var tokens: [String] = []
        var current = ""
        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if ch == "-" && !current.isEmpty {
                tokens.append(current); current = "-"
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }

        var path = Path()
        var i = 0
        var command = "M"
        func number() -> CGFloat {
            defer { i += 1 }
            return i < tokens.count ? CGFloat(Double(tokens[i]) ?? 0) : 0
        }
        func point() -> CGPoint {
            let x = number()
            let y = number()
            return CGPoint(x: x, y: y)
        }
        while i < tokens.count {
            if let first = tokens[i].first, first.isLetter {
                command = tokens[i]
                i += 1
                if command == "Z" { path.closeSubpath(); continue }
            }
            switch command {
            case "M": path.move(to: point()); command = "L"
            case "L": path.addLine(to: point())
            case "C":
                let c1 = point(), c2 = point(), end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            default: i += 1
            }
        }
        return path
    }
}

/// The app icon in SwiftUI: the hen on moss, for the top of the app and anywhere the icon shows.
public struct HenMark: View {
    var size: CGFloat
    public init(size: CGFloat = 30) { self.size = size }
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous).fill(HenColors.moss)
            HenBuddy(mood: .neutral, size: size * 0.82, animate: false, interactive: false).offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
