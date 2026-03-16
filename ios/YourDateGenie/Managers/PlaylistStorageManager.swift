import Foundation
import Combine

/// Persists saved playlists to UserDefaults (iOS equivalent of web localStorage).
final class PlaylistStorageManager: ObservableObject {
    static let shared = PlaylistStorageManager()
    
    private let key = "date_genie_playlists"
    
    @Published private(set) var playlists: [SavedPlaylist] = []
    
    private init() {
        load()
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedPlaylist].self, from: data) else {
            playlists = []
            return
        }
        playlists = decoded
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    // MARK: - Public API
    
    func savePlaylist(
        name: String,
        datePlanTitle: String,
        vibe: String,
        songs: [(title: String, artist: String, duration: String?)],
        stops: [PlaylistStop]?,
        energy: String? = nil,
        era: String? = nil,
        mood: String? = nil
    ) -> SavedPlaylist {
        let now = ISO8601DateFormatter().string(from: Date())
        let savedSongs = songs.map { s in
            SavedPlaylistSong(title: s.title, artist: s.artist, isCustom: false, addedAt: now)
        }
        let playlist = SavedPlaylist(
            name: name,
            datePlanTitle: datePlanTitle,
            vibe: vibe,
            songs: savedSongs,
            stops: stops,
            energy: energy,
            era: era,
            mood: mood
        )
        playlists.insert(playlist, at: 0)
        save()
        return playlist
    }
    
    func updatePlaylist(_ playlist: SavedPlaylist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        var updated = playlist
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = updated
        save()
        objectWillChange.send()
    }
    
    func updateSongs(playlistId: String, songs: [SavedPlaylistSong]) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var updated = playlists[idx]
        updated.songs = songs
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = updated
        save()
        objectWillChange.send()
    }
    
    func deletePlaylist(id: String) {
        playlists.removeAll { $0.id == id }
        save()
    }
    
    func addSong(playlistId: String, title: String, artist: String, isCustom: Bool = true) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var pl = playlists[idx]
        pl.songs.append(SavedPlaylistSong(title: title, artist: artist, isCustom: isCustom))
        pl.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = pl
        save()
        objectWillChange.send()
    }
    
    func removeSong(playlistId: String, songId: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var pl = playlists[idx]
        pl.songs.removeAll { $0.id == songId }
        pl.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = pl
        save()
        objectWillChange.send()
    }
    
    func replaceSong(playlistId: String, songId: String, newTitle: String, newArtist: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }),
              let songIdx = playlists[idx].songs.firstIndex(where: { $0.id == songId }) else { return }
        var pl = playlists[idx]
        pl.songs[songIdx] = SavedPlaylistSong(
            title: newTitle,
            artist: newArtist,
            isCustom: true,
            addedAt: ISO8601DateFormatter().string(from: Date())
        )
        pl.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = pl
        save()
        objectWillChange.send()
    }
    
    func getPlaylist(id: String) -> SavedPlaylist? {
        playlists.first { $0.id == id }
    }
    
    /// Genre order for sectioned display (key + more + other)
    static let genreOrder = ["romantic", "upbeat", "chill", "adventurous", "jazzy", "indie", "classic", "rnb", "latin", "afrobeats", "kpop", "reggae", "country", "bollywood", "arabic", "jpop", "rock", "electronic", "blues"]
    
    /// Playlists grouped by vibe for sectioned list
    var playlistsByGenre: [(genre: String, list: [SavedPlaylist])] {
        var map: [String: [SavedPlaylist]] = [:]
        for p in playlists {
            let vibe = p.vibe.lowercased().isEmpty ? "other" : p.vibe.lowercased()
            map[vibe, default: []].append(p)
        }
        var result: [(genre: String, list: [SavedPlaylist])] = []
        for g in Self.genreOrder {
            if let list = map[g], !list.isEmpty { result.append((g, list)) }
        }
        for (g, list) in map where !Self.genreOrder.contains(g) {
            result.append((g, list))
        }
        return result
    }
}
