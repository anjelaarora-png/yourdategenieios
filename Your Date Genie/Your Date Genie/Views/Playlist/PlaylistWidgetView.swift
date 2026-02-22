import SwiftUI

struct PlaylistWidgetView: View {
    let planTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var playlist: DatePlaylist?
    @State private var selectedMood: String = "romantic"
    
    let moods = [
        ("romantic", "Romantic", "💕"),
        ("upbeat", "Upbeat", "🎉"),
        ("chill", "Chill", "😌"),
        ("intimate", "Intimate", "🕯️"),
        ("adventurous", "Adventurous", "🚀"),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    if playlist == nil {
                        // Mood selection
                        moodSelectionSection
                        
                        // Generate button
                        generateButton
                    } else {
                        // Playlist display
                        playlistSection
                    }
                }
                .padding(20)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                if playlist != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            openInSpotify()
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
            }
            
            Text("Date Playlist")
                .font(.custom("Cormorant-Bold", size: 28, relativeTo: .title))
                .foregroundColor(Color(UIColor.label))
            
            Text("Curated music for \(planTitle)")
                .font(.system(size: 15))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }
    
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's the vibe?")
                .font(.system(size: 16, weight: .semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(moods, id: \.0) { mood in
                    MoodCard(
                        value: mood.0,
                        label: mood.1,
                        emoji: mood.2,
                        isSelected: selectedMood == mood.0,
                        onTap: { selectedMood = mood.0 }
                    )
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button {
            generatePlaylist()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(isGenerating ? "Creating playlist..." : "Generate Playlist")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.goldGradient)
            .cornerRadius(14)
            .shadow(color: Color.brandGold.opacity(0.4), radius: 10, y: 4)
        }
        .disabled(isGenerating)
    }
    
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Playlist header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist?.name ?? "Your Playlist")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("\(playlist?.songs.count ?? 0) songs · \(playlist?.totalDuration ?? "~1 hr")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                // Spotify button
                Button {
                    openInSpotify()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                        Text("Open in Spotify")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
                }
            }
            
            // Songs list
            VStack(spacing: 0) {
                ForEach(playlist?.songs ?? []) { song in
                    SongRow(song: song)
                    
                    if song.id != playlist?.songs.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            
            // Regenerate option
            Button {
                playlist = nil
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Generate different playlist")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.brandPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
    
    private func generatePlaylist() {
        isGenerating = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            playlist = DatePlaylist(
                name: "Romantic Evening Vibes",
                mood: selectedMood,
                totalDuration: "1 hr 15 min",
                songs: [
                    PlaylistSong(title: "At Last", artist: "Etta James", duration: "3:02", albumArt: nil),
                    PlaylistSong(title: "L-O-V-E", artist: "Nat King Cole", duration: "2:34", albumArt: nil),
                    PlaylistSong(title: "The Way You Look Tonight", artist: "Frank Sinatra", duration: "3:24", albumArt: nil),
                    PlaylistSong(title: "Can't Help Falling in Love", artist: "Elvis Presley", duration: "3:01", albumArt: nil),
                    PlaylistSong(title: "La Vie En Rose", artist: "Édith Piaf", duration: "3:08", albumArt: nil),
                    PlaylistSong(title: "Unforgettable", artist: "Nat King Cole", duration: "3:28", albumArt: nil),
                    PlaylistSong(title: "Moon River", artist: "Audrey Hepburn", duration: "2:45", albumArt: nil),
                    PlaylistSong(title: "Fly Me to the Moon", artist: "Frank Sinatra", duration: "2:31", albumArt: nil),
                ]
            )
            isGenerating = false
        }
    }
    
    private func openInSpotify() {
        if let url = URL(string: "spotify://") {
            UIApplication.shared.open(url)
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
    let albumArt: URL?
}

// MARK: - Supporting Views
struct MoodCard: View {
    let value: String
    let label: String
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor.label))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.brandGold : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandGold : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SongRow: View {
    let song: PlaylistSong
    
    var body: some View {
        HStack(spacing: 12) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.gray)
                )
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(song.duration)
                .font(.system(size: 13))
                .foregroundColor(Color(UIColor.tertiaryLabel))
            
            // Play button
            Button {
                // Play preview
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    PlaylistWidgetView(planTitle: "Romantic Italian Evening")
}
