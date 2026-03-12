import Foundation

// MARK: - PostgreSQL Database Models
// These models map to the 7 PostgreSQL tables defined in the schema

// MARK: - Table 1: Users
struct DBUser: Codable, Identifiable, Equatable {
    let userId: UUID
    var name: String
    var email: String
    var passwordHash: String
    var gender: String?
    var birthday: Date?
    var homeAddress: String?
    var travelMode: String?
    var createdAt: Date
    
    var id: UUID { userId }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case email
        case passwordHash = "password_hash"
        case gender
        case birthday
        case homeAddress = "home_address"
        case travelMode = "travel_mode"
        case createdAt = "created_at"
    }
    
    init(
        userId: UUID = UUID(),
        name: String,
        email: String,
        passwordHash: String,
        gender: String? = nil,
        birthday: Date? = nil,
        homeAddress: String? = nil,
        travelMode: String? = nil,
        createdAt: Date = Date()
    ) {
        self.userId = userId
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.gender = gender
        self.birthday = birthday
        self.homeAddress = homeAddress
        self.travelMode = travelMode
        self.createdAt = createdAt
    }
}

// MARK: - Table 2: Couples
struct DBCouple: Codable, Identifiable, Equatable {
    let coupleId: UUID
    let userId1: UUID
    var userId2: UUID?
    var relationshipType: String?
    var createdAt: Date
    
    var id: UUID { coupleId }
    
    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case userId1 = "user_id_1"
        case userId2 = "user_id_2"
        case relationshipType = "relationship_type"
        case createdAt = "created_at"
    }
    
    init(
        coupleId: UUID = UUID(),
        userId1: UUID,
        userId2: UUID? = nil,
        relationshipType: String? = nil,
        createdAt: Date = Date()
    ) {
        self.coupleId = coupleId
        self.userId1 = userId1
        self.userId2 = userId2
        self.relationshipType = relationshipType
        self.createdAt = createdAt
    }
}

// MARK: - Table 3: Preferences
struct DBPreferences: Codable, Identifiable, Equatable {
    let preferenceId: UUID
    let userId: UUID
    var coupleId: UUID?
    var cuisineTypes: [String]?
    var activityTypes: [String]?
    var drinkPreferences: [String]?
    var budgetRange: String?
    var loveLanguages: [String]?
    var foodAllergies: [String]?
    var hardNos: [String]?
    var accessibilityNeeds: [String]?
    var updatedAt: Date
    
    var id: UUID { preferenceId }
    
    enum CodingKeys: String, CodingKey {
        case preferenceId = "preference_id"
        case userId = "user_id"
        case coupleId = "couple_id"
        case cuisineTypes = "cuisine_types"
        case activityTypes = "activity_types"
        case drinkPreferences = "drink_preferences"
        case budgetRange = "budget_range"
        case loveLanguages = "love_languages"
        case foodAllergies = "food_allergies"
        case hardNos = "hard_nos"
        case accessibilityNeeds = "accessibility_needs"
        case updatedAt = "updated_at"
    }
    
    init(
        preferenceId: UUID = UUID(),
        userId: UUID,
        coupleId: UUID? = nil,
        cuisineTypes: [String]? = nil,
        activityTypes: [String]? = nil,
        drinkPreferences: [String]? = nil,
        budgetRange: String? = nil,
        loveLanguages: [String]? = nil,
        foodAllergies: [String]? = nil,
        hardNos: [String]? = nil,
        accessibilityNeeds: [String]? = nil,
        updatedAt: Date = Date()
    ) {
        self.preferenceId = preferenceId
        self.userId = userId
        self.coupleId = coupleId
        self.cuisineTypes = cuisineTypes
        self.activityTypes = activityTypes
        self.drinkPreferences = drinkPreferences
        self.budgetRange = budgetRange
        self.loveLanguages = loveLanguages
        self.foodAllergies = foodAllergies
        self.hardNos = hardNos
        self.accessibilityNeeds = accessibilityNeeds
        self.updatedAt = updatedAt
    }
}

// MARK: - Table 4: Date Plans
struct DBDatePlan: Codable, Identifiable, Equatable {
    let planId: UUID
    let coupleId: UUID
    var scheduledAt: Date?
    var planTitle: String?
    var planTagline: String?
    var selectedOption: String?
    var planOptions: [PlanOptionSummary]?
    var location: String?
    var activityType: String?
    var budget: Decimal?
    var budgetRange: String?
    var outfitSuggestion: String?
    var whatToBring: [String]?
    var weatherNote: String?
    var geniesSecretTouch: String?
    var conversationStarters: [String]?
    var itinerary: [ItineraryStop]?
    var totalTravelTime: String?
    var venueCount: Int?
    var routeMapUrl: String?
    var status: String
    var createdAt: Date
    
