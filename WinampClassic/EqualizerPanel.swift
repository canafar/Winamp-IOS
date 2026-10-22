import UIKit

final class EQSlider: UIControl {
    var gain: Float = 0 {
        didSet {
            gain = EqualizerSettings.clamp(gain)
            accessibilityValue = String(format: "%+.1f dB", gain)
            setNeedsDisplay()
        }
    }
    var changed: ((Float) -> Void)?

    init(x: CGFloat, label: String) {
        super.init(frame: CGRect(x: x, y: 38, width: 14, height: 63))
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityTraits = .adjustable
        let reset = UITapGestureRecognizer(target: self, action: #selector(resetGain))
        reset.numberOfTapsRequired = 2
        addGestureRecognizer(reset)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.interpolationQuality = .none
        let position = Int((12 - gain) / 24 * 63)
        let frame = 27 - position * 28 / 64
        Skin.draw("eqmain", CGRect(x: 13 + (frame % 14) * 15, y: frame < 14 ? 164 : 229, width: 14, height: 63), at: .zero)
        Skin.draw("eqmain", CGRect(x: 0, y: isTracking ? 176 : 164, width: 11, height: 11),
                  at: CGPoint(x: 1, y: 51 - (63 - position) * 52 / 64))
    }

    private func update(_ touch: UITouch) {
        let fraction = max(0, min(1, (touch.location(in: self).y - 5.5) / 51))
        let value = Float(12 - fraction * 24)
        gain = abs(value) < 0.35 ? 0 : value
        changed?(gain)
    }
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { update(touch); return true }
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { update(touch); return true }
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) { if let touch = touch { update(touch) }; setNeedsDisplay() }
    override func cancelTracking(with event: UIEvent?) { setNeedsDisplay() }
    override func accessibilityIncrement() { gain += 1; changed?(gain) }
    override func accessibilityDecrement() { gain -= 1; changed?(gain) }
    @objc private func resetGain() { gain = 0; changed?(gain) }
}

final class EqualizerPanel: UIView {
    private let store: PlayerStore
    private var sliders: [EQSlider] = []
    private var onButton: UIButton!
    private var autoButton: UIButton!
    private(set) var presetsButton: UIButton!
    var close: (() -> Void)?
    var showPresets: (() -> Void)?

    init(store: PlayerStore) {
        self.store = store
        super.init(frame: CGRect(x: 0, y: 116, width: 275, height: 116))
        backgroundColor = .black
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
        for i in 0..<11 {
            let label = i == 0 ? "Preamp" : "\(Int(EqualizerSettings.frequencies[i - 1])) Hz"
            let slider = EQSlider(x: CGFloat(i == 0 ? 21 : 78 + (i - 1) * 18), label: label)
            slider.changed = { [weak self] gain in
                guard let self = self else { return }
                var settings = self.store.eqSettings
                if i == 0 { settings.preamp = gain } else { settings.gains[i - 1] = gain }
                self.store.setEqualizer(settings)
            }
            addSubview(slider)
            sliders.append(slider)
        }
        onButton = Skin.button("eqmain", normal: CGRect(x: 69, y: 119, width: 25, height: 12), at: CGPoint(x: 14, y: 18), label: "Ekolayzır açık / kapalı") { [weak self] in
            guard let self = self else { return }
            var settings = self.store.eqSettings
            settings.enabled.toggle()
            self.store.setEqualizer(settings)
        }
        autoButton = Skin.button("eqmain", normal: CGRect(x: 35, y: 119, width: 33, height: 12), at: CGPoint(x: 39, y: 18), label: "Parçaya özel EQ ayarlarını hatırla") { [weak self] in
            guard let self = self else { return }; self.store.setEQAuto(!self.store.eqAuto)
        }
        presetsButton = Skin.button("eqmain", normal: CGRect(x: 224, y: 164, width: 44, height: 12), pressed: CGRect(x: 224, y: 176, width: 44, height: 12), at: CGPoint(x: 217, y: 18), label: "Ekolayzır hazır ayarları") { [weak self] in self?.showPresets?() }
        [onButton!, autoButton!, presetsButton!].forEach { addSubview($0) }
        addSubview(Skin.button("eqmain", normal: CGRect(x: 0, y: 116, width: 9, height: 9), pressed: CGRect(x: 0, y: 125, width: 9, height: 9), at: CGPoint(x: 264, y: 3), label: "EQ panelini gizle") { [weak self] in self?.close?() })
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh() {
        let settings = store.eqSettings
        for (i, slider) in sliders.enumerated() where !slider.isTracking {
            slider.gain = i == 0 ? settings.preamp : settings.gains[i - 1]
        }
        onButton.setImage(Skin.image("eqmain", CGRect(x: settings.enabled ? 69 : 10, y: 119, width: 25, height: 12)), for: .normal)
        onButton.setImage(Skin.image("eqmain", CGRect(x: settings.enabled ? 187 : 128, y: 119, width: 25, height: 12)), for: .highlighted)
        autoButton.setImage(Skin.image("eqmain", CGRect(x: store.eqAuto ? 94 : 35, y: 119, width: 33, height: 12)), for: .normal)
        autoButton.setImage(Skin.image("eqmain", CGRect(x: store.eqAuto ? 212 : 153, y: 119, width: 33, height: 12)), for: .highlighted)
        onButton.accessibilityValue = settings.enabled ? "Açık" : "Kapalı"
        autoButton.accessibilityValue = store.eqAuto ? "Açık" : "Kapalı"
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.interpolationQuality = .none
        Skin.draw("eqmain", CGRect(x: 0, y: 0, width: 275, height: 116), at: .zero)
        Skin.draw("eqmain", CGRect(x: 0, y: 134, width: 275, height: 14), at: .zero)
        Skin.draw("eqmain", CGRect(x: 0, y: 294, width: 113, height: 19), at: CGPoint(x: 86, y: 17))
        // Display the slider gain curve. This is not a measured frequency response.
        context.saveGState()
        context.clip(to: CGRect(x: 86, y: 17, width: 113, height: 19))
        let settings = store.eqSettings
        let preampY = 17 + CGFloat(12 - settings.preamp) / 24 * 18
        UIColor.gray.setStroke()
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 86, y: preampY)); context.addLine(to: CGPoint(x: 199, y: preampY)); context.strokePath()
        UIColor(red: 0.85, green: 0.85, blue: 0.4, alpha: 1).setStroke()
        for (i, gain) in settings.gains.enumerated() {
            let p = CGPoint(x: 88 + CGFloat(i) * 12, y: 17 + CGFloat(12 - gain) / 24 * 18)
            if i == 0 { context.move(to: p) } else { context.addLine(to: p) }
        }
        context.strokePath()
        context.restoreGState()
    }
}
