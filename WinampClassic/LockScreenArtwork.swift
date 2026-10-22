import UIKit
import MediaPlayer

/// Static artwork for iOS Now Playing. Transport and elapsed time remain system controls.
enum LockScreenArtwork {
    static func make(title: String) -> MPMediaItemArtwork {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: CGSize(width: 275, height: 275), format: format).image { renderer in
            let context = renderer.cgContext
            UIColor(red: 0.12, green: 0.12, blue: 0.19, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 275, height: 275))
            context.interpolationQuality = .none
            context.saveGState()
            context.translateBy(x: 0, y: 79)
            Skin.image("main_base").draw(at: .zero)
            Skin.text(title, at: CGPoint(x: 111, y: 27), limit: 30)
            // No frozen timer or fabricated spectrum in cover art.
            Skin.text("WINAMP", at: CGPoint(x: 43, y: 29), limit: 6)
            Skin.draw("volume", CGRect(x: 0, y: 300, width: 68, height: 13), at: CGPoint(x: 107, y: 57))
            Skin.draw("volume", CGRect(x: 15, y: 422, width: 14, height: 11), at: CGPoint(x: 145, y: 58))
            Skin.draw("balance", CGRect(x: 9, y: 0, width: 38, height: 13), at: CGPoint(x: 177, y: 57))
            Skin.draw("balance", CGRect(x: 15, y: 422, width: 14, height: 11), at: CGPoint(x: 189, y: 58))
            Skin.draw("posbar", CGRect(x: 0, y: 0, width: 248, height: 10), at: CGPoint(x: 16, y: 72))
            context.restoreGState()
            Skin.text("WINAMP", at: CGPoint(x: 122, y: 224), limit: 6)
        }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
