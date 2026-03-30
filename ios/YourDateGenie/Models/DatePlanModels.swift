import Foundation

// MARK: - Date Plan Stop
struct DatePlanStop: Identifiable, Hashable, Codable {
    let id: UUID
    let order: Int
    let name: String
    let venueType: String
    let timeSlot: String
    let duration: String
    let description: String
    let whyItFits: String
    let romanticTip: String
    let emoji: String
    
    // Travel info
    var travelTimeFromPrevious: String?
    var travelDistanceFromPrevious: String?
    var travelMode: String?
    
    // Google Places validation
    var validated: Bool?
    var placeId: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    
    // Enhanced venue info
    var websiteUrl: String?
    var phoneNumber: String?
    var openingHours: [String]?
    var estimatedCostPerPerson: String?
    /// Direct reservation URL (OpenTable, Resy, or venue booking page). Especially for dinner/restaurants.
    var bookingUrl: String?
    /// Place photo URL from Google Business Profile (Place Details photos), for cards and lists.
    var imageUrl: String?
    
    init(
        order: Int,
        name: String,
        venueType: String,
        timeSlot: String,
        duration: String,
        description: String,
        whyItFits: String,
        romanticTip: String,
        emoji: String,
        travelTimeFromPrevious: String? = nil,
        travelDistanceFromPrevious: String? = nil,
        travelMode: String? = nil,
        validated: Bool? = nil,
        placeId: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        websiteUrl: String? = nil,
        phoneNumber: String? = nil,
        openingHours: [String]? = nil,
        estimatedCostPerPerson: String? = nil,
        bookingUrl: String? = nil,
        imageUrl: String? = nil
    ) {
        self.id = UUID()
        self.order = order
        self.name = name
        self.venueType = venueType
        self.timeSlot = timeSlot
        self.duration = duration
        self.description = description
        self.whyItFits = whyItFits
        self.romanticTip = romanticTip
        self.emoji = emoji
        self.travelTimeFromPrevious = travelTimeFromPrevious
        self.travelDistanceFromPrevious = travelDistanceFromPrevious
        self.travelMode = travelMode
        self.validated = validated
        self.placeId = placeId
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.websiteUrl = websiteUrl
        self.phoneNumber = phoneNumber
        self.openingHours = openingHours
        self.estimatedCostPerPerson = estimatedCostPerPerson
        self.bookingUrl = bookingUrl
        self.imageUrl = imageUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id, order, name, venueType, timeSlot, duration, description, whyItFits, romanticTip, emoji
        case travelTimeFromPrevious, travelDistanceFromPrevious, travelMode
        case validated, placeId, address, latitude, longitude
        case websiteUrl, phoneNumber, openingHours, estimatedCostPerPerson, bookingUrl, imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        order = try c.decode(Int.self, forKey: .order)
        name = try c.decode(String.self, forKey: .name)
        venueType = try c.decodeIfPresent(String.self, forKey: .venueType) ?? ""
        timeSlot = try c.decodeIfPresent(String.self, forKey: .timeSlot) ?? ""
        duration = try c.decodeIfPresent(String.self, forKey: .duration) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        whyItFits = try c.decodeIfPresent(String.self, forKey: .whyItFits) ?? ""
        romanticTip = try c.decodeIfPresent(String.self, forKey: .romanticTip) ?? ""
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "📍"
        travelTimeFromPrevious = try c.decodeIfPresent(String.self, forKey: .travelTimeFromPrevious)
        travelDistanceFromPrevious = try c.decodeIfPresent(String.self, forKey: .travelDistanceFromPrevious)
        travelMode = try c.decodeIfPresent(String.self, forKey: .travelMode)
        validated = try c.decodeIfPresent(Bool.self, forKey: .validated)
        placeId = try c.decodeIfPresent(String.self, forKey: .placeId)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        websiteUrl = try c.decodeIfPresent(String.self, forKey: .websiteUrl)
        phoneNumber = try c.decodeIfPresent(String.self, forKey: .phoneNumber)
        openingHours = try c.decodeIfPresent([String].self, forKey: .openingHours)
        estimatedCostPerPerson = try c.decodeIfPresent(String.self, forKey: .estimatedCostPerPerson)
        bookingUrl = try c.decodeIfPresent(String.self, forKey: .bookingUrl)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(order, forKey: .order)
        try c.encode(name, forKey: .name)
        try c.encode(venueType, forKey: .venueType)
        try c.encode(timeSlot, forKey: .timeSlot)
        try c.encode(duration, forKey: .duration)
        try c.encode(description, forKey: .description)
        try c.encode(whyItFits, forKey: .whyItFits)
        try c.encode(romanticTip, forKey: .romanticTip)
        try c.encode(emoji, forKey: .emoji)
        try c.encodeIfPresent(travelTimeFromPrevious, forKey: .travelTimeFromPrevious)
        try c.encodeIfPresent(travelDistanceFromPrevious, forKey: .travelDistanceFromPrevious)
        try c.encodeIfPresent(travelMode, forKey: .travelMode)
        try c.encodeIfPresent(validated, forKey: .validated)
        try c.encodeIfPresent(placeId, forKey: .placeId)
        try c.encodeIfPresent(address, forKey: .address)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encodeIfPresent(websiteUrl, forKey: .websiteUrl)
        try c.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try c.encodeIfPresent(openingHours, forKey: .openingHours)
        try c.encodeIfPresent(estimatedCostPerPerson, forKey: .estimatedCostPerPerson)
        try c.encodeIfPresent(bookingUrl, forKey: .bookingUrl)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
}

// MARK: - Genie Secret Touch
struct GenieSecretTouch: Codable, Equatable {
    let title: String
    let description: String
    let emoji: String
}

// MARK: - Gift Suggestion
struct GiftSuggestion: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let priceRange: String
    let whereToBuy: String
    var purchaseUrl: String?
    let whyItFits: String
    let emoji: String
    var storeSearchQuery: String?
    var imageUrl: String?
    
