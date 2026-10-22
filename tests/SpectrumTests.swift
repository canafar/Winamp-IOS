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
        require(SpectrumAnalyzer.barCount == 19 && EqualizerSettings.frequencies.count == 10, "Visual bands must be independent of EQ")
        for rate in [22050.0, 44100.0, 48000.0] {
            let edges = SpectrumAnalyzer.edges(sampleRate: rate)
            for expected in [3,7,11,15] {
                let frequency = (edges[expected] + edges[expected+1]) / 2
                let samples = tone(frequency, sampleRate: rate)
                let normal = analyzer.analyze(snapshot(samples, samples, rate: rate))
                let reversed = analyzer.analyze(snapshot(samples, samples.map { -$0 }, rate: rate))
                require(reversed.bands.allSatisfy { $0 == 0 }, "Source sums stereo before FFT")
                let peak = normal.bands.indices.max { normal.bands[$0] < normal.bands[$1] }!
                require(peak == expected, "Tone mapped to wrong source group")
                let quieter = tone(frequency, sampleRate: rate, amplitude: 0.025)
                let quiet = analyzer.analyze(snapshot(quieter, quieter, rate: rate))
                require(normal.bands[peak] > quiet.bands[peak], "Spectrum ignored amplitude")
                require(normal.bands.count == 19 && normal.scope.count == 75, "Wrong source geometry")
                if expected == 3 {
                    // Independent NumPy FFT + original integration equations, 512-sample Hann.
                    let golden: [Float] = [0,0,1,11,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                    require(zip(normal.bands, golden).allSatisfy { abs($0.0*15-$0.1) < 0.01 }, "Source FFT golden vector mismatch")
                }
            }
        }
        var envelope = SpectrumEnvelope()
        envelope.update(level: 1, dt: 0.016)
        require(envelope.height == 1 && envelope.peak == 1, "Instant source attack")
        envelope.update(level: 0, dt: 0.016)
        require(abs(envelope.height - 14.0/15) < 0.0001, "Source falloff must be 12/16 pixels per 16 ms")
        var at60 = SpectrumEnvelope(), at120 = SpectrumEnvelope()
        at60.update(level: 1, dt: 0.016); at120.update(level: 1, dt: 0.016)
        for _ in 0..<30 { at60.update(level: 0, dt: 1.0/60) }
        for _ in 0..<60 { at120.update(level: 0, dt: 1.0/120) }
        require(at60.height == at120.height && at60.peak == at120.peak, "Animation speed depends on display refresh")
        require(at60.peak > at60.height, "Detached source peak missing")
        for _ in 0..<120 { envelope.update(level: 0, dt: 0.016) }
        require(envelope.peak == 0 && envelope.height == 0, "Silent peaks did not clear")
        require(PlaylistDuration.summary([190,2420]) == "43:30", "Total playlist duration")
        require(PlaylistDuration.summary([3600,61]) == "1:01:01", "Long playlist duration")
        require(PlaylistDuration.summary([190,nil]) == "3:10+", "Unknown durations must not pretend to be complete")
        require(PlaylistDuration.summary([nil]) == "?", "Unknown duration")
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
        print("PASS: source peak acceleration/decay, time modes, legacy playlist, duration persistence, bundled MP3 decode")
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
        print("PASS: silence, source FFT, variable tap sizes, mono, ring wrap and reset")
    }
}
