import SwiftUI

struct PlaylistWidgetView: View {
    let planTitle: String
    var planId: UUID? = nil
    var stops: [PlaylistStop]? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEnergy: EnergyLevel?
    @State private var selectedVibe: VibeOption = .romantic
    @State private var selectedEra: EraOption = .any
    @State private var selectedMood: MoodOption = .none
    @State private var isGenerating = false
    @State private var playlist: DatePlaylist?
    @State private var currentlyPlaying: String?
    @State private var copiedToClipboard = false
    @State private var showAddSong = false
    @State private var replaceSongItem: IdentifiableInt?
    @State private var showSavedPlaylists = false
    @State private var savedMessage = false
    @State private var moreVibesExpanded = false
    @State private var playlistGenerationError: String?
    /// Stable row id for `playlists.playlist_id` when `planId` is nil (upserts must not mint a new UUID each save).
    @State private var widgetPlaylistRowId = UUID()
    @StateObject private var storage = PlaylistStorageManager.shared
    @StateObject private var previewPlayer = PreviewPlayerManager()
    
    enum VibeOption: String, CaseIterable {
        case romantic = "romantic"
        case pop = "pop"
        case upbeat = "upbeat"
        case chill = "chill"
        case jazzy = "jazzy"
        case indie = "indie"
        case classic = "classic"
        case rnb = "rnb"
        case adventurous = "adventurous"
        case latin = "latin"
        case afrobeats = "afrobeats"
        case kpop = "kpop"
        case reggae = "reggae"
        case country = "country"
        case bollywood = "bollywood"
        case arabic = "arabic"
        case jpop = "jpop"
        case rock = "rock"
        case electronic = "electronic"
        case blues = "blues"
        
        var label: String {
            switch self {
            case .romantic: return "Romantic"
            case .pop: return "Pop"
            case .upbeat: return "Upbeat"
            case .chill: return "Chill"
            case .jazzy: return "Jazzy"
            case .indie: return "Indie"
            case .classic: return "Classic"
            case .rnb: return "R&B"
            case .adventurous: return "Eclectic"
            case .latin: return "Latin"
            case .afrobeats: return "Afrobeats"
            case .kpop: return "K-Pop"
            case .reggae: return "Reggae"
            case .country: return "Country"
            case .bollywood: return "Bollywood"
            case .arabic: return "Arabic"
            case .jpop: return "J-Pop"
            case .rock: return "Rock"
            case .electronic: return "Electronic"
            case .blues: return "Blues"
            }
        }
        
        var emoji: String {
            switch self {
            case .romantic: return "💕"
            case .pop: return "🎵"
            case .upbeat: return "🎉"
            case .chill: return "🌙"
            case .jazzy: return "🎷"
            case .indie: return "🎸"
            case .classic: return "🎻"
            case .rnb: return "🎤"
            case .adventurous: return "✨"
            case .latin: return "🌴"
            case .afrobeats: return "🔥"
            case .kpop: return "💜"
            case .reggae: return "🎵"
            case .country: return "🤠"
            case .bollywood: return "🎬"
            case .arabic: return "🕌"
            case .jpop: return "🌸"
            case .rock: return "🤘"
            case .electronic: return "⚡"
            case .blues: return "🎸"
            }
        }
        
        var description: String {
            switch self {
            case .romantic: return "Intimate love songs"
            case .pop: return "Pop hits & radio favorites"
            case .upbeat: return "Dance & party hits"
            case .chill: return "Lo-fi & relaxed"
            case .jazzy: return "Smooth jazz & soul"
            case .indie: return "Alternative vibes"
            case .classic: return "Timeless standards"
            case .rnb: return "Modern R&B"
            case .adventurous: return "Genre-bending"
            case .latin: return "Salsa, reggaeton & more"
            case .afrobeats: return "Afrobeats & amapiano"
            case .kpop: return "K-Pop & K-R&B"
            case .reggae: return "Reggae & dancehall"
            case .country: return "Country & Americana"
            case .bollywood: return "Bollywood & Indian"
            case .arabic: return "Arabic & Middle Eastern"
            case .jpop: return "J-Pop & Japanese"
            case .rock: return "Rock & alternative"
            case .electronic: return "Electronic & EDM"
            case .blues: return "Blues & soul"
            }
        }
        
        /// Key vibes shown prominently on the main screen (first 8).
        static var keyVibes: [VibeOption] {
            [.romantic, .pop, .upbeat, .chill, .jazzy, .classic, .rnb, .adventurous]
        }
        
        /// Additional famous genres in the "More" section (global).
        static var moreVibes: [VibeOption] {
            [.indie, .latin, .afrobeats, .kpop, .reggae, .country, .bollywood, .arabic, .jpop, .rock, .electronic, .blues]
        }
    }
    
    enum MusicPlatform: String, CaseIterable {
        case spotify
        case apple
        case youtube
        
        var name: String {
            switch self {
            case .spotify: return "Spotify"
            case .apple: return "Apple Music"
            case .youtube: return "YouTube Music"
            }
        }
        
        var color: Color {
            switch self {
            case .spotify: return Color(hex: "1DB954")
            case .apple: return Color(hex: "FC3C44")
            case .youtube: return Color(hex: "FF0000")
            }
        }
        
        var icon: String {
            switch self {
            case .spotify: return "play.circle.fill"
            case .apple: return "music.note"
            case .youtube: return "play.rectangle.fill"
            }
        }
        
        func searchUrl(for query: String) -> String {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            switch self {
            case .spotify:
                return "https://open.spotify.com/search/\(encoded)"
            case .apple:
                return "https://music.apple.com/search?term=\(encoded)"
            case .youtube:
                return "https://music.youtube.com/search?q=\(encoded)"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if let currentPlaylist = playlist {
                    playlistContent(currentPlaylist)
                } else {
                    generateView
                }
                
                if let err = playlistGenerationError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.luxuryGold)
                        Text("Showing suggestions. \(err)")
                            .font(Font.inter(12, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button("OK") { playlistGenerationError = nil }
                            .font(Font.inter(12, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.luxuryMaroonLight.opacity(0.95))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.luxuryGold.opacity(0.3)),
                        alignment: .bottom
                    )
                    .padding(.horizontal, 0)
                }
            }
            .navigationTitle("Date Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(Font.inter(16, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Your Playlists") {
                        showSavedPlaylists = true
                    }
                    .font(Font.inter(14, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSavedPlaylists) {
                SavedPlaylistsView()
            }
            .sheet(isPresented: $showAddSong) {
                SongSearchView(title: "Add Song") { title, artist in
                    addSong(title: title, artist: artist)
                }
            }
            .sheet(item: $replaceSongItem) { ident in
                SongSearchView(title: "Replace Song") { title, artist in
                    replaceSong(at: ident.value, title: title, artist: artist)
                    replaceSongItem = nil
                }
            }
            .onChange(of: previewPlayer.isPlaying) { _, isPlaying in
                if !isPlaying { currentlyPlaying = nil }
            }
        }
    }
    