    init(name: String, description: String, priceRange: String, whereToBuy: String, purchaseUrl: String? = nil, whyItFits: String, emoji: String, storeSearchQuery: String? = nil, imageUrl: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.priceRange = priceRange
        self.whereToBuy = whereToBuy
        self.purchaseUrl = purchaseUrl
        self.whyItFits = whyItFits
        self.emoji = emoji
        self.storeSearchQuery = storeSearchQuery
        self.imageUrl = imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        priceRange = try c.decodeIfPresent(String.self, forKey: .priceRange) ?? ""
        whereToBuy = try c.decodeIfPresent(String.self, forKey: .whereToBuy) ?? ""
        purchaseUrl = try c.decodeIfPresent(String.self, forKey: .purchaseUrl)
        whyItFits = try c.decodeIfPresent(String.self, forKey: .whyItFits) ?? ""
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "🎁"
        storeSearchQuery = try c.decodeIfPresent(String.self, forKey: .storeSearchQuery)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
    }
}

// MARK: - Conversation Starter
struct ConversationStarter: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let category: String
    let emoji: String
    
    init(question: String, category: String, emoji: String) {
        self.id = UUID()
        self.question = question
        self.category = category
        self.emoji = emoji
    }
    
    enum CodingKeys: String, CodingKey {
        case id, question, category, emoji
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        question = try c.decode(String.self, forKey: .question)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "General"
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "💬"
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(question, forKey: .question)
        try c.encode(category, forKey: .category)
        try c.encode(emoji, forKey: .emoji)
    }
}

// MARK: - Starting Point (departure for route; not a step in the itinerary)
struct StartingPoint: Codable, Equatable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Date Plan
struct DatePlan: Identifiable, Equatable, Codable {
    let id: UUID
    var optionLabel: String?
    let title: String
    let tagline: String
    let totalDuration: String
    let estimatedCost: String
    let stops: [DatePlanStop]
    /// Departure location for the route; itinerary steps start at 1 (first venue). Not encoded as a stop.
    var startingPoint: StartingPoint?
    let genieSecretTouch: GenieSecretTouch
    let packingList: [String]
    let weatherNote: String
    
