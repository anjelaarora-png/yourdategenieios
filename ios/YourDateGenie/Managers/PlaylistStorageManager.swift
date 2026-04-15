import Foundation
import Combine

/// Persists saved playlists to UserDefaults and Supabase when user is logged in (survives reinstall).
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
    
    /// Persist to UserDefaults and upsert **one** playlist to Supabase immediately when logged in (`skipSupabase` when merging from cloud).
    private func save(skipSupabase: Bool = false, syncPlaylistId: String? = nil) {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: key)
        guard !skipSupabase, let pid = syncPlaylistId,
              let playlist = playlists.first(where: { $0.id == pid }) else { return }
        Task {
            await syncOnePlaylistToSupabase(playlist)
        }
    }

    private func dbPlaylist(from playlist: SavedPlaylist, coupleId: UUID, userId: UUID? = nil) -> DBPlaylist? {
        guard let playlistId = UUID(uuidString: playlist.id) else { return nil }
        let tracks = playlist.songs.enumerated().map { index, s in
            PlaylistTrack(
                trackNumber: index + 1,
                title: s.title,
                artist: s.artist,
                album: nil,
                duration: "—",
                whyItFits: nil
            )
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let generatedAt = iso.date(from: playlist.createdAt)
            ?? iso.date(from: String(playlist.createdAt.prefix(19)) + "Z")
            ?? Date()
        let updatedAt = iso.date(from: playlist.updatedAt)
            ?? iso.date(from: String(playlist.updatedAt.prefix(19)) + "Z")
        return DBPlaylist(
            playlistId: playlistId,
            planId: nil,
            coupleId: coupleId,
            userId: userId,
            title: playlist.name,
            description: [playlist.datePlanTitle, playlist.vibe].filter { !$0.isEmpty }.joined(separator: " • "),
            vibe: playlist.vibe,
            datePlanTitle: playlist.datePlanTitle,
            stops: playlist.stops,
            tracks: tracks,
            totalDurationMinutes: max(1, playlist.songs.count * 4),
            generatedAt: generatedAt,
            updatedAt: updatedAt
        )
    }

    private func syncOnePlaylistToSupabase(_ playlist: SavedPlaylist) async {
        do {
            let userId = await MainActor.run { UserProfileManager.shared.userId }
            let coupleId = try await SupabaseService.shared.resolveCoupleIdForCurrentUser()
            guard let db = dbPlaylist(from: playlist, coupleId: coupleId, userId: userId) else { return }
            _ = try await SupabaseService.shared.upsertPlaylist(db)
            print("[PlaylistStorage] upsertPlaylist success playlist_id=\(db.playlistId)")
        } catch {
            print("[PlaylistStorage] upsertPlaylist failed: \(error)")
        }
    }
    
    private func deletePlaylistFromSupabase(id: String) {
        guard let playlistId = UUID(uuidString: id) else { return }
        Task {
            try? await SupabaseService.shared.deletePlaylist(playlistId: playlistId)
        }
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
        save(syncPlaylistId: playlist.id)
        return playlist
    }
    
    func updatePlaylist(_ playlist: SavedPlaylist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        var updated = playlist
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = updated
        save(syncPlaylistId: playlist.id)
        objectWillChange.send()
    }
    
    func updateSongs(playlistId: String, songs: [SavedPlaylistSong]) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var updated = playlists[idx]
        updated.songs = songs
        updated.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = updated
        save(syncPlaylistId: playlistId)
        objectWillChange.send()
    }
    
    func deletePlaylist(id: String) {
        deletePlaylistFromSupabase(id: id)
        playlists.removeAll { $0.id == id }
        save(skipSupabase: true)
    }
    
    func addSong(playlistId: String, title: String, artist: String, isCustom: Bool = true) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var pl = playlists[idx]
        pl.songs.append(SavedPlaylistSong(title: title, artist: artist, isCustom: isCustom))
        pl.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = pl
        save(syncPlaylistId: playlistId)
        objectWillChange.send()
    }
    
    func removeSong(playlistId: String, songId: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        var pl = playlists[idx]
        pl.songs.removeAll { $0.id == songId }
        pl.updatedAt = ISO8601DateFormatter().string(from: Date())
        playlists[idx] = pl
        save(syncPlaylistId: playlistId)
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
        save(syncPlaylistId: playlistId)
        objectWillChange.send()
    }
    
    func getPlaylist(id: String) -> SavedPlaylist? {
        playlists.first { $0.id == id }
    }
    
    /// Call after login to restore playlists from Supabase and push any local-only playlists to the cloud.
    func syncFromSupabaseWhenLoggedIn(coupleId: UUID) {
        Task { await syncFromSupabaseWhenLoggedInAsync(coupleId: coupleId) }
    }

    func syncFromSupabaseWhenLoggedInAsync(coupleId: UUID) async {
        guard let list = try? await SupabaseService.shared.getPlaylists(coupleId: coupleId) else { return }
        await MainActor.run {
            mergeFromSupabase(dbPlaylists: list)
        }
        let cloudIds = Set(list.map { $0.playlistId.uuidString })
        let locals = await MainActor.run { playlists.filter { !cloudIds.contains($0.id) } }
        for p in locals {
            await syncOnePlaylistToSupabase(p)
        }
    }

    /// Fallback sync path for users who don't yet have a couple record.
    /// Uses the user_id-scoped RLS policies added in the web-sync migration.
    func syncFromSupabaseWhenLoggedInByUserIdAsync(userId: UUID) async {
        guard let list = try? await SupabaseService.shared.getPlaylists(userId: userId) else { return }
        await MainActor.run {
            mergeFromSupabase(dbPlaylists: list)
        }
        let cloudIds = Set(list.map { $0.playlistId.uuidString })
        let locals = await MainActor.run { playlists.filter { !cloudIds.contains($0.id) } }
        for p in locals {
            await syncOnePlaylistToSupabase(p)
        }
    }
    
    /// Merge playlists from Supabase (account) into local list; skips ones already present by id.
    func mergeFromSupabase(dbPlaylists: [DBPlaylist]) {
        var existingIds = Set(playlists.map(\.id))
        let iso = ISO8601DateFormatter()
        for db in dbPlaylists {
            let id = db.playlistId.uuidString
            guard !existingIds.contains(id) else { continue }
            let songs = (db.tracks ?? []).map { t in
                SavedPlaylistSong(title: t.title, artist: t.artist, isCustom: false, addedAt: nil)
            }
            let saved = SavedPlaylist(
                id: id,
                name: db.title ?? "Playlist",
                datePlanTitle: db.datePlanTitle ?? db.title ?? "Date Night",
                vibe: db.vibe ?? "other",
                songs: songs,
                stops: db.stops,
                energy: nil,
                era: nil,
                mood: nil,
                createdAt: iso.string(from: db.generatedAt),
                updatedAt: iso.string(from: db.updatedAt ?? db.generatedAt)
            )
            playlists.insert(saved, at: 0)
            existingIds.insert(id)
        }
        save(skipSupabase: true)
        objectWillChange.send()
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
