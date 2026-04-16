import Foundation

// MARK: - Date Experience (Supabase `events` table)

struct DateExperience: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let dateTime: Date
    let location: String
    let imageUrl: String
    let eventbriteUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case dateTime    = "date_time"
        case location
        case imageUrl    = "image_url"
        case eventbriteUrl = "eventbrite_url"
    }

    // Derive badge: events happening today or already started → "LIVE", future → "LIMITED"
    var badgeLabel: String {
        Calendar.current.isDateInToday(dateTime) || dateTime <= Date() ? "LIVE" : "LIMITED"
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: dateTime)
    }

    var ctaLabel: String {
        eventbriteUrl.isEmpty ? "View" : "Join"
    }
}
