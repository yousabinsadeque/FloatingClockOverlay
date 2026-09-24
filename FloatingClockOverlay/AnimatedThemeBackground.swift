import SwiftUI

// MARK: - Animated Theme Background

struct AnimatedThemeBackground: View {
    let theme: ClockTheme

    var body: some View {
        switch theme {
        case .weather:       LiveWeatherAnimation()
        case .toyStory:      ToyStoryAnimation()
        case .f1:            F1Animation()
        case .naruto:        NarutoAnimation()
        case .weatheringYou: WeatheringAnimation()
        case .yourName:      YourNameAnimation()
        case .frozen:        FrozenAnimation()
        case .onePiece:      OnePieceAnimation()
        default:             EmptyView()
        }
    }
}

// MARK: - Live Weather Animation

struct LiveWeatherAnimation: View {
    @ObservedObject private var ws = WeatherService.shared

    var body: some View {
        let p = ws.palette
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                switch ws.condition {
                case .rain:
                    drawRain(ctx: ctx, size: size, t: t, p: p)
                case .snow:
                    drawSnow(ctx: ctx, size: size, t: t, p: p)
                case .thunderstorm:
                    drawRain(ctx: ctx, size: size, t: t, p: p)
                    drawLightning(ctx: ctx, size: size, t: t, p: p)
                case .hot:
                    drawSunRays(ctx: ctx, size: size, t: t, p: p, intense: true)
                case .clear:
                    if ws.timeOfDay == .night {
                        drawStars(ctx: ctx, size: size, t: t, p: p)
                    } else {
                        drawSunRays(ctx: ctx, size: size, t: t, p: p, intense: false)
                    }
                case .cloudy:
                    drawClouds(ctx: ctx, size: size, t: t, p: p)
                case .fog:
                    drawFog(ctx: ctx, size: size, t: t, p: p)
                }
            }
        }
        .onAppear { ws.startIfNeeded() }
    }

    private func drawRain(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        for i in 0..<35 {
            let seed = Double(i) * 43.7
            let x = (seed * 17.3).truncatingRemainder(dividingBy: Double(size.width))
            let speed = 70 + seed.truncatingRemainder(dividingBy: 50)
            let y = (t * speed + seed * 11).truncatingRemainder(dividingBy: Double(size.height) + 20) - 10
            let len = 6 + seed.truncatingRemainder(dividingBy: 10)
            let alpha = 0.25 + 0.2 * (seed.truncatingRemainder(dividingBy: 1.0))

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 1.5, y: y + len))
            ctx.stroke(path, with: .color(p.particle.opacity(alpha)), lineWidth: 1.5)
        }
    }

    private func drawSnow(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        for i in 0..<25 {
            let seed = Double(i) * 53.9
            let speed = 10 + seed.truncatingRemainder(dividingBy: 15)
            let drift = sin(t * 0.6 + seed) * 12
            let x = (seed * 11.3).truncatingRemainder(dividingBy: Double(size.width)) + drift
            let y = (t * speed + seed * 17).truncatingRemainder(dividingBy: Double(size.height) + 10) - 5
            let r = 1.5 + seed.truncatingRemainder(dividingBy: 3.0)
            let alpha = 0.5 + 0.4 * (0.5 + 0.5 * sin(t * 0.8 + seed))

            let color = i % 3 == 0 ? p.secondary : p.particle
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(color.opacity(alpha)))
        }
    }

    private func drawSunRays(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette, intense: Bool) {
        let cx = size.width * 0.8
        let cy = size.height * 0.2
        let basePulse = intense ? 0.12 : 0.08
        let pulse = basePulse + 0.04 * sin(t * 0.6)

        let glowR = min(size.width, size.height) * (intense ? 1.0 : 0.8)
        ctx.fill(Path(ellipseIn: CGRect(x: cx - glowR / 2, y: cy - glowR / 2, width: glowR, height: glowR)),
                 with: .color(p.glow.opacity(pulse * 0.5)))

        let rayCount = intense ? 12 : 8
        for i in 0..<rayCount {
            let angle = Double(i) * .pi * 2 / Double(rayCount) + t * 0.15
            let rayLen = min(size.width, size.height) * (intense ? 0.45 : 0.35)
            let alpha = 0.06 + 0.04 * sin(t * 0.8 + Double(i))

            var path = Path()
            path.move(to: CGPoint(x: cx, y: cy))
            path.addLine(to: CGPoint(x: cx + cos(angle) * rayLen, y: cy + sin(angle) * rayLen))
            ctx.stroke(path, with: .color(p.particle.opacity(alpha)), lineWidth: intense ? 2.5 : 2)
        }

        let coreR: CGFloat = intense ? 8 : 6
        ctx.fill(Path(ellipseIn: CGRect(x: cx - coreR, y: cy - coreR, width: coreR * 2, height: coreR * 2)),
                 with: .color(p.particle.opacity(0.3)))
    }

    private func drawStars(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        // Moon glow
        let mx = size.width * 0.75
        let my = size.height * 0.2
        let moonPulse = 0.06 + 0.03 * sin(t * 0.4)
        let moonR = min(size.width, size.height) * 0.5
        ctx.fill(Path(ellipseIn: CGRect(x: mx - moonR / 2, y: my - moonR / 2, width: moonR, height: moonR)),
                 with: .color(p.glow.opacity(moonPulse)))

        let coreR: CGFloat = 4
        ctx.fill(Path(ellipseIn: CGRect(x: mx - coreR, y: my - coreR, width: coreR * 2, height: coreR * 2)),
                 with: .color(p.particle.opacity(0.4)))

        // Twinkling stars
        for i in 0..<18 {
            let seed = Double(i) * 113.7
            let x = (seed * 7.1).truncatingRemainder(dividingBy: Double(size.width))
            let y = (seed * 13.3).truncatingRemainder(dividingBy: Double(size.height))
            let twinkle = 0.15 + 0.6 * (0.5 + 0.5 * sin(t * (1.2 + seed.truncatingRemainder(dividingBy: 2.0)) + seed))
            let r = 0.6 + seed.truncatingRemainder(dividingBy: 1.5)

            let color = i % 4 == 0 ? p.secondary : p.particle
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(color.opacity(twinkle)))
        }
    }

    private func drawClouds(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        for i in 0..<5 {
            let seed = Double(i) * 97.1
            let x = (seed * 3.7 + t * (5 + seed.truncatingRemainder(dividingBy: 8)))
                .truncatingRemainder(dividingBy: Double(size.width) + 60) - 30
            let y = (seed * 7.3).truncatingRemainder(dividingBy: Double(size.height) * 0.6)
            let w = 30 + seed.truncatingRemainder(dividingBy: 25)
            let h = w * 0.45
            let alpha = 0.08 + 0.06 * (seed.truncatingRemainder(dividingBy: 1.0))

            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)),
                     with: .color(p.particle.opacity(alpha)))
            ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.3, y: y - h * 0.3, width: w * 0.6, height: h * 0.8)),
                     with: .color(p.secondary.opacity(alpha * 0.8)))
        }
    }

    private func drawFog(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        for i in 0..<6 {
            let seed = Double(i) * 67.3
            let y = Double(size.height) * (0.2 + Double(i) * 0.12)
            let drift = sin(t * 0.2 + seed) * 15
            let alpha = 0.06 + 0.03 * sin(t * 0.4 + seed)

            let rect = CGRect(x: drift - 10, y: y, width: Double(size.width) + 20, height: 8)
            ctx.fill(Path(ellipseIn: rect), with: .color(p.particle.opacity(alpha)))
        }
    }

    private func drawLightning(ctx: GraphicsContext, size: CGSize, t: Double, p: WeatherPalette) {
        let cycle = t.truncatingRemainder(dividingBy: 3.0)
        guard cycle < 0.15 else { return }
        let flash = 0.12 + 0.15 * sin(t * 40)
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(p.glow.opacity(flash)))
    }
}

