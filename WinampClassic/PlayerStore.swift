import Foundation
import AVFoundation
import MediaPlayer

/// All UI and playback mutations run on the main thread (Swift 5 language mode).
final class PlayerStore: NSObject {
    private(set) var tracks: [Track] = []
    private(set) var index: Int?
    private(set) var player: EnginePlayer?
    var changed: (() -> Void)?
    var failed: ((String) -> Void)?
    var shuffle = false { didSet { resetShuffle(); changed?() } }
    var repeatAll = false { didSet { changed?() } }
    var volume: Float = 0.75 { didSet { player?.volume = volume; changed?() } }
    var pan: Float = 0 { didSet { player?.pan = pan; changed?() } }
    private(set) var eqSettings = EqualizerSettings()
    private(set) var eqAuto = false
    private var perTrackEQ: [String: EqualizerSettings] = [:]
    private var shouldResume = false
    private var shuffleRemaining: [Int] = []
    private var commandTargets: [(MPRemoteCommand, Any)] = []
    private let files = FileManager.default
    private let directory: URL
    private static let introFilename = "winamp-intro.mp3"
    private static let introInstalledKey = "intro.installed.v1"
    private static let introPlayedKey = "intro.played.v1"
    private var attemptedIntro = false
    private var artworkTitle: String?
    private var artwork: MPMediaItemArtwork?

    var playing: Bool { player?.isPlaying == true }
    var position: Double { player?.currentTime ?? 0 }
    var duration: Double { player?.duration ?? 0 }
    var title: String { index.flatMap { tracks.indices.contains($0) ? tracks[$0].title : nil } ?? "WINAMP - ADD MUSIC" }

