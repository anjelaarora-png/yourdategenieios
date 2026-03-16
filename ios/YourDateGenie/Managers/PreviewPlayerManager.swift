import Foundation
import AVFoundation

/// Plays 30-second iTunes preview URLs. One instance per flow (e.g. shared in playlist views).
final class PreviewPlayerManager: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrackKey: String?
    
    private var player: AVPlayer?
    private var observer: Any?
    
    func play(url: String, trackKey: String) {
        stop()
        guard let previewURL = URL(string: url) else { return }
        let item = AVPlayerItem(url: previewURL)
        player = AVPlayer(playerItem: item)
        currentTrackKey = trackKey
        isPlaying = true
        player?.play()
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.currentTrackKey = nil
            self?.observer.map { NotificationCenter.default.removeObserver($0) }
            self?.observer = nil
        }
    }
    
    func stop() {
        player?.pause()
        player = nil
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
        }
        observer = nil
        isPlaying = false
        currentTrackKey = nil
    }
}