    private func addSong(title: String, artist: String) {
        guard var current = playlist else { return }
        let newSong = PlaylistSong(title: title, artist: artist, duration: "—", energy: nil, era: nil)
        playlist = DatePlaylist(name: current.name, mood: current.mood, totalDuration: current.totalDuration, songs: current.songs + [newSong])
    }
    
    private func replaceSong(at index: Int, title: String, artist: String) {
        guard var current = playlist, index >= 0, index < current.songs.count else { return }
        var songs = current.songs
        songs[index] = PlaylistSong(title: title, artist: artist, duration: "—", energy: nil, era: nil)
        playlist = DatePlaylist(name: current.name, mood: current.mood, totalDuration: current.totalDuration, songs: songs)
    }
    
    private func removeSong(at index: Int) {
        guard var current = playlist, index >= 0, index < current.songs.count else { return }
        var songs = current.songs
        songs.remove(at: index)
        playlist = DatePlaylist(name: current.name, mood: current.mood, totalDuration: current.totalDuration, songs: songs)
    }
    
    private func savePlaylistToStorage() {
        guard let current = playlist else { return }
        let songTuples = current.songs.map { (title: $0.title, artist: $0.artist, duration: $0.duration) }
        _ = storage.savePlaylist(
            name: "\(selectedVibe.label) Playlist",
            datePlanTitle: planTitle,
            vibe: selectedVibe.rawValue,
            songs: songTuples,
            stops: stops,
            energy: selectedEnergy?.rawValue,
            era: selectedEra == .any ? nil : selectedEra.rawValue,
            mood: selectedMood == .none ? nil : selectedMood.rawValue
        )
        savedMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedMessage = false }
        persistPlaylistToSupabaseIfNeeded(current)
    }
    
    // MARK: - Generate View
    private var generateView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header: vinyl playing with musical notes
                VStack(spacing: 14) {
                    MusicRecordAnimationView(size: 100, showNotes: true)
                    
                    Text("Create Your Soundtrack")
                        .font(Font.tangerine(42, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("Curated for your moment — pick a vibe and we’ll set the mood.")
                        .font(Font.playfair(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                
                // Step 1: Energy
                VStack(alignment: .leading, spacing: 14) {
                    Text("How's the energy?")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .padding(.horizontal, 20)
                    HStack(spacing: 12) {
                        ForEach(EnergyLevel.allCases, id: \.self) { level in
                            Button {
                                selectedEnergy = level
                            } label: {
                                Text(level.label)
                                    .font(Font.inter(14, weight: .medium))
                                    .foregroundColor(selectedEnergy == level ? Color.luxuryMaroon : Color.luxuryCream)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedEnergy == level ? Color.luxuryGold : Color.luxuryMaroonLight)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Step 2: Genre (when energy selected)
                if selectedEnergy != nil {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Pick a genre")
                            .font(Font.playfair(16, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                            .padding(.horizontal, 20)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(VibeOption.keyVibes, id: \.self) { vibe in
                                VibeCard(vibe: vibe, isSelected: selectedVibe == vibe, action: { selectedVibe = vibe })
                            }
                        }
                        .padding(.horizontal, 20)
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { moreVibesExpanded.toggle() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: moreVibesExpanded ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.luxuryGold)
                                    Text("More vibes")
                                        .font(Font.playfair(15, weight: .medium))
                                        .foregroundColor(Color.luxuryCreamMuted)
                                }
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            if moreVibesExpanded {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(VibeOption.moreVibes, id: \.self) { vibe in
                                        VibeCard(vibe: vibe, isSelected: selectedVibe == vibe, action: { selectedVibe = vibe })
                                    }
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // Optional: Era
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Era")
                            .font(Font.playfair(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EraOption.allCases, id: \.self) { era in
                                    Button { selectedEra = era } label: {
                                        Text(era.label)
                                            .font(Font.inter(12, weight: .medium))
                                            .foregroundColor(selectedEra == era ? Color.luxuryMaroon : Color.luxuryCreamMuted)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedEra == era ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.6))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Optional: Mood
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood")
                            .font(Font.playfair(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .padding(.horizontal, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MoodOption.allCases, id: \.self) { mood in
                                    Button { selectedMood = mood } label: {
                                        Text(mood.label)
                                            .font(Font.inter(12, weight: .medium))
                                            .foregroundColor(selectedMood == mood ? Color.luxuryMaroon : Color.luxuryCreamMuted)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedMood == mood ? Color.luxuryGold : Color.luxuryMaroonLight.opacity(0.6))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Generate button
                    Button {
                        generatePlaylist()
                    } label: {
                        HStack(spacing: 10) {
                            if isGenerating {
                                ProgressView()
                                    .tint(Color.luxuryMaroon)
                            } else {
                                Image(systemName: "play.fill")
                                Text("Generate \(selectedVibe.label) Playlist")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    .disabled(isGenerating)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Playlist Content
    private func playlistContent(_ currentPlaylist: DatePlaylist) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.luxuryGold.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 36))
                            .foregroundStyle(LinearGradient.goldShimmer)
                    }
                    
                    VStack(spacing: 6) {
                        Text(currentPlaylist.name)
                            .font(Font.displayTitle())
                            .foregroundColor(Color.luxuryGold)
                        
                        HStack(spacing: 8) {
                            Text(selectedVibe.emoji)
                            Text(currentPlaylist.mood)
                                .font(Font.playfair(15, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        
                        Text("\(currentPlaylist.songs.count) songs · \(currentPlaylist.totalDuration)")
                            .font(Font.inter(12, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }
                .padding(.top, 20)
                
                // Platform buttons - Open All
                VStack(spacing: 12) {
                    Text("Open all songs on:")
                        .font(Font.playfair(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    
                    HStack(spacing: 12) {
                        ForEach(MusicPlatform.allCases, id: \.self) { platform in
                            PlatformButton(platform: platform) {
                                openAllOnPlatform(platform, songs: currentPlaylist.songs)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Save & Copy
                HStack(spacing: 12) {
                    Button {
                        savePlaylistToStorage()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: savedMessage ? "checkmark.circle.fill" : "square.and.arrow.down")
                            Text(savedMessage ? "Saved!" : "Save Playlist")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                    .disabled(savedMessage)
                    
                    Button {
                        copyPlaylistToClipboard(currentPlaylist)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(copiedToClipboard ? "Copied!" : "Copy")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                }
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
                
                // Song list
                VStack(spacing: 2) {
                    ForEach(Array(currentPlaylist.songs.enumerated()), id: \.element.id) { index, song in
                        SongRow(
                            song: song,
                            index: index + 1,
                            isPlaying: currentlyPlaying == song.id.uuidString,
                            onTap: {
                                let key = "\(song.title)|\(song.artist)"
                                if previewPlayer.currentTrackKey == key, previewPlayer.isPlaying {
                                    previewPlayer.stop()
                                    currentlyPlaying = nil
                                } else {
                                    Task {
                                        if let url = await ITunesSearchService.getPreviewUrl(title: song.title, artist: song.artist) {
                                            await MainActor.run {
                                                previewPlayer.play(url: url, trackKey: key)
                                                withAnimation { currentlyPlaying = song.id.uuidString }
                                            }
                                        }
                                    }
                                }
                            },
                            onOpenPlatform: { platform in
                                openSongOnPlatform(song, platform: platform)
                            },
                            onReplace: { replaceSongItem = IdentifiableInt(value: index) },
                            onDelete: { removeSong(at: index) }
                        )
                    }
                }
                .luxuryCard(hasBorder: false)
                .padding(.horizontal, 20)
                
                // Actions
                HStack(spacing: 12) {
                    Button {
                        resetPlaylist()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                    
                    Button {
                        playlist = nil
                        playlistGenerationError = nil
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Change Vibe")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryOutlineButtonStyle(isSmall: true))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Functions
    private func resetPlaylist() {
        generatePlaylist()
    }
    
    private func generatePlaylist() {
        guard let energy = selectedEnergy else { return }
        isGenerating = true
        let vibe = selectedVibe
        let era = selectedEra
        let mood = selectedMood
        let stopsForApi = stops
        let planTitleForApi = planTitle
        Task {
            do {
                let result = try await SupabaseService.shared.generatePlaylist(
                    vibe: vibe.rawValue,
                    datePlanTitle: planTitleForApi,
                    stops: stopsForApi?.map { (name: $0.name, venueType: $0.venueType) },
                    era: era == .any ? nil : era.rawValue,
                    mood: mood == .none ? nil : mood.rawValue,
                    energy: energy.rawValue
                )
                let songs = result.songs.map { s in
                    PlaylistSong(
                        title: s.title,
                        artist: s.artist,
                        duration: "—",
                        energy: nil,
                        era: nil
                    )
                }
                let datePlaylist = DatePlaylist(
                    name: result.playlistName,
                    mood: result.vibeDescription,
                    totalDuration: "~\(songs.count * 4) min",
                    songs: songs
                )
                await MainActor.run {
                    self.playlist = datePlaylist
                    self.isGenerating = false
                    self.playlistGenerationError = nil
                    persistPlaylistToSupabaseIfNeeded(datePlaylist)
                }
            } catch {
                let errorMessage = (error as? SupabaseError)?.localizedDescription ?? error.localizedDescription
                await MainActor.run {
                    self.playlistGenerationError = errorMessage
                    let currentKeys = playlist.map { Set($0.songs.map { "\($0.title)|\($0.artist)" }) } ?? []
                    self.playlist = Self.generateSongsForVibeStatic(
                        vibe: vibe,
                        energy: energy,
                        era: era,
                        mood: mood,
                        excludingSongKeys: currentKeys.isEmpty ? nil : currentKeys
                    )
                    self.isGenerating = false
                }
            }
        }
    }
    
    /// Persist current playlist to Supabase when the user has a session (resolves couple_id if needed).
    private func persistPlaylistToSupabaseIfNeeded(_ datePlaylist: DatePlaylist) {
        let tracks = datePlaylist.songs.enumerated().map { index, s in
            PlaylistTrack(
                trackNumber: index + 1,
                title: s.title,
                artist: s.artist,
                album: nil,
                duration: s.duration,
                whyItFits: nil
            )
        }
        let playlistRowId = planId ?? widgetPlaylistRowId
        Task {
            do {
                let coupleId = try await SupabaseService.shared.resolveCoupleIdForCurrentUser()
                let dbPlaylist = DBPlaylist(
                    playlistId: playlistRowId,
                    planId: planId,
                    coupleId: coupleId,
                    title: datePlaylist.name,
                    description: datePlaylist.mood,
                    tracks: tracks,
                    totalDurationMinutes: max(1, datePlaylist.songs.count * 4),
                    generatedAt: Date()
                )
                _ = try await SupabaseService.shared.upsertPlaylist(dbPlaylist)
                print("[PlaylistWidget] upsertPlaylist success playlist_id=\(dbPlaylist.playlistId)")
            } catch {
                print("[PlaylistWidget] persistPlaylistToSupabaseIfNeeded failed (no session or couple): \(error)")
            }
        }
    }
    
    /// Shared with SavedPlaylistsView for local regenerate.
    static func generateSongsForVibeStatic(
        vibe: VibeOption,
        energy: EnergyLevel,
        era: EraOption = .any,
        mood: MoodOption = .none,
        excludingSongKeys: Set<String>? = nil
    ) -> DatePlaylist {
        generateSongsForVibeInternal(vibe, energy: energy, era: era, mood: mood, excludingSongKeys: excludingSongKeys ?? [])
    }
    
    private func generateSongsForVibe(_ vibe: VibeOption) -> DatePlaylist {
        Self.generateSongsForVibeInternal(vibe, energy: .balanced, era: .any, mood: .none)
    }
    
    /// Picks a random subset so each generate/regenerate gives different songs.
    private static func sampleSongs(from pool: [PlaylistSong], count: Int = 8) -> [PlaylistSong] {
        let shuffled = pool.shuffled()
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
    
    private static func generateSongsForVibeInternal(
        _ vibe: VibeOption,
        energy: EnergyLevel,
        era: EraOption = .any,
        mood: MoodOption = .none,
        excludingSongKeys: Set<String> = []
    ) -> DatePlaylist {
        let fullPool: [PlaylistSong]
        let moodLabel: String
        
        switch vibe {
        case .romantic:
            moodLabel = "Intimate & Elegant"
            fullPool = [
                PlaylistSong(title: "La Vie en Rose", artist: "Édith Piaf", duration: "3:45", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "The Way You Look Tonight", artist: "Frank Sinatra", duration: "4:12", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Can't Help Falling in Love", artist: "Elvis Presley", duration: "3:01", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "At Last", artist: "Etta James", duration: "3:02", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Thinking Out Loud", artist: "Ed Sheeran", duration: "4:41", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "A Thousand Years", artist: "Christina Perri", duration: "4:45", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Perfect", artist: "Ed Sheeran", duration: "4:23", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "All of Me", artist: "John Legend", duration: "4:29", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Make You Feel My Love", artist: "Adele", duration: "3:32", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "L-O-V-E", artist: "Nat King Cole", duration: "2:35", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Can't Take My Eyes Off You", artist: "Frankie Valli", duration: "3:23", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Just the Way You Are", artist: "Billy Joel", duration: "4:49", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Something", artist: "The Beatles", duration: "3:02", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Truly Madly Deeply", artist: "Savage Garden", duration: "4:37", energy: .balanced, era: .nineties),
                PlaylistSong(title: "I Will Always Love You", artist: "Whitney Houston", duration: "4:31", energy: .chill, era: .nineties),
                PlaylistSong(title: "Kiss Me", artist: "Ed Sheeran", duration: "3:40", energy: .chill, era: .twentyTensNow),
            ]
        case .pop:
            moodLabel = "Pop Hits & Radio Favorites"
            fullPool = [
                PlaylistSong(title: "Blinding Lights", artist: "The Weeknd", duration: "3:20", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Levitating", artist: "Dua Lipa", duration: "3:23", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Watermelon Sugar", artist: "Harry Styles", duration: "2:54", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Shake It Off", artist: "Taylor Swift", duration: "3:39", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Uptown Funk", artist: "Bruno Mars", duration: "4:30", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Happy", artist: "Pharrell Williams", duration: "3:53", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Flowers", artist: "Miley Cyrus", duration: "3:20", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "As It Was", artist: "Harry Styles", duration: "2:47", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Don't Start Now", artist: "Dua Lipa", duration: "3:03", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Locked Out of Heaven", artist: "Bruno Mars", duration: "3:53", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Shape of You", artist: "Ed Sheeran", duration: "3:53", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Someone Like You", artist: "Adele", duration: "4:45", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Rolling in the Deep", artist: "Adele", duration: "3:48", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Firework", artist: "Katy Perry", duration: "3:47", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Roar", artist: "Katy Perry", duration: "3:43", energy: .energetic, era: .twentyTensNow),
            ]
        case .upbeat:
            moodLabel = "Fun & Energetic"
            fullPool = [
                PlaylistSong(title: "Uptown Funk", artist: "Bruno Mars", duration: "4:30", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Happy", artist: "Pharrell Williams", duration: "3:53", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Can't Stop the Feeling", artist: "Justin Timberlake", duration: "4:00", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Shake It Off", artist: "Taylor Swift", duration: "3:39", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Dance Monkey", artist: "Tones and I", duration: "3:29", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Good as Hell", artist: "Lizzo", duration: "2:39", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Levitating", artist: "Dua Lipa", duration: "3:23", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Blinding Lights", artist: "The Weeknd", duration: "3:20", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Don't Start Now", artist: "Dua Lipa", duration: "3:03", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "As It Was", artist: "Harry Styles", duration: "2:47", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Watermelon Sugar", artist: "Harry Styles", duration: "2:54", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Sunroof", artist: "Nicky Youre & dazy", duration: "2:43", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "About Damn Time", artist: "Lizzo", duration: "3:11", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Flowers", artist: "Miley Cyrus", duration: "3:20", energy: .energetic, era: .twentyTensNow),
            ]
        case .chill:
            moodLabel = "Relaxed & Cozy"
            fullPool = [
                PlaylistSong(title: "Electric Feel", artist: "MGMT", duration: "3:49", energy: .chill, era: .twoThousands),
                PlaylistSong(title: "Dreams", artist: "Fleetwood Mac", duration: "4:14", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Banana Pancakes", artist: "Jack Johnson", duration: "3:12", energy: .chill, era: .twoThousands),
                PlaylistSong(title: "Put Your Records On", artist: "Corinne Bailey Rae", duration: "3:35", energy: .chill, era: .twoThousands),
                PlaylistSong(title: "Sea of Love", artist: "Cat Power", duration: "2:20", energy: .chill, era: .twoThousands),
                PlaylistSong(title: "Skinny Love", artist: "Bon Iver", duration: "3:58", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Cherry Wine", artist: "Hozier", duration: "4:13", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Lost in Japan", artist: "Shawn Mendes", duration: "3:25", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Holocene", artist: "Bon Iver", duration: "5:36", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "The Less I Know the Better", artist: "Tame Impala", duration: "3:36", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Cigarette Daydreams", artist: "Cage the Elephant", duration: "3:24", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Bloom", artist: "The Paper Kites", duration: "3:30", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Riptide", artist: "Vance Joy", duration: "3:24", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Stubborn Love", artist: "The Lumineers", duration: "4:39", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Ophelia", artist: "The Lumineers", duration: "2:58", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Flume", artist: "Bon Iver", duration: "3:39", energy: .chill, era: .twentyTensNow),
            ]
        case .jazzy:
            moodLabel = "Smooth & Sophisticated"
            fullPool = [
                PlaylistSong(title: "Fly Me to the Moon", artist: "Frank Sinatra", duration: "2:31", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Take Five", artist: "Dave Brubeck", duration: "5:24", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Feeling Good", artist: "Nina Simone", duration: "2:55", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Blue in Green", artist: "Miles Davis", duration: "5:37", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Girl from Ipanema", artist: "Stan Getz", duration: "5:24", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "My Funny Valentine", artist: "Chet Baker", duration: "4:03", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Autumn Leaves", artist: "Nat King Cole", duration: "3:03", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Summertime", artist: "Ella Fitzgerald", duration: "4:58", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "What a Wonderful World", artist: "Louis Armstrong", duration: "2:21", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Lullaby of Birdland", artist: "Ella Fitzgerald", duration: "3:59", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Strange Fruit", artist: "Billie Holiday", duration: "3:12", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Round Midnight", artist: "Thelonious Monk", duration: "3:13", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "So What", artist: "Miles Davis", duration: "9:22", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Take the A Train", artist: "Duke Ellington", duration: "2:54", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "In a Sentimental Mood", artist: "Duke Ellington", duration: "4:15", energy: .chill, era: .seventiesEighties),
            ]
        case .indie:
            moodLabel = "Alternative & Artistic"
            fullPool = [
                PlaylistSong(title: "Lover, You Should've Come Over", artist: "Jeff Buckley", duration: "6:43", energy: .balanced, era: .nineties),
                PlaylistSong(title: "Motion Sickness", artist: "Phoebe Bridgers", duration: "3:47", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Pink + White", artist: "Frank Ocean", duration: "3:04", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Two Weeks", artist: "Grizzly Bear", duration: "4:03", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Midnight City", artist: "M83", duration: "4:03", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Robbers", artist: "The 1975", duration: "4:15", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Youth", artist: "Daughter", duration: "4:50", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Myth", artist: "Beach House", duration: "4:18", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "First Day of My Life", artist: "Bright Eyes", duration: "3:08", energy: .chill, era: .twoThousands),
                PlaylistSong(title: "The Scientist", artist: "Coldplay", duration: "5:09", energy: .balanced, era: .twoThousands),
                PlaylistSong(title: "Skinny Love", artist: "Bon Iver", duration: "3:58", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Such Great Heights", artist: "The Postal Service", duration: "4:26", energy: .balanced, era: .twoThousands),
                PlaylistSong(title: "1901", artist: "Phoenix", duration: "3:13", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Dog Days Are Over", artist: "Florence + The Machine", duration: "4:12", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Home", artist: "Edward Sharpe & The Magnetic Zeros", duration: "5:03", energy: .energetic, era: .twentyTensNow),
            ]
        case .classic:
            moodLabel = "Timeless & Elegant"
            fullPool = [
                PlaylistSong(title: "Unchained Melody", artist: "The Righteous Brothers", duration: "3:36", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Your Song", artist: "Elton John", duration: "4:01", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Stand By Me", artist: "Ben E. King", duration: "2:58", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Let's Stay Together", artist: "Al Green", duration: "3:18", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Wonderful Tonight", artist: "Eric Clapton", duration: "3:45", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "When a Man Loves a Woman", artist: "Percy Sledge", duration: "2:56", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "In My Life", artist: "The Beatles", duration: "2:27", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "God Only Knows", artist: "The Beach Boys", duration: "2:51", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Something Stupid", artist: "Frank & Nancy Sinatra", duration: "2:50", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "The First Time Ever I Saw Your Face", artist: "Roberta Flack", duration: "4:20", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "My Girl", artist: "The Temptations", duration: "2:57", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "What a Wonderful World", artist: "Louis Armstrong", duration: "2:21", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Fly Me to the Moon", artist: "Frank Sinatra", duration: "2:31", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Moon River", artist: "Audrey Hepburn", duration: "2:42", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Can't Help Falling in Love", artist: "Elvis Presley", duration: "3:01", energy: .chill, era: .seventiesEighties),
            ]
        case .rnb:
            moodLabel = "Smooth & Soulful"
            fullPool = [
                PlaylistSong(title: "Best Part", artist: "Daniel Caesar ft. H.E.R.", duration: "3:29", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Golden", artist: "Jill Scott", duration: "4:14", energy: .balanced, era: .twoThousands),
                PlaylistSong(title: "Adorn", artist: "Miguel", duration: "3:13", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Electric", artist: "Alina Baraz ft. Khalid", duration: "3:00", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Crew Love", artist: "Drake ft. The Weeknd", duration: "3:26", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Often", artist: "The Weeknd", duration: "4:10", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Love Galore", artist: "SZA ft. Travis Scott", duration: "4:35", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Come Through and Chill", artist: "Miguel", duration: "3:29", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Die With a Smile", artist: "Lady Gaga & Bruno Mars", duration: "3:31", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Peaches", artist: "Justin Bieber", duration: "3:18", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Leave the Door Open", artist: "Silk Sonic", duration: "4:02", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Smokin Out the Window", artist: "Silk Sonic", duration: "3:17", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Sure Thing", artist: "Miguel", duration: "3:15", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Location", artist: "Khalid", duration: "3:39", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Redbone", artist: "Childish Gambino", duration: "5:27", energy: .chill, era: .twentyTensNow),
            ]
        case .adventurous:
            moodLabel = "Eclectic & Genre-Bending"
            fullPool = [
                PlaylistSong(title: "Get Lucky", artist: "Daft Punk ft. Pharrell", duration: "6:09", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Redbone", artist: "Childish Gambino", duration: "5:27", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Tame Impala", artist: "Let It Happen", duration: "7:47", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Feel Good Inc.", artist: "Gorillaz", duration: "3:41", energy: .energetic, era: .twoThousands),
                PlaylistSong(title: "Do I Wanna Know?", artist: "Arctic Monkeys", duration: "4:32", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "N.Y. State of Mind", artist: "Nas", duration: "4:53", energy: .balanced, era: .nineties),
                PlaylistSong(title: "Electric Feel", artist: "MGMT", duration: "3:49", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Little Dark Age", artist: "MGMT", duration: "4:59", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Tongue Tied", artist: "Grouplove", duration: "3:38", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Safe and Sound", artist: "Capital Cities", duration: "3:12", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Pumped Up Kicks", artist: "Foster the People", duration: "3:59", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Lisztomania", artist: "Phoenix", duration: "4:01", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Breezeblocks", artist: "alt-J", duration: "3:47", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Oblivion", artist: "Grimes", duration: "4:11", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Intro", artist: "The xx", duration: "2:07", energy: .chill, era: .twentyTensNow),
            ]
        case .latin:
            moodLabel = "Latin & Reggaeton"
            fullPool = [
                PlaylistSong(title: "Despacito", artist: "Luis Fonsi ft. Daddy Yankee", duration: "3:48", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Vivir Mi Vida", artist: "Marc Anthony", duration: "3:31", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Dákiti", artist: "Bad Bunny & Jhay Cortez", duration: "3:25", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Bailando", artist: "Enrique Iglesias", duration: "4:03", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "La Gozadera", artist: "Gente de Zona ft. Marc Anthony", duration: "3:23", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Yo No Sé Mañana", artist: "Luis Enrique", duration: "4:19", energy: .balanced, era: .twoThousands),
                PlaylistSong(title: "Propuesta Indecente", artist: "Romeo Santos", duration: "3:55", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Con Calma", artist: "Daddy Yankee ft. Snow", duration: "3:13", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Taki Taki", artist: "DJ Snake ft. Selena Gomez", duration: "3:32", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Mi Gente", artist: "J Balvin & Willy William", duration: "3:05", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Te Bote", artist: "Casper, Nio Garcia, Darell", duration: "3:47", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "X", artist: "Nicky Jam & J Balvin", duration: "2:53", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "I Like It", artist: "Cardi B ft. Bad Bunny", duration: "4:13", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Vente Pa' Ca", artist: "Ricky Martin", duration: "4:00", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Hawái", artist: "Maluma", duration: "3:20", energy: .chill, era: .twentyTensNow),
            ]
        case .afrobeats:
            moodLabel = "Afrobeats & Amapiano"
            fullPool = [
                PlaylistSong(title: "Last Last", artist: "Burna Boy", duration: "2:52", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Love Nwantiti", artist: "CKay", duration: "2:55", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Essence", artist: "Wizkid ft. Tems", duration: "4:08", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Peru", artist: "Fireboy DML", duration: "2:33", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Calm Down", artist: "Rema ft. Selena Gomez", duration: "3:59", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Soweto", artist: "Victony ft. Tempoe", duration: "2:28", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "KU LO SA", artist: "Oxlade", duration: "2:35", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Rush", artist: "Ayra Starr", duration: "3:05", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "People", artist: "Libianca", duration: "2:41", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Unavailable", artist: "Davido", duration: "2:44", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Soweto", artist: "Victony", duration: "2:28", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Overloading", artist: "Mavins, Crayon, Ayra Starr", duration: "3:25", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Monalisa", artist: "Lojay & Chris Brown", duration: "3:33", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Finesse", artist: "Pheelz & BNXN", duration: "2:31", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Bandana", artist: "Fireboy DML & Asake", duration: "2:34", energy: .energetic, era: .twentyTensNow),
            ]
        case .kpop:
            moodLabel = "K-Pop & K-R&B"
            fullPool = [
                PlaylistSong(title: "Dynamite", artist: "BTS", duration: "3:19", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Kill This Love", artist: "BLACKPINK", duration: "3:11", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Cupid", artist: "FIFTY FIFTY", duration: "2:54", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Super Shy", artist: "NewJeans", duration: "2:34", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Love Scenario", artist: "iKON", duration: "3:29", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Spring Day", artist: "BTS", duration: "4:34", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Ditto", artist: "NewJeans", duration: "3:05", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Hype Boy", artist: "NewJeans", duration: "2:59", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Butter", artist: "BTS", duration: "2:42", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "How You Like That", artist: "BLACKPINK", duration: "3:01", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Life Goes On", artist: "BTS", duration: "3:27", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "OMG", artist: "NewJeans", duration: "3:32", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Anti-Hero", artist: "Taylor Swift", duration: "3:20", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Attention", artist: "NewJeans", duration: "3:00", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Fancy", artist: "TWICE", duration: "3:33", energy: .energetic, era: .twentyTensNow),
            ]
        case .reggae:
            moodLabel = "Reggae & Dancehall"
            fullPool = [
                PlaylistSong(title: "One Love", artist: "Bob Marley & The Wailers", duration: "3:20", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "No Woman No Cry", artist: "Bob Marley", duration: "3:46", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Could You Be Loved", artist: "Bob Marley", duration: "3:57", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Bam Bam", artist: "Sister Nancy", duration: "3:16", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Welcome to Jamrock", artist: "Damian Marley", duration: "3:33", energy: .energetic, era: .twoThousands),
                PlaylistSong(title: "Murder She Wrote", artist: "Chaka Demus & Pliers", duration: "4:05", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Buffalo Soldier", artist: "Bob Marley", duration: "4:17", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Three Little Birds", artist: "Bob Marley", duration: "3:00", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Is This Love", artist: "Bob Marley", duration: "3:52", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Stir It Up", artist: "Bob Marley", duration: "3:37", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Jamming", artist: "Bob Marley", duration: "3:31", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "One Drop", artist: "Bob Marley", duration: "3:51", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Get Up Stand Up", artist: "Bob Marley", duration: "3:17", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Waiting in Vain", artist: "Bob Marley", duration: "4:16", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Sun Is Shining", artist: "Bob Marley", duration: "4:58", energy: .chill, era: .seventiesEighties),
            ]
        case .country:
            moodLabel = "Country & Americana"
            fullPool = [
                PlaylistSong(title: "Tennessee Whiskey", artist: "Chris Stapleton", duration: "4:53", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Die With a Smile", artist: "Lady Gaga & Bruno Mars", duration: "3:31", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Cruise", artist: "Florida Georgia Line", duration: "3:28", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Body Like a Back Road", artist: "Sam Hunt", duration: "2:45", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "The Dance", artist: "Garth Brooks", duration: "3:47", energy: .chill, era: .nineties),
                PlaylistSong(title: "Need You Now", artist: "Lady A", duration: "4:37", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Wagon Wheel", artist: "Darius Rucker", duration: "4:58", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Before He Cheats", artist: "Carrie Underwood", duration: "3:19", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "The House That Built Me", artist: "Miranda Lambert", duration: "3:56", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Humble and Kind", artist: "Tim McGraw", duration: "4:20", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "God's Country", artist: "Blake Shelton", duration: "3:25", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Beautiful Crazy", artist: "Luke Combs", duration: "3:13", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Meant to Be", artist: "Bebe Rexha ft. Florida Georgia Line", duration: "2:43", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Fancy", artist: "Reba McEntire", duration: "4:59", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Jolene", artist: "Dolly Parton", duration: "2:41", energy: .chill, era: .seventiesEighties),
            ]
        case .bollywood:
            moodLabel = "Bollywood & Indian"
            fullPool = [
                PlaylistSong(title: "Kesariya", artist: "Arijit Singh", duration: "4:28", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Raatan Lambiyan", artist: "Jubin Nautiyal", duration: "3:50", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Tum Hi Ho", artist: "Arijit Singh", duration: "4:22", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Channa Mereya", artist: "Arijit Singh", duration: "4:49", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Raabta", artist: "Arijit Singh", duration: "4:02", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Gerua", artist: "Arijit Singh & Antara Mitra", duration: "5:45", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Agar Tum Saath Ho", artist: "Alka Yagnik & Arijit Singh", duration: "5:41", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Kabira", artist: "Tochi Raina & Rekha Bhardwaj", duration: "3:43", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Samjhawan", artist: "Arijit Singh", duration: "4:29", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Tujh Mein Rab Dikhta Hai", artist: "Roop Kumar Rathod", duration: "4:41", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Phir Le Aaya Dil", artist: "Arijit Singh", duration: "5:59", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Kal Ho Naa Ho", artist: "Sonu Nigam", duration: "5:21", energy: .balanced, era: .twoThousands),
            ]
        case .arabic:
            moodLabel = "Arabic & Middle Eastern"
            fullPool = [
                PlaylistSong(title: "Habibi", artist: "Ricky Rich", duration: "2:39", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "El Bint El Amoura", artist: "Mohamed Ramadan", duration: "3:31", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Salam Aleikum", artist: "Maher Zain", duration: "3:40", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Aïcha", artist: "Khaled", duration: "4:19", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Didi", artist: "Khaled", duration: "4:20", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Enta Eih", artist: "Nancy Ajram", duration: "3:48", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Nour El Ein", artist: "Amr Diab", duration: "5:50", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Tamally Maak", artist: "Amr Diab", duration: "4:48", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Habibi Ya Nour El Ein", artist: "Amr Diab", duration: "4:18", energy: .energetic, era: .nineties),
                PlaylistSong(title: "El Leila", artist: "Amr Diab", duration: "4:22", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Albi Ya Albi", artist: "Nancy Ajram", duration: "3:26", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Lama Bada Yatathana", artist: "Fairuz", duration: "6:42", energy: .chill, era: .seventiesEighties),
            ]
        case .jpop:
            moodLabel = "J-Pop & Japanese"
            fullPool = [
                PlaylistSong(title: "Lemon", artist: "Kenshi Yonezu", duration: "4:17", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Pretender", artist: "Official HIGE DANDism", duration: "5:26", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Subtitle", artist: "Official HIGE DANDism", duration: "4:00", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Koi", artist: "Gen Hoshino", duration: "3:42", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Uchiage Hanabi", artist: "DAOKO × Kenshi Yonezu", duration: "4:49", energy: .chill, era: .twentyTensNow),
                PlaylistSong(title: "Paprika", artist: "Kenshi Yonezu", duration: "3:25", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Silhouette", artist: "Kenshi Yonezu", duration: "4:14", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Peace Sign", artist: "Kenshi Yonezu", duration: "3:58", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "I Love", artist: "Official HIGE DANDism", duration: "4:42", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Mixed Nuts", artist: "Official HIGE DANDism", duration: "3:33", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Cry Baby", artist: "Official HIGE DANDism", duration: "4:22", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Shukumei", artist: "Official HIGE DANDism", duration: "4:07", energy: .balanced, era: .twentyTensNow),
            ]
        case .rock:
            moodLabel = "Rock & Alternative"
            fullPool = [
                PlaylistSong(title: "Sweet Child O' Mine", artist: "Guns N' Roses", duration: "5:56", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Smells Like Teen Spirit", artist: "Nirvana", duration: "5:01", energy: .energetic, era: .nineties),
                PlaylistSong(title: "Bohemian Rhapsody", artist: "Queen", duration: "5:55", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Wonderwall", artist: "Oasis", duration: "4:18", energy: .balanced, era: .nineties),
                PlaylistSong(title: "Don't Stop Believin'", artist: "Journey", duration: "4:11", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Livin' on a Prayer", artist: "Bon Jovi", duration: "4:31", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Highway to Hell", artist: "AC/DC", duration: "3:28", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Back in Black", artist: "AC/DC", duration: "4:15", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Stairway to Heaven", artist: "Led Zeppelin", duration: "8:02", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Hotel California", artist: "Eagles", duration: "6:30", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "November Rain", artist: "Guns N' Roses", duration: "8:57", energy: .balanced, era: .nineties),
                PlaylistSong(title: "Paradise City", artist: "Guns N' Roses", duration: "6:46", energy: .energetic, era: .seventiesEighties),
            ]
        case .electronic:
            moodLabel = "Electronic & EDM"
            fullPool = [
                PlaylistSong(title: "Starboy", artist: "The Weeknd ft. Daft Punk", duration: "3:50", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "One More Time", artist: "Daft Punk", duration: "5:20", energy: .energetic, era: .twoThousands),
                PlaylistSong(title: "Titanium", artist: "David Guetta ft. Sia", duration: "4:05", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Wake Me Up", artist: "Avicii", duration: "4:09", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Levels", artist: "Avicii", duration: "5:38", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Clarity", artist: "Zedd ft. Foxes", duration: "4:31", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Stay", artist: "Zedd & Alessia Cara", duration: "3:30", energy: .balanced, era: .twentyTensNow),
                PlaylistSong(title: "Lean On", artist: "Major Lazer & DJ Snake", duration: "2:56", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Get Lucky", artist: "Daft Punk ft. Pharrell", duration: "6:09", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Summer", artist: "Calvin Harris", duration: "3:42", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "This Is What You Came For", artist: "Calvin Harris ft. Rihanna", duration: "3:42", energy: .energetic, era: .twentyTensNow),
                PlaylistSong(title: "Where Are Ü Now", artist: "Jack Ü ft. Justin Bieber", duration: "4:10", energy: .energetic, era: .twentyTensNow),
            ]
        case .blues:
            moodLabel = "Blues & Soul"
            fullPool = [
                PlaylistSong(title: "The Thrill Is Gone", artist: "B.B. King", duration: "5:24", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Sweet Home Chicago", artist: "Robert Johnson", duration: "2:59", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Cross Road Blues", artist: "Robert Johnson", duration: "2:29", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Stormy Monday", artist: "T-Bone Walker", duration: "3:02", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Born Under a Bad Sign", artist: "Albert King", duration: "2:47", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Pride and Joy", artist: "Stevie Ray Vaughan", duration: "3:39", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Texas Flood", artist: "Stevie Ray Vaughan", duration: "5:21", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "I'd Rather Go Blind", artist: "Etta James", duration: "2:36", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "At Last", artist: "Etta James", duration: "3:02", energy: .chill, era: .seventiesEighties),
                PlaylistSong(title: "Respect", artist: "Aretha Franklin", duration: "2:27", energy: .energetic, era: .seventiesEighties),
                PlaylistSong(title: "Chain of Fools", artist: "Aretha Franklin", duration: "2:47", energy: .balanced, era: .seventiesEighties),
                PlaylistSong(title: "Midnight Train to Georgia", artist: "Gladys Knight", duration: "4:39", energy: .chill, era: .seventiesEighties),
            ]
        }
        
        // Effective energy set: user's energy intersected with mood's range; if empty, use mood's range so we never ignore both.
        let allowedEnergies: Set<EnergyLevel> = {
            if mood != .none, let moodEnergies = MoodOption.energyRange(for: mood) {
                return moodEnergies.contains(energy) ? [energy] : moodEnergies
            }
            return [energy]
        }()
        var filtered = fullPool.filter { song in
            guard let songEnergy = song.energy else { return true }
            return allowedEnergies.contains(songEnergy)
        }
        // Filter by era (nil or .any = any). 2020s+ offline pool includes 2010s–now tracks when needed.
        if era != .any {
            filtered = filtered.filter { song in
                guard let songEra = song.era else { return true }
                switch era {
                case .twentyTwenties:
                    return songEra == .twentyTwenties || songEra == .twentyTensNow
                default:
                    return songEra == era
                }
            }
        }
        // Complete refresh: exclude current playlist songs; fall back only when too few match so we still show 8
        let available = excludingSongKeys.isEmpty
            ? filtered
            : filtered.filter { !excludingSongKeys.contains("\($0.title)|\($0.artist)") }
        let source: [PlaylistSong]
        if available.count >= 8 {
            source = available
        } else if filtered.count >= 8 {
            source = filtered
        } else {
            // Relax era only (keep energy/mood)
            let relaxed = fullPool.filter { song in
                guard let songEnergy = song.energy else { return true }
                guard allowedEnergies.contains(songEnergy) else { return false }
                if era != .any, let songEra = song.era {
                    switch era {
                    case .twentyTwenties:
                        return songEra == .twentyTwenties || songEra == .twentyTensNow
                    default:
                        return songEra == era
                    }
                }
                return true
            }
            if relaxed.count >= 8 {
                source = relaxed
            } else {
                // Last resort: energy-only so we still respect primary option
                let energyOnly = fullPool.filter { song in
                    guard let songEnergy = song.energy else { return true }
                    return allowedEnergies.contains(songEnergy)
                }
                source = energyOnly.count >= 8 ? energyOnly : fullPool
            }
        }
        return DatePlaylist(
            name: "\(vibe.label) Evening",
            mood: moodLabel,
            totalDuration: "~32 min",
            songs: Self.sampleSongs(from: source, count: 8)
        )
    }
    
    private func openSongOnPlatform(_ song: PlaylistSong, platform: MusicPlatform) {
        let query = "\(song.title) \(song.artist)"
        if let url = URL(string: platform.searchUrl(for: query)) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAllOnPlatform(_ platform: MusicPlatform, songs: [PlaylistSong]) {
        // Open first song immediately (others would require user to tap back and tap again due to iOS restrictions)
        if let firstSong = songs.first {
            openSongOnPlatform(firstSong, platform: platform)
        }
    }
    
    private func copyPlaylistToClipboard(_ playlist: DatePlaylist) {
        var text = "Date Night Playlist: \(planTitle)\n\n"
        for (index, song) in playlist.songs.enumerated() {
            text += "\(index + 1). \(song.title) - \(song.artist)\n"
        }
        
        UIPasteboard.general.string = text
        withAnimation(.spring(response: 0.3)) {
            copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            withAnimation {
                self.copiedToClipboard = false
            }
        })
    }
}

// MARK: - Vibe Card
struct VibeCard: View {
    let vibe: PlaylistWidgetView.VibeOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(vibe.emoji)
                    .font(.system(size: 24))
                
                Text(vibe.label)
                    .font(Font.inter(11, weight: .semibold))
                    .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryCream)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Platform Button
struct PlatformButton: View {
    let platform: PlaylistWidgetView.MusicPlatform
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.system(size: 20))
                    .foregroundColor(platform.color)
                
                Text(platform.name)
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(platform.color.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Identifiable Int (for sheet binding)
private struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}

// MARK: - Song Row
struct SongRow: View {
    let song: PlaylistSong
    let index: Int
    let isPlaying: Bool
    let onTap: () -> Void
    let onOpenPlatform: (PlaylistWidgetView.MusicPlatform) -> Void
    var onReplace: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var showPlatforms = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    if isPlaying {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.luxuryGold)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 14))
                            .foregroundColor(Color.luxuryMaroon)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.luxuryMaroonLight)
                            .frame(width: 40, height: 40)
                        
                        Text("\(index)")
                            .font(Font.inter(13, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(Font.playfair(14, weight: .semibold))
                        .foregroundColor(isPlaying ? Color.luxuryGold : Color.luxuryCream)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(song.duration)
                    .font(Font.inter(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                if let onReplace = onReplace {
                    Button(action: onReplace) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryGold)
                            .frame(width: 28, height: 28)
                    }
                }
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryError)
                            .frame(width: 28, height: 28)
                    }
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showPlatforms.toggle()
                    }
                } label: {
                    Image(systemName: showPlatforms ? "chevron.up" : "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGold)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isPlaying ? Color.luxuryGold.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            // Platform buttons
            if showPlatforms {
                HStack(spacing: 10) {
                    ForEach(PlaylistWidgetView.MusicPlatform.allCases, id: \.self) { platform in
                        Button {
                            onOpenPlatform(platform)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: platform.icon)
                                    .font(.system(size: 12))
                                Text(platform.name)
                                    .font(Font.inter(10, weight: .medium))
                            }
                            .foregroundColor(platform.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(platform.color.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Models
struct DatePlaylist {
    let name: String
    let mood: String
    let totalDuration: String
    let songs: [PlaylistSong]
}

struct PlaylistSong: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: String
    var energy: EnergyLevel?
    var era: EraOption?
    
    init(title: String, artist: String, duration: String, energy: EnergyLevel? = nil, era: EraOption? = nil) {
        self.title = title
        self.artist = artist
        self.duration = duration
        self.energy = energy
        self.era = era
    }
}

enum EnergyLevel: String, CaseIterable {
    case chill = "chill"
    case balanced = "balanced"
    case energetic = "energetic"
    
    var label: String {
        switch self {
        case .chill: return "Chill"
        case .balanced: return "Balanced"
        case .energetic: return "Energetic"
        }
    }
}

enum EraOption: String, CaseIterable {
    case any = "any"
    case seventiesEighties = "70s-80s"
    case nineties = "90s"
    case twoThousands = "2000s"
    /// Sent to generate-playlist as `2010s` (Last.fm decade tag); aligns with label "2010s–2019".
    case twentyTensNow = "2010s"
    case twentyTwenties = "2020s-now"
    
    var label: String {
        switch self {
        case .any: return "Any time"
        case .seventiesEighties: return "70s–80s"
        case .nineties: return "90s"
        case .twoThousands: return "2000s"
        case .twentyTensNow: return "2010s–2019"
        case .twentyTwenties: return "2020s–now"
        }
    }
}

extension EraOption {
    /// Decodes saved playlists; legacy value `2010s-now` equals `.twentyTensNow`.
    static func fromStored(_ raw: String?) -> EraOption {
        guard let r = raw?.lowercased(), !r.isEmpty, r != "any" else { return .any }
        if let e = EraOption(rawValue: r) { return e }
        if r == "2010s-now" { return .twentyTensNow }
        return .any
    }
}

enum MoodOption: String, CaseIterable {
    case none = "none"
    case romanticDinner = "romantic_dinner"
    case party = "party"
    case roadTrip = "road_trip"
    case focus = "focus"
    
    var label: String {
        switch self {
        case .none: return "None"
        case .romanticDinner: return "Romantic dinner"
        case .party: return "Party"
        case .roadTrip: return "Road trip"
        case .focus: return "Focus"
        }
    }
    
    /// Energy levels allowed when this mood is selected (filters pool).
    static func energyRange(for mood: MoodOption) -> Set<EnergyLevel>? {
        switch mood {
        case .none: return nil
        case .romanticDinner: return [.chill, .balanced]
        case .party: return [.balanced, .energetic]
        case .roadTrip: return [.chill, .balanced, .energetic]
        case .focus: return [.chill]
        }
    }
}

#Preview {
    PlaylistWidgetView(planTitle: "Romantic Italian Night")
}