    override init() {
        directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        super.init()
        if let data = UserDefaults.standard.data(forKey: "equalizer.settings"),
           let saved = try? JSONDecoder().decode(EqualizerSettings.self, from: data) { eqSettings = saved.sanitized() }
        eqAuto = UserDefaults.standard.bool(forKey: "equalizer.auto")
        if let data = UserDefaults.standard.data(forKey: "equalizer.tracks"),
           let saved = try? JSONDecoder().decode([String: EqualizerSettings].self, from: data) {
            perTrackEQ = saved.mapValues { $0.sanitized() }
        }
        do {
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
            let manifest = directory.appendingPathComponent("playlist.json")
            if files.fileExists(atPath: manifest.path) {
                tracks = try JSONDecoder().decode([Track].self, from: Data(contentsOf: manifest))
                    .filter { $0.filename == URL(fileURLWithPath: $0.filename).lastPathComponent && files.fileExists(atPath: directory.appendingPathComponent($0.filename).path) }
            }
            // Fill duration fields missing from older playlist manifests.
            for i in tracks.indices where tracks[i].duration == nil {
                if let probe = try? AVAudioFile(forReading: directory.appendingPathComponent(tracks[i].filename)) {
                    tracks[i].duration = Double(probe.length) / probe.processingFormat.sampleRate
                }
            }
            if !UserDefaults.standard.bool(forKey: Self.introInstalledKey) {
                if !tracks.contains(where: { $0.filename == Self.introFilename }) {
                    guard let source = Bundle.main.url(forResource: "intro", withExtension: "mp3") else {
                        throw PlaybackError.unreadable
                    }
                    let target = directory.appendingPathComponent(Self.introFilename)
                    if !files.fileExists(atPath: target.path) { try files.copyItem(at: source, to: target) }
                    let probe = try AVAudioFile(forReading: target)
                    tracks.insert(Track(filename: Self.introFilename, title: "DJ Mike Llama – Llama Whippin",
                                        duration: Double(probe.length) / probe.processingFormat.sampleRate), at: 0)
                }
                try JSONEncoder().encode(tracks).write(to: manifest, options: .atomic)
                UserDefaults.standard.set(true, forKey: Self.introInstalledKey)
            } else {
                try JSONEncoder().encode(tracks).write(to: manifest, options: .atomic)
            }
        } catch { startupError = error.localizedDescription }
        NotificationCenter.default.addObserver(self, selector: #selector(interruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        installRemoteCommands()
    }

    private(set) var startupError: String?

    /// Called only after the screen and error handlers are ready. Never on resume.
    func playIntroOnFirstLaunch() {
        guard !attemptedIntro, startupError == nil else { return }
        attemptedIntro = true
        guard !UserDefaults.standard.bool(forKey: Self.introPlayedKey),
              let row = tracks.firstIndex(where: { $0.filename == Self.introFilename }) else { return }
        select(row)
        if playing { UserDefaults.standard.set(true, forKey: Self.introPlayedKey) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        commandTargets.forEach { $0.0.removeTarget($0.1) }
    }

    /// Copy Files-provider URLs immediately while their security scope is valid.
    /// Validate each file before adding it; a bad import never stops current audio.
    func add(_ urls: [URL]) {
        var errors: [String] = []
        for source in urls {
            let scoped = source.startAccessingSecurityScopedResource()
            defer { if scoped { source.stopAccessingSecurityScopedResource() } }
            let name = UUID().uuidString + "." + source.pathExtension.lowercased()
            let target = directory.appendingPathComponent(name)
            do {
                var coordinationError: NSError?
                var copyError: Error?
                NSFileCoordinator().coordinate(readingItemAt: source, options: [], error: &coordinationError) { url in
                    do { try files.copyItem(at: url, to: target) } catch { copyError = error }
                }
                if let error = coordinationError { throw error }
                if let error = copyError { throw error }
                let probe = try AVAudioFile(forReading: target)
                guard probe.length > 0, (1...2).contains(probe.processingFormat.channelCount) else { throw PlaybackError.unreadable }
                tracks.append(Track(filename: name, title: source.deletingPathExtension().lastPathComponent,
                                    duration: Double(probe.length) / probe.processingFormat.sampleRate))
            } catch {
                try? files.removeItem(at: target)
                errors.append(source.lastPathComponent + ": " + error.localizedDescription)
            }
        }
        save()
        resetShuffle()
        changed?()
        if !errors.isEmpty { failed?(errors.joined(separator: "\n")) }
    }

    func select(_ newIndex: Int, autoplay: Bool = true) {
        guard tracks.indices.contains(newIndex) else { return }
        do {
            let next = try EnginePlayer(contentsOf: directory.appendingPathComponent(tracks[newIndex].filename))
            next.volume = volume
            next.pan = pan
            if eqAuto { eqSettings = perTrackEQ[tracks[newIndex].filename] ?? EqualizerSettings() }
            next.apply(eqSettings)
            next.didFinish = { [weak self] in self?.next(automatic: true) }
            next.configurationChanged = { [weak self] in self?.updateNowPlaying(); self?.changed?() }
            player?.stop()
            player = next
            index = newIndex
            shuffleRemaining.removeAll { $0 == newIndex }
            if autoplay { play() } else { updateNowPlaying(); changed?() }
        } catch { failed?(error.localizedDescription) }
    }

    func play() {
        guard !tracks.isEmpty else { return }
        guard let player = player else { select(index ?? 0); return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try player.play()
            updateNowPlaying()
            changed?()
        } catch {
            deactivateSession()
            failed?(error.localizedDescription)
        }
    }

    func pause() {
        player?.pause()
        updateNowPlaying()
        deactivateSession()
        changed?()
    }

    func stop() {
        player?.stop()
        updateNowPlaying()
        deactivateSession()
        changed?()
    }

    func seek(_ time: Double) {
        guard time.isFinite else { return }
        do { try player?.seek(to: max(0, min(time, duration))) }
        catch { failed?(error.localizedDescription) }
        updateNowPlaying()
        changed?()
    }

    func next(automatic: Bool = false) {
        guard !tracks.isEmpty else { return }
        let current = index ?? -1
        if shuffle && tracks.count > 1 {
            if shuffleRemaining.isEmpty {
                if automatic && !repeatAll { stop(); return }
                resetShuffle()
            }
            if let row = shuffleRemaining.randomElement() { select(row) }
        } else if current + 1 < tracks.count {
            select(current + 1)
        } else if repeatAll || !automatic {
            select(0)
        } else { stop() }
    }

    func previous() {
        if position > 3 { seek(0); return }
        guard !tracks.isEmpty else { return }
        select(max(0, (index ?? 0) - 1))
    }

    func remove(at row: Int) {
        guard tracks.indices.contains(row) else { return }
        let removed = tracks[row]
        if index == row {
            stop()
            player = nil
            index = nil
        } else if let current = index, row < current { index = current - 1 }
        perTrackEQ.removeValue(forKey: removed.filename)
        persistEqualizer()
        tracks.remove(at: row)
        resetShuffle()
        do { try files.removeItem(at: directory.appendingPathComponent(removed.filename)) }
        catch { failed?(error.localizedDescription) }
        save()
        updateNowPlaying()
        changed?()
    }

    func setEqualizer(_ settings: EqualizerSettings) {
        eqSettings = settings.sanitized()
        player?.apply(eqSettings)
        if eqAuto, let row = index { perTrackEQ[tracks[row].filename] = eqSettings }
        persistEqualizer()
        changed?()
    }

    func setEQAuto(_ enabled: Bool) {
        eqAuto = enabled
        if enabled, let row = index {
            eqSettings = perTrackEQ[tracks[row].filename] ?? eqSettings
            perTrackEQ[tracks[row].filename] = eqSettings
            player?.apply(eqSettings)
        }
        persistEqualizer()
        changed?()
    }

    private func persistEqualizer() {
        UserDefaults.standard.set(try? JSONEncoder().encode(eqSettings), forKey: "equalizer.settings")
        UserDefaults.standard.set(eqAuto, forKey: "equalizer.auto")
        UserDefaults.standard.set(try? JSONEncoder().encode(perTrackEQ), forKey: "equalizer.tracks")
    }

    private func save() {
        do { try JSONEncoder().encode(tracks).write(to: directory.appendingPathComponent("playlist.json"), options: .atomic) }
        catch { failed?("Liste kaydedilemedi: " + error.localizedDescription) }
    }

    private func resetShuffle() {
        shuffleRemaining = tracks.indices.filter { $0 != index }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    @objc private func interruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let kind = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if kind == .began {
                self.shouldResume = self.playing
                self.player?.pause()
                self.updateNowPlaying()
                self.changed?()
            } else {
                let options = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
                if self.shouldResume && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) { self.play() }
                self.shouldResume = false
            }
        }
    }