    // Relationship enhancers
    var giftSuggestions: [GiftSuggestion]?
    var conversationStarters: [ConversationStarter]?
    
    /// When the user added this plan to the calendar; shown on saved-plan cards.
    var scheduledDate: Date?
    
    /// Use when creating a new plan (generates new id).
    init(
        optionLabel: String? = nil,
        title: String,
        tagline: String,
        totalDuration: String,
        estimatedCost: String,
        stops: [DatePlanStop],
        startingPoint: StartingPoint? = nil,
        genieSecretTouch: GenieSecretTouch,
        packingList: [String],
        weatherNote: String,
        giftSuggestions: [GiftSuggestion]? = nil,
        conversationStarters: [ConversationStarter]? = nil,
        scheduledDate: Date? = nil
    ) {
        self.id = UUID()
        self.optionLabel = optionLabel
        self.title = title
        self.tagline = tagline
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.stops = stops
        self.startingPoint = startingPoint
        self.genieSecretTouch = genieSecretTouch
        self.packingList = packingList
        self.weatherNote = weatherNote
        self.giftSuggestions = giftSuggestions
        self.conversationStarters = conversationStarters
        self.scheduledDate = scheduledDate
    }
    
    /// Use when restoring from cloud (preserves plan id for sync).
    init(
        id: UUID,
        optionLabel: String? = nil,
        title: String,
        tagline: String,
        totalDuration: String,
        estimatedCost: String,
        stops: [DatePlanStop],
        startingPoint: StartingPoint? = nil,
        genieSecretTouch: GenieSecretTouch,
        packingList: [String],
        weatherNote: String,
        giftSuggestions: [GiftSuggestion]? = nil,
        conversationStarters: [ConversationStarter]? = nil,
        scheduledDate: Date? = nil
    ) {
        self.id = id
        self.optionLabel = optionLabel
        self.title = title
        self.tagline = tagline
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.stops = stops
        self.startingPoint = startingPoint
        self.genieSecretTouch = genieSecretTouch
        self.packingList = packingList
        self.weatherNote = weatherNote
        self.giftSuggestions = giftSuggestions
        self.conversationStarters = conversationStarters
        self.scheduledDate = scheduledDate
    }
    
    /// Preferred image for cards/lists: first stop's Google place photo, or a theme-based stock image.
    var displayImageUrl: String {
        if let url = stops.first?.imageUrl, !url.isEmpty { return url }
        return Self.themeStockImageUrl(for: self)
    }
    
    /// Returns a stock image URL that matches the date plan theme (title, tagline, venue types).
    static func themeStockImageUrl(for plan: DatePlan) -> String {
        let t = (plan.title + " " + plan.tagline).lowercased()
        let venueTypes = plan.stops.map { $0.venueType.lowercased() }.joined(separator: " ")
        let combined = t + " " + venueTypes
        if combined.contains("rooftop") || combined.contains("sunset") || combined.contains("skyline") {
            return "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=400&h=300&fit=crop"
        }
        if combined.contains("wine") || combined.contains("vineyard") || combined.contains("vino") {
            return "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400&h=300&fit=crop"
        }
        if combined.contains("jazz") || combined.contains("music") || combined.contains("live") {
            return "https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=400&h=300&fit=crop"
        }
        if combined.contains("picnic") || combined.contains("park") || combined.contains("outdoor") || combined.contains("garden") {
            return "https://images.unsplash.com/photo-1528495612343-9ca9f4a4de28?w=400&h=300&fit=crop"
        }
        if combined.contains("beach") || combined.contains("coastal") || combined.contains("sea") {
            return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=300&fit=crop"
        }
        if combined.contains("art") || combined.contains("museum") || combined.contains("gallery") {
            return "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=400&h=300&fit=crop"
        }
        if combined.contains("adventure") || combined.contains("hike") || combined.contains("explore") {
            return "https://images.unsplash.com/photo-1533130061792-64b345e4a833?w=400&h=300&fit=crop"
        }
        if combined.contains("cozy") || combined.contains("intimate") || combined.contains("candle") {
            return "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=300&fit=crop"
        }
        return "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=400&h=300&fit=crop"
    }
}

