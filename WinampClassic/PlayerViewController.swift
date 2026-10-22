import UIKit
import UniformTypeIdentifiers

final class PlayerViewController: UIViewController, UIDocumentPickerDelegate, UITableViewDataSource, UITableViewDelegate {
    private let store = PlayerStore()
    private let canvas = UIView()
    private let spectrum = SpectrumView()
    private var lastScrollTime = CACurrentMediaTime()
    private lazy var equalizerPanel = EqualizerPanel(store: store)
    private var equalizerVisible = true
    private var equalizerButton: UIButton!
    private let main = MainPanel(frame: CGRect(x: 0, y: 0, width: 275, height: 116))
    private let playlist = UIImageView(image: Skin.image("playlist_base").resizableImage(
        withCapInsets: UIEdgeInsets(top: 38, left: 0, bottom: 38, right: 0), resizingMode: .tile))
    private var playlistBottomButtons: [(UIButton, CGRect)] = []
    private let table = UITableView(frame: .zero, style: .plain)
    private var timer: CADisplayLink?
    private let footer = PlaylistFooterView()
    private var playlistVisible = true
    private var errors: [String] = []
    private var reportedStartupError = false
    private var shuffledButton: UIButton!
    private var repeatButton: UIButton!
    private var playlistButton: UIButton!
    private let volume = SystemVolumeView()
    private let balance = SkinSlider(kind: .balance, frame: CGRect(x: 177, y: 57, width: 38, height: 13), label: "Sol sağ denge")
    private let position = SkinSlider(kind: .position, frame: CGRect(x: 16, y: 72, width: 248, height: 10), label: "Parça konumu")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        canvas.backgroundColor = .black
        view.addSubview(canvas)
        canvas.addSubview(main)
        main.store = store
        main.addSubview(spectrum)
        main.backgroundColor = .black
        main.contentScaleFactor = 1
        main.layer.magnificationFilter = .nearest
        main.layer.minificationFilter = .nearest
        playlist.frame = CGRect(x: 0, y: 116, width: 275, height: 232)
        playlist.isUserInteractionEnabled = true
        playlist.layer.magnificationFilter = .nearest
        playlist.clipsToBounds = true
        canvas.addSubview(playlist)
        canvas.addSubview(equalizerPanel)
        equalizerPanel.close = { [weak self] in self?.toggleEqualizer() }
        equalizerPanel.showPresets = { [weak self] in self?.showEQPresets() }

