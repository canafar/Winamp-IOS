import Foundation
import AVFoundation
import Accelerate

/// A bounded stereo ring. The audio thread never waits for the UI and never
/// performs an FFT, dispatches work, or retains an AVAudioPCMBuffer.
final class SpectrumCapture {
    static let capacity = 2048
    private let lock = NSLock()
    private let left = UnsafeMutablePointer<Float>.allocate(capacity: SpectrumCapture.capacity)
    private let right = UnsafeMutablePointer<Float>.allocate(capacity: SpectrumCapture.capacity)
    private var cursor = 0
    private var count = 0
    private var revision: UInt64 = 0
    private var sampleRate: Double = 44100

    init() {
        left.initialize(repeating: 0, count: Self.capacity)
        right.initialize(repeating: 0, count: Self.capacity)
    }
    deinit {
        left.deinitialize(count: Self.capacity); left.deallocate()
        right.deinitialize(count: Self.capacity); right.deallocate()
    }

    func ingest(_ buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0,
              buffer.format.channelCount > 0, lock.try() else { return }
        defer { lock.unlock() }
        sampleRate = buffer.format.sampleRate
        let rightChannel = buffer.format.channelCount > 1 ? 1 : 0
        let length = Int(buffer.frameLength)
        // EnginePlayer's processing format is Float32, non-interleaved.
        for i in max(0, length - Self.capacity)..<length {
            left[cursor] = channels[0][i]
            right[cursor] = channels[rightChannel][i]
            cursor = (cursor + 1) % Self.capacity
        }
        count = min(Self.capacity, count + length)
        revision &+= 1
    }

    struct Snapshot {
        let left: [Float]
        let right: [Float]
        let sampleRate: Double
        let revision: UInt64
    }

    func snapshot() -> Snapshot {
        var l = [Float](repeating: 0, count: Self.capacity)
        var r = l
        // Make the second array unique before taking the lock.
        r.withUnsafeMutableBufferPointer { _ in }
        lock.lock()
        let start = (cursor - count + Self.capacity) % Self.capacity
        for i in 0..<count {
            let source = (start + i) % Self.capacity
            l[Self.capacity - count + i] = left[source]
            r[Self.capacity - count + i] = right[source]
        }
        let rate = sampleRate
        let version = revision
        lock.unlock()
        return Snapshot(left: l, right: r, sampleRate: rate, revision: version)
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        cursor = 0; count = 0; revision &+= 1
    }
}

/// Main-thread analysis. Stereo powers are combined after FFT so opposite-phase
/// channels cannot cancel the spectrum.
final class SpectrumAnalyzer {
    static let barCount = EqualizerSettings.frequencies.count
    private static let log2Size: vDSP_Length = 11
    private let size = SpectrumCapture.capacity
    private let setup: FFTSetup
    private let window: [Float]
    private let amplitudeScale: Float

    init() {
        guard let fft = vDSP_create_fftsetup(Self.log2Size, FFTRadix(kFFTRadix2)) else {
            preconditionFailure("FFT setup could not be created")
        }
        setup = fft
        let n = SpectrumCapture.capacity
        window = (0..<n).map { Float(0.5 - 0.5 * cos(2 * Double.pi * Double($0) / Double(n - 1))) }
        amplitudeScale = 2 / window.reduce(0, +)
    }
    deinit { vDSP_destroy_fftsetup(setup) }

    struct Frame {
        let bands: [Float] // 0...1, -60...0 dBFS display range
        static let silent = Frame(bands: Array(repeating: 0, count: SpectrumAnalyzer.barCount))
    }

    static func edges(sampleRate: Double) -> [Double] {
        let upper = min(20000, sampleRate / 2)
        guard upper > 40 else { return Array(repeating: 0, count: barCount + 1) }
        let centers = EqualizerSettings.frequencies.map { Double($0) }
        let midpoints = (1..<barCount).map { min(upper, sqrt(centers[$0 - 1] * centers[$0])) }
        return [40] + midpoints + [upper]
    }

    private func powers(_ samples: [Float]) -> [Float] {
        let mean = samples.reduce(0, +) / Float(size)
        var real = (0..<size).map { (samples[$0] - mean) * window[$0] }
        var imaginary = [Float](repeating: 0, count: size)
        real.withUnsafeMutableBufferPointer { re in
            imaginary.withUnsafeMutableBufferPointer { im in
                var split = DSPSplitComplex(realp: re.baseAddress!, imagp: im.baseAddress!)
                vDSP_fft_zip(setup, &split, 1, Self.log2Size, FFTDirection(FFT_FORWARD))
            }
        }
        return (0..<(size / 2)).map {
            (real[$0] * real[$0] + imaginary[$0] * imaginary[$0]) * amplitudeScale * amplitudeScale
        }
    }

    func analyze(_ snapshot: SpectrumCapture.Snapshot) -> Frame {
        guard snapshot.left.count == size, snapshot.right.count == size,
              snapshot.sampleRate.isFinite, snapshot.sampleRate > 80 else { return .silent }
        let lp = powers(snapshot.left)
        let rp = powers(snapshot.right)
        let boundaries = Self.edges(sampleRate: snapshot.sampleRate)
        let binHz = snapshot.sampleRate / Double(size)
        let bands: [Float] = (0..<Self.barCount).map { bar in
            guard boundaries[bar] < boundaries[bar + 1] else { return 0 }
            let lower = max(1, min(size / 2 - 1, Int(ceil(boundaries[bar] / binHz))))
            let upper = max(lower + 1, min(size / 2, Int(ceil(boundaries[bar + 1] / binHz))))
            var power: Float = 0
            for bin in lower..<upper { power = max(power, (lp[bin] + rp[bin]) * 0.5) }
            let db = 10 * log10(max(power, 1e-12))
            return max(0, min(1, (db + 60) / 60))
        }
        return Frame(bands: bands)
    }
}
