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
    var phoneNumber: String?
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
        case phoneNumber = "phone_number"
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
        phoneNumber: String? = nil,
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
        self.phoneNumber = phoneNumber
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
    // Location / travel
    var defaultCity: String?
    var defaultStartingPoint: String?
    var defaultNeighborhood: String?
    var energyLevel: String?
    var transportationMode: String?
    var travelRadius: String?
    // Diet / activity
    var cuisineTypes: [String]?
    var activityTypes: [String]?
    var drinkPreferences: [String]?
    var dietaryRestrictions: [String]?
    var budgetRange: String?
    var foodAllergies: [String]?
    var hardNos: [String]?
    var accessibilityNeeds: [String]?
    // Lifestyle
    var smokingPreference: String?
    var smokingActivities: [String]?
    // Identity
    var gender: String?
    var partnerGender: String?
    var loveLanguages: [String]?
    var partnerLoveLanguages: [String]?
    // Relationship context
    var relationshipStage: String?
    var conversationTopics: [String]?
    var additionalNotes: String?
    // Gift preferences
    var giftRecipient: String?
    var giftInterests: [String]?
    var giftBudget: String?
    var giftOccasion: String?
    var giftNotes: String?
    var giftRecipientIdentity: String?
    var giftStyle: [String]?
    var giftFavoriteBrands: String?
    var giftSizes: String?

    var updatedAt: Date

    var id: UUID { preferenceId }

    enum CodingKeys: String, CodingKey {
        case preferenceId = "preference_id"
        case userId = "user_id"
        case coupleId = "couple_id"
        case defaultCity = "default_city"
        case defaultStartingPoint = "default_starting_point"
        case defaultNeighborhood = "default_neighborhood"
        case energyLevel = "energy_level"
        case transportationMode = "transportation_mode"
        case travelRadius = "travel_radius"
        case cuisineTypes = "cuisine_types"
        case activityTypes = "activity_types"
        case drinkPreferences = "drink_preferences"
        case dietaryRestrictions = "dietary_restrictions"
        case budgetRange = "budget_range"
        case foodAllergies = "food_allergies"
        case hardNos = "hard_nos"
        case accessibilityNeeds = "accessibility_needs"
        case smokingPreference = "smoking_preference"
        case smokingActivities = "smoking_activities"
        case gender
        case partnerGender = "partner_gender"
        case loveLanguages = "love_languages"
        case partnerLoveLanguages = "partner_love_languages"
        case relationshipStage = "relationship_stage"
        case conversationTopics = "conversation_topics"
        case additionalNotes = "additional_notes"
        case giftRecipient = "gift_recipient"
        case giftInterests = "gift_interests"
        case giftBudget = "gift_budget"
        case giftOccasion = "gift_occasion"
        case giftNotes = "gift_notes"
        case giftRecipientIdentity = "gift_recipient_identity"
        case giftStyle = "gift_style"
        case giftFavoriteBrands = "gift_favorite_brands"
        case giftSizes = "gift_sizes"
        case updatedAt = "updated_at"
    }

    init(
        preferenceId: UUID = UUID(),
        userId: UUID,
        coupleId: UUID? = nil,
        defaultCity: String? = nil,
        defaultStartingPoint: String? = nil,
        defaultNeighborhood: String? = nil,
        energyLevel: String? = nil,
        transportationMode: String? = nil,
        travelRadius: String? = nil,
        cuisineTypes: [String]? = nil,
        activityTypes: [String]? = nil,
        drinkPreferences: [String]? = nil,
        dietaryRestrictions: [String]? = nil,
        budgetRange: String? = nil,
        loveLanguages: [String]? = nil,
        partnerLoveLanguages: [String]? = nil,
        foodAllergies: [String]? = nil,
        hardNos: [String]? = nil,
        accessibilityNeeds: [String]? = nil,
        smokingPreference: String? = nil,
        smokingActivities: [String]? = nil,
        gender: String? = nil,
        partnerGender: String? = nil,
        relationshipStage: String? = nil,
        conversationTopics: [String]? = nil,
        additionalNotes: String? = nil,
        giftRecipient: String? = nil,
        giftInterests: [String]? = nil,
        giftBudget: String? = nil,
        giftOccasion: String? = nil,
        giftNotes: String? = nil,
        giftRecipientIdentity: String? = nil,
        giftStyle: [String]? = nil,
        giftFavoriteBrands: String? = nil,
        giftSizes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.preferenceId = preferenceId
        self.userId = userId
        self.coupleId = coupleId
        self.defaultCity = defaultCity
        self.defaultStartingPoint = defaultStartingPoint
        self.defaultNeighborhood = defaultNeighborhood
        self.energyLevel = energyLevel
        self.transportationMode = transportationMode
        self.travelRadius = travelRadius
        self.cuisineTypes = cuisineTypes
        self.activityTypes = activityTypes
        self.drinkPreferences = drinkPreferences
        self.dietaryRestrictions = dietaryRestrictions
        self.budgetRange = budgetRange
        self.loveLanguages = loveLanguages
        self.partnerLoveLanguages = partnerLoveLanguages
        self.foodAllergies = foodAllergies
        self.hardNos = hardNos
        self.accessibilityNeeds = accessibilityNeeds
        self.smokingPreference = smokingPreference
        self.smokingActivities = smokingActivities
        self.gender = gender
        self.partnerGender = partnerGender
        self.relationshipStage = relationshipStage
        self.conversationTopics = conversationTopics
        self.additionalNotes = additionalNotes
        self.giftRecipient = giftRecipient
        self.giftInterests = giftInterests
        self.giftBudget = giftBudget
        self.giftOccasion = giftOccasion
        self.giftNotes = giftNotes
        self.giftRecipientIdentity = giftRecipientIdentity
        self.giftStyle = giftStyle
        self.giftFavoriteBrands = giftFavoriteBrands
        self.giftSizes = giftSizes
        self.updatedAt = updatedAt
    }
}