// MARK: - Toy Story — Floating stars in deep space

struct ToyStoryAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bg = Color(hex: "1E1031")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                for i in 0..<25 {
                    let seed = Double(i) * 137.508
                    let speed = 0.3 + (seed.truncatingRemainder(dividingBy: 1.7))
                    let x = (seed * 7.3 + t * speed * 8).truncatingRemainder(dividingBy: Double(size.width) + 20) - 10
                    let baseY = (seed * 13.1).truncatingRemainder(dividingBy: Double(size.height))
                    let y = baseY + sin(t * speed + seed) * 6
                    let r = 1.0 + (seed.truncatingRemainder(dividingBy: 2.5))
                    let pulse = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2.0 + seed))

                    let starColor: Color = i % 3 == 0
                        ? Color(hex: "5CF115").opacity(pulse)
                        : Color(hex: "FFD659").opacity(pulse * 0.8)

                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(starColor))
                }
            }
        }
    }
}

// MARK: - F1 — Formula 1 car racing around border, 60s lap, exhaust, checkered flag

struct F1Animation: View {
    @ObservedObject private var s = ClockSettings.shared

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let lapDuration = 60.0
            let progress = CGFloat(t.truncatingRemainder(dividingBy: lapDuration) / lapDuration)

            let team = s.f1Team

