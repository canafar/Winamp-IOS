import UIKit

final class PlaylistFooterView: UIView {
    weak var store: PlayerStore?
    var remaining = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
    }
    convenience init() { self.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ rect: CGRect) {
        guard let store = store, let context = UIGraphicsGetCurrentContext() else { return }
        context.interpolationQuality = .none
        let selected = store.index.flatMap { store.tracks.indices.contains($0) ? store.tracks[$0].duration : nil }
        let total = PlaylistDuration.summary(store.tracks.map { $0.duration })
        let selection = store.index == nil ? "0:00" : PlaylistDuration.summary([selected])
        context.saveGState()
        context.clip(to: CGRect(x: 132, y: 10, width: 90, height: 6))
        UIColor.black.setFill(); UIRectFill(CGRect(x: 132, y: 10, width: 90, height: 6))
        Skin.text(selection + "/" + total, at: CGPoint(x: 132, y: 10), limit: 18)
        context.restoreGState()
        let seconds = PlaybackTime.seconds(position: store.position, duration: store.duration, remaining: remaining)
        let clock = (remaining ? "-" : " ") + String(format: "%02d:%02d", min(99, seconds / 60), seconds % 60)
        context.saveGState()
        context.clip(to: CGRect(x: 189, y: 23, width: 34, height: 6))
        UIColor.black.setFill(); UIRectFill(CGRect(x: 189, y: 23, width: 34, height: 6))
        Skin.text(clock, at: CGPoint(x: 193, y: 23), limit: 6)
        context.restoreGState()
    }
}