// MARK: - Sample Data for Previews
extension DatePlan {
    static let sample = DatePlan(
        optionLabel: "Option A",
        title: "Classic SoHo Romance",
        tagline: "Vinyl, Velvet, and Vino in the heart of SoHo",
        totalDuration: "4.5 hours",
        estimatedCost: "$150-250 per person",
        stops: [
            DatePlanStop(
                order: 1,
                name: "Housing Works Bookstore",
                venueType: "Music & Books",
                timeSlot: "3:15 PM",
                duration: "1 hour",
                description: "Start your afternoon by browsing a curated selection of vinyl and books at this legendary music hub. While they recently moved to Rockefeller, their spirit and pop-ups remain a SoHo staple. We will visit the iconic Housing Works Bookstore nearby for that classic SoHo feel.",
                whyItFits: "Combines the requested music interest with the classic, intellectual charm of SoHo.",
                romanticTip: "Pick out a book or a record you think the other person would love and explain why at the end of the date.",
                emoji: "💿",
                validated: true,
                address: "126 Crosby St, New York, NY 10012, United States",
                websiteUrl: "https://housingworks.org",
                phoneNumber: "(212) 334-3324",
                estimatedCostPerPerson: "Free (to browse)/person"
            ),
            DatePlanStop(
                order: 2,
                name: "Glossier NYC",
                venueType: "Boutique Shopping",
                timeSlot: "4:30 PM",
                duration: "45 minutes",
                description: "A short walk away to the Glossier flagship store. It's an immersive shopping experience with beautiful pink aesthetics, perfect for picking up a small fragrance or skincare treat in a high-energy environment.",
                whyItFits: "Provides the 'shopping' activity in a venue that is world-renowned and quintessentially SoHo.",
                romanticTip: "The lighting in the 'Selfie Room' is incredible—be sure to take your first 'official' photo together here.",
                emoji: "🛍️",
                travelTimeFromPrevious: "4 mins",
                travelDistanceFromPrevious: "0.2 mi",
                validated: true,
                address: "72 Spring St, New York, NY 10012, United States",
                websiteUrl: "https://glossier.com",
                phoneNumber: "(212) 321-5092",
                estimatedCostPerPerson: "$30-50/person"
            ),
            DatePlanStop(
                order: 3,
                name: "Raoul's",
                venueType: "French Bistro",
                timeSlot: "5:30 PM",
                duration: "2 hours",
                description: "End your date at this iconic SoHo French bistro that has been a neighborhood staple since 1975. The candlelit atmosphere and classic French fare make it perfect for a romantic dinner.",
                whyItFits: "A legendary romantic venue that captures the essence of classic SoHo dining.",
                romanticTip: "Request the garden room for the most intimate setting.",
                emoji: "🍷",
                travelTimeFromPrevious: "10 mins",
                travelDistanceFromPrevious: "0.4 mi",
                validated: true,
                address: "180 Prince St, New York, NY 10012, United States",
                websiteUrl: "https://raouls.com",
                phoneNumber: "(212) 966-3518",
                estimatedCostPerPerson: "$80-120/person"
            )
        ],
        genieSecretTouch: GenieSecretTouch(
            title: "The Written Sentiment",
            description: "Before arriving at the restaurant, pop into a local stationary boutique like 'Goods for the Study' and write a quick, heartfelt note about your favorite moment from the afternoon to hand to them over cocktails.",
            emoji: "💌"
        ),
        packingList: ["Comfortable walking shoes (fashionable but practical)", "A light jacket for the March breeze", "Portable phone charger", "A small umbrella just in case"],
        weatherNote: "March in NYC can be chilly (mid-40s); stay close while walking between venues!",
        giftSuggestions: [
            GiftSuggestion(
                name: "Moonster Leather Journal Gift Set",
                description: "A high-quality, refillable leather journal for them to jot down their thoughts or sketches during your city adventures.",
                priceRange: "$30-40",
                whereToBuy: "Amazon",
                whyItFits: "Perfect for the 'Classic Romantic' style, encouraging them to document your shared memories.",
                emoji: "📓"
            ),
            GiftSuggestion(
                name: "Boy Smells Italian Kush Scented Candle",
                description: "A sophisticated, long-lasting candle to bring the chic atmosphere of SoHo back to their home.",
                priceRange: "$38-45",
                whereToBuy: "Amazon",
                whyItFits: "Connects to the Italian theme of the date and the recipient's love for a polished, cozy home environment.",
                emoji: "🕯️"
            ),
            GiftSuggestion(
                name: "Humans of New York by Brandon Stanton",
                description: "A beautiful coffee table book featuring the iconic architecture and street style of New York City.",
                priceRange: "$20-30",
                whereToBuy: "Amazon",
                whyItFits: "A memento of your NYC adventure that they can flip through and remember the day.",
                emoji: "📚"
            )
        ],
        conversationStarters: [
            ConversationStarter(
                question: "If we could live anywhere in New York for a month, which neighborhood would you choose?",
                category: "Dreams",
                emoji: "✈️"
            ),
            ConversationStarter(
                question: "What's a memory from today you want to remember forever?",
                category: "Connection",
                emoji: "💕"
            )
        ]
    )
    
