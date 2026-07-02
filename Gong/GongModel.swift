import Foundation
import SwiftUI

/// A single mallet strike. All visual consequences of a strike — wobble,
/// flash, ripples, particles — are computed analytically from its timestamp,
/// so the entire animation system is a pure function of time.
struct Strike: Identifiable {
    let id = UUID()
    let date: Date
    let velocity: Double
    let seed: UInt64
}

@MainActor
final class GongModel: ObservableObject {

    @Published private(set) var strikes: [Strike] = []
    @Published var isPressing = false
    @Published var pressStarted: Date?
    @Published var releasedAt: Date?
    @Published var releaseWindUp: Double = 0

    /// Maximum wind-up time for the mallet; holding longer adds nothing.
    static let maxWindUp: Double = 1.4

    func beginPress(at date: Date) {
        guard pressStarted == nil else { return }
        pressStarted = date
        releasedAt = nil
        isPressing = true
    }

    /// Ends the press and lands the strike. Returns the strike velocity.
    @discardableResult
    func endPress(at date: Date, elite: Bool) -> Double {
        let held = pressStarted.map { date.timeIntervalSince($0) } ?? 0
        pressStarted = nil
        isPressing = false
        releasedAt = date

        let windUp = min(max(held, 0), Self.maxWindUp) / Self.maxWindUp
        releaseWindUp = 1 - pow(1 - windUp, 2.2)
        let velocity = min(1.0, 0.34 + 0.66 * windUp)

        strikes.append(Strike(date: date, velocity: velocity, seed: UInt64.random(in: 0..<UInt64.max)))
        if strikes.count > 10 {
            strikes.removeFirst(strikes.count - 10)
        }

        GongSoundEngine.shared.strike(velocity: velocity, elite: elite)
        GongHaptics.shared.strike(velocity: velocity)
        return velocity
    }

    // MARK: - Analytic animation curves

    /// Damped oscillation of the gong on its ropes, degrees about the x-axis.
    func wobbleAngle(at date: Date) -> Double {
        var angle = 0.0
        for strike in strikes {
            let t = date.timeIntervalSince(strike.date)
            guard t >= 0, t < 6 else { continue }
            let amplitude = 8.5 * strike.velocity
            angle += -amplitude * exp(-t * 1.7) * sin(2 * .pi * 1.3 * t)
        }
        return max(-14, min(14, angle))
    }

    /// Brief compression of the disc at the moment of contact.
    func strikeScale(at date: Date) -> Double {
        var scale = 1.0
        for strike in strikes {
            let t = date.timeIntervalSince(strike.date)
            guard t >= 0, t < 1.2 else { continue }
            let kick = sin(min(t * 26, .pi)) * exp(-t * 2.6)
            scale -= 0.05 * strike.velocity * kick
        }
        return scale
    }

    /// Radial light flash at contact, 0...1.
    func flashOpacity(at date: Date) -> Double {
        var flash = 0.0
        for strike in strikes {
            let t = date.timeIntervalSince(strike.date)
            guard t >= 0, t < 1.0 else { continue }
            flash += 0.6 * strike.velocity * exp(-t * 5.5)
        }
        return min(flash, 0.85)
    }

    /// Mallet pull-back progress 0...1 while the press is held.
    func windUp(at date: Date) -> Double {
        guard let start = pressStarted else { return 0 }
        let held = date.timeIntervalSince(start)
        let progress = min(max(held, 0), Self.maxWindUp) / Self.maxWindUp
        // Ease-out so the first moments of the pull feel responsive.
        return 1 - pow(1 - progress, 2.2)
    }

    /// How hard the most recent strike was, for callers that missed the return value.
    var lastStrike: Strike? { strikes.last }
}
