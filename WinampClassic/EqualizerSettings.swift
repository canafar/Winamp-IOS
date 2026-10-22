import Foundation

struct EqualizerSettings: Codable {
    // Frequencies printed on the original classic skin (not the ISO variant).
    static let frequencies: [Float] = [70, 180, 320, 600, 1000, 3000, 6000, 12000, 14000, 16000]
    var enabled = true
    var preamp: Float = 0
    var gains = [Float](repeating: 0, count: 10)

    func sanitized() -> EqualizerSettings {
        var result = self
        result.preamp = Self.clamp(preamp)
        result.gains = (0..<10).map { Self.clamp(gains.indices.contains($0) ? gains[$0] : 0) }
        return result
    }

    static func clamp(_ value: Float) -> Float { value.isFinite ? max(-12, min(12, value)) : 0 }

    // Original CreateEQPresets raw slider positions, pinned source revision in EQ-PRESETS.md.
    static let classicPositions: [(String, [Int])] = [
        ("Classical", [31,31,31,31,31,31,44,44,44,48]),
        ("Club", [31,31,26,22,22,22,26,31,31,31]),
        ("Dance", [16,20,28,32,32,42,44,44,32,32]),
        ("Flat", [31,31,31,31,31,31,31,31,31,31]),
        ("Laptop speakers/headphones", [24,14,23,38,36,29,24,16,11,8]),
        ("Large hall", [15,15,22,22,31,40,40,40,31,31]),
        ("Party", [20,20,31,31,31,31,31,31,20,20]),
        ("Pop", [35,24,20,19,23,34,36,36,35,35]),
        ("Reggae", [31,31,33,42,31,21,21,31,31,31]),
        ("Rock", [19,24,41,45,38,25,17,14,14,14]),
        ("Soft", [24,29,34,36,34,25,18,16,14,12]),
        ("Ska", [36,40,39,33,25,22,17,16,14,16]),
        ("Full Bass", [16,16,16,22,29,39,46,49,50,50]),
        ("Soft Rock", [25,25,28,33,39,41,38,33,27,17]),
        ("Full Treble", [48,48,48,39,27,14,6,6,6,4]),
        ("Full Bass & Treble", [20,22,31,44,40,29,18,14,12,12]),
        ("Live", [40,31,25,23,22,22,25,27,27,28]),
        ("Techno", [19,22,31,41,40,31,19,16,16,17]),
    ]

    // Winamp In.cpp VALTODB: center 31, asymmetric 31/32 steps to +/-12 dB.
    static func classicGain(_ position: Int) -> Float {
        let delta = max(-31, min(32, position - 31))
        return delta > 0 ? -12 * Float(delta) / 32 : -12 * Float(delta) / 31
    }

    static let classicPresets: [(String, EqualizerSettings)] = classicPositions.map { name, positions in
        (name, EqualizerSettings(preamp: 0, gains: positions.map { classicGain($0) }))
    }
    // Keep the two earlier custom presets available without calling them upstream presets.
    static let presets: [(String, EqualizerSettings)] = classicPresets + [
        ("Bass (iOS)", EqualizerSettings(preamp: -6, gains: [6, 5, 3, 1, 0, 0, 0, 0, 0, 0])),
        ("Vocal (iOS)", EqualizerSettings(preamp: -4, gains: [-2, -1, 0, 2, 4, 3, 1, -1, -2, -2]))
    ]
}