    static let sampleOptionB = DatePlan(
        optionLabel: "Option B",
        title: "SoHo Discovery Route",
        tagline: "Vinyl, Vibes, and Velvet Cocktails in the Heart of SoHo",
        totalDuration: "4.5 hours",
        estimatedCost: "$150-250",
        stops: [
            DatePlanStop(
                order: 1,
                name: "Rough Trade NYC",
                venueType: "Record Store",
                timeSlot: "3:00 PM",
                duration: "1 hour",
                description: "Start your afternoon exploring this massive indie record store with live performances and a great cafe. Browse their curated vinyl collection together.",
                whyItFits: "Perfect for music lovers who want an interactive, discovery-based experience.",
                romanticTip: "Challenge each other to find a record that represents your relationship.",
                emoji: "🎵",
                validated: true,
                address: "30 Rockefeller Plaza, New York, NY 10112",
                estimatedCostPerPerson: "$20-40/person"
            ),
            DatePlanStop(
                order: 2,
                name: "The Mercer Kitchen",
                venueType: "New American Restaurant",
                timeSlot: "4:30 PM",
                duration: "1.5 hours",
                description: "Hidden beneath the Mercer Hotel, this Jean-Georges restaurant offers inventive American cuisine in a stylish subterranean setting.",
                whyItFits: "A hidden gem that rewards the adventurous diner.",
                romanticTip: "Ask for the corner banquette for a more intimate dining experience.",
                emoji: "🍽️",
                travelTimeFromPrevious: "15 mins",
                validated: true,
                address: "99 Prince St, New York, NY 10012",
                estimatedCostPerPerson: "$60-90/person"
            ),
            DatePlanStop(
                order: 3,
                name: "Pegu Club",
                venueType: "Speakeasy Cocktail Bar",
                timeSlot: "6:30 PM",
                duration: "1.5 hours",
                description: "End at this legendary cocktail lounge known for expertly crafted drinks and an intimate, sophisticated atmosphere.",
                whyItFits: "A fitting finale for adventurous spirits who appreciate craft cocktails.",
                romanticTip: "Let the bartender surprise you with their dealer's choice.",
                emoji: "🍸",
                travelTimeFromPrevious: "8 mins",
                validated: true,
                address: "77 W Houston St, New York, NY 10012",
                estimatedCostPerPerson: "$40-60/person"
            )
        ],
        genieSecretTouch: GenieSecretTouch(
            title: "The Discovery Game",
            description: "Create a scavenger hunt throughout the date - whoever spots the most interesting street art, unique storefront, or hidden detail wins a kiss.",
            emoji: "🎯"
        ),
        packingList: ["Comfortable walking shoes", "Camera or phone for photos", "Light jacket", "Cash for tips"],
        weatherNote: "Partly cloudy with cool temperatures - perfect for exploring on foot!",
        giftSuggestions: nil,
        conversationStarters: nil
    )
    
