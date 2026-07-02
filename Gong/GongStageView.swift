import SwiftUI

/// The stage: a suspended gong on silk cords beneath a gilded beam, a
/// wind-up mallet, and the full strike choreography — wobble, flash,
/// ripples, and a burst of gold. Every animation is a pure function of
/// time driven by a single `TimelineView`.
struct GongStageView: View {

    @ObservedObject var model: GongModel
    let elite: Bool
    let onStrike: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let now = timeline.date
                let size = geo.size
                let radius = min(size.width, size.height * 0.72) * 0.36
                let center = CGPoint(x: size.width / 2, y: size.height * 0.54)
                let finish = Theme.finish(elite: elite)
                let wobble = model.wobbleAngle(at: now)
                let shimmerTime = Float(now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 600))

                ZStack {
                    DustCanvas(now: now)

                    // Gilded suspension beam.
                    BeamView(width: size.width, finish: finish)
                        .position(x: size.width / 2, y: 14)

                    // Ropes + gong swing together about the beam line.
                    ZStack {
                        RopeView(height: center.y - radius * 0.82 - 18)
                            .position(x: center.x - radius * 0.56, y: (center.y - radius * 0.82 - 18) / 2 + 18)
                        RopeView(height: center.y - radius * 0.82 - 18)
                            .position(x: center.x + radius * 0.56, y: (center.y - radius * 0.82 - 18) / 2 + 18)

                        GongFaceView(finish: finish, diameter: radius * 2, shimmerTime: shimmerTime)
                            .scaleEffect(model.strikeScale(at: now))
                            .shadow(color: .black.opacity(0.65), radius: radius * 0.18, y: radius * 0.14)
                            .shadow(color: finish.ringGlow.opacity(elite ? 0.4 : 0.25), radius: radius * 0.4)
                            .position(center)
                    }
                    .rotation3DEffect(
                        .degrees(wobble),
                        axis: (x: 1, y: 0, z: 0.05),
                        anchor: .top,
                        perspective: 0.5
                    )

                    // Contact flash.
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.white, finish.ringGlow.opacity(0.5), .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: radius * 1.15
                            )
                        )
                        .frame(width: radius * 2.3, height: radius * 2.3)
                        .position(center)
                        .opacity(model.flashOpacity(at: now))
                        .blendMode(.screen)
                        .allowsHitTesting(false)

                    EffectsCanvas(model: model, now: now, center: center, radius: radius, finish: finish)
                        .allowsHitTesting(false)

                    MalletView(model: model, now: now, center: center, radius: radius)
                        .allowsHitTesting(false)

                    if elite {
                        EliteCrestView()
                            .position(x: center.x, y: center.y + radius + 34)
                    }

                    // Invisible strike surface pinned to the resting gong frame.
                    Color.clear
                        .contentShape(Circle())
                        .frame(width: radius * 2.1, height: radius * 2.1)
                        .position(center)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in model.beginPress(at: Date()) }
                                .onEnded { _ in
                                    let velocity = model.endPress(at: Date(), elite: elite)
                                    onStrike(velocity)
                                }
                        )
                }
            }
        }
    }
}

// MARK: - Gong face

struct GongFaceView: View {
    let finish: Theme.Finish
    let diameter: CGFloat
    let shimmerTime: Float

