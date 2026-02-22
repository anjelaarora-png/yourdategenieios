import Foundation

// MARK: - Date Plan Stop
struct DatePlanStop: Identifiable, Hashable {
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
        estimatedCostPerPerson: String? = nil
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
    }
}

// MARK: - Genie Secret Touch
struct GenieSecretTouch: Codable {
    let title: String
    let description: String
    let emoji: String
}

// MARK: - Gift Suggestion
struct GiftSuggestion: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let priceRange: String
    let whereToBuy: String
    var purchaseUrl: String?
    let whyItFits: String
    let emoji: String
    
    init(name: String, description: String, priceRange: String, whereToBuy: String, purchaseUrl: String? = nil, whyItFits: String, emoji: String) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.priceRange = priceRange
        self.whereToBuy = whereToBuy
        self.purchaseUrl = purchaseUrl
        self.whyItFits = whyItFits
        self.emoji = emoji
    }
}

// MARK: - Conversation Starter
struct ConversationStarter: Identifiable, Hashable {
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
}

// MARK: - Date Plan
struct DatePlan: Identifiable {
    let id: UUID
    var optionLabel: String?
    let title: String
    let tagline: String
    let totalDuration: String
    let estimatedCost: String
    let stops: [DatePlanStop]
    let genieSecretTouch: GenieSecretTouch
    let packingList: [String]
    let weatherNote: String
    
    // Relationship enhancers
    var giftSuggestions: [GiftSuggestion]?
    var conversationStarters: [ConversationStarter]?
    
    init(
        optionLabel: String? = nil,
        title: String,
        tagline: String,
        totalDuration: String,
        estimatedCost: String,
        stops: [DatePlanStop],
        genieSecretTouch: GenieSecretTouch,
        packingList: [String],
        weatherNote: String,
        giftSuggestions: [GiftSuggestion]? = nil,
        conversationStarters: [ConversationStarter]? = nil
    ) {
        self.id = UUID()
        self.optionLabel = optionLabel
        self.title = title
        self.tagline = tagline
        self.totalDuration = totalDuration
        self.estimatedCost = estimatedCost
        self.stops = stops
        self.genieSecretTouch = genieSecretTouch
        self.packingList = packingList
        self.weatherNote = weatherNote
        self.giftSuggestions = giftSuggestions
        self.conversationStarters = conversationStarters
    }
}

// MARK: - Sample Data for Previews
extension DatePlan {
    static let sample = DatePlan(
        optionLabel: "Option A",
        title: "Romantic Italian Evening",
        tagline: "A cozy night filled with pasta, wine, and city views",
        totalDuration: "4-5 hours",
        estimatedCost: "$120-180",
        stops: [
            DatePlanStop(
                order: 1,
                name: "The Cellar Wine Bar",
                venueType: "Wine Bar",
                timeSlot: "7:00 PM",
                duration: "1 hour",
                description: "A cozy underground wine bar with an impressive Italian wine selection",
                whyItFits: "Perfect intimate setting to start your evening",
                romanticTip: "Ask for the corner booth for extra privacy",
                emoji: "🍷",
                address: "123 Wine Street"
            ),
            DatePlanStop(
                order: 2,
                name: "Trattoria Milano",
                venueType: "Italian Restaurant",
                timeSlot: "8:15 PM",
                duration: "2 hours",
                description: "Authentic Italian cuisine with handmade pasta",
                whyItFits: "Matches your love for Italian food and romantic ambiance",
                romanticTip: "Try the truffle pasta - it's their signature dish",
                emoji: "🍝",
                travelTimeFromPrevious: "10 min",
                address: "456 Pasta Avenue"
            ),
            DatePlanStop(
                order: 3,
                name: "Skyview Rooftop",
                venueType: "Rooftop Bar",
                timeSlot: "10:30 PM",
                duration: "1 hour",
                description: "Stunning city views with craft cocktails",
                whyItFits: "End the night with unforgettable views",
                romanticTip: "Grab a spot near the railing for the best view",
                emoji: "🌃",
                travelTimeFromPrevious: "5 min",
                address: "789 Skyline Blvd"
            )
        ],
        genieSecretTouch: GenieSecretTouch(
            title: "Bring a small bouquet",
            description: "Pick up some flowers before dinner - it's a classic for a reason",
            emoji: "💐"
        ),
        packingList: ["Jacket (rooftop can be breezy)", "Breath mints", "Fully charged phone"],
        weatherNote: "Clear skies expected - perfect for rooftop views!",
        giftSuggestions: [
            GiftSuggestion(
                name: "Italian Wine Set",
                description: "A curated selection of Italian wines",
                priceRange: "$45-60",
                whereToBuy: "Local wine shop",
                whyItFits: "Extends the Italian theme beyond dinner",
                emoji: "🍷"
            )
        ],
        conversationStarters: [
            ConversationStarter(
                question: "If we could live anywhere in Italy for a month, where would you choose?",
                category: "Dreams",
                emoji: "✈️"
            ),
            ConversationStarter(
                question: "What's a memory from tonight you want to remember forever?",
                category: "Connection",
                emoji: "💕"
            )
        ]
    )
}
