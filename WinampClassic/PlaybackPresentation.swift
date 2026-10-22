import Foundation

struct Track: Codable {
    let filename: String
    let title: String
    // Optional so playlists saved by earlier versions still decode.
    var duration: Double? = nil
}

enum PlaybackTime {
    static func seconds(position: Double, duration: Double, remaining: Bool) -> Int {
        let value = remaining ? ceil(max(0, duration - position)) : floor(max(0, position))
        return value.isFinite ? Int(min(value, 5999999)) : 0
    }
    static func label(_ duration: Double?) -> String {
        guard let duration = duration, duration.isFinite, duration >= 0 else { return "--:--" }
        let total = seconds(position: duration, duration: duration, remaining: false)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// draw_sa.cpp defaults: fo[2] = 12, pfo[1] = 1.1; SA.cpp step = 16 ms.
struct SpectrumEnvelope {
    private var bar = 0
    private var peakPosition = 0
    private var velocity: Float = 3
    private var accumulator: Float = 0
    private(set) var height: Float = 0
    private(set) var peak: Float = 0
    mutating func update(level: Float, dt: Float) {
        accumulator += max(0, min(0.1, dt))
        while accumulator + 0.000001 >= 0.016 {
            accumulator = max(0, accumulator - 0.016)
            var value = Int(max(0, min(1, level)) * 15)
            if value * 16 < bar { bar -= 12; value = max(0, bar >> 4) }
            else { bar = value * 16 }
            bar = max(0, bar)
            if peakPosition <= value * 256 {
                peakPosition = value * 256
                velocity = 3
            }
            height = Float(value) / 15
            peak = Float(peakPosition / 256) / 15
            peakPosition = max(0, peakPosition - Int(velocity))
            velocity = min(4096, velocity * 1.1)
        }
    }
}

enum PlaylistDuration {
    static func summary(_ durations: [Double?]) -> String {
        let known = durations.compactMap { $0 }.filter { $0.isFinite && $0 >= 0 }
        let seconds = known.reduce(0) { $0 + Int(min($1, 5999999)) }
        let unknown = known.count != durations.count
        if seconds == 0 { return unknown ? "?" : "0:00" }
        let value = seconds < 3600 ? String(format: "%d:%02d", seconds/60, seconds%60)
            : String(format: "%d:%02d:%02d", seconds/3600, (seconds/60)%60, seconds%60)
        return value + (unknown ? "+" : "")
    }
}
