import SwiftUI

struct PlaylistWidgetView: View {
    let planTitle: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVibe: VibeOption = .romantic
    @State private var isGenerating = false
    @State private var playlist: DatePlaylist?
    @State private var currentlyPlaying: String?
    @State private var copiedToClipboard = false
    
    enum VibeOption: String, CaseIterable {
        case romantic = "romantic"
        case upbeat = "upbeat"
        case chill = "chill"
        case jazzy = "jazzy"
        case indie = "indie"
        case classic = "classic"
        case rnb = "rnb"
        case adventurous = "adventurous"
        
        var label: String {
            switch self {
            case .romantic: return "Romantic"
            case .upbeat: return "Upbeat"
            case .chill: return "Chill"
            case .jazzy: return "Jazzy"
            case .indie: return "Indie"
            case .classic: return "Classic"
            case .rnb: return "R&B"
            case .adventurous: return "Eclectic"
            }
        }
        
        var emoji: String {
            switch self {
            case .romantic: return "💕"
            case .upbeat: return "🎉"
            case .chill: return "🌙"
            case .jazzy: return "🎷"
            case .indie: return "🎸"
            case .classic: return "🎻"
            case .rnb: return "🎤"
            case .adventurous: return "✨"
            }
        }
        
        var description: String {
            switch self {
            case .romantic: return "Intimate love songs"
            case .upbeat: return "Dance & party hits"
            case .chill: return "Lo-fi & relaxed"
            case .jazzy: return "Smooth jazz & soul"
            case .indie: return "Alternative vibes"
            case .classic: return "Timeless standards"
            case .rnb: return "Modern R&B"
            case .adventurous: return "Genre-bending"
            }
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
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if let currentPlaylist = playlist {
                    playlistContent(currentPlaylist)
                } else {
                    generateView
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
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Generate View
    private var generateView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(Color.luxuryGold.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                                .frame(width: CGFloat(100 + index * 30), height: CGFloat(100 + index * 30))
                        }
                        
                        Circle()
                            .fill(Color.luxuryMaroonLight)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 32))
                                    .foregroundStyle(LinearGradient.goldShimmer)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    Text("Create Your Soundtrack")
                        .font(Font.displayTitle())
                        .foregroundColor(Color.luxuryGold)
                    
