import AVFoundation

enum EqualizerDSP {
    static func configure(_ equalizer: AVAudioUnitEQ, settings: EqualizerSettings, sampleRate: Double) {
        precondition(equalizer.bands.count == EqualizerSettings.frequencies.count)
        let settings = settings.sanitized()
        for (i, band) in equalizer.bands.enumerated() {
            let frequency = EqualizerSettings.frequencies[i]
            band.filterType = .parametric
            band.frequency = min(frequency, Float(sampleRate * 0.45))
            band.bandwidth = 1.0
            band.gain = settings.gains[i]
            // Above Nyquist there is no signal for this band to process.
            band.bypass = !settings.enabled || frequency >= Float(sampleRate * 0.5)
        }
        equalizer.globalGain = settings.enabled ? settings.preamp : 0
    }
}
