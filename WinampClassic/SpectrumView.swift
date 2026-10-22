import UIKit

/// Nineteen original frequency groups in the classic 76x16 area; tap for a connected line.
final class SpectrumView: UIControl {
    // Default classic palette, bottom to top (upstream draw.cpp).
    private static let palette: [UIColor] = [
        (24,132,8), (41,148,0), (49,156,8), (57,181,16),
        (50,190,16), (41,206,16), (148,222,33), (189,222,41),
        (214,181,33), (222,165,24), (198,123,8), (214,115,0),
        (214,102,0), (214,90,0), (206,41,16), (239,49,16)
    ].map { UIColor(red: CGFloat($0.0)/255, green: CGFloat($0.1)/255, blue: CGFloat($0.2)/255, alpha: 1) }
    private let analyzer = SpectrumAnalyzer()
    private weak var lastPlayer: EnginePlayer?
    private var lastRevision: UInt64?
    private var signal = SpectrumAnalyzer.Frame.silent
    private var envelopes = Array(repeating: SpectrumEnvelope(), count: SpectrumAnalyzer.barCount)
    private var lastUpdate = CACurrentMediaTime()
    private var lastSignalTime = CACurrentMediaTime()
    private var scopeMode = UserDefaults.standard.bool(forKey: "visualizer.scope")

    init() {
        super.init(frame: CGRect(x: 24, y: 43, width: 76, height: 16))
        backgroundColor = .black
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
        layer.minificationFilter = .nearest
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Spektrum görünümü"
        accessibilityHint = "19 frekans çubuğu ve osiloskop arasında geçiş yapar"
        updateAccessibility()
        addAction(UIAction { [weak self] _ in self?.toggleMode() }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func toggleMode() {
        scopeMode.toggle()
        UserDefaults.standard.set(scopeMode, forKey: "visualizer.scope")
        updateAccessibility()
        setNeedsDisplay()
    }
    override func accessibilityActivate() -> Bool { toggleMode(); return true }
    private func updateAccessibility() { accessibilityValue = scopeMode ? "Osiloskop" : "Frekans çubukları" }

    func update(player: EnginePlayer?, playing: Bool) {
        let now = CACurrentMediaTime()
        let dt = Float(max(0, min(0.1, now - lastUpdate)))
        lastUpdate = now
        if lastPlayer !== player {
            lastPlayer = player; lastRevision = nil
            envelopes = Array(repeating: SpectrumEnvelope(), count: SpectrumAnalyzer.barCount)
        }
        if playing, let player = player {
            let snapshot = player.visualization.snapshot()
            if lastRevision != snapshot.revision {
                signal = analyzer.analyze(snapshot)
                lastRevision = snapshot.revision
                lastSignalTime = now
            }
            if now - lastSignalTime > 0.25 { signal = .silent }
        } else {
            signal = .silent
            lastRevision = nil
        }
        for i in envelopes.indices { envelopes[i].update(level: signal.bands[i], dt: dt) }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setShouldAntialias(false)
        // Preserve the source skin's dotted analyzer background.
        Skin.draw("main", CGRect(x: 24, y: 43, width: 76, height: 16), at: .zero)
        if scopeMode {
            let colors: [UIColor] = [(255,255,255),(214,214,222),(181,189,189),(160,170,175),(148,156,165)].map {
                UIColor(red: CGFloat($0.0)/255, green: CGFloat($0.1)/255, blue: CGFloat($0.2)/255, alpha: 1)
            }
            var previous: Int?
            for i in signal.scope.indices {
                let y = max(0, min(15, 8 + Int(signal.scope[i] * 8)))
                colors[abs(y / 2 - 4)].setFill()
                let from = previous ?? y
                UIRectFill(CGRect(x: i, y: min(from,y), width: 1, height: abs(y-from)+1))
                previous = y
            }
        } else {
            for i in envelopes.indices {
                let left = i * 4
                let width = 3
                let height = Int((envelopes[i].height * 15).rounded())
                for level in 0..<height {
                    Self.palette[level].setFill()
                    UIRectFill(CGRect(x: left, y: 15 - level, width: width, height: 1))
                }
                if envelopes[i].peak > 0.02 {
                    UIColor(white: 150.0/255, alpha: 1).setFill()
                    UIRectFill(CGRect(x: left, y: max(0, 15 - Int((envelopes[i].peak * 15).rounded())), width: width, height: 1))
                }
            }
        }
    }
}
