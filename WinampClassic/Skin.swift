import UIKit
import AVFoundation

enum Skin {
    static let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String, _ source: CGRect? = nil) -> UIImage {
        let key = name + (source.map { NSCoder.string(for: $0) } ?? "")
        if let cached = cache[key] { return cached }
        guard let image = UIImage(named: name) else { preconditionFailure("Missing skin image: \(name)") }
        let result: UIImage
        if let source = source {
            guard let crop = image.cgImage?.cropping(to: source) else { preconditionFailure("Bad sprite: \(key)") }
            result = UIImage(cgImage: crop, scale: 1, orientation: .up)
        } else { result = image }
        cache[key] = result
        return result
    }

    static func draw(_ name: String, _ source: CGRect, at point: CGPoint) {
        image(name, source).draw(in: CGRect(origin: point, size: source.size))
    }

    static func text(_ value: String, at point: CGPoint, limit: Int) {
        let normalized = value.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "ı", with: "i").uppercased()
        let punctuation = Array(".:()-'!_+\\/[]~&%,=$#")
        for (offset, char) in normalized.prefix(limit).enumerated() {
            let x: Int
            let y: Int
            if let ascii = char.asciiValue, (65...90).contains(ascii) { x = Int(ascii - 65); y = 0 }
            else if let digit = char.wholeNumberValue, digit < 10 { x = digit; y = 6 }
            else if let i = punctuation.firstIndex(of: char) { x = i + 11; y = 6 }
            else if char == " " { x = 30; y = 0 }
            else { x = 3; y = 12 }
            draw("text", CGRect(x: x * 5, y: y, width: 5, height: 6), at: CGPoint(x: point.x + CGFloat(offset * 5), y: point.y))
        }
    }

    static func button(_ name: String, normal: CGRect, pressed: CGRect? = nil,
                       at point: CGPoint, label: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(origin: point, size: normal.size)
        button.setImage(image(name, normal), for: .normal)
        if let pressed = pressed { button.setImage(image(name, pressed), for: .highlighted) }
        button.imageView?.layer.magnificationFilter = .nearest
        button.imageView?.layer.minificationFilter = .nearest
        button.accessibilityLabel = label
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}

final class SkinSlider: UIControl {
    enum Kind { case volume, balance, position }
    let kind: Kind
    var value: CGFloat = 0 { didSet {
        value = kind == .balance ? BalanceControl.snapped(value) : max(0, min(1, value))
        setNeedsDisplay()
        accessibilityValue = kind == .balance ? BalanceControl.label(value) : "\(Int(value * 100))%"
    } }
    var onChange: ((CGFloat) -> Void)?
    var onTrackingChanged: ((Bool) -> Void)?

    init(kind: Kind, frame: CGRect, label: String) {
        self.kind = kind
        super.init(frame: frame)
        backgroundColor = .clear
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
        layer.minificationFilter = .nearest
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityTraits = .adjustable
        if kind == .balance {
            let reset = UITapGestureRecognizer(target: self, action: #selector(centerBalance))
            reset.numberOfTapsRequired = 2
            addGestureRecognizer(reset)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.interpolationQuality = .none
        switch kind {
        case .volume:
            Skin.draw("volume", CGRect(x: 0, y: Int(value * 27) * 15, width: 68, height: 13), at: .zero)
            Skin.draw("volume", CGRect(x: isTracking ? 0 : 15, y: 422, width: 14, height: 11), at: CGPoint(x: floor(value * 51), y: 1))
        case .balance:
            Skin.draw("balance", CGRect(x: 9, y: Int(abs(value * 2 - 1) * 27) * 15, width: 38, height: 13), at: .zero)
            Skin.draw("balance", CGRect(x: isTracking ? 0 : 15, y: 422, width: 14, height: 11), at: CGPoint(x: floor(value * 24), y: 1))
        case .position:
            Skin.draw("posbar", CGRect(x: 0, y: 0, width: 248, height: 10), at: .zero)
            Skin.draw("posbar", CGRect(x: isTracking ? 278 : 248, y: 0, width: 29, height: 10), at: CGPoint(x: floor(value * 219), y: 0))
        }
    }

    private func update(_ touch: UITouch) {
        let thumb: CGFloat = kind == .position ? 29 : 14
        let travel: CGFloat = kind == .volume ? 51 : bounds.width - thumb
        value = (touch.location(in: self).x - thumb / 2) / travel
        onChange?(value)
    }
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { onTrackingChanged?(true); update(touch); return true }
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { update(touch); return true }
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) { if let touch = touch { update(touch) }; onTrackingChanged?(false); setNeedsDisplay() }
    override func cancelTracking(with event: UIEvent?) { onTrackingChanged?(false); setNeedsDisplay() }
    override func accessibilityIncrement() { value += 0.05; onChange?(value) }
    override func accessibilityDecrement() { value -= 0.05; onChange?(value) }
    @objc private func centerBalance() { value = 0.5; onChange?(value) }
}

final class MainPanel: UIView {
    weak var store: PlayerStore?
    var playlistVisible = true
    var remaining = false
    var scrollTick = 0
    private var status = PanelStatus()
    var heldStatus: String?
    private var lastTitle = ""