        let actions: [() -> Void] = [
            { [weak self] in self?.store.previous() },
            { [weak self] in self?.play() },
            { [weak self] in guard let self = self else { return }; self.store.playing ? self.store.pause() : self.play() },
            { [weak self] in self?.store.stop() },
            { [weak self] in self?.store.next() }
        ]
        for i in 0..<5 {
            let width = i == 4 ? 22 : 23
            main.addSubview(Skin.button("cbuttons", normal: CGRect(x: i * 23, y: 0, width: width, height: 18),
                pressed: CGRect(x: i * 23, y: 18, width: width, height: 18),
                at: CGPoint(x: 16 + i * 23, y: 88), label: ["Önceki", "Oynat", "Duraklat / devam", "Durdur", "Sonraki"][i], action: actions[i]))
        }
        main.addSubview(Skin.button("cbuttons", normal: CGRect(x: 114, y: 0, width: 22, height: 16),
            pressed: CGRect(x: 114, y: 16, width: 22, height: 16), at: CGPoint(x: 136, y: 89), label: "Dosyalardan müzik ekle") { [weak self] in self?.importMusic() })
        shuffledButton = Skin.button("shufrep", normal: CGRect(x: 28, y: 0, width: 47, height: 15), at: CGPoint(x: 164, y: 89), label: "Karışık çal") { [weak self] in self?.store.shuffle.toggle() }
        repeatButton = Skin.button("shufrep", normal: CGRect(x: 0, y: 0, width: 28, height: 15), at: CGPoint(x: 210, y: 89), label: "Listeyi tekrarla") { [weak self] in self?.store.repeatAll.toggle() }
        playlistButton = Skin.button("shufrep", normal: CGRect(x: 23, y: 73, width: 23, height: 12), at: CGPoint(x: 242, y: 58), label: "Çalma listesini göster / gizle") { [weak self] in self?.togglePlaylist() }
        [shuffledButton!, repeatButton!, playlistButton!].forEach { main.addSubview($0) }
        equalizerButton = Skin.button("shufrep", normal: CGRect(x: 0, y: 73, width: 23, height: 12), at: CGPoint(x: 219, y: 58), label: "Ekolayzır panelini göster / gizle") { [weak self] in self?.toggleEqualizer() }
        main.addSubview(equalizerButton)
        main.addSubview(Skin.button("titlebar", normal: CGRect(x: 0, y: 0, width: 9, height: 9), at: CGPoint(x: 6, y: 3), label: "Kullanım bilgisi") { [weak self] in
            self?.showMessage("Eject veya ADD: müzik ekle. Parçaya dokun: oynat. Sola kaydır: sil. Zaman göstergesine dokun: kalan süre. EQ: paneli aç/kapat. ON: sesi filtrele. AUTO: parçaya özel ayarı hatırla. Sürgüye çift dokun: sıfırla.")
        })
        let time = UIButton(frame: CGRect(x: 36, y: 23, width: 65, height: 20))
        time.accessibilityLabel = "Geçen / kalan süre"
        time.addAction(UIAction { [weak self] _ in self?.main.remaining.toggle(); self?.main.setNeedsDisplay() }, for: .touchUpInside)
        main.addSubview(time)
        main.addSubview(volume)
        [balance, position].forEach { main.addSubview($0) }
        volume.levelChanged = { [weak self] value in
            guard let self = self else { return }
            let text = "VOLUME= \(Int((value * 100).rounded()))%"
            if self.volume.isAdjusting { self.main.heldStatus = text }
            self.main.showStatus(text)
        }
        volume.trackingChanged = { [weak self] active, value in
            guard let self = self else { return }
            let text = "VOLUME= \(Int((value * 100).rounded()))%"
            self.main.heldStatus = active ? text : nil
            self.main.showStatus(text)
        }
        balance.onChange = { [weak self] value in
            guard let self = self else { return }
            self.store.pan = Float(value * 2 - 1)
            let text = BalanceControl.label(value)
            if self.balance.isTracking { self.main.heldStatus = text }
            self.main.showStatus(text)
        }
        balance.onTrackingChanged = { [weak self] active in
            guard let self = self else { return }
            let text = BalanceControl.label(self.balance.value)
            self.main.heldStatus = active ? text : nil
            self.main.showStatus(text)
        }
        position.onChange = { [weak self] value in guard let self = self else { return }; self.store.seek(Double(value) * self.store.duration) }

