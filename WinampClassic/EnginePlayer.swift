import AVFoundation
import Foundation

/// File -> player node -> 10-band EQ / preamp -> mixer -> device.
/// Transport and parameter changes are confined to the main thread.
final class EnginePlayer {
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 10)
    private let file: AVAudioFile
    private var generation = 0
    private var anchor: Double = 0
    private var lastPosition: Double = 0
    private var configurationObserver: NSObjectProtocol?
    let visualization = SpectrumCapture()
    private var tapInstalled = false
    private var graphAttached = false
    private(set) var isPlaying = false
    var didFinish: (() -> Void)?
    var configurationChanged: (() -> Void)?
    var volume: Float = 0.75 { didSet { engine.mainMixerNode.outputVolume = max(0, min(1, volume)) } }
    var pan: Float = 0 { didSet { node.pan = max(-1, min(1, pan)) } }
    var format: AVAudioFormat { file.processingFormat }
    var numberOfChannels: Int { Int(format.channelCount) }
    var duration: Double { Double(file.length) / format.sampleRate }
    var currentTime: Double {
        get {
            if isPlaying, let render = node.lastRenderTime, let time = node.playerTime(forNodeTime: render), time.sampleRate > 0 {
                lastPosition = min(duration, anchor + max(0, Double(time.sampleTime) / time.sampleRate))
            }
            return isPlaying ? lastPosition : anchor
        }
    }

    init(contentsOf url: URL) throws {
        file = try AVAudioFile(forReading: url)
        guard file.length > 0, file.processingFormat.sampleRate > 0,
              (1...2).contains(file.processingFormat.channelCount) else {
            throw NSError(domain: "WinampAudio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bu sürüm mono ve stereo ses dosyalarını destekler."])
        }
        engine.attach(node)
        engine.attach(equalizer)
        graphAttached = true
        engine.connect(node, to: equalizer, format: format)
        engine.connect(equalizer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume
        apply(EqualizerSettings())
        // Bounded PCM capture only; all FFT work runs on the UI side.
        let capture = visualization
        equalizer.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            capture.ingest(buffer)
        }
        tapInstalled = true
        configurationObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            guard let self = self, !self.engine.isRunning else { return }
            // Hardware route changes invalidate node timelines. Pause safely;
            // explicit Play restarts rendering for the current device format.
            self.pause()
            self.configurationChanged?()
        }
    }

    deinit {
        if let observer = configurationObserver { NotificationCenter.default.removeObserver(observer) }
        if tapInstalled { equalizer.removeTap(onBus: 0) }
        if graphAttached { node.stop(); engine.stop() }
    }

    func apply(_ settings: EqualizerSettings) {
        EqualizerDSP.configure(equalizer, settings: settings, sampleRate: format.sampleRate)
    }

    func play() throws {
        if isPlaying { return }
        if anchor >= duration { anchor = 0 }
        generation += 1
        let token = generation
        node.stop()
        let start = AVAudioFramePosition(anchor * format.sampleRate)
        let count = file.length - start
        guard count > 0 else { return }
        // scheduleSegment uses UInt32 frame counts. scheduleFile supports longer
        // files at the beginning; a long seek segment is rejected explicitly.
        guard count <= Int64(UInt32.max) || start == 0 else {
            throw NSError(domain: "WinampAudio", code: 2, userInfo: [NSLocalizedDescriptionKey: "Bu kadar uzun bir dosyada bu konumdan oynatma desteklenmiyor."])
        }
        try engine.start()
        let completion: @Sendable (AVAudioPlayerNodeCompletionCallbackType) -> Void = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, self.generation == token, self.isPlaying else { return }
                self.isPlaying = false
                self.anchor = self.duration
                self.lastPosition = self.duration
                self.didFinish?()
            }
        }
        if count > Int64(UInt32.max) {
            node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: completion)
        } else {
            node.scheduleSegment(file, startingFrame: start, frameCount: AVAudioFrameCount(count), at: nil,
                                 completionCallbackType: .dataPlayedBack, completionHandler: completion)
        }
        lastPosition = anchor
        isPlaying = true
        node.play()
    }

    func pause() {
        let time = currentTime
        generation += 1 // Ignore completion callbacks delivered by stop/seek.
        isPlaying = false
        node.stop()
        engine.pause()
        visualization.reset()
        anchor = time
        lastPosition = time
    }

    func stop() { pause(); anchor = 0; lastPosition = 0 }

    func seek(to seconds: Double) throws {
        let resume = isPlaying
        pause()
        anchor = min(duration, max(0, seconds))
        lastPosition = anchor
        if resume {
            if anchor >= duration { didFinish?() }
            else { try play() }
        }
    }

}