    static let sampleOptionC = DatePlan(
        optionLabel: "Option C",
        title: "Cozy SoHo Boutique & Beats",
        tagline: "Vinyl, Velvet, and Vino in the heart of SoHo",
        totalDuration: "4-5 hours (plus travel time)",
        estimatedCost: "$150-250 total",
        stops: [
            DatePlanStop(
                order: 1,
                name: "McNally Jackson Books",
                venueType: "Independent Bookstore & Cafe",
                timeSlot: "2:30 PM",
                duration: "1 hour",
                description: "Begin at this beloved independent bookstore with a cozy cafe. Browse together, share book recommendations, and enjoy a warm drink.",
                whyItFits: "Creates an intimate, intellectual atmosphere perfect for deep conversation.",
                romanticTip: "Each pick a book for the other as a gift.",
                emoji: "📚",
                validated: true,
                address: "52 Prince St, New York, NY 10012",
                estimatedCostPerPerson: "$15-30/person"
            ),
            DatePlanStop(
                order: 2,
                name: "Balthazar",
                venueType: "French Brasserie",
                timeSlot: "4:00 PM",
                duration: "2 hours",
                description: "Iconic SoHo brasserie with classic French fare, bustling energy, and timeless Parisian ambiance.",
                whyItFits: "The warm, romantic atmosphere is perfect for a lingering conversation over great food.",
                romanticTip: "Share the seafood tower and toast to your adventure.",
                emoji: "🥐",
                travelTimeFromPrevious: "5 mins",
                validated: true,
                address: "80 Spring St, New York, NY 10012",
                estimatedCostPerPerson: "$70-100/person"
            ),
            DatePlanStop(
                order: 3,
                name: "Fanelli Cafe",
                venueType: "Historic Bar",
                timeSlot: "6:30 PM",
                duration: "1.5 hours",
                description: "One of NYC's oldest bars, established in 1847. This no-frills neighborhood spot offers authentic charm and great drinks.",
                whyItFits: "A cozy, unpretentious spot to wind down and reflect on your day.",
                romanticTip: "Grab the corner table and create your own little world.",
                emoji: "🍺",
                travelTimeFromPrevious: "3 mins",
                validated: true,
                address: "94 Prince St, New York, NY 10012",
                estimatedCostPerPerson: "$25-40/person"
            )
        ],
        genieSecretTouch: GenieSecretTouch(
            title: "The Reading Nook Moment",
            description: "At the bookstore, find a quiet corner, sit together, and read the first chapter of a book out loud to each other.",
            emoji: "📖"
        ),
        packingList: ["Cozy sweater or cardigan", "Reading glasses if needed", "Small tote bag for purchases", "Hand warmers"],
        weatherNote: "Perfect weather for cozying up indoors between stops.",
        giftSuggestions: nil,
        conversationStarters: nil
    )
}