                    Text("AI-curated music for \"\(planTitle)\"")
                        .font(Font.playfair(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Vibe Selection
                VStack(alignment: .leading, spacing: 14) {
                    Text("Choose your vibe:")
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(VibeOption.allCases, id: \.self) { vibe in
                            VibeCard(
                                vibe: vibe,
                                isSelected: selectedVibe == vibe,
                                action: { selectedVibe = vibe }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
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
                
                // Copy button
                Button {
                    copyPlaylistToClipboard(currentPlaylist)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(copiedToClipboard ? "Copied!" : "Copy Playlist")
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
                                withAnimation {
                                    currentlyPlaying = currentlyPlaying == song.id.uuidString ? nil : song.id.uuidString
                                }
                            },
                            onOpenPlatform: { platform in
                                openSongOnPlatform(song, platform: platform)
                            }
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
        isGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.playlist = generateSongsForVibe(self.selectedVibe)
            self.isGenerating = false
        })
    }
    
    private func generateSongsForVibe(_ vibe: VibeOption) -> DatePlaylist {
        let songs: [PlaylistSong]
        let mood: String
        
        switch vibe {
        case .romantic:
            mood = "Intimate & Elegant"
            songs = [
                PlaylistSong(title: "La Vie en Rose", artist: "Édith Piaf", duration: "3:45"),
                PlaylistSong(title: "The Way You Look Tonight", artist: "Frank Sinatra", duration: "4:12"),
                PlaylistSong(title: "Can't Help Falling in Love", artist: "Elvis Presley", duration: "3:01"),
                PlaylistSong(title: "At Last", artist: "Etta James", duration: "3:02"),
                PlaylistSong(title: "Thinking Out Loud", artist: "Ed Sheeran", duration: "4:41"),
                PlaylistSong(title: "A Thousand Years", artist: "Christina Perri", duration: "4:45"),
                PlaylistSong(title: "Perfect", artist: "Ed Sheeran", duration: "4:23"),
                PlaylistSong(title: "All of Me", artist: "John Legend", duration: "4:29"),
            ]
        case .upbeat:
            mood = "Fun & Energetic"
            songs = [
                PlaylistSong(title: "Uptown Funk", artist: "Bruno Mars", duration: "4:30"),
                PlaylistSong(title: "Happy", artist: "Pharrell Williams", duration: "3:53"),
                PlaylistSong(title: "Can't Stop the Feeling", artist: "Justin Timberlake", duration: "4:00"),
                PlaylistSong(title: "Shake It Off", artist: "Taylor Swift", duration: "3:39"),
                PlaylistSong(title: "Dance Monkey", artist: "Tones and I", duration: "3:29"),
                PlaylistSong(title: "Good as Hell", artist: "Lizzo", duration: "2:39"),
                PlaylistSong(title: "Levitating", artist: "Dua Lipa", duration: "3:23"),
                PlaylistSong(title: "Blinding Lights", artist: "The Weeknd", duration: "3:20"),
            ]
        case .chill:
            mood = "Relaxed & Cozy"
            songs = [
                PlaylistSong(title: "Electric Feel", artist: "MGMT", duration: "3:49"),
                PlaylistSong(title: "Dreams", artist: "Fleetwood Mac", duration: "4:14"),
                PlaylistSong(title: "Banana Pancakes", artist: "Jack Johnson", duration: "3:12"),
                PlaylistSong(title: "Put Your Records On", artist: "Corinne Bailey Rae", duration: "3:35"),
                PlaylistSong(title: "Sea of Love", artist: "Cat Power", duration: "2:20"),
                PlaylistSong(title: "Skinny Love", artist: "Bon Iver", duration: "3:58"),
                PlaylistSong(title: "Cherry Wine", artist: "Hozier", duration: "4:13"),
                PlaylistSong(title: "Lost in Japan", artist: "Shawn Mendes", duration: "3:25"),
            ]
        case .jazzy:
            mood = "Smooth & Sophisticated"
            songs = [
                PlaylistSong(title: "Fly Me to the Moon", artist: "Frank Sinatra", duration: "2:31"),
                PlaylistSong(title: "Take Five", artist: "Dave Brubeck", duration: "5:24"),
                PlaylistSong(title: "Feeling Good", artist: "Nina Simone", duration: "2:55"),
                PlaylistSong(title: "Blue in Green", artist: "Miles Davis", duration: "5:37"),
                PlaylistSong(title: "Girl from Ipanema", artist: "Stan Getz", duration: "5:24"),
                PlaylistSong(title: "My Funny Valentine", artist: "Chet Baker", duration: "4:03"),
                PlaylistSong(title: "Autumn Leaves", artist: "Nat King Cole", duration: "3:03"),
                PlaylistSong(title: "Summertime", artist: "Ella Fitzgerald", duration: "4:58"),
            ]
        case .indie:
            mood = "Alternative & Artistic"
            songs = [
                PlaylistSong(title: "Lover, You Should've Come Over", artist: "Jeff Buckley", duration: "6:43"),
                PlaylistSong(title: "Motion Sickness", artist: "Phoebe Bridgers", duration: "3:47"),
                PlaylistSong(title: "Pink + White", artist: "Frank Ocean", duration: "3:04"),
                PlaylistSong(title: "Two Weeks", artist: "Grizzly Bear", duration: "4:03"),
                PlaylistSong(title: "Midnight City", artist: "M83", duration: "4:03"),
                PlaylistSong(title: "Robbers", artist: "The 1975", duration: "4:15"),
                PlaylistSong(title: "Youth", artist: "Daughter", duration: "4:50"),
                PlaylistSong(title: "Myth", artist: "Beach House", duration: "4:18"),
            ]
        case .classic:
            mood = "Timeless & Elegant"
            songs = [
                PlaylistSong(title: "Unchained Melody", artist: "The Righteous Brothers", duration: "3:36"),
                PlaylistSong(title: "Your Song", artist: "Elton John", duration: "4:01"),
                PlaylistSong(title: "Stand By Me", artist: "Ben E. King", duration: "2:58"),
                PlaylistSong(title: "Let's Stay Together", artist: "Al Green", duration: "3:18"),
                PlaylistSong(title: "Wonderful Tonight", artist: "Eric Clapton", duration: "3:45"),
                PlaylistSong(title: "When a Man Loves a Woman", artist: "Percy Sledge", duration: "2:56"),
                PlaylistSong(title: "In My Life", artist: "The Beatles", duration: "2:27"),
                PlaylistSong(title: "God Only Knows", artist: "The Beach Boys", duration: "2:51"),
            ]
        case .rnb:
            mood = "Smooth & Soulful"
            songs = [
                PlaylistSong(title: "Best Part", artist: "Daniel Caesar ft. H.E.R.", duration: "3:29"),
                PlaylistSong(title: "Golden", artist: "Jill Scott", duration: "4:14"),
                PlaylistSong(title: "Adorn", artist: "Miguel", duration: "3:13"),
                PlaylistSong(title: "Electric", artist: "Alina Baraz ft. Khalid", duration: "3:00"),
                PlaylistSong(title: "Crew Love", artist: "Drake ft. The Weeknd", duration: "3:26"),
                PlaylistSong(title: "Often", artist: "The Weeknd", duration: "4:10"),
                PlaylistSong(title: "Love Galore", artist: "SZA ft. Travis Scott", duration: "4:35"),
                PlaylistSong(title: "Come Through and Chill", artist: "Miguel", duration: "3:29"),
            ]
        case .adventurous:
            mood = "Eclectic & Genre-Bending"
            songs = [
                PlaylistSong(title: "Get Lucky", artist: "Daft Punk ft. Pharrell", duration: "6:09"),
                PlaylistSong(title: "Redbone", artist: "Childish Gambino", duration: "5:27"),
                PlaylistSong(title: "Tame Impala", artist: "Let It Happen", duration: "7:47"),
                PlaylistSong(title: "Feel Good Inc.", artist: "Gorillaz", duration: "3:41"),
                PlaylistSong(title: "Do I Wanna Know?", artist: "Arctic Monkeys", duration: "4:32"),
                PlaylistSong(title: "N.Y. State of Mind", artist: "Nas", duration: "4:53"),
                PlaylistSong(title: "Electric Feel", artist: "MGMT", duration: "3:49"),
                PlaylistSong(title: "Little Dark Age", artist: "MGMT", duration: "4:59"),
            ]
        }
        
        return DatePlaylist(
            name: "\(vibe.label) Evening",
            mood: mood,
            totalDuration: "~32 min",
            songs: songs
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

// MARK: - Song Row
struct SongRow: View {
    let song: PlaylistSong
    let index: Int
    let isPlaying: Bool
    let onTap: () -> Void
    let onOpenPlatform: (PlaylistWidgetView.MusicPlatform) -> Void
    
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
}

#Preview {
    PlaylistWidgetView(planTitle: "Romantic Italian Night")
}