            Canvas { ctx, size in
                let bg = Color(hex: "1A1C20")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                let pad: CGFloat = 6
                let l = pad, r = size.width - pad, top = pad, bot = size.height - pad
                let h = r - l, v = bot - top
                let perim = (h + v) * 2

                // Racetrack border in team accent color
                let borderRect = CGRect(x: l, y: top, width: h, height: v)
                let borderPath = Path(roundedRect: borderRect, cornerRadius: 6)
                ctx.stroke(borderPath, with: .color(team.accentColor.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 4, dash: [8, 8]))

                // Checkered flag at top-middle
                let flagW: CGFloat = 24
                let flagH: CGFloat = 12
                let flagX = size.width / 2 - flagW / 2
                let flagY: CGFloat = 0
                let sq: CGFloat = 4
                for row in 0..<Int(flagH / sq) {
                    for col in 0..<Int(flagW / sq) {
                        let isWhite = (row + col) % 2 == 0
                        let rect = CGRect(x: flagX + CGFloat(col) * sq,
                                          y: flagY + CGFloat(row) * sq,
                                          width: sq, height: sq)
                        ctx.fill(Path(rect), with: .color(isWhite ? Color.white.opacity(0.45) : Color.black.opacity(0.45)))
                    }
                }

                // Speed lines
                for i in 0..<12 {
                    let seed = Double(i) * 73.7
                    let speed = 60 + seed.truncatingRemainder(dividingBy: 100)
                    let y = (seed * 13.3).truncatingRemainder(dividingBy: Double(size.height))
                    let startX = (t * speed + seed * 4).truncatingRemainder(dividingBy: Double(size.width) + 150) - 150
                    let lineLen = 12 + seed.truncatingRemainder(dividingBy: 25)
                    let alpha = 0.06 + 0.1 * (0.5 + 0.5 * sin(t * 2 + seed))
                    let color = i % 3 == 0 ? team.carColor : team.accentColor
                    var path = Path()
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: startX + lineLen, y: y))
                    ctx.stroke(path, with: .color(color.opacity(alpha)), lineWidth: 1)
                }

                // Car position & angle
                let carPos = f1Pos(progress: progress, l: l, r: r, top: top, bot: bot, h: h, v: v, perim: perim)
                let carAngle = f1Angle(progress: progress, h: h, v: v, perim: perim)

                // Exhaust trail — 20 puffs
                for s in 1..<21 {
                    let sp = progress - CGFloat(s) * 0.0025
                    let wp = sp < 0 ? sp + 1 : sp
                    let sPos = f1Pos(progress: wp, l: l, r: r, top: top, bot: bot, h: h, v: v, perim: perim)
                    let age = CGFloat(s) / 20.0
                    let r = 2 + age * 7
                    let a = (1 - age) * 0.5
                    let jitter = sin(t * 8 + Double(s)) * 1.5
                    let rect = CGRect(x: sPos.x - r + CGFloat(jitter), y: sPos.y - r,
                                      width: r * 2, height: r * 2)
                    let c = Color(white: 0.6 + age * 0.3)
                    ctx.fill(Path(ellipseIn: rect), with: .color(c.opacity(a)))
                }

                // Draw F1 car
                ctx.translateBy(x: carPos.x, y: carPos.y)
                ctx.rotate(by: .radians(carAngle))

                // Rear wing
                let wingRect = CGRect(x: -13, y: -6, width: 2, height: 12)
                ctx.fill(Path(wingRect), with: .color(Color(hex: "333333")))

                // Main body — long narrow F1 shape in team color
                var bodyPath = Path()
                bodyPath.move(to: CGPoint(x: -11, y: -4))
                bodyPath.addLine(to: CGPoint(x: 10, y: -2))
                bodyPath.addLine(to: CGPoint(x: 12, y: 0))
                bodyPath.addLine(to: CGPoint(x: 10, y: 2))
                bodyPath.addLine(to: CGPoint(x: -11, y: 4))
                bodyPath.closeSubpath()
                ctx.fill(bodyPath, with: .color(team.carColor))

                // Cockpit
                let cockpit = CGRect(x: -2, y: -2, width: 5, height: 4)
                ctx.fill(Path(roundedRect: cockpit, cornerRadius: 1), with: .color(Color(hex: "222222")))

                // Front wing
                let fwRect = CGRect(x: 11, y: -5, width: 2, height: 10)
                ctx.fill(Path(fwRect), with: .color(Color(hex: "444444")))

                // Wheels (4)
                let wc = Color(hex: "111111")
                ctx.fill(Path(ellipseIn: CGRect(x: -10, y: -7, width: 4, height: 3)), with: .color(wc))
                ctx.fill(Path(ellipseIn: CGRect(x: -10, y: 4, width: 4, height: 3)), with: .color(wc))
                ctx.fill(Path(ellipseIn: CGRect(x: 7, y: -6, width: 4, height: 3)), with: .color(wc))
                ctx.fill(Path(ellipseIn: CGRect(x: 7, y: 3, width: 4, height: 3)), with: .color(wc))

                // Driver number on side
                let num = Text(team.number).font(.system(size: 5, weight: .black)).foregroundColor(.white)
                ctx.draw(ctx.resolve(num), at: CGPoint(x: -5, y: 0))
            }
        }
    }

    private func f1Pos(progress: CGFloat, l: CGFloat, r: CGFloat, top: CGFloat, bot: CGFloat,
                        h: CGFloat, v: CGFloat, perim: CGFloat) -> CGPoint {
        let d = progress * perim
        if d < h { return CGPoint(x: l + d, y: top) }
        else if d < h + v { return CGPoint(x: r, y: top + d - h) }
        else if d < h * 2 + v { return CGPoint(x: r - (d - h - v), y: bot) }
        else { return CGPoint(x: l, y: bot - (d - h * 2 - v)) }
    }

    private func f1Angle(progress: CGFloat, h: CGFloat, v: CGFloat, perim: CGFloat) -> Double {
        let d = progress * perim
        if d < h { return 0 }
        else if d < h + v { return .pi / 2 }
        else if d < h * 2 + v { return .pi }
        else { return -.pi / 2 }
    }
}