// MARK: - Travel Mode Icon (SF Symbol for itinerary and route map)
enum TravelModeIcon {
    /// Normalized mode key for consistent icon and label lookup (walking, driving, transit, biking, rideshare).
    /// Handles exact values and substrings so "20 mins driving" or "by car" still map correctly.
    static func normalizedMode(_ travelMode: String?) -> String {
        guard let raw = travelMode?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return "walking" }
        let mode = raw.lowercased()
        switch mode {
        case "car", "drive", "driving", "by car", "driven": return "driving"
        case "uber", "lyft", "taxi", "rideshare", "ride-share": return "rideshare"
        case "transit", "public-transit", "bus", "train", "subway", "metro", "public transport": return "transit"
        case "bike", "bicycle", "biking", "cycling", "cycle": return "biking"
        case "walk", "walking", "by foot", "on foot", "foot": return "walking"
        default:
            if mode.contains("driv") || mode.contains("car") || mode.contains("drive") { return "driving" }
            if mode.contains("walk") || mode.contains("foot") { return "walking" }
            if mode.contains("bike") || mode.contains("cycl") { return "biking" }
            if mode.contains("transit") || mode.contains("bus") || mode.contains("train") || mode.contains("subway") || mode.contains("metro") { return "transit" }
            if mode.contains("uber") || mode.contains("lyft") || mode.contains("taxi") || mode.contains("rideshare") { return "rideshare" }
            return "walking"
        }
    }
    
    /// SF Symbol for the given transportation mode. Driving = car, Walking = figure.walk, etc.
    /// When travelMode is nil/empty, infers from time text (e.g. "Drive 15 mins" or "15 mins by driving" → car).
    static func sfSymbol(for travelMode: String?, inferFromTimeText timeText: String? = nil) -> String {
        let mode = effectiveMode(travelMode: travelMode, timeText: timeText)
        switch mode {
        case "driving": return "car.fill"
        case "rideshare": return "car.fill"
        case "transit": return "tram.fill"
        case "biking": return "bicycle"
        case "walking": return "figure.walk"
        default: return "figure.walk"
        }
    }

    /// Resolves mode from explicit travelMode or by inferring from time text (e.g. "Drive 12 mins" → driving).
    private static func effectiveMode(travelMode: String?, timeText: String?) -> String {
        if let raw = travelMode?.trimmingCharacters(in: .whitespaces), !raw.isEmpty {
            return normalizedMode(raw)
        }
        guard let text = timeText?.trimmingCharacters(in: .whitespaces), !text.isEmpty else {
            return "walking"
        }
        let lower = text.lowercased()
        if lower.contains("driv") || lower.contains("car") || lower.contains("drive") { return "driving" }
        if lower.contains("uber") || lower.contains("lyft") || lower.contains("taxi") || lower.contains("rideshare") { return "rideshare" }
        if lower.contains("transit") || lower.contains("bus") || lower.contains("train") || lower.contains("subway") || lower.contains("metro") { return "transit" }
        if lower.contains("bike") || lower.contains("cycl") { return "biking" }
        if lower.contains("walk") || lower.contains("foot") { return "walking" }
        return "walking"
    }
    
    /// Short display label for route legs: "Walking", "Driving", "Transit", "Biking", "Rideshare".
    static func displayLabel(for travelMode: String?) -> String {
        switch normalizedMode(travelMode) {
        case "driving": return "Driving"
        case "rideshare": return "Rideshare"
        case "transit": return "Transit"
        case "biking": return "Biking"
        case "walking": return "Walking"
        default: return "Walking"
        }
    }
}

// MARK: - Map URL Helper
/// Builds Google Maps URLs so "View in Maps" / Directions open the correct business by name.
enum MapURLHelper {
    /// Last comma-separated segment of address (e.g. "123 Main St, Newark, NJ" → "NJ").
    static func cityFromAddress(_ address: String?) -> String {
        guard let address = address?.trimmingCharacters(in: .whitespaces), !address.isEmpty else { return "" }
        let parts = address.split(separator: ",", omittingEmptySubsequences: true).map { String($0.trimmingCharacters(in: .whitespaces)) }
        return parts.last ?? ""
    }
    