// MARK: - Table 4: Date Plans (`public.date_plans` — same rows as web; iOS uses `id` + `couple_id` + shared columns)
struct DBDatePlan: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var coupleId: UUID?
    var dateScheduled: Date?
    var title: String
    var tagline: String?
    var totalDuration: String?
    var estimatedCost: String?
    var stops: [DatePlanStop]
    var startingPoint: StartingPoint?
    var genieSecretTouch: GenieSecretTouch?
    var packingList: [String]?
    var weatherNote: String?
    var status: String
    var selectedOption: String?
    var planOptions: [PlanOptionSummary]?
    var giftSuggestions: [GiftSuggestion]?
    var conversationStarters: [ConversationStarter]?
    var rating: Int?
    var ratingNotes: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case coupleId = "couple_id"
        case dateScheduled = "date_scheduled"
        case title
        case tagline
        case totalDuration = "total_duration"
        case estimatedCost = "estimated_cost"
        case stops
        case startingPoint = "starting_point"
        case genieSecretTouch = "genie_secret_touch"
        case packingList = "packing_list"
        case weatherNote = "weather_note"
        case status
        case selectedOption = "selected_option"
        case planOptions = "plan_options"
        case giftSuggestions = "gift_suggestions"
        case conversationStarters = "conversation_starters"
        case rating
        case ratingNotes = "rating_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        coupleId: UUID? = nil,
        dateScheduled: Date? = nil,
        title: String,
        tagline: String? = nil,
        totalDuration: String? = nil,
        estimatedCost: String? = nil,
        stops: [DatePlanStop] = [],
        startingPoint: StartingPoint? = nil,
        genieSecretTouch: GenieSecretTouch? = nil,
        packingList: [String]? = nil,
        weatherNote: String? = nil,
        status: String = "planned",
        selectedOption: String? = nil,
        planOptions: [PlanOptionSummary]? = nil,
        giftSuggestions: [GiftSuggestion]? = nil,
        conversationStarters: [ConversationStarter]? = nil,
        rating: Int? = nil,
        ratingNotes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.coupleId = coupleId
        self.dateScheduled = dateScheduled
        self.title = title
        self.tagline = tagline
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.stops = stops
        self.startingPoint = startingPoint
        self.genieSecretTouch = genieSecretTouch
        self.packingList = packingList
        self.weatherNote = weatherNote
        self.status = status
        self.selectedOption = selectedOption
        self.planOptions = planOptions
        self.giftSuggestions = giftSuggestions
        self.conversationStarters = conversationStarters
        self.rating = rating
        self.ratingNotes = ratingNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        coupleId = try c.decodeIfPresent(UUID.self, forKey: .coupleId)
        dateScheduled = try c.decodeIfPresent(Date.self, forKey: .dateScheduled)
        title = try c.decode(String.self, forKey: .title)
        tagline = try c.decodeIfPresent(String.self, forKey: .tagline)
        totalDuration = try c.decodeIfPresent(String.self, forKey: .totalDuration)
        estimatedCost = try c.decodeIfPresent(String.self, forKey: .estimatedCost)
        stops = (try? c.decode([DatePlanStop].self, forKey: .stops)) ?? []
        startingPoint = try? c.decode(StartingPoint.self, forKey: .startingPoint)
        if let touch = try? c.decode(GenieSecretTouch.self, forKey: .genieSecretTouch) {
            genieSecretTouch = touch
        } else if let s = try? c.decode(String.self, forKey: .genieSecretTouch),
                  let data = s.data(using: .utf8),
                  let obj = try? JSONDecoder().decode(GenieSecretTouch.self, from: data) {
            genieSecretTouch = obj
        } else {
            genieSecretTouch = nil
        }
        packingList = try c.decodeIfPresent([String].self, forKey: .packingList)
        weatherNote = try c.decodeIfPresent(String.self, forKey: .weatherNote)
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "generated"
        selectedOption = try c.decodeIfPresent(String.self, forKey: .selectedOption)
        planOptions = try c.decodeIfPresent([PlanOptionSummary].self, forKey: .planOptions)
        giftSuggestions = try c.decodeIfPresent([GiftSuggestion].self, forKey: .giftSuggestions)
        if let starters = try? c.decode([ConversationStarter].self, forKey: .conversationStarters) {
            conversationStarters = starters
        } else if let strings = try? c.decode([String].self, forKey: .conversationStarters) {
            conversationStarters = strings.map { ConversationStarter(question: $0, category: "Conversation", emoji: "💭") }
        } else {
            conversationStarters = nil
        }
        rating = try c.decodeIfPresent(Int.self, forKey: .rating)
        ratingNotes = try c.decodeIfPresent(String.self, forKey: .ratingNotes)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(coupleId, forKey: .coupleId)
        try c.encodeIfPresent(dateScheduled, forKey: .dateScheduled)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(tagline, forKey: .tagline)
        try c.encodeIfPresent(totalDuration, forKey: .totalDuration)
        try c.encodeIfPresent(estimatedCost, forKey: .estimatedCost)
        try c.encode(stops, forKey: .stops)
        try c.encodeIfPresent(startingPoint, forKey: .startingPoint)
        try c.encodeIfPresent(genieSecretTouch, forKey: .genieSecretTouch)
        try c.encodeIfPresent(packingList, forKey: .packingList)
        try c.encodeIfPresent(weatherNote, forKey: .weatherNote)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(selectedOption, forKey: .selectedOption)
        try c.encodeIfPresent(planOptions, forKey: .planOptions)
        try c.encodeIfPresent(giftSuggestions, forKey: .giftSuggestions)
        try c.encodeIfPresent(conversationStarters, forKey: .conversationStarters)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encodeIfPresent(ratingNotes, forKey: .ratingNotes)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Experiences Waiting (`public.experiences_waiting` — unsaved generated plans; not `date_plans`)