// MARK: - Naruto — Chakra energy particles swirling

struct NarutoAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bg = Color(hex: "0D1117")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                let cx = size.width / 2
                let cy = size.height / 2

                for i in 0..<20 {
                    let seed = Double(i) * 67.1
                    let angle = t * (0.4 + seed.truncatingRemainder(dividingBy: 0.8)) + seed
                    let radius = 10 + seed.truncatingRemainder(dividingBy: Double(min(size.width, size.height)) * 0.45)
                    let x = cx + cos(angle) * radius
                    let y = cy + sin(angle) * radius * 0.6
                    let pulse = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * 3.0 + seed))
                    let r = 1.5 + seed.truncatingRemainder(dividingBy: 3.0)

                    let color: Color = i % 2 == 0
                        ? Color(hex: "FF7B00").opacity(pulse * 0.7)
                        : Color(hex: "53A6FD").opacity(pulse * 0.5)

                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Weathering with You — Rain drops with golden light

struct WeatheringAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bg = Color(hex: "161F2E")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                // Golden light glow at top right
                let sunPulse = 0.06 + 0.04 * sin(t * 0.8)
                let sunRect = CGRect(x: size.width * 0.6, y: -size.height * 0.3,
                                     width: size.width * 0.8, height: size.height * 0.8)
                ctx.fill(Path(ellipseIn: sunRect),
                         with: .color(Color(hex: "FFB732").opacity(sunPulse)))

                // Rain drops
                for i in 0..<30 {
                    let seed = Double(i) * 43.7
                    let x = (seed * 17.3).truncatingRemainder(dividingBy: Double(size.width))
                    let speed = 60 + seed.truncatingRemainder(dividingBy: 40)
                    let y = (t * speed + seed * 11).truncatingRemainder(dividingBy: Double(size.height) + 20) - 10
                    let len = 4 + seed.truncatingRemainder(dividingBy: 8)
                    let alpha = 0.15 + 0.15 * (seed.truncatingRemainder(dividingBy: 1.0))

                    let color = Color(hex: "4BA3E3").opacity(alpha)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - 1, y: y + len))
                    ctx.stroke(path, with: .color(color), lineWidth: 1.0)
                }
            }
        }
    }
}

// MARK: - Your Name — Comet trail across twilight with twinkling stars

