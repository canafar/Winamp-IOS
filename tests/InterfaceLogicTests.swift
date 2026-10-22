import Foundation

@main
enum InterfaceLogicTests {
    static func require(_ value: Bool, _ message: String) { if !value { fatalError(message) } }
    static func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.001 }
    static func main() {
        var status = PanelStatus()
        require(status.text(at: 10) == nil, "Unexpected initial status")
        status.show("VOLUME: 50%", at: 10)
        require(status.text(at: 11.9) == "VOLUME: 50%", "Feedback disappears early")
        status.show("VOLUME: 75%", at: 11)
        require(status.text(at: 12.5) == "VOLUME: 75%", "New feedback failed to replace/extend")
        require(status.text(at: 13) == nil, "Song title cannot return after feedback")
        // iPhone 13 portrait: safe top 47, bottom 34, full screen 390x844.
        let layout = PlayerLayout(width: 390, availableHeight: 763, equalizer: true, playlist: true)
        require(near(layout.scale * 275, 390), "Side gaps remain")
        require(near(layout.height * layout.scale, 763), "Unused vertical space")
        require(near(layout.playlistY + layout.playlistHeight, layout.height), "Playlist fails to reach bottom")
        require(layout.playlistHeight > 232, "Playlist did not expand")
        // Bottom controls must stay at exactly the same inset regardless of height.
        let bottom = 203 + layout.playlistHeight - 232 + 20
        require(near(layout.playlistHeight - bottom, 9), "Footer detached from skin")
        for width: CGFloat in [320, 375, 390, 430] {
            for height: CGFloat in [460, 650, 763] {
                for eq in [false, true] {
                    let l = PlayerLayout(width: width, availableHeight: height, equalizer: eq, playlist: true)
                    require(l.scale * 275 <= width + 0.001 && l.height * l.scale <= height + 0.001, "Layout overflows screen")
                    require(l.playlistHeight >= 96, "Playlist controls overlap")
                    require(near(l.playlistY, eq ? 232 : 116), "EQ toggle left a gap")
                }
            }
        }
        for value: CGFloat in [0.49, 0.495, 0.5, 0.505, 0.51] {
            require(BalanceControl.snapped(value) == 0.5, "Center did not latch")
        }
        for value: CGFloat in [0, 0.489, 0.511, 1] {
            require(BalanceControl.snapped(value) == value, "Latch failed to release")
        }
        require(BalanceControl.label(0.5) == "BALANCE= CENTRE", "Center label")
        require(BalanceControl.label(0) == "BALANCE= 100% LEFT", "Left label")
        require(BalanceControl.label(1) == "BALANCE= 100% RIGHT", "Right label")
        require(BalanceControl.label(0.165) == "BALANCE= 67% LEFT", "Left percentage must be distance from centre")
        require(BalanceControl.label(0.715) == "BALANCE= 43% RIGHT", "Right percentage must be distance from centre")
        let names = ["Classical", "Club", "Dance", "Flat", "Laptop speakers/headphones", "Large hall",
                     "Party", "Pop", "Reggae", "Rock", "Soft", "Ska", "Full Bass", "Soft Rock",
                     "Full Treble", "Full Bass & Treble", "Live", "Techno"]
        require(EqualizerSettings.classicPresets.map { $0.0 } == names, "Missing source presets")
        require(EqualizerSettings.classicPresets.allSatisfy { $0.1.gains.count == 10 && $0.1.preamp == 0 }, "Preset structure")
        require(EqualizerSettings.classicGain(0) == 12 && EqualizerSettings.classicGain(31) == 0 && EqualizerSettings.classicGain(63) == -12, "Source VALTODB conversion")
        let flat = EqualizerSettings.classicPresets.first { $0.0 == "Flat" }!.1
        require(flat.gains.allSatisfy { $0 == 0 }, "Flat is not flat")
        let rock = EqualizerSettings.classicPresets.first { $0.0 == "Rock" }!.1
        require(abs(rock.gains[0] - 144.0 / 31) < 0.0001 && rock.gains[3] == -5.25, "Rock differs from source")
        print("PASS: fullscreen sizing, EQ visibility, footer anchors, center latch and 18 original presets")
    }
}
