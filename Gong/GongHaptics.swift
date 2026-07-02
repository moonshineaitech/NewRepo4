import CoreHaptics
import UIKit

/// Strike haptics: a hard transient for the mallet contact followed by a
/// decaying rumble that mirrors the gong's ring-down.
final class GongHaptics {

    static let shared = GongHaptics()

    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let fallback = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    func strike(velocity: Double) {
        let intensity = Float(max(0.2, min(1.0, velocity)))

        guard supportsHaptics, let engine else {
            fallback.impactOccurred(intensity: CGFloat(intensity))
            return
        }

        let contact = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.72),
            ],
            relativeTime: 0
        )

        let ringDuration = 0.9 + 0.5 * Double(intensity)
        let ring = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.65),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18),
            ],
            relativeTime: 0.015,
            duration: ringDuration
        )

        let fade = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: ringDuration * 0.35, value: 0.45),
                CHHapticParameterCurve.ControlPoint(relativeTime: ringDuration, value: 0.0),
            ],
            relativeTime: 0.015
        )

        do {
            let pattern = try CHHapticPattern(events: [contact, ring], parameterCurves: [fade])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback.impactOccurred(intensity: CGFloat(intensity))
        }
    }
}