    @objc private func routeChanged(_ notification: Notification) {
        guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        DispatchQueue.main.async { [weak self] in self?.shouldResume = false; self?.pause() }
    }

    @objc private func mediaReset() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let time = self.position
            self.player = nil
            if let row = self.index { self.select(row, autoplay: false); self.seek(time) }
        }
    }

    private func installRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        func bind(_ command: MPRemoteCommand, _ body: @escaping (PlayerStore, MPRemoteCommandEvent) -> Void) {
            command.isEnabled = true
            let target = command.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                DispatchQueue.main.async { body(self, event) }
                return .success
            }
            commandTargets.append((command, target))
        }
        bind(center.playCommand) { store, _ in store.play() }
        bind(center.pauseCommand) { store, _ in store.pause() }
        bind(center.togglePlayPauseCommand) { store, _ in store.playing ? store.pause() : store.play() }
        bind(center.nextTrackCommand) { store, _ in store.next() }
        bind(center.previousTrackCommand) { store, _ in store.previous() }
        bind(center.changePlaybackPositionCommand) { store, event in
            if let event = event as? MPChangePlaybackPositionCommandEvent { store.seek(event.positionTime) }
        }
    }

    private func updateNowPlaying() {
        guard index != nil, player != nil else { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; return }
        if artworkTitle != title || artwork == nil {
            artwork = LockScreenArtwork.make(title: title)
            artworkTitle = title
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]
        if let artwork = artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private enum PlaybackError: LocalizedError {
        case unreadable
        var errorDescription: String? { "Bu ses dosyası iOS ses altyapısıyla açılamadı. MP3, AAC/M4A veya WAV deneyin." }
    }
}
