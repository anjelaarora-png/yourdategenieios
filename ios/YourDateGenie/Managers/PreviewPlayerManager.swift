import Foundation
import AVFoundation

/// Plays 30-second iTunes preview URLs. One instance per flow (e.g. shared in playlist views).
final class PreviewPlayerManager: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrackKey: String?
    
    private var player: AVPlayer?
    private var observer: Any?
    private var failObserver: Any?
    
    func play(url: String, trackKey: String) {
        stop()
        guard let previewURL = URL(string: url) else { return }
        // Without .playback, preview audio is often silent when the Ring/Silent switch is on.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Still attempt playback; session may already be configured.
        }
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
        failObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.currentTrackKey = nil
            self?.failObserver.map { NotificationCenter.default.removeObserver($0) }
            self?.failObserver = nil
            if let obs = self?.observer {
                NotificationCenter.default.removeObserver(obs)
                self?.observer = nil
            }
            self?.player?.pause()
            self?.player = nil
        }
    }
    
    func stop() {
        player?.pause()
        player = nil
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
        }
        observer = nil
        if let obs = failObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        failObserver = nil
        isPlaying = false
        currentTrackKey = nil
    }
}