    var id: UUID { planId }
    
    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case coupleId = "couple_id"
        case scheduledAt = "scheduled_at"
        case planTitle = "plan_title"
        case planTagline = "plan_tagline"
        case selectedOption = "selected_option"
        case planOptions = "plan_options"
        case location
        case activityType = "activity_type"
        case budget
        case budgetRange = "budget_range"
        case outfitSuggestion = "outfit_suggestion"
        case whatToBring = "what_to_bring"
        case weatherNote = "weather_note"
        case geniesSecretTouch = "genies_secret_touch"
        case conversationStarters = "conversation_starters"
        case itinerary
        case totalTravelTime = "total_travel_time"
        case venueCount = "venue_count"
        case routeMapUrl = "route_map_url"
        case status
        case createdAt = "created_at"
    }
    
    init(
        planId: UUID = UUID(),
        coupleId: UUID,
        scheduledAt: Date? = nil,
        planTitle: String? = nil,
        planTagline: String? = nil,
        selectedOption: String? = nil,
        planOptions: [PlanOptionSummary]? = nil,
        location: String? = nil,
        activityType: String? = nil,
        budget: Decimal? = nil,
        budgetRange: String? = nil,
        outfitSuggestion: String? = nil,
        whatToBring: [String]? = nil,
        weatherNote: String? = nil,
        geniesSecretTouch: String? = nil,
        conversationStarters: [String]? = nil,
        itinerary: [ItineraryStop]? = nil,
        totalTravelTime: String? = nil,
        venueCount: Int? = nil,
        routeMapUrl: String? = nil,
        status: String = "planned",
        createdAt: Date = Date()
    ) {
        self.planId = planId
        self.coupleId = coupleId
        self.scheduledAt = scheduledAt
        self.planTitle = planTitle
        self.planTagline = planTagline
        self.selectedOption = selectedOption
        self.planOptions = planOptions
        self.location = location
        self.activityType = activityType
        self.budget = budget
        self.budgetRange = budgetRange
        self.outfitSuggestion = outfitSuggestion
        self.whatToBring = whatToBring
        self.weatherNote = weatherNote
        self.geniesSecretTouch = geniesSecretTouch
        self.conversationStarters = conversationStarters
        self.itinerary = itinerary
        self.totalTravelTime = totalTravelTime
        self.venueCount = venueCount
        self.routeMapUrl = routeMapUrl
        self.status = status
        self.createdAt = createdAt
    }
}

// MARK: - Plan Option Summary (JSONB)
struct PlanOptionSummary: Codable, Equatable, Identifiable {
    var id: String { option }
    let option: String
    let title: String
    let tagline: String
    let durationHours: Double
    let budgetRange: String
    let venueCount: Int
    let venuesVerified: Int
    
    enum CodingKeys: String, CodingKey {
        case option
        case title
        case tagline
        case durationHours = "duration_hours"
        case budgetRange = "budget_range"
        case venueCount = "venue_count"
        case venuesVerified = "venues_verified"
    }
}

// MARK: - Itinerary Stop (JSONB)
struct ItineraryStop: Codable, Equatable, Identifiable {
    var id: Int { stopNumber }
    let stopNumber: Int
    let arrivalTime: String
    let durationMinutes: Int
    let placeId: String?
    let name: String
    let category: String
    let address: String
    let phone: String?
    let website: String?
    let description: String
    let whyThisFits: String
    let romanticTip: String?
    let costPerPerson: String?
    let verified: Bool
    let travelToNext: TravelInfo?
    
    enum CodingKeys: String, CodingKey {
        case stopNumber = "stop_number"
        case arrivalTime = "arrival_time"
        case durationMinutes = "duration_minutes"
        case placeId = "place_id"
        case name
        case category
        case address
        case phone
        case website
        case description
        case whyThisFits = "why_this_fits"
        case romanticTip = "romantic_tip"
        case costPerPerson = "cost_per_person"
        case verified
        case travelToNext = "travel_to_next"
    }
}

// MARK: - Travel Info (JSONB)
struct TravelInfo: Codable, Equatable {
    let duration: String
    let distance: String
    let mode: String
}

// MARK: - Table 5: Date Memories
struct DBDateMemory: Codable, Identifiable, Equatable {
    let memoryId: UUID
    let planId: UUID
    let coupleId: UUID
    var rating: Int?
    var notes: String?
    var photoUrls: [String]?
    var createdAt: Date
    