struct YourNameAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Twilight gradient
                let bg = Color(hex: "161224")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                // Twinkling stars
                for i in 0..<15 {
                    let seed = Double(i) * 113.7
                    let x = (seed * 7.1).truncatingRemainder(dividingBy: Double(size.width))
                    let y = (seed * 13.3).truncatingRemainder(dividingBy: Double(size.height))
                    let twinkle = 0.2 + 0.8 * (0.5 + 0.5 * sin(t * (1.5 + seed.truncatingRemainder(dividingBy: 2.0)) + seed))
                    let r = 0.8 + seed.truncatingRemainder(dividingBy: 1.5)

                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(Color.white.opacity(twinkle * 0.6)))
                }

                // Comet
                let cometCycle = 8.0
                let cometT = t.truncatingRemainder(dividingBy: cometCycle) / cometCycle
                let cometX = -size.width * 0.2 + cometT * size.width * 1.4
                let cometY = size.height * 0.15 + cometT * size.height * 0.5

                let tailLen: CGFloat = 35
                for j in 0..<12 {
                    let frac = CGFloat(j) / 12.0
                    let tx = cometX - frac * tailLen
                    let ty = cometY - frac * tailLen * 0.3
                    let alpha = (1.0 - frac) * 0.5 * (cometT < 0.95 ? 1.0 : (1.0 - cometT) * 20)
                    let r = (1.0 - frac) * 2.5

                    let color: Color = frac < 0.3
                        ? Color(hex: "E0F7FA").opacity(alpha)
                        : Color(hex: "FF4D85").opacity(alpha * 0.8)

                    ctx.fill(Path(ellipseIn: CGRect(x: tx - r, y: ty - r, width: r * 2, height: r * 2)),
                             with: .color(color))
                }
            }
        }
    }
}

// MARK: - Frozen — Snowflakes falling with ice shimmer

struct FrozenAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bg = Color(hex: "09142B")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                // Ice shimmer at edges
                let shimmer = 0.03 + 0.03 * sin(t * 1.2)
                let shimmerRect = CGRect(x: -10, y: -10, width: size.width + 20, height: size.height + 20)
                ctx.stroke(Path(shimmerRect.insetBy(dx: 3, dy: 3)),
                           with: .color(Color(hex: "81D4FA").opacity(shimmer)), lineWidth: 4)

                // Snowflakes
                for i in 0..<22 {
                    let seed = Double(i) * 53.9
                    let speed = 12 + seed.truncatingRemainder(dividingBy: 18)
                    let drift = sin(t * 0.8 + seed) * 10
                    let x = (seed * 11.3).truncatingRemainder(dividingBy: Double(size.width)) + drift
                    let y = (t * speed + seed * 17).truncatingRemainder(dividingBy: Double(size.height) + 10) - 5
                    let r = 1.0 + seed.truncatingRemainder(dividingBy: 2.5)
                    let alpha = 0.3 + 0.4 * (0.5 + 0.5 * sin(t + seed))

                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(Color.white.opacity(alpha)))
                }
            }
        }
    }
}

// MARK: - One Piece — Ocean waves with glowing particles

struct OnePieceAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bg = Color(hex: "0A192F")
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

                // Ocean wave lines
                for w in 0..<4 {
                    let waveY = size.height * (0.55 + Double(w) * 0.12)
                    let speed = 0.6 + Double(w) * 0.15
                    let amp = 3.0 + Double(w) * 1.5
                    let alpha = 0.08 + Double(w) * 0.03

                    var path = Path()
                    for px in stride(from: 0, to: Double(size.width), by: 2) {
                        let y = waveY + sin(px * 0.03 + t * speed) * amp
                        if px == 0 { path.move(to: CGPoint(x: px, y: y)) }
                        else { path.addLine(to: CGPoint(x: px, y: y)) }
                    }
                    ctx.stroke(path, with: .color(Color(hex: "4BA3E3").opacity(alpha)), lineWidth: 1.5)
                }

                // Floating gold particles (treasure vibes)
                for i in 0..<12 {
                    let seed = Double(i) * 87.3
                    let x = (seed * 9.1).truncatingRemainder(dividingBy: Double(size.width))
                    let baseY = (seed * 14.7).truncatingRemainder(dividingBy: Double(size.height) * 0.5)
                    let y = baseY + sin(t * 0.7 + seed) * 5
                    let pulse = 0.3 + 0.5 * (0.5 + 0.5 * sin(t * 1.8 + seed))
                    let r = 1.2 + seed.truncatingRemainder(dividingBy: 1.8)

                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(Color(hex: "FBBF24").opacity(pulse * 0.6)))
                }
            }
        }
    }
}
