import UIKit
import MediaPlayer
import AVFoundation

/// A visible, skinned system control. iOS owns the thumb, gestures, accessibility
/// and hardware-button synchronization; there is no second software-volume slider.
final class SystemVolumeView: MPVolumeView {
    private var observation: NSKeyValueObservation?
    private var level = AVAudioSession.sharedInstance().outputVolume
    var trackingChanged: ((Bool, Float) -> Void)?
    private(set) var isAdjusting = false
    var currentLevel: Float { AVAudioSession.sharedInstance().outputVolume }
    var levelChanged: ((Float) -> Void)?

    init() {
        super.init(frame: CGRect(x: 107, y: 57, width: 68, height: 13))
        let touch = VolumeTouchObserver(target: self, action: #selector(observeTouch(_:)))
        touch.cancelsTouchesInView = false
        touch.delaysTouchesBegan = false
        touch.delaysTouchesEnded = false
        addGestureRecognizer(touch)
        showsRouteButton = false
        showsVolumeSlider = true
        backgroundColor = .clear
        contentScaleFactor = 1
        layer.magnificationFilter = .nearest
        layer.minificationFilter = .nearest
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let clearTrack = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format)
            .image { _ in }.resizableImage(withCapInsets: .zero)
        for state: UIControl.State in [.normal, .highlighted, .disabled] {
            setMinimumVolumeSliderImage(clearTrack, for: state)
            setMaximumVolumeSliderImage(clearTrack, for: state)
            setVolumeThumbImage(Skin.image("volume", CGRect(x: state == .highlighted ? 0 : 15,
                                                          y: 422, width: 14, height: 11)), for: state)
        }
        observation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.level = value
                self.setNeedsDisplay()
                self.levelChanged?(value)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func observeTouch(_ gesture: UIGestureRecognizer) {
        isAdjusting = gesture.state == .began || gesture.state == .changed
        trackingChanged?(isAdjusting, currentLevel)
    }

    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect { bounds }

    override func volumeThumbRect(forBounds bounds: CGRect, volumeSliderRect rect: CGRect, value: Float) -> CGRect {
        CGRect(x: bounds.minX + floor(CGFloat(max(0, min(1, value))) * 51),
               y: bounds.minY + 1, width: 14, height: 11)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIGraphicsGetCurrentContext()?.interpolationQuality = .none
        Skin.draw("volume", CGRect(x: 0, y: Int(max(0, min(1, level)) * 27) * 15,
                                  width: 68, height: 13), at: .zero)
    }

    func refreshFromSystem() {
        level = AVAudioSession.sharedInstance().outputVolume
        setNeedsDisplay()
    }
}

/// Observes touch-down without taking gestures away from the system slider.
private final class VolumeTouchObserver: UIGestureRecognizer {
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { state = .began }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) { state = .changed }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { state = .ended }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { state = .cancelled }
}
