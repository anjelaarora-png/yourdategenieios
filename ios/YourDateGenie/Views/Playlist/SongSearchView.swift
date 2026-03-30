import SwiftUI

/// YouTube-style song search (iTunes API); call onSelect with chosen song.
struct SongSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSelect: (String, String) -> Void
    
    @State private var query = ""
    @State private var results: [ITunesSongResult] = []
    @State private var isSearching = false
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.luxuryMuted)
                        TextField("Search song or artist...", text: $query)
                            .foregroundColor(Color.luxuryCream)
                            .autocorrectionDisabled()
                            .onChange(of: query) { _, newValue in
                                performSearch(newValue)
                            }
                    }
                    .padding(14)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    if isSearching {
                        ProgressView()
                            .tint(Color.luxuryGold)
                            .padding(.vertical, 24)
                    } else if results.isEmpty && query.count >= 2 {
                        Text("No songs found")
                            .font(Font.playfair(15))
                            .foregroundColor(Color.luxuryMuted)
                            .padding(.vertical, 24)
                    } else {
                        List {
                            ForEach(Array(results.enumerated()), id: \.offset) { _, song in
                                Button {
                                    onSelect(song.trackName ?? "", song.artistName ?? "")
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        if let urlString = song.artworkUrl60?.replacingOccurrences(of: "60x60", with: "100x100"),
                                           let url = URL(string: urlString) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Rectangle().fill(Color.luxuryMaroonLight)
                                            }
                                            .frame(width: 44, height: 44)
                                            .cornerRadius(6)
                                        } else {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.luxuryMaroonLight)
                                                .frame(width: 44, height: 44)
                                                .overlay(Image(systemName: "music.note").foregroundColor(Color.luxuryMuted))
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(song.trackName ?? "—")
                                                .font(Font.playfair(14, weight: .semibold))
                                                .foregroundColor(Color.luxuryCream)
                                                .lineLimit(1)
                                            Text(song.artistName ?? "—")
                                                .font(Font.inter(12))
                                                .foregroundColor(Color.luxuryMuted)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.luxuryMaroonLight)
                                .listRowSeparatorTint(Color.luxuryGold.opacity(0.3))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func performSearch(_ q: String) {
        task?.cancel()
        let t = q.trimmingCharacters(in: .whitespaces)
        guard t.count >= 2 else {
            results = []
            return
        }
        task = Task {
            isSearching = true
            defer { isSearching = false }
            do {
                let r = try await ITunesSearchService.searchSongs(query: t)
                if !Task.isCancelled {
                    results = r
                }
            } catch {
                if !Task.isCancelled { results = [] }
            }
        }
    }
}
