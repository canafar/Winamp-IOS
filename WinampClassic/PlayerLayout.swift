import Foundation

/// All dimensions below are classic skin pixels until transformed by scale.
struct PlayerLayout {
    let scale: CGFloat
    let height: CGFloat
    let playlistY: CGFloat
    let playlistHeight: CGFloat

    init(width: CGFloat, availableHeight: CGFloat, equalizer: Bool, playlist: Bool) {
        let fixed: CGFloat = equalizer ? 232 : 116
        let minimum = fixed + (playlist ? 96 : 0)
        scale = max(0.01, min(width / 275, availableHeight / minimum))
        height = max(minimum, availableHeight / scale)
        playlistY = fixed
        playlistHeight = max(96, height - fixed)
    }
}

enum BalanceControl {
    /// Center latch: enter at 49...51 percent; leave only beyond that interval.
    static func snapped(_ value: CGFloat) -> CGFloat {
        let clamped = value.isFinite ? max(0, min(1, value)) : 0.5
        return (0.49...0.51).contains(clamped) ? 0.5 : clamped
    }
    static func percentages(_ value: CGFloat) -> (left: Int, right: Int) {
        let right = Int((snapped(value) * 100).rounded())
        return (100 - right, right)
    }
    static func label(_ value: CGFloat) -> String {
        let p = percentages(value)
        return "BAL L\(p.left)% R\(p.right)%"
    }
}