    /// City and state/region for display (e.g. "Newark, NJ", "London, Greater London"); no zip/postal code.
    /// Uses last two meaningful parts of the address; skips known country names; strips zip/postal from the result.
    static func cityStateOrRegionFromAddress(_ address: String?) -> String {
        guard let address = address?.trimmingCharacters(in: .whitespaces), !address.isEmpty else { return "" }
        let parts = address.split(separator: ",", omittingEmptySubsequences: true).map { String($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count >= 2 else {
            let single = parts.first ?? ""
            return stripZipPostalFromSegment(single)
        }
        let countryLike = Set(["usa", "u.s.a.", "united states", "canada", "uk", "united kingdom", "australia", "germany", "france", "spain", "italy", "japan", "india", "mexico", "brazil", "netherlands", "ireland", "new zealand", "south africa", "uae", "singapore", "thailand"])
        let last = parts[parts.count - 1].lowercased()
        let dropCountry = parts.count >= 3 && countryLike.contains(last)
        let from = dropCountry ? parts.count - 3 : parts.count - 2
        let to = dropCountry ? parts.count - 1 : parts.count
        var segment = parts[from..<to].map { stripZipPostalFromSegment($0) }
        segment = segment.filter { !$0.isEmpty }
        return segment.joined(separator: ", ")
    }
    
    /// Remove zip/postal codes from a segment for display (any country). Never show zipcodes on nav/home.
    private static func stripZipPostalFromSegment(_ segment: String) -> String {
        var s = segment.trimmingCharacters(in: .whitespaces)
        // Whole segment is only digits (US zip alone, AU/FR/DE etc. postal as segment)
        if s.range(of: #"^\d{3,10}(-\d{2,6})?$"#, options: .regularExpression) != nil {
            return ""
        }
        // UK-style postcode: whole segment like "SW1A 1AA" or "M1 1AA"
        if s.range(of: #"^[A-Za-z]{1,2}\d[A-Za-z0-9]?\s*\d[A-Za-z]{2}$"#, options: .regularExpression) != nil {
            return ""
        }
        // Canadian postcode: A1A 1A1
        if s.range(of: #"^[A-Za-z]\d[A-Za-z]\s*\d[A-Za-z]\d$"#, options: .regularExpression) != nil {
            return ""
        }
        // Trailing space + digits (US 5/5+4, and other countries' numeric postal)
        if let r = s.range(of: #" \d{3,10}(-\d{2,6})?$"#, options: .regularExpression) {
            s = String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        // Trailing space + UK/Canadian-style alphanumeric postcode
        if let r = s.range(of: #" [A-Za-z]{1,2}\d[A-Za-z0-9]?\s*\d[A-Za-z]{2}$"#, options: .regularExpression) {
            s = String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Google Maps search URL by place name and optional city (opens the correct business).
    static func googleMapsSearchURL(placeName: String, city: String?) -> URL? {
        let name = placeName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        let query = city?.isEmpty == false ? "\(name) \(city!)" : name
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
    }

    /// URL for a single stop: always use search-by-name so the place opens correctly in Maps (place_id can fail to resolve).
    static func urlForStop(_ stop: DatePlanStop) -> URL? {
        let city = cityFromAddress(stop.address)
        return googleMapsSearchURL(placeName: stop.name, city: city.isEmpty ? nil : city)
    }

    /// Value for Google Maps directions origin/destination/waypoints: "place_id:xxx" or encoded "Name, City".
    static func directionsQueryValue(for stop: DatePlanStop) -> String {
        if let placeId = stop.placeId, !placeId.isEmpty {
            return "place_id:\(placeId)"
        }
        let city = cityFromAddress(stop.address)
        let query = city.isEmpty ? stop.name : "\(stop.name), \(city)"
        return query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    }
    
    /// URL to open directions from starting point to a destination stop (e.g. "Get to stop 1").
    static func directionsURL(origin: StartingPoint, destination: DatePlanStop) -> URL? {
        let originStr = "\(origin.latitude),\(origin.longitude)"
        let destStr = directionsQueryValue(for: destination)
        let destEncoded = destStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destStr
        return URL(string: "https://www.google.com/maps/dir/?api=1&origin=\(originStr)&destination=\(destEncoded)")
    }
}