struct DBExperiencesWaitingRow: Codable, Equatable, Identifiable {
    let id: UUID
    let userId: UUID
    var coupleId: UUID?
    var plan: DatePlan
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case coupleId = "couple_id"
        case plan
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, userId: UUID, coupleId: UUID?, plan: DatePlan, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.coupleId = coupleId
        self.plan = plan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(coupleId, forKey: .coupleId)
        try c.encode(plan, forKey: .plan)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
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

// MARK: - Table 5: Date Memories (`public.date_memories` — matches web; `image_url` is storage path or legacy full URL)
struct DBDateMemory: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var datePlanId: UUID?
    var venueId: UUID?
    /// Object path inside `date-memories` bucket (e.g. `userId/file.jpg`) or legacy public URL string.
    var imageUrl: String
    var caption: String?
    var takenAt: Date
    var isPublic: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case datePlanId = "date_plan_id"
        case venueId = "venue_id"
        case imageUrl = "image_url"
        case caption
        case takenAt = "taken_at"
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        datePlanId: UUID? = nil,
        venueId: UUID? = nil,
        imageUrl: String,
        caption: String? = nil,
        takenAt: Date,
        isPublic: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.datePlanId = datePlanId
        self.venueId = venueId
        self.imageUrl = imageUrl
        self.caption = caption
        self.takenAt = takenAt
        self.isPublic = isPublic
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        datePlanId = try c.decodeIfPresent(UUID.self, forKey: .datePlanId)
        venueId = try c.decodeIfPresent(UUID.self, forKey: .venueId)
        imageUrl = try c.decode(String.self, forKey: .imageUrl)
        caption = try c.decodeIfPresent(String.self, forKey: .caption)
        takenAt = try c.decodeIfPresent(Date.self, forKey: .takenAt) ?? Date()
        isPublic = try c.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(datePlanId, forKey: .datePlanId)
        try c.encodeIfPresent(venueId, forKey: .venueId)
        try c.encode(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(caption, forKey: .caption)
        try c.encode(takenAt, forKey: .takenAt)
        try c.encode(isPublic, forKey: .isPublic)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// MARK: - Table 6: Gift Suggestions
struct DBGiftSuggestion: Codable, Identifiable, Equatable {
    let giftId: UUID
    /// Nil for standalone Gift Finder items not tied to a specific plan.
    var planId: UUID?
    let coupleId: UUID
    var userId: UUID?
    var name: String?
    var priceRange: String?
    var description: String?
    var whyItFits: String?
    var whereToBuy: String?
    var purchaseUrl: String?
    var emoji: String?
    var storeSearchQuery: String?
    var imageUrl: String?
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
        case userId = "user_id"
        case name
        case priceRange = "price_range"
        case description
        case whyItFits = "why_it_fits"
        case whereToBuy = "where_to_buy"
        case purchaseUrl = "purchase_url"
        case emoji
        case storeSearchQuery = "store_search_query"
        case imageUrl = "image_url"
        case liked
        case purchased
        case purchasedAt = "purchased_at"
        case purchasedForPlanId = "purchased_for_plan_id"
        case createdAt = "created_at"
    }

    init(
        giftId: UUID = UUID(),
        planId: UUID? = nil,
        coupleId: UUID,
        userId: UUID? = nil,
        name: String? = nil,
        priceRange: String? = nil,
        description: String? = nil,
        whyItFits: String? = nil,
        whereToBuy: String? = nil,
        purchaseUrl: String? = nil,
        emoji: String? = nil,
        storeSearchQuery: String? = nil,
        imageUrl: String? = nil,
        liked: Bool? = nil,
        purchased: Bool = false,
        purchasedAt: Date? = nil,
        purchasedForPlanId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.giftId = giftId
        self.planId = planId
        self.coupleId = coupleId
        self.userId = userId
        self.name = name
        self.priceRange = priceRange
        self.description = description
        self.whyItFits = whyItFits
        self.whereToBuy = whereToBuy
        self.purchaseUrl = purchaseUrl
        self.emoji = emoji
        self.storeSearchQuery = storeSearchQuery
        self.imageUrl = imageUrl
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
    /// Optional when playlist is a standalone soundtrack not tied to a date plan.
    let planId: UUID?
    /// Nullable after migration – web users without a couple can still have rows.
    var coupleId: UUID?
    /// Added in web-sync migration; used for user_id-scoped RLS and fetching without a couple.
    var userId: UUID?
    var title: String?
    var description: String?
    var platform: String?
    /// Music genre / vibe (e.g. "romantic", "chill"). Added in web-sync migration.
    var vibe: String?
    /// Title of the date plan this playlist was generated for. Added in web-sync migration.
    var datePlanTitle: String?
    /// Date-plan stops stored for regeneration. Added in web-sync migration.
    var stops: [PlaylistStop]?
    var externalUrl: String?
    var externalPlaylistId: String?
    var tracks: [PlaylistTrack]?
    var totalDurationMinutes: Int?
    var generatedAt: Date
    /// Last-modified timestamp. Added in web-sync migration.
    var updatedAt: Date?

    var id: UUID { playlistId }

    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case planId = "plan_id"
        case coupleId = "couple_id"
        case userId = "user_id"
        case title
        case description
        case platform
        case vibe
        case datePlanTitle = "date_plan_title"
        case stops
        case externalUrl = "external_url"
        case externalPlaylistId = "external_playlist_id"
        case tracks
        case totalDurationMinutes = "total_duration_minutes"
        case generatedAt = "generated_at"
        case updatedAt = "updated_at"
    }

    init(
        playlistId: UUID = UUID(),
        planId: UUID? = nil,
        coupleId: UUID? = nil,
        userId: UUID? = nil,
        title: String? = nil,
        description: String? = nil,
        platform: String? = nil,
        vibe: String? = nil,
        datePlanTitle: String? = nil,
        stops: [PlaylistStop]? = nil,
        externalUrl: String? = nil,
        externalPlaylistId: String? = nil,
        tracks: [PlaylistTrack]? = nil,
        totalDurationMinutes: Int? = nil,
        generatedAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.playlistId = playlistId
        self.planId = planId
        self.coupleId = coupleId
        self.userId = userId
        self.title = title
        self.description = description
        self.platform = platform
        self.vibe = vibe
        self.datePlanTitle = datePlanTitle
        self.stops = stops
        self.externalUrl = externalUrl
        self.externalPlaylistId = externalPlaylistId
        self.tracks = tracks
        self.totalDurationMinutes = totalDurationMinutes
        self.generatedAt = generatedAt
        self.updatedAt = updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(playlistId, forKey: .playlistId)
        try c.encodeIfPresent(planId, forKey: .planId)
        try c.encodeIfPresent(coupleId, forKey: .coupleId)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(vibe, forKey: .vibe)
        try c.encodeIfPresent(datePlanTitle, forKey: .datePlanTitle)
        try c.encodeIfPresent(stops, forKey: .stops)
        try c.encodeIfPresent(externalUrl, forKey: .externalUrl)
        try c.encodeIfPresent(externalPlaylistId, forKey: .externalPlaylistId)
        try c.encodeIfPresent(tracks, forKey: .tracks)
        try c.encodeIfPresent(totalDurationMinutes, forKey: .totalDurationMinutes)
        try c.encode(generatedAt, forKey: .generatedAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
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

// MARK: - Partner Sessions (Plan Together cross-device)
struct DBPartnerSession: Codable, Identifiable {
    var id: UUID?
    var sessionId: String
    var inviterName: String?
    var inviterUserId: UUID?
    var inviterData: QuestionnaireData?
    var partnerData: QuestionnaireData?
    var inviterPlannedDates: [DBProposedDateTime]?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var identifier: UUID { id ?? UUID() }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case inviterName = "inviter_name"
        case inviterUserId = "inviter_user_id"
        case inviterData = "inviter_data"
        case partnerData = "partner_data"
        case inviterPlannedDates = "inviter_planned_dates"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DBProposedDateTime: Codable {
    var date: Date
    var timeLabel: String
    enum CodingKeys: String, CodingKey {
        case date
        case timeLabel = "time_label"
    }
}

struct DBPartnerSessionPlan: Codable, Identifiable {
    let id: UUID
    var partnerSessionId: UUID
    var planIndex: Int
    var planJson: DatePlan
    var inviterRank: Int?
    var partnerRank: Int?
    var createdAt: Date

    var identifier: UUID { id }

    enum CodingKeys: String, CodingKey {
        case id
        case partnerSessionId = "partner_session_id"
        case planIndex = "plan_index"
        case planJson = "plan_json"
        case inviterRank = "inviter_rank"
        case partnerRank = "partner_rank"
        case createdAt = "created_at"
    }
}

// MARK: - iOS user-generated content (love notes, sparks, saved starters, draft)
struct DBUserIosSyncPayload: Codable, Equatable {
    let userId: UUID
    var loveNotes: [SavedLoveNote]
    var savedConversationStarters: [SavedConversationStarter]
    var sparkSessions: [SparkSession]
    /// In-progress love note draft — survives reinstall and roams across devices.
    var loveNoteDraft: LoveNoteDraft?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case loveNotes = "love_notes"
        case savedConversationStarters = "saved_conversation_starters"
        case sparkSessions = "spark_sessions"
        case loveNoteDraft = "love_note_draft"
    }

    init(
        userId: UUID,
        loveNotes: [SavedLoveNote],
        savedConversationStarters: [SavedConversationStarter],
        sparkSessions: [SparkSession],
        loveNoteDraft: LoveNoteDraft? = nil
    ) {
        self.userId = userId
        self.loveNotes = loveNotes
        self.savedConversationStarters = savedConversationStarters
        self.sparkSessions = sparkSessions
        self.loveNoteDraft = loveNoteDraft
    }
}
