import SwiftUI

/// Saved playlists grouped by genre; empty state with spinning record; optional "Explore more genres" section.
struct SavedPlaylistsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = PlaylistStorageManager.shared
    @State private var selectedPlaylist: SavedPlaylist?
    @State private var exploreGenresExpanded = false
    
    private let genreLabels: [String: String] = [
        "romantic": "Romantic", "pop": "Pop", "upbeat": "Upbeat", "chill": "Chill", "adventurous": "Eclectic",
        "jazzy": "Jazzy", "indie": "Indie", "classic": "Classic", "rnb": "R&B",
        "latin": "Latin", "afrobeats": "Afrobeats", "kpop": "K-Pop", "reggae": "Reggae", "country": "Country",
        "bollywood": "Bollywood", "arabic": "Arabic", "jpop": "J-Pop", "rock": "Rock", "electronic": "Electronic", "blues": "Blues"
    ]
    
    private let vibeEmojis: [String: String] = [
        "romantic": "💕", "pop": "🎵", "upbeat": "🎉", "chill": "🌙", "adventurous": "✨",
        "jazzy": "🎷", "indie": "🎸", "classic": "🎻", "rnb": "🎤",
        "latin": "🌴", "afrobeats": "🔥", "kpop": "💜", "reggae": "🎵", "country": "🤠",
        "bollywood": "🎬", "arabic": "🕌", "jpop": "🌸", "rock": "🤘", "electronic": "⚡", "blues": "🎸"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                
                if storage.playlists.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(storage.playlistsByGenre, id: \.genre) { section in
                                sectionView(section)
                            }
                            exploreMoreGenresSection
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Playlists")
                        .font(Font.tangerine(26, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedPlaylist) { playlist in
                SavedPlaylistDetailView(
                    playlist: binding(for: playlist),
                    onDismiss: { selectedPlaylist = nil }
                )
            }
            .onAppear {
                guard let coupleId = UserProfileManager.shared.coupleId else { return }
                Task {
                    if let list = try? await SupabaseService.shared.getPlaylists(coupleId: coupleId), !list.isEmpty {
                        await MainActor.run {
                            storage.mergeFromSupabase(dbPlaylists: list)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            MusicRecordAnimationView(size: 88, showNotes: true)
            Text("No Playlists Yet")
                .font(Font.displayTitle())
                .foregroundColor(Color.luxuryGold)
            Text("Create a playlist from your date plan to save and listen to your perfect date night music.")
                .font(Font.playfair(15))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sectionView(_ section: (genre: String, list: [SavedPlaylist])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(vibeEmojis[section.genre] ?? "🎵")
                Text(genreLabels[section.genre] ?? section.genre.capitalized)
                    .font(Font.tangerine(22, weight: .bold))
                    .foregroundColor(Color.luxuryMuted)
            }
            .padding(.horizontal, 20)
            
            ForEach(section.list) { p in
                Button {
                    selectedPlaylist = p
                } label: {
                    HStack(spacing: 14) {
                        Text(vibeEmojis[p.vibe] ?? "🎵")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name)
                                .font(Font.tangerine(22, weight: .bold))
                                .foregroundColor(Color.luxuryCream)
                                .lineLimit(1)
                            Text("From: \(p.datePlanTitle)")
                                .font(Font.inter(12))
                                .foregroundColor(Color.luxuryMuted)
                                .lineLimit(1)
                            Text("\(p.songs.count) songs")
                                .font(Font.inter(11))
                                .foregroundColor(Color.luxuryMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryGold)
                    }
                    .padding(16)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var exploreMoreGenresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    exploreGenresExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Explore more genres")
                        .font(Font.playfair(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Spacer()
                    Image(systemName: exploreGenresExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(16)
                .background(Color.luxuryMaroonLight.opacity(0.8))
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            
            if exploreGenresExpanded {
                Text("Create playlists from the Date Playlist button on your date plan to discover Romantic, Upbeat, Chill, Jazzy, Indie, Classic, R&B, and Eclectic vibes.")
                    .font(Font.inter(13))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private func binding(for playlist: SavedPlaylist) -> Binding<SavedPlaylist> {
        Binding(
            get: { storage.getPlaylist(id: playlist.id) ?? playlist },
            set: { storage.updatePlaylist($0) }
        )
    }
}

// MARK: - Saved Playlist Detail (Regenerate, Add, Replace, Delete)
private struct ReplaceSongItem: Identifiable {
    let songId: String
    var id: String { songId }
}

struct SavedPlaylistDetailView: View {
    @Binding var playlist: SavedPlaylist
    let onDismiss: () -> Void
    
    @StateObject private var storage = PlaylistStorageManager.shared
    @State private var showAddSong = false
    @State private var replaceSongItem: ReplaceSongItem?
    @State private var isEditingTitle = false
    @State private var editingTitleText = ""
    @State private var isRegenerating = false
    @StateObject private var previewPlayer = PreviewPlayerManager()
    @State private var currentPlayingKey: String?
    
    /// Always show data from storage so regenerate/updates reflect immediately.
    private var displayedPlaylist: SavedPlaylist {
        storage.getPlaylist(id: playlist.id) ?? playlist
    }
    
    /// Song list from storage so the view re-renders when storage.playlists changes (regenerate, add, delete).
    private var currentSongs: [SavedPlaylistSong] {
        storage.playlists.first(where: { $0.id == playlist.id })?.songs ?? displayedPlaylist.songs
    }
    
    private let vibeEmojis: [String: String] = [
        "romantic": "💕", "pop": "🎵", "upbeat": "🎉", "chill": "🌙", "adventurous": "✨",
        "jazzy": "🎷", "indie": "🎸", "classic": "🎻", "rnb": "🎤",
        "latin": "🌴", "afrobeats": "🔥", "kpop": "💜", "reggae": "🎵", "country": "🤠",
        "bollywood": "🎬", "arabic": "🕌", "jpop": "🌸", "rock": "🤘", "electronic": "⚡", "blues": "🎸"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Editable playlist title (Tangerine)
                        VStack(spacing: 8) {
                            if isEditingTitle {
                                HStack(spacing: 10) {
                                    TextField("Playlist name", text: $editingTitleText)
                                        .font(Font.tangerine(26, weight: .bold))
                                        .foregroundColor(Color.luxuryCream)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color.luxuryMaroonLight)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                                        )
                                        .onSubmit { savePlaylistTitle() }
                                    Button {
                                        savePlaylistTitle()
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color.luxuryGold)
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 6) {
                                    Button {
                                        editingTitleText = displayedPlaylist.name
                                        isEditingTitle = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(displayedPlaylist.name)
                                                .font(Font.tangerine(28, weight: .bold))
                                                .foregroundColor(Color.luxuryGold)
                                                .multilineTextAlignment(.center)
                                            Image(systemName: "pencil.circle")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.luxuryGold.opacity(0.8))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    let subtitleParts: [String] = [
                                        displayedPlaylist.energy.flatMap { EnergyLevel(rawValue: $0) }.map { $0.label },
                                        displayedPlaylist.era.flatMap { EraOption.fromStored($0) }.flatMap { $0 != .any ? $0.label : nil },
                                        displayedPlaylist.mood.flatMap { MoodOption(rawValue: $0) }.flatMap { $0 != .none ? $0.label : nil }
                                    ].compactMap { $0 }
                                    if !subtitleParts.isEmpty {
                                        Text(subtitleParts.joined(separator: " · "))
                                            .font(Font.inter(12))
                                            .foregroundColor(Color.luxuryCreamMuted)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        Button {
                            regeneratePlaylist()
                        } label: {
                            HStack(spacing: 8) {
                                if isRegenerating {
                                    ProgressView()
                                        .tint(Color.luxuryGold)
                                    Text("Regenerating…")
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Regenerate playlist")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                        .disabled(isRegenerating)
                        .padding(.horizontal, 20)
                        
                        Button {
                            showAddSong = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text("Add Song")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 2) {
                            ForEach(Array(currentSongs.enumerated()), id: \.element.id) { index, song in
                                SavedSongRow(
                                    song: song,
                                    index: index + 1,
                                    isPlaying: currentPlayingKey == "\(song.title)|\(song.artist)",
                                    onPlayPreview: { playPreview(for: song) },
                                    onReplace: { replaceSongItem = ReplaceSongItem(songId: song.id) },
                                    onDelete: {
                                        storage.removeSong(playlistId: playlist.id, songId: song.id)
                                        if let p = storage.getPlaylist(id: playlist.id) { playlist = p }
                                    }
                                )
                            }
                        }
                        .luxuryCard(hasBorder: false)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(displayedPlaylist.name)
                        .font(Font.tangerine(24, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showAddSong) {
                SongSearchView(title: "Add Song") { title, artist in
                    storage.addSong(playlistId: displayedPlaylist.id, title: title, artist: artist)
                    if let p = storage.getPlaylist(id: playlist.id) { playlist = p }
                }
            }
            .sheet(item: $replaceSongItem) { item in
                SongSearchView(title: "Replace Song") { title, artist in
                    storage.replaceSong(playlistId: displayedPlaylist.id, songId: item.songId, newTitle: title, newArtist: artist)
                    if let p = storage.getPlaylist(id: playlist.id) { playlist = p }
                    replaceSongItem = nil
                }
            }
            .onChange(of: previewPlayer.isPlaying) { _, isPlaying in
                if !isPlaying { currentPlayingKey = nil }
            }
        }
    }
    
    private func playPreview(for song: SavedPlaylistSong) {
        let key = "\(song.title)|\(song.artist)"
        if previewPlayer.currentTrackKey == key, previewPlayer.isPlaying {
            previewPlayer.stop()
            currentPlayingKey = nil
        } else {
            Task {
                if let url = await ITunesSearchService.getPreviewUrl(title: song.title, artist: song.artist) {
                    await MainActor.run {
                        previewPlayer.play(url: url, trackKey: key)
                        currentPlayingKey = key
                    }
                }
            }
        }
    }
    
    private func regeneratePlaylist() {
        guard !isRegenerating else { return }
        isRegenerating = true
        let normalizedVibe = normalizeVibe(displayedPlaylist.vibe)
        guard let vibeOption = PlaylistWidgetView.VibeOption(rawValue: normalizedVibe) else {
            isRegenerating = false
            return
        }
        let energy = (displayedPlaylist.energy.flatMap { EnergyLevel(rawValue: $0) }) ?? .balanced
        let era = EraOption.fromStored(displayedPlaylist.era)
        let mood = (displayedPlaylist.mood.flatMap { MoodOption(rawValue: $0) }) ?? .none
        let playlistId = displayedPlaylist.id
        Task {
            do {
                let result = try await SupabaseService.shared.generatePlaylist(
                    vibe: vibeOption.rawValue,
                    datePlanTitle: displayedPlaylist.datePlanTitle,
                    stops: nil,
                    era: era == .any ? nil : era.rawValue,
                    mood: mood == .none ? nil : mood.rawValue,
                    energy: energy.rawValue
                )
                let now = ISO8601DateFormatter().string(from: Date())
                let newSongs = result.songs.map { s in
                    SavedPlaylistSong(title: s.title, artist: s.artist, isCustom: false, addedAt: now)
                }
                await MainActor.run {
                    storage.updateSongs(playlistId: playlistId, songs: newSongs)
                    if let updated = storage.getPlaylist(id: playlist.id) { playlist = updated }
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    let datePlaylist = PlaylistWidgetView.generateSongsForVibeStatic(
                        vibe: vibeOption,
                        energy: energy,
                        era: era,
                        mood: mood,
                        excludingSongKeys: Set(currentSongs.map { "\($0.title)|\($0.artist)" })
                    )
                    let fallbackSongs = datePlaylist.songs.map { s in
                        SavedPlaylistSong(title: s.title, artist: s.artist, isCustom: false, addedAt: ISO8601DateFormatter().string(from: Date()))
                    }
                    storage.updateSongs(playlistId: playlistId, songs: fallbackSongs)
                    if let updated = storage.getPlaylist(id: playlist.id) { playlist = updated }
                    isRegenerating = false
                }
            }
        }
    }
    
    private func normalizeVibe(_ vibe: String) -> String {
        let v = vibe.lowercased()
        if v == "classical" { return "classic" }
        return v
    }
    
    private func savePlaylistTitle() {
        let trimmed = editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isEditingTitle = false
            return
        }
        var updated = displayedPlaylist
        updated.name = trimmed
        storage.updatePlaylist(updated)
        if let p = storage.getPlaylist(id: playlist.id) { playlist = p }
        isEditingTitle = false
    }
}

// MARK: - Saved Song Row (title, artist, play preview, Replace, Delete)
struct SavedSongRow: View {
    let song: SavedPlaylistSong
    let index: Int
    var isPlaying: Bool = false
    let onPlayPreview: () -> Void
    let onReplace: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.luxuryMaroonLight)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(index)")
                        .font(Font.inter(13, weight: .medium))
                        .foregroundColor(Color.luxuryMuted)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(Font.playfair(14, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(1)
                Text(song.artist)
                    .font(Font.inter(12))
                    .foregroundColor(Color.luxuryMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onPlayPreview) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 32, height: 32)
            }
            Button(action: onReplace) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 28, height: 28)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
                    .foregroundColor(Color.luxuryError)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