        table.frame = CGRect(x: 12, y: 20, width: 243, height: 174)
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.rowHeight = 18
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.indicatorStyle = .white
        table.register(UITableViewCell.self, forCellReuseIdentifier: "track")
        playlist.addSubview(table)
        footer.store = store
        footer.isUserInteractionEnabled = false
        playlist.addSubview(footer)
        addPlaylistAction(CGRect(x: 189, y: 215, width: 34, height: 10), "Geçen / kalan süre") { [weak self] in
            self?.main.remaining.toggle()
            self?.tick()
        }
        addPlaylistAction(CGRect(x: 10, y: 203, width: 28, height: 20), "Müzik ekle") { [weak self] in self?.importMusic() }
        addPlaylistAction(CGRect(x: 39, y: 203, width: 28, height: 20), "Geçerli parçayı sil") { [weak self] in
            guard let self = self, let index = self.store.index else { return }; self.store.remove(at: index)
        }
        addPlaylistAction(CGRect(x: 264, y: 3, width: 9, height: 9), "Çalma listesini gizle") { [weak self] in self?.togglePlaylist() }
        for (i, action) in actions.enumerated() {
            addPlaylistAction(CGRect(x: 128 + i * 10, y: 215, width: 10, height: 14), ["Önceki", "Oynat", "Duraklat", "Durdur", "Sonraki"][i], action: action)
        }
        addPlaylistAction(CGRect(x: 178, y: 215, width: 10, height: 14), "Dosya ekle") { [weak self] in self?.importMusic() }
        // Preserve the original chrome; explain features not implemented yet.
        for (x, label) in [(68, "Seçim"), (97, "Liste seçenekleri"), (228, "Liste dosyası")] {
            addPlaylistAction(CGRect(x: x, y: 203, width: 28, height: 20), label) { [weak self] in self?.showMessage("Bu Winamp liste menüsü ilk sürüme henüz eklenmedi. Parçaları dokunarak çalabilir, sola kaydırarak silebilirsin.") }
        }
        store.changed = { [weak self] in self?.refresh() }
        store.failed = { [weak self] in self?.showMessage($0) }
        NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: UIApplication.willResignActiveNotification, object: nil)
        refresh()
        startTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.playIntroOnFirstLaunch()
        if !reportedStartupError, let error = store.startupError { reportedStartupError = true; showMessage(error) }
        presentNextError()
    }

    deinit { timer?.invalidate(); NotificationCenter.default.removeObserver(self) }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaLayoutGuide.layoutFrame
        // No outer margin or vertical centering: begin immediately below status area.
        let layout = PlayerLayout(width: safe.width, availableHeight: safe.height,
                                  equalizer: equalizerVisible, playlist: playlistVisible)
        playlist.frame = CGRect(x: 0, y: layout.playlistY, width: 275, height: layout.playlistHeight)
        table.frame = CGRect(x: 12, y: 20, width: 243, height: layout.playlistHeight - 58)
        footer.frame = CGRect(x: 0, y: layout.playlistHeight - 38, width: 275, height: 38)
        for (button, original) in playlistBottomButtons {
            button.frame = original.offsetBy(dx: 0, dy: layout.playlistHeight - 232)
        }
        canvas.bounds = CGRect(x: 0, y: 0, width: 275, height: layout.height)
        canvas.transform = CGAffineTransform(scaleX: layout.scale, y: layout.scale)
        canvas.center = CGPoint(x: safe.midX, y: safe.minY + layout.height * layout.scale / 2)
        canvas.layer.magnificationFilter = .nearest
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func addPlaylistAction(_ frame: CGRect, _ label: String, action: @escaping () -> Void) {
        let button = UIButton(frame: frame)
        button.accessibilityLabel = label
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        playlist.addSubview(button)
        if frame.minY >= 194 { playlistBottomButtons.append((button, frame)) }
    }

    private func play() { if store.tracks.isEmpty { importMusic() } else { store.play() } }
    private func togglePlaylist() {
        playlistVisible.toggle()
        playlist.isHidden = !playlistVisible
        refresh()
        view.setNeedsLayout()
    }

    private func toggleEqualizer() {
        equalizerVisible.toggle()
        equalizerPanel.isHidden = !equalizerVisible
        refresh()
        view.setNeedsLayout()
    }

    private func showEQPresets() {
        guard presentedViewController == nil else { return }
        let sheet = UIAlertController(title: "EQ Presets", message: "Hazır ayar seç", preferredStyle: .actionSheet)
        for (name, settings) in EqualizerSettings.presets {
            sheet.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in self?.store.setEqualizer(settings) })
        }
        sheet.addAction(UIAlertAction(title: "İptal", style: .cancel))
        sheet.popoverPresentationController?.sourceView = equalizerPanel.presetsButton
        sheet.popoverPresentationController?.sourceRect = equalizerPanel.presetsButton.bounds
        present(sheet, animated: true)
    }

    private func refresh() {
        equalizerPanel.refresh()
        equalizerButton.setImage(Skin.image("shufrep", CGRect(x: 0, y: equalizerVisible ? 73 : 61, width: 23, height: 12)), for: .normal)
        if !balance.isTracking { balance.value = CGFloat((store.pan + 1) / 2) }
        shuffledButton.setImage(Skin.image("shufrep", CGRect(x: 28, y: store.shuffle ? 30 : 0, width: 47, height: 15)), for: .normal)
        repeatButton.setImage(Skin.image("shufrep", CGRect(x: 0, y: store.repeatAll ? 30 : 0, width: 28, height: 15)), for: .normal)
        shuffledButton.accessibilityValue = store.shuffle ? "Açık" : "Kapalı"
        repeatButton.accessibilityValue = store.repeatAll ? "Açık" : "Kapalı"
        playlistButton.setImage(Skin.image("shufrep", CGRect(x: 23, y: playlistVisible ? 73 : 61, width: 23, height: 12)), for: .normal)
        table.reloadData()
        tick()
    }

    @objc private func startTimer() {
        volume.refreshFromSystem()
        guard timer == nil else { return }
        let target = PlayerDisplayLinkTarget()
        target.owner = self
        let timer = CADisplayLink(target: target, selector: #selector(PlayerDisplayLinkTarget.step))
        timer.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        timer.add(to: .main, forMode: .common)
        self.timer = timer
    }
    @objc private func stopTimer() { timer?.invalidate(); timer = nil }
    fileprivate func tick() {
        if !position.isTracking { position.value = store.duration > 0 ? CGFloat(store.position / store.duration) : 0 }
        spectrum.update(player: store.player, playing: store.playing)
        let now = CACurrentMediaTime()
        if now - lastScrollTime >= 0.1 {
            main.scrollTick += Int((now - lastScrollTime) / 0.1)
            lastScrollTime = now
        }
        footer.remaining = main.remaining
        footer.setNeedsDisplay()
        main.setNeedsDisplay()
    }

    private func importMusic() {
        guard presentedViewController == nil else { return }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        store.add(urls)
        controller.dismiss(animated: true) { [weak self] in self?.presentNextError() }
    }

    private func showMessage(_ message: String) { errors.append(message); presentNextError() }
    private func presentNextError() {
        guard view.window != nil, presentedViewController == nil, !errors.isEmpty else { return }
        let alert = UIAlertController(title: "Winamp Classic — iOS", message: errors.removeFirst(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
            DispatchQueue.main.async { self?.presentNextError() }
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { store.tracks.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "track", for: indexPath)
        cell.backgroundColor = store.index == indexPath.row ? UIColor(red: 0, green: 0.12, blue: 0.25, alpha: 1) : .black
        cell.textLabel?.textColor = store.index == indexPath.row ? .white : Skin.green
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
        cell.textLabel?.text = "\(indexPath.row + 1). \(store.tracks[indexPath.row].title)"
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        let duration = PlaybackTime.label(store.tracks[indexPath.row].duration)
        let durationLabel = (cell.accessoryView as? UILabel) ?? UILabel()
        durationLabel.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
        durationLabel.textColor = cell.textLabel?.textColor
        durationLabel.textAlignment = .right
        durationLabel.text = duration
        durationLabel.frame = CGRect(x: 0, y: 0, width: max(34, CGFloat(duration.count) * 6), height: 18)
        cell.accessoryView = durationLabel
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.accessibilityLabel = store.tracks[indexPath.row].title + ", " + duration
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { store.select(indexPath.row) }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { store.remove(at: indexPath.row) }
    }
}

private final class PlayerDisplayLinkTarget: NSObject {
    weak var owner: PlayerViewController?
    @objc func step() { owner?.tick() }
}