    var body: some View {
        ZStack {
            // Base metal, lit from the upper left.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: finish.highlight, location: 0.0),
                            .init(color: finish.light, location: 0.28),
                            .init(color: finish.mid, location: 0.62),
                            .init(color: finish.dark, location: 1.0),
                        ]),
                        center: UnitPoint(x: 0.38, y: 0.33),
                        startRadius: 0,
                        endRadius: diameter * 0.72
                    )
                )

            // Anisotropic brushing.
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.16),
                            .clear,
                            .black.opacity(0.22),
                            .clear,
                            .white.opacity(0.10),
                            .clear,
                            .black.opacity(0.16),
                            .clear,
                        ]),
                        center: .center
                    )
                )
                .blendMode(.overlay)

            // Concentric lathe ridges.
            ForEach(0..<7, id: \.self) { index in
                let fraction = 0.36 + 0.085 * CGFloat(index)
                Circle()
                    .stroke(Color.black.opacity(0.20), lineWidth: 1.4)
                    .frame(width: diameter * fraction, height: diameter * fraction)
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1.0)
                    .frame(width: diameter * fraction + 2.4, height: diameter * fraction + 2.4)
            }

            // Hand-hammered texture.
            HammeredTexture()
                .clipShape(Circle())

            // Raised central boss.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: finish.highlight, location: 0.0),
                            .init(color: finish.light, location: 0.4),
                            .init(color: finish.mid, location: 0.75),
                            .init(color: finish.dark, location: 1.0),
                        ]),
                        center: UnitPoint(x: 0.36, y: 0.3),
                        startRadius: 0,
                        endRadius: diameter * 0.16
                    )
                )
                .frame(width: diameter * 0.27, height: diameter * 0.27)
                .shadow(color: .black.opacity(0.45), radius: diameter * 0.02, y: diameter * 0.012)

            // Turned rim.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [finish.highlight, finish.mid, finish.dark]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: diameter * 0.028
                )
        }
        .frame(width: diameter, height: diameter)
        .compositingGroup()
        .colorEffect(
            ShaderLibrary.goldShimmer(
                .float(Double(shimmerTime)),
                .float2(Double(diameter), Double(diameter))
            )
        )
    }
}

/// Deterministic hammered dimples; identical on every launch.
struct HammeredTexture: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 0xD1_5C)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            for _ in 0..<150 {
                let angle = Double.random(in: 0..<(2 * .pi), using: &rng)
                let distance = radius * sqrt(CGFloat(Double.random(in: 0.02..<0.88, using: &rng)))
                let point = CGPoint(
                    x: center.x + cos(angle) * distance,
                    y: center.y + sin(angle) * distance
                )
                let dimpleRadius = CGFloat(Double.random(in: 3..<9, using: &rng))

                let highlightRect = CGRect(
                    x: point.x - dimpleRadius - 1, y: point.y - dimpleRadius - 1,
                    width: dimpleRadius * 2, height: dimpleRadius * 2
                )
                context.fill(
                    Path(ellipseIn: highlightRect),
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.10), .clear]),
                        center: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                        startRadius: 0,
                        endRadius: dimpleRadius
                    )
                )

                let shadeRect = highlightRect.offsetBy(dx: 2, dy: 2)
                context.fill(
                    Path(ellipseIn: shadeRect),
                    with: .radialGradient(
                        Gradient(colors: [Color.black.opacity(0.12), .clear]),
                        center: CGPoint(x: shadeRect.midX, y: shadeRect.midY),
                        startRadius: 0,
                        endRadius: dimpleRadius
                    )
                )
            }
        }
    }
}

// MARK: - Suspension

struct BeamView: View {
    let width: CGFloat
    let finish: Theme.Finish

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [finish.highlight, finish.mid, finish.dark]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width * 0.86, height: 6)
            HStack {
                BeamFinial(finish: finish)
                Spacer()
                BeamFinial(finish: finish)
            }
            .frame(width: width * 0.9)
        }
    }
}

struct BeamFinial: View {
    let finish: Theme.Finish

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [finish.highlight, finish.mid]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
    }
}

struct RopeView: View {
    let height: CGFloat

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.38, green: 0.10, blue: 0.10),
                        Color(red: 0.55, green: 0.16, blue: 0.14),
                        Color(red: 0.30, green: 0.07, blue: 0.08),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 4, height: max(height, 1))
    }
}

// MARK: - Élite crest

struct EliteCrestView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "laurel.leading")
            Text("É L I T E")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .tracking(4)
            Image(systemName: "laurel.trailing")
        }
        .font(.system(size: 14))
        .foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: [Theme.goldHighlight, Theme.goldMid]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: Theme.goldMid.opacity(0.6), radius: 8)
    }
}
