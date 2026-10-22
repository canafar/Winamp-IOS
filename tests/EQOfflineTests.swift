import AVFoundation
import Foundation

/// Run on a Mac with scripts/test-eq.sh. No speaker output or signing required.
@main
enum EQOfflineTests {
    static func require(_ condition: Bool, _ message: String) {
        if !condition { fatalError(message) }
    }

    static func rms(frequency: Float, settings: EqualizerSettings) throws -> Double {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let eq = AVAudioUnitEQ(numberOfBands: 10)
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        engine.attach(player); engine.attach(eq)
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
        EqualizerDSP.configure(eq, settings: settings, sampleRate: 48000)
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 1024)
        let input = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48000)!
        input.frameLength = 48000
        for ch in 0..<2 {
            for i in 0..<48000 {
                input.floatChannelData![ch][i] = Float(0.05 * sin(2 * Double.pi * Double(frequency) * Double(i) / 48000))
            }
        }
        player.scheduleBuffer(input)
        try engine.start(); player.play()
        defer { player.stop(); engine.stop() }
        let output = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 1024)!
        var frames = 0
        var sum: Double = 0
        var count = 0
        var retries = 0
        while frames < 48000 {
            let requested = AVAudioFrameCount(min(1024, 48000 - frames))
            let status = try engine.renderOffline(requested, to: output)
            if status == .cannotDoInCurrentContext {
                retries += 1; require(retries < 1000, "Offline renderer stalled"); continue
            }
            require(status == .success, "Offline renderer failed: \(status)")
            require(output.frameLength > 0, "No output frames")
            for i in 0..<Int(output.frameLength) where frames + i >= 12000 {
                let sample = Double(output.floatChannelData![0][i]); sum += sample * sample; count += 1
            }
            frames += Int(output.frameLength)
        }
        return sqrt(sum / Double(count))
    }

    static func main() throws {
        var malformed = EqualizerSettings(preamp: .infinity, gains: [20, -30, .nan])
        malformed = malformed.sanitized()
        require(malformed.gains.count == 10 && malformed.gains[0] == 12 && malformed.gains[1] == -12 && malformed.gains[2] == 0 && malformed.preamp == 0, "Settings validation failed")
        let flat = EqualizerSettings()
        for index in [0, 4, 9] {
            let frequency = EqualizerSettings.frequencies[index]
            let baseline = try rms(frequency: frequency, settings: flat)
            require(abs(baseline - 0.05 / sqrt(2)) < 0.001, "Flat changed audio level")
            var boosted = flat; boosted.gains[index] = 6
            let measured = 20 * log10(try rms(frequency: frequency, settings: boosted) / baseline)
            require(abs(measured - 6) < 0.6, "Band \(frequency) Hz expected +6 dB, got \(measured)")
            boosted.enabled = false; boosted.preamp = 8
            let bypass = 20 * log10(try rms(frequency: frequency, settings: boosted) / baseline)
            require(abs(bypass) < 0.1, "OFF did not bypass EQ and preamp")
            print("PASS: \(frequency) Hz gain and bypass")
        }
        var preamp = flat; preamp.preamp = -6
        let base = try rms(frequency: 1000, settings: flat)
        let attenuation = 20 * log10(try rms(frequency: 1000, settings: preamp) / base)
        require(abs(attenuation + 6) < 0.1, "Preamp attenuation failed")
        let lowRate = AVAudioUnitEQ(numberOfBands: 10)
        EqualizerDSP.configure(lowRate, settings: flat, sampleRate: 22050)
        require(lowRate.bands[7...9].allSatisfy { $0.bypass }, "Bands above Nyquist must bypass")
        print("PASS: preamp, settings validation and low sample rate")
    }
}
