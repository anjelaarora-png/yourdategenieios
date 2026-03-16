import Foundation

// MARK: - Saved playlist (mirrors web localStorage structure for parity)
struct PlaylistStop: Codable, Equatable {
    let name: String
    let venueType: String
}

struct SavedPlaylistSong: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var artist: String
    var year: Int?
    var isCustom: Bool?
    var addedAt: String?
    
    init(id: String = UUID().uuidString, title: String, artist: String, year: Int? = nil, isCustom: Bool? = false, addedAt: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.year = year
        self.isCustom = isCustom
        self.addedAt = addedAt ?? ISO8601DateFormatter().string(from: Date())
    }
}

struct SavedPlaylist: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var datePlanTitle: String
    var vibe: String
    var songs: [SavedPlaylistSong]
    var stops: [PlaylistStop]?
    var energy: String?
    var era: String?
    var mood: String?
    var createdAt: String
    var updatedAt: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        datePlanTitle: String,
        vibe: String,
        songs: [SavedPlaylistSong],
        stops: [PlaylistStop]? = nil,
        energy: String? = nil,
        era: String? = nil,
        mood: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.datePlanTitle = datePlanTitle
        self.vibe = vibe
        self.songs = songs
        self.stops = stops
        self.energy = energy
        self.era = era
        self.mood = mood
        let now = ISO8601DateFormatter().string(from: Date())
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }
}
