import Foundation
import AVFoundation

@main
enum SpectrumTests {
    static func require(_ condition: Bool, _ message: String) {
        if !condition { fatalError(message) }
    }
    static func tone(_ frequency: Double, sampleRate: Double, amplitude: Float = 0.25) -> [Float] {
        (0..<SpectrumCapture.capacity).map { amplitude * Float(sin(2 * Double.pi * frequency * Double($0) / sampleRate)) }
    }
    static func snapshot(_ left: [Float], _ right: [Float], rate: Double = 48000) -> SpectrumCapture.Snapshot {
        SpectrumCapture.Snapshot(left: left, right: right, sampleRate: rate, revision: 1)
    }
    static func main() throws {
        let analyzer = SpectrumAnalyzer()
        let zero = Array(repeating: Float(0), count: SpectrumCapture.capacity)
        let silence = analyzer.analyze(snapshot(zero, zero))
        require(silence.bands.allSatisfy { $0 == 0 }, "Silence must be silent")
        let dc = Array(repeating: Float(0.5), count: SpectrumCapture.capacity)
        require(analyzer.analyze(snapshot(dc, dc)).bands.allSatisfy { $0 == 0 }, "DC leaked into frequency display")
        for rate in [22050.0, 44100.0, 48000.0] {
            var lastPeak = -1
            for frequency in EqualizerSettings.frequencies.map({ Double($0) }).filter({ $0 < rate / 2 }) {
                let samples = tone(frequency, sampleRate: rate)
                let normal = analyzer.analyze(snapshot(samples, samples, rate: rate))
                let reversed = analyzer.analyze(snapshot(samples, samples.map { -$0 }, rate: rate))
                require(zip(normal.bands, reversed.bands).allSatisfy { pair in abs(pair.0 - pair.1) < 0.0001 }, "Anti-phase stereo cancelled spectrum")
                let peak = normal.bands.indices.max { normal.bands[$0] < normal.bands[$1] }!
                let edges = SpectrumAnalyzer.edges(sampleRate: rate)
                let expected = (0..<SpectrumAnalyzer.barCount).first { frequency >= edges[$0] && frequency < edges[$0 + 1] }!
                require(peak == expected, "Tone \(frequency) Hz at \(rate) Hz mapped to wrong bar")
                require(peak > lastPeak, "Higher tone must move to the right")
                lastPeak = peak
                let quieter = tone(frequency, sampleRate: rate, amplitude: 0.025)
                let quiet = analyzer.analyze(snapshot(quieter, quieter, rate: rate))
                require(normal.bands[peak] > quiet.bands[peak] + 0.25, "Spectrum ignored amplitude")
                require(normal.bands.count == 10, "Spectrum must have ten EQ regions")
            }
            print("PASS: frequency ordering, amplitude and anti-phase stereo at \(rate) Hz")
        }
        var envelope = SpectrumEnvelope()
        envelope.update(level: 1, dt: 0.1)
        envelope.update(level: 0, dt: 0.1)
        require(envelope.peak == 1 && envelope.height < 1, "Peak did not detach from falling bar")
        envelope.update(level: 0, dt: 0.1)
        require(envelope.peak == 1, "Peak fell before hold elapsed")
        envelope.update(level: 0, dt: 0.1)
        require(envelope.peak < 1 && envelope.peak > envelope.height, "Peak did not fall slowly")
        for _ in 0..<40 { envelope.update(level: 0, dt: 0.1) }
        require(envelope.peak == 0 && envelope.height == 0, "Silent peaks did not clear")
        require(PlaybackTime.seconds(position: 61.2, duration: 180, remaining: false) == 61, "Elapsed time")
        require(PlaybackTime.seconds(position: 61.2, duration: 180, remaining: true) == 119, "Remaining time")
        require(PlaybackTime.seconds(position: 181, duration: 180, remaining: true) == 0, "Negative remainder")
        require(PlaybackTime.label(185) == "3:05" && PlaybackTime.label(nil) == "--:--", "Playlist formatting")
        let legacy = Data(#"[{"filename":"old.mp3","title":"Old track"}]"#.utf8)
        let old = try JSONDecoder().decode([Track].self, from: legacy)
        require(old.count == 1 && old[0].duration == nil, "Legacy playlist migration")
        let saved = [Track(filename: "new.mp3", title: "New", duration: 185)]
        let decoded = try JSONDecoder().decode([Track].self, from: JSONEncoder().encode(saved))
        require(decoded[0].duration == 185, "Duration persistence")
        let intro = try AVAudioFile(forReading: URL(fileURLWithPath: "WinampClassic/Resources/intro.mp3"))
        let introBuffer = AVAudioPCMBuffer(pcmFormat: intro.processingFormat, frameCapacity: 2048)!
        try intro.read(into: introBuffer)
        require(intro.length > 0 && introBuffer.frameLength > 0, "Bundled intro failed to decode")
        print("PASS: peak hold/decay, time modes, legacy playlist, duration persistence, bundled MP3 decode")
        let capture = SpectrumCapture()
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 257)!
        buffer.frameLength = 257
        for part in 0..<10 {
            for i in 0..<257 { buffer.floatChannelData![0][i] = Float(part * 257 + i) }
            capture.ingest(buffer)
        }
        let captured = capture.snapshot()
        require(captured.left == captured.right, "Mono channel was not mirrored")
        require(captured.left.first == 522 && captured.left.last == 2569, "Ring did not preserve latest samples in time order")
        capture.reset()
        require(capture.snapshot().left.allSatisfy { $0 == 0 }, "Reset retained old audio")
        print("PASS: silence, DC rejection, variable tap sizes, mono, ring wrap and reset")
    }
}