    func showStatus(_ text: String) {
        status.show(text, at: ProcessInfo.processInfo.systemUptime)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let store = store else { return }
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .none
        Skin.image("main_base").draw(at: .zero)
        let total = PlaybackTime.seconds(position: store.position, duration: store.duration, remaining: remaining)
        let digits = [min(99, total / 60) / 10, min(99, total / 60) % 10, total % 60 / 10, total % 10]
        for (x, digit) in zip([48, 60, 78, 90], digits) {
            Skin.draw("numbers", CGRect(x: digit * 9, y: 0, width: 9, height: 13), at: CGPoint(x: x, y: 26))
        }
        if remaining { Skin.green.setFill(); UIRectFill(CGRect(x: 40, y: 32, width: 5, height: 1)) }
        let icon = store.playing ? 0 : (store.position > 0 ? 9 : 18)
        Skin.draw("playpaus", CGRect(x: icon, y: 0, width: 9, height: 9), at: CGPoint(x: 26, y: 28))
        if store.playing { Skin.draw("playpaus", CGRect(x: 36, y: 0, width: 3, height: 9), at: CGPoint(x: 24, y: 28)) }
        var title = store.title
        if lastTitle != title { lastTitle = title; scrollTick = 0 }
        var textOffset: CGFloat = 0
        if title.count > 30 {
            let loop = Array(title + "   ***   ")
            let start = (scrollTick / 5) % loop.count
            textOffset = CGFloat(scrollTick % 5)
            title = String((0..<32).map { loop[(start + $0) % loop.count] })
        }
        if let message = heldStatus ?? status.text(at: ProcessInfo.processInfo.systemUptime) {
            title = message
            textOffset = 0
        }
        context?.saveGState()
        context?.clip(to: CGRect(x: 111, y: 25, width: 154, height: 9))
        Skin.text(title, at: CGPoint(x: 111 - textOffset, y: 27), limit: 32)
        context?.restoreGState()
        if let player = store.player {
            let sampleRate = Int(player.sourceSampleRate / 1000)
            Skin.text(player.bitrateKbps.map { String(format: "%3d", min(999, $0)) } ?? "---", at: CGPoint(x: 111, y: 43), limit: 3)
            Skin.text(String(sampleRate), at: CGPoint(x: 156, y: 43), limit: 2)
            Skin.draw("monoster", CGRect(x: 29, y: player.numberOfChannels == 1 ? 0 : 12, width: 28, height: 12), at: CGPoint(x: 212, y: 41))
            Skin.draw("monoster", CGRect(x: 0, y: player.numberOfChannels >= 2 ? 0 : 12, width: 29, height: 12), at: CGPoint(x: 239, y: 41))

        }
    }
}
