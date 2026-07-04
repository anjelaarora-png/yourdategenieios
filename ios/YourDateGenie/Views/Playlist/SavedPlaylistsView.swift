import SwiftUI

/// Saved playlists — recent first, then grouped by vibe.
struct SavedPlaylistsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = PlaylistStorageManager.shared
    @State private var selectedPlaylistId: String?

    private let vibeEmojis: [String: String] = [
        "romantic": "💕", "pop": "🎵", "upbeat": "🎉", "chill": "🌙", "adventurous": "✨",
        "jazzy": "🎷", "indie": "🎸", "classic": "🎻", "rnb": "🎤",
        "latin": "🌴", "afrobeats": "🔥", "kpop": "💜", "reggae": "🎵", "country": "🤠",
        "bollywood": "🎬", "arabic": "🕌", "jpop": "🌸", "rock": "🤘", "electronic": "⚡", "blues": "🎸"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if storage.playlists.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            PlaylistScreenStyle.sectionLabel(title: "Saved playlists", icon: "music.note.list")
                            ForEach(storage.recentPlaylists) { playlist in
                                playlistRow(playlist)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Playlists")
                        .font(Font.bodySerif(18, weight: .regular))
                        .foregroundColor(Color.accentGold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color.accentGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: Binding(
                get: { selectedPlaylistId != nil },
                set: { if !$0 { selectedPlaylistId = nil } }
            )) {
                if let id = selectedPlaylistId {
                    SavedPlaylistDetailView(playlistId: id) {
                        selectedPlaylistId = nil
                    }
                }
            }
            .task { await refreshFromCloud() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            MusicRecordAnimationView(size: 88, showNotes: true)
            Text("No playlists yet")
                .font(Font.bodySerif(24, weight: .regular))
                .foregroundColor(Color.accentGold)
            Text("Generate a soundtrack from your date plan, name it, and it'll show up here.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func playlistRow(_ playlist: SavedPlaylist) -> some View {
        Button {
            selectedPlaylistId = playlist.id
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.creamCard.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text(vibeEmojis[playlist.vibe] ?? "🎵")
                        .font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(Font.bodySerif(16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)
                    Text(playlist.datePlanTitle)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .lineLimit(1)
                    Text("\(playlist.songs.count) songs")
                        .font(Font.bodySans(11, weight: .medium))
                        .foregroundColor(Color.textPrimary.opacity(0.45))
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.luxuryCreamMuted.opacity(0.7))
            }
            .padding(14)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxeSurfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func refreshFromCloud() async {
        let list: [DBPlaylist]?
        if let coupleId = UserProfileManager.shared.coupleId {
            list = try? await SupabaseService.shared.getPlaylists(coupleId: coupleId)
        } else if let userId = UserProfileManager.shared.userId {
            list = try? await SupabaseService.shared.getPlaylists(userId: userId)
        } else {
            list = nil
        }
        if let list, !list.isEmpty {
            await MainActor.run { storage.mergeFromSupabase(dbPlaylists: list) }
        }
    }
}

// MARK: - Saved Playlist Detail

private struct ReplaceSongItem: Identifiable {
    let songId: String
    var id: String { songId }
}

struct SavedPlaylistDetailView: View {
    let playlistId: String
    let onDismiss: () -> Void

    @ObservedObject private var storage = PlaylistStorageManager.shared
    @State private var showAddSong = false
    @State private var replaceSongItem: ReplaceSongItem?
    @State private var isEditingTitle = false
    @State private var editingTitleText = ""
    @State private var isRegenerating = false
    @StateObject private var previewPlayer = PreviewPlayerManager()
    @State private var currentPlayingKey: String?

    private var displayedPlaylist: SavedPlaylist? {
        storage.getPlaylist(id: playlistId)
    }

    private let vibeEmojis: [String: String] = [
        "romantic": "💕", "pop": "🎵", "upbeat": "🎉", "chill": "🌙", "adventurous": "✨",
        "jazzy": "🎷", "indie": "🎸", "classic": "🎻", "rnb": "🎤",
        "latin": "🌴", "afrobeats": "🔥", "kpop": "💜", "reggae": "🎵", "country": "🤠",
        "bollywood": "🎬", "arabic": "🕌", "jpop": "🌸", "rock": "🤘", "electronic": "⚡", "blues": "🎸"
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let playlist = displayedPlaylist {
                    detailContent(playlist)
                } else {
                    VStack(spacing: 16) {
                        ProgressView().tint(Color.accentGold)
                        Text("Playlist not found")
                            .font(Font.bodySans(14))
                            .foregroundColor(Color.luxuryCreamMuted)
                        Button("Close", action: onDismiss)
                            .foregroundColor(Color.accentGold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundPrimary)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(displayedPlaylist?.name ?? "Playlist")
                        .font(Font.bodySerif(18, weight: .regular))
                        .foregroundColor(Color.accentGold)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(Color.accentGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func detailContent(_ playlist: SavedPlaylist) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    if isEditingTitle {
                        LoveNoteCreamCard(bannerSubtitle: "Playlist name") {
                            HStack(spacing: 10) {
                                TextField("Playlist name", text: $editingTitleText)
                                    .font(Font.bodySerif(16, weight: .regular))
                                    .foregroundColor(Color.textOnCard)
                                    .submitLabel(.done)
                                    .onSubmit { savePlaylistTitle() }
                                Button(action: savePlaylistTitle) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.accentGold)
                                }
                            }
                            .padding(12)
                        }
                    } else {
                        Button {
                            editingTitleText = playlist.name
                            isEditingTitle = true
                        } label: {
                            HStack(spacing: 8) {
                                Text(playlist.name)
                                    .font(Font.bodySerif(24, weight: .regular))
                                    .foregroundColor(Color.accentGold)
                                    .multilineTextAlignment(.center)
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.accentGold.opacity(0.85))
                            }
                        }
                        .buttonStyle(.plain)

                        let subtitleParts: [String] = [
                            playlist.vibe.capitalized,
                            playlist.energy.flatMap { EnergyLevel(rawValue: $0) }.map { $0.label },
                            playlist.era.flatMap { EraOption.fromStored($0) }.flatMap { $0 != .any ? $0.label : nil },
                            playlist.mood.flatMap { MoodOption(rawValue: $0) }.flatMap { $0 != .none ? $0.label : nil }
                        ].compactMap { $0 }
                        if !subtitleParts.isEmpty {
                            Text(subtitleParts.joined(separator: " · "))
                                .font(Font.bodySans(12, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        Text("From: \(playlist.datePlanTitle)")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    outlineAction(title: isRegenerating ? "Regenerating…" : "Regenerate", icon: "arrow.clockwise") {
                        regeneratePlaylist(playlist)
                    }
                    .disabled(isRegenerating)
                    outlineAction(title: "Add Song", icon: "plus.circle") {
                        showAddSong = true
                    }
                }

                PlaylistScreenStyle.sectionLabel(title: "Tracks", icon: "music.note")
                    .frame(maxWidth: .infinity, alignment: .leading)

                LoveNoteCreamCard(bannerSubtitle: "\(playlist.songs.count) songs") {
                    VStack(spacing: 0) {
                        ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
                            SavedSongRow(
                                song: song,
                                index: index + 1,
                                isPlaying: currentPlayingKey == "\(song.title)|\(song.artist)",
                                onPlayPreview: { playPreview(for: song) },
                                onReplace: { replaceSongItem = ReplaceSongItem(songId: song.id) },
                                onDelete: {
                                    storage.removeSong(playlistId: playlistId, songId: song.id)
                                }
                            )
                            if index < playlist.songs.count - 1 {
                                Divider().background(Color.maroonBorderTint)
                            }
                        }
                    }
                }

                Button(role: .destructive) {
                    storage.deletePlaylist(id: playlistId)
                    onDismiss()
                } label: {
                    Label("Delete Playlist", systemImage: "trash")
                        .font(Font.bodySans(14, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showAddSong) {
            SongSearchView(title: "Add Song") { title, artist in
                storage.addSong(playlistId: playlistId, title: title, artist: artist)
            }
        }
        .sheet(item: $replaceSongItem) { item in
            SongSearchView(title: "Replace Song") { title, artist in
                storage.replaceSong(playlistId: playlistId, songId: item.songId, newTitle: title, newArtist: artist)
                replaceSongItem = nil
            }
        }
        .onChange(of: previewPlayer.isPlaying) { _, isPlaying in
            if !isPlaying { currentPlayingKey = nil }
        }
    }

    private func outlineAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
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

    private func regeneratePlaylist(_ playlist: SavedPlaylist) {
        guard !isRegenerating else { return }
        isRegenerating = true
        let normalizedVibe = normalizeVibe(playlist.vibe)
        guard let vibeOption = PlaylistWidgetView.VibeOption(rawValue: normalizedVibe) else {
            isRegenerating = false
            return
        }
        let energy = (playlist.energy.flatMap { EnergyLevel(rawValue: $0) }) ?? .balanced
        let era = EraOption.fromStored(playlist.era)
        let mood = (playlist.mood.flatMap { MoodOption(rawValue: $0) }) ?? .none
        Task {
            do {
                let result = try await SupabaseService.shared.generatePlaylist(
                    vibe: vibeOption.rawValue,
                    datePlanTitle: playlist.datePlanTitle,
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
                    isRegenerating = false
                }
            } catch {
                await MainActor.run {
                    let currentKeys = Set(playlist.songs.map { "\($0.title)|\($0.artist)" })
                    let datePlaylist = PlaylistWidgetView.generateSongsForVibeStatic(
                        vibe: vibeOption,
                        energy: energy,
                        era: era,
                        mood: mood,
                        excludingSongKeys: currentKeys
                    )
                    let fallbackSongs = datePlaylist.songs.map { s in
                        SavedPlaylistSong(title: s.title, artist: s.artist, isCustom: false, addedAt: ISO8601DateFormatter().string(from: Date()))
                    }
                    storage.updateSongs(playlistId: playlistId, songs: fallbackSongs)
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
        guard !trimmed.isEmpty, var updated = displayedPlaylist else {
            isEditingTitle = false
            return
        }
        updated.name = trimmed
        storage.updatePlaylist(updated)
        isEditingTitle = false
    }
}

// MARK: - Saved Song Row

struct SavedSongRow: View {
    let song: SavedPlaylistSong
    let index: Int
    var isPlaying: Bool = false
    let onPlayPreview: () -> Void
    let onReplace: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(Font.bodySans(12, weight: .semibold))
                .foregroundColor(Color.textMutedOnCard)
                .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(Font.bodySerif(14, weight: .semibold))
                    .foregroundColor(Color.textOnCard)
                    .lineLimit(1)
                Text(song.artist)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.textMutedOnCard)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button(action: onPlayPreview) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.accentGold)
            }
            Button(action: onReplace) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13))
                    .foregroundColor(Color.accentGold)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 13))
                    .foregroundColor(Color.luxuryError)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