    var id: UUID { memoryId }
    
    enum CodingKeys: String, CodingKey {
        case memoryId = "memory_id"
        case planId = "plan_id"
        case coupleId = "couple_id"
        case rating
        case notes
        case photoUrls = "photo_urls"
        case createdAt = "created_at"
    }
    
    init(
        memoryId: UUID = UUID(),
        planId: UUID,
        coupleId: UUID,
        rating: Int? = nil,
        notes: String? = nil,
        photoUrls: [String]? = nil,
        createdAt: Date = Date()
    ) {
        self.memoryId = memoryId
        self.planId = planId
        self.coupleId = coupleId
        self.rating = rating
        self.notes = notes
        self.photoUrls = photoUrls
        self.createdAt = createdAt
    }
}

// MARK: - Table 6: Gift Suggestions
struct DBGiftSuggestion: Codable, Identifiable, Equatable {
    let giftId: UUID
    let planId: UUID
    let coupleId: UUID
    var name: String?
    var priceRange: String?
    var description: String?
    var whyItFits: String?
    var whereToBuy: String?
    var liked: Bool?
    var purchased: Bool
    var purchasedAt: Date?
    var purchasedForPlanId: UUID?
    var createdAt: Date
    
    var id: UUID { giftId }
    
    enum CodingKeys: String, CodingKey {
        case giftId = "gift_id"
        case planId = "plan_id"
        case coupleId = "couple_id"
        case name
        case priceRange = "price_range"
        case description
        case whyItFits = "why_it_fits"
        case whereToBuy = "where_to_buy"
        case liked
        case purchased
        case purchasedAt = "purchased_at"
        case purchasedForPlanId = "purchased_for_plan_id"
        case createdAt = "created_at"
    }
    
    init(
        giftId: UUID = UUID(),
        planId: UUID,
        coupleId: UUID,
        name: String? = nil,
        priceRange: String? = nil,
        description: String? = nil,
        whyItFits: String? = nil,
        whereToBuy: String? = nil,
        liked: Bool? = nil,
        purchased: Bool = false,
        purchasedAt: Date? = nil,
        purchasedForPlanId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.giftId = giftId
        self.planId = planId
        self.coupleId = coupleId
        self.name = name
        self.priceRange = priceRange
        self.description = description
        self.whyItFits = whyItFits
        self.whereToBuy = whereToBuy
        self.liked = liked
        self.purchased = purchased
        self.purchasedAt = purchasedAt
        self.purchasedForPlanId = purchasedForPlanId
        self.createdAt = createdAt
    }
}

// MARK: - Table 7: Playlists
struct DBPlaylist: Codable, Identifiable, Equatable {
    let playlistId: UUID
    let planId: UUID
    let coupleId: UUID
    var title: String?
    var description: String?
    var platform: String?
    var externalUrl: String?
    var externalPlaylistId: String?
    var tracks: [PlaylistTrack]?
    var totalDurationMinutes: Int?
    var generatedAt: Date
    
    var id: UUID { playlistId }
    
    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case planId = "plan_id"
        case coupleId = "couple_id"
        case title
        case description
        case platform
        case externalUrl = "external_url"
        case externalPlaylistId = "external_playlist_id"
        case tracks
        case totalDurationMinutes = "total_duration_minutes"
        case generatedAt = "generated_at"
    }
    
    init(
        playlistId: UUID = UUID(),
        planId: UUID,
        coupleId: UUID,
        title: String? = nil,
        description: String? = nil,
        platform: String? = nil,
        externalUrl: String? = nil,
        externalPlaylistId: String? = nil,
        tracks: [PlaylistTrack]? = nil,
        totalDurationMinutes: Int? = nil,
        generatedAt: Date = Date()
    ) {
        self.playlistId = playlistId
        self.planId = planId
        self.coupleId = coupleId
        self.title = title
        self.description = description
        self.platform = platform
        self.externalUrl = externalUrl
        self.externalPlaylistId = externalPlaylistId
        self.tracks = tracks
        self.totalDurationMinutes = totalDurationMinutes
        self.generatedAt = generatedAt
    }
}

// MARK: - Playlist Track (JSONB)
struct PlaylistTrack: Codable, Equatable, Identifiable {
    var id: Int { trackNumber }
    let trackNumber: Int
    let title: String
    let artist: String
    let album: String?
    let duration: String
    let whyItFits: String?
    
    enum CodingKeys: String, CodingKey {
        case trackNumber = "track_number"
        case title
        case artist
        case album
        case duration
        case whyItFits = "why_it_fits"
    }
}
