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

/// Port of classic_vis.cpp makeSpecData / SABuffer: 512-point Hann FFT,
/// stereo sum, warped bins and Hermite integration. 75 source columns are
/// grouped into the original 19 visual bars (EQ stays 10).
final class SpectrumAnalyzer {
    static let barCount = 19
    private let window = (0..<512).map { Float(0.5 - 0.5 * cos(2 * Double.pi * Double($0) / 511)) }
    private let setup: FFTSetup
    init() {
        guard let fft = vDSP_create_fftsetup(9, FFTRadix(kFFTRadix2)) else { fatalError("FFT setup") }
        setup = fft
    }
    deinit { vDSP_destroy_fftsetup(setup) }
    struct Frame {
        let bands: [Float]
        let scope: [Float]
        static let silent = Frame(bands: Array(repeating: 0, count: 19), scope: Array(repeating: 0, count: 75))
    }
    // Same polynomial exp2 approximation as classic_vis.cpp fpow2.
    static func sourcePower(_ x: Double) -> Double {
        let y = x / 12
        let integer = floor(y), fraction = y - integer
        return pow(2, integer) * (0.33977 * fraction * fraction + 0.66023 * fraction + 1)
    }
    static func sourceBin(_ x: Double) -> Double {
        (sourcePower(x) - 1) * (255 / sourcePower(75)) + 1
    }
    static func edges(sampleRate: Double) -> [Double] {
        (0...barCount).map { sourceBin(Double(min(75, $0 * 4))) * sampleRate / 512 }
    }
    private func hermite(_ x: Float, _ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        let c1 = 0.5 * (c - a)
        let c3 = 1.5 * (b - c) + 0.5 * (d - a)
        let c2 = a - b + c1 - c3
        return ((c3 * x + c2) * x + c1) * x + b
    }
    func analyze(_ snapshot: SpectrumCapture.Snapshot) -> Frame {
        guard snapshot.left.count >= 576, snapshot.right.count == snapshot.left.count,
              snapshot.sampleRate.isFinite, snapshot.sampleRate > 80 else { return .silent }
        let offset = snapshot.left.count - 512
        var real = (0..<512).map { i -> Float in
            return (snapshot.left[offset+i] + snapshot.right[offset+i]) * window[i]
        }
        var imaginary = [Float](repeating: 0, count: 512)
        real.withUnsafeMutableBufferPointer { re in
            imaginary.withUnsafeMutableBufferPointer { im in
                var split = DSPSplitComplex(realp: re.baseAddress!, imagp: im.baseAddress!)
                vDSP_fft_zip(setup, &split, 1, 9, FFTDirection(FFT_FORWARD))
            }
        }
        var magnitudes = (0..<256).map { sqrt(real[$0]*real[$0] + imaginary[$0]*imaginary[$0]) * 0.5 }
        // IPP RToPerm stores Nyquist in the imaginary slot of bin zero.
        magnitudes[0] = sqrt(real[0]*real[0] + real[256]*real[256]) * 0.5
        var columns = [Float]()
        for x in 0..<75 {
            var binF = Float(Self.sourceBin(Double(x)))
            let next = Float(Self.sourceBin(Double(x+1)))
            var bin = Int(floor(binF))
            let end = min(Int(floor(next)), 255)
            var mult = Float(bin+1) - binF
            var interpolate = true
            var value: Float = 0
            repeat {
                if bin == end { mult = next - binF; interpolate = true }
                if interpolate {
                    value += hermite(binF-Float(bin), magnitudes[max(0,bin-1)], magnitudes[bin],
                        bin < 255 ? magnitudes[bin+1] : 0, bin < 254 ? magnitudes[bin+2] : 0) * mult
                } else { value += magnitudes[bin] }
                interpolate = false; bin += 1; binF = Float(bin)
            } while bin <= end
            columns.append(Float(Int(max(0, min(255, value)))))
        }
        let bands: [Float] = (0..<Self.barCount).map { i in
            let sum = (0..<4).reduce(Float(0)) { total, j in
                let index = i * 4 + j
                return total + (index < 75 ? columns[index] : 0)
            }
            return min(15, floor(sum / 4)) / 15
        }
        let scope = (0..<75).map { i -> Float in
            let index = snapshot.left.count - 576 + Int(Double(i) * 576 / 75)
            let left = floor(max(-1, min(127.0/128, snapshot.left[index])) * 128)
            let right = floor(max(-1, min(127.0/128, snapshot.right[index])) * 128)
            return Float(Int((left + right) / 16)) / 8
        }
        return Frame(bands: bands, scope: scope)
    }
}
