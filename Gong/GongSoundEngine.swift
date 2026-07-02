import AVFoundation
import Foundation

/// A physically-inspired gong synthesizer.
///
/// Rather than shipping a sampled recording, the instrument is rendered at
/// launch from first principles: a bank of inharmonic partials (measured
/// ratios typical of a large chau gong), each with its own decay time,
/// bloom envelope, and slow phase-modulated shimmer, plus a mallet-felt
/// noise transient and a sub fundamental. The buffer is played through a
/// small pool of voices so rapid strikes overlap naturally, with a hall
/// reverb for the room. The Élite instrument is retuned upward into the
/// brighter "Aurum" voice via a time-pitch stage.
final class GongSoundEngine {

    static let shared = GongSoundEngine()

    private let engine = AVAudioEngine()
    private let submix = AVAudioMixerNode()
    private let reverb = AVAudioUnitReverb()

    private struct Voice {
        let player: AVAudioPlayerNode
        let pitch: AVAudioUnitTimePitch
    }

    private var voices: [Voice] = []
    private var nextVoiceIndex = 0

    private let sampleRate: Double = 32_000
    private let renderFormat: AVAudioFormat
    private var gongBuffer: AVAudioPCMBuffer?
    private let bufferLock = NSLock()

    private init() {
        renderFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        configureSession()
        buildGraph()
        startEngine()

        // Rendering ~18 s of a 14-partial gong takes well under a second in
        // release builds; do it off the main thread so launch stays instant.
        let format = renderFormat
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let buffer = Self.renderGong(format: format)
            guard let self else { return }
            self.bufferLock.lock()
            self.gongBuffer = buffer
            self.bufferLock.unlock()
        }
    }

    // MARK: - Graph

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func buildGraph() {
        engine.attach(submix)
        engine.attach(reverb)

        reverb.loadFactoryPreset(.largeHall2)
        reverb.wetDryMix = 34

        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            engine.attach(player)
            engine.attach(pitch)
            engine.connect(player, to: pitch, format: renderFormat)
            engine.connect(pitch, to: submix, format: renderFormat)
            voices.append(Voice(player: player, pitch: pitch))
        }

        engine.connect(submix, to: reverb, format: renderFormat)
        engine.connect(reverb, to: engine.mainMixerNode, format: renderFormat)
    }

    private func startEngine() {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            // The visual and haptic strike still land; audio will retry on
            // the next strike.
        }
    }

    // MARK: - Strikes

    /// Sound the gong.
    /// - Parameters:
    ///   - velocity: 0...1, how hard the mallet lands.
    ///   - elite: whether the instrument wears the Aurum (gold) voice.
    func strike(velocity: Double, elite: Bool) {
        if !engine.isRunning {
            configureSession()
            startEngine()
        }

        bufferLock.lock()
        let buffer = gongBuffer
        bufferLock.unlock()
        guard let buffer, engine.isRunning else { return }

        let clamped = max(0.05, min(1.0, velocity))
        let voice = voices[nextVoiceIndex]
        nextVoiceIndex = (nextVoiceIndex + 1) % voices.count

        // Slight per-strike detune keeps repeated strikes organic; the Élite
        // instrument sits ~2.3 semitones brighter.
        let wobble = Float.random(in: -22...22)
        voice.pitch.pitch = (elite ? 230 : 0) + wobble
        voice.player.volume = Float(0.30 + 0.70 * clamped)

        voice.player.stop()
        voice.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        voice.player.play()
    }

    // MARK: - Synthesis

    private static func renderGong(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = 18.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else {
            return nil
        }
        buffer.frameLength = frameCount

        // Partial table for a large chau gong, tuned around G2.
        // (ratio, amplitude, decay seconds, shimmer rate Hz, shimmer depth)
        let fundamental = 92.5
        let partials: [(ratio: Double, amp: Double, decay: Double, shimmerRate: Double, shimmerDepth: Double)] = [
            (0.53, 0.50, 3.2, 0.0, 0.0),   // sub thump
            (1.00, 1.00, 9.5, 0.0, 0.0),
            (1.52, 0.72, 7.8, 0.0, 0.0),
            (2.05, 0.62, 6.4, 2.1, 1.6),
            (2.48, 0.50, 5.6, 2.7, 1.9),
            (2.96, 0.44, 4.9, 3.3, 2.2),
            (3.42, 0.38, 4.2, 3.9, 2.4),
            (4.10, 0.33, 3.5, 4.4, 2.7),
            (4.83, 0.28, 2.9, 5.0, 2.9),
            (5.62, 0.24, 2.4, 5.7, 3.1),
            (6.71, 0.19, 1.9, 6.3, 3.3),
            (7.94, 0.15, 1.5, 7.1, 3.4),
            (9.38, 0.11, 1.2, 8.0, 3.5),
            (11.02, 0.08, 0.9, 9.2, 3.6),
        ]

        struct PartialState {
            let omega: Double
            let amp: Double
            let invDecay: Double
            let shimmerOmega: Double
            let shimmerDepth: Double
            let shimmerPhase: Double
            let phase: Double
            let bloom: Bool
        }

        var states: [PartialState] = []
        states.reserveCapacity(partials.count)
        var seed = SeededGenerator(seed: 0xC0F_FEE)
        for (index, p) in partials.enumerated() {
            states.append(PartialState(
                omega: 2.0 * .pi * fundamental * p.ratio,
                amp: p.amp,
                invDecay: 1.0 / p.decay,
                shimmerOmega: 2.0 * .pi * p.shimmerRate,
                shimmerDepth: p.shimmerDepth,
                shimmerPhase: Double.random(in: 0..<(2 * .pi), using: &seed),
                phase: Double.random(in: 0..<(2 * .pi), using: &seed),
                bloom: index >= 4
            ))
        }

        let frames = Int(frameCount)
        var samples = [Float](repeating: 0, count: frames)
        var noiseLowpass = 0.0
        var noiseSeed = SeededGenerator(seed: 0xBEEF)
        var peak: Float = 0

        for frame in 0..<frames {
            let t = Double(frame) / sampleRate
            var value = 0.0

            // Mallet-felt transient: band-limited noise burst.
            if t < 0.6 {
                let white = Double.random(in: -1...1, using: &noiseSeed)
                noiseLowpass += 0.22 * (white - noiseLowpass)
                value += noiseLowpass * 0.9 * exp(-t * 11.0)
            }

            let attack = 1.0 - exp(-t * 90.0)

            for state in states {
                var envelope = state.amp * exp(-t * state.invDecay)
                if state.bloom {
                    // Upper partials swell in after the strike — the
                    // signature "bloom" of a large gong.
                    envelope *= 0.35 + 0.65 * min(t / 1.15, 1.0)
                }
                let shimmer = state.shimmerDepth == 0
                    ? 0.0
                    : state.shimmerDepth * sin(state.shimmerOmega * t + state.shimmerPhase)
                value += envelope * sin(state.omega * t + state.phase + shimmer)
            }

            let sample = Float(value * attack)
            samples[frame] = sample
            peak = max(peak, abs(sample))
        }

        let gain: Float = peak > 0 ? 0.88 / peak : 0
        let left = channels[0]
        let right = channels[1]
        // A short Haas offset on the right channel widens the image.
        let haasOffset = Int(sampleRate * 0.0045)
        for frame in 0..<frames {
            let value = samples[frame] * gain
            left[frame] = value
            right[frame] = frame >= haasOffset ? samples[frame - haasOffset] * gain : value
        }

        return buffer
    }
}
