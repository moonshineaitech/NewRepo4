import SwiftUI

// MARK: - Strike effects (ripples + gold burst)

/// Ripples and particle bursts, rendered analytically from strike timestamps.
/// The parent `TimelineView` redraws every frame; each strike's seed replays
/// the identical particle cloud deterministically, so no per-frame state is
/// stored anywhere.
struct EffectsCanvas: View {
    let model: GongModel
    let now: Date
    let center: CGPoint
    let radius: CGFloat
    let finish: Theme.Finish

    var body: some View {
        Canvas { context, _ in
            context.blendMode = .plusLighter

            for strike in model.strikes {
                drawRipples(for: strike, in: &context)
                drawBurst(for: strike, in: &context)
            }
        }
    }

    private func drawRipples(for strike: Strike, in context: inout GraphicsContext) {
        for ring in 0..<3 {
            let delay = 0.14 * Double(ring)
            let t = now.timeIntervalSince(strike.date) - delay
            guard t > 0, t < 1.5 else { continue }

            let progress = t / 1.5
            let ringRadius = radius * (1.0 + 1.55 * progress)
            let alpha = pow(1 - progress, 1.7) * 0.5 * (0.4 + 0.6 * strike.velocity)
            let lineWidth = (4.0 - 2.8 * progress) * (0.5 + 0.5 * strike.velocity)

            let rect = CGRect(
                x: center.x - ringRadius, y: center.y - ringRadius,
                width: ringRadius * 2, height: ringRadius * 2
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(finish.ringGlow.opacity(alpha)),
                lineWidth: lineWidth
            )
        }
    }

    private func drawBurst(for strike: Strike, in context: inout GraphicsContext) {
        let t = now.timeIntervalSince(strike.date)
        guard t >= 0, t < 2.1 else { return }

        var rng = SeededGenerator(seed: strike.seed)
        let count = 24 + Int(46 * strike.velocity)

        for _ in 0..<count {
            let angle = Double.random(in: 0..<(2 * .pi), using: &rng)
            let speed = Double(radius) * Double.random(in: 0.8..<2.1, using: &rng) * (0.4 + 0.6 * strike.velocity)
            let life = Double.random(in: 0.9..<1.9, using: &rng)
            let size = Double.random(in: 1.4..<3.4, using: &rng)
            let warmth = Double.random(in: 0..<1, using: &rng)

            guard t < life else { continue }

            // Exponential deceleration plus a hint of gravity.
            let travel = speed * (1 - exp(-2.0 * t)) / 2.0
            let x = Double(center.x) + cos(angle) * travel
            let y = Double(center.y) + sin(angle) * travel + 42 * t * t

            let fade = pow(max(0, 1 - t / life), 1.5)
            let dotSize = size * (1 - 0.3 * t / life)
            let color = warmth > 0.72 ? Color.white : finish.particle

            let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(fade)))
        }
    }
}

// MARK: - Ambient dust

/// Slow-rising motes of gold dust drifting through the gallery light.
struct DustCanvas: View {
    let now: Date

    var body: some View {
        Canvas { context, size in
            let t = now.timeIntervalSinceReferenceDate
            var rng = SeededGenerator(seed: 0xD057)

            for _ in 0..<34 {
                let baseX = Double.random(in: 0..<1, using: &rng)
                let baseY = Double.random(in: 0..<1, using: &rng)
                let rise = Double.random(in: 6..<18, using: &rng)
                let drift = Double.random(in: 8..<24, using: &rng)
                let phase = Double.random(in: 0..<(2 * .pi), using: &rng)
                let sway = Double.random(in: 0.1..<0.5, using: &rng)
                let twinkle = Double.random(in: 0.4..<1.6, using: &rng)
                let dotRadius = Double.random(in: 0.7..<2.0, using: &rng)
                let baseOpacity = Double.random(in: 0.04..<0.14, using: &rng)

                let height = Double(size.height)
                let width = Double(size.width)
                let y = height - fmod(baseY * height + t * rise, height + 40) + 20
                let x = baseX * width + sin(t * sway + phase) * drift
                let opacity = baseOpacity * (0.55 + 0.45 * sin(t * twinkle + phase * 2))
                guard opacity > 0.005 else { continue }

                let rect = CGRect(
                    x: x - dotRadius, y: y - dotRadius,
                    width: dotRadius * 2, height: dotRadius * 2
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(red: 1.0, green: 0.92, blue: 0.72).opacity(opacity))
                )
            }
        }
    }
}

// MARK: - Mallet

/// The ceremonial mallet: appears on touch, draws back while held, and
/// swings through the strike on release.
struct MalletView: View {
    let model: GongModel
    let now: Date
    let center: CGPoint
    let radius: CGFloat

    private static let restAngle = 14.0
    private static let hitAngle = -14.0
    private static let maxPull = 58.0

    var body: some View {
        let state = malletState()
        let headDiameter = radius * 0.34
        let handleHeight = radius * 0.82
        let totalHeight = headDiameter + handleHeight - 4
        let pivot = CGPoint(x: center.x + radius * 0.88, y: center.y + radius * 0.5)

        VStack(spacing: -4) {
            // Suede head with a gold collar.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.98, green: 0.94, blue: 0.84),
                            Color(red: 0.85, green: 0.78, blue: 0.62),
                            Color(red: 0.62, green: 0.53, blue: 0.38),
                        ]),
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: headDiameter * 0.7
                    )
                )
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldDark]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                )
                .frame(width: headDiameter, height: headDiameter)
                .shadow(color: .black.opacity(0.5), radius: 6, y: 4)

            // Dark walnut handle.
            RoundedRectangle(cornerRadius: 3.5)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.30, green: 0.18, blue: 0.10),
                            Color(red: 0.16, green: 0.09, blue: 0.05),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 7, height: handleHeight)
        }
        .rotationEffect(.degrees(state.angle), anchor: .bottom)
        .opacity(state.opacity)
        .position(x: pivot.x, y: pivot.y - totalHeight / 2)
    }

    private func malletState() -> (angle: Double, opacity: Double) {
        if model.isPressing, let start = model.pressStarted {
            let held = now.timeIntervalSince(start)
            let pull = model.windUp(at: now)
            let opacity = min(1, max(held, 0) / 0.12)
            return (Self.restAngle + Self.maxPull * pull, opacity)
        }

        if let released = model.releasedAt {
            let t = now.timeIntervalSince(released)
            let releaseAngle = Self.restAngle + Self.maxPull * model.releaseWindUp
            if t < 0.07 {
                // The swing itself: fast sweep into the disc.
                let progress = max(0, t) / 0.07
                return (releaseAngle + (Self.hitAngle - releaseAngle) * progress, 1)
            }
            if t < 1.4 {
                // Recover to rest, then fade away.
                let recover = min(1, (t - 0.07) / 0.55)
                let angle = Self.hitAngle + (Self.restAngle - Self.hitAngle) * recover
                let opacity = t < 0.55 ? 1.0 : max(0, 1 - (t - 0.55) / 0.85)
                return (angle, opacity)
            }
        }

        return (Self.restAngle, 0)
    }
}
