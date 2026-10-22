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

struct SpectrumEnvelope {
    var height: Float = 0
    var peak: Float = 0
    private var hold: Float = 0

    mutating func update(level: Float, dt: Float) {
        let delta = max(0, min(0.1, dt))
        height = max(max(0, min(1, level)), height - delta * 1.8)
        if height >= peak && height > 0 {
            peak = height
            hold = 0.25
        } else {
            let fallingTime = max(0, delta - hold)
            hold = max(0, hold - delta)
            peak = max(height, peak - fallingTime * 0.4)
        }
    }
}
