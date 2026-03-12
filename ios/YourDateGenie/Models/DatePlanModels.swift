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
    
    init(name: String, description: String, priceRange: String, whereToBuy: String, purchaseUrl: String? = nil, whyItFits: String, emoji: String, storeSearchQuery: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.priceRange = priceRange
        self.whereToBuy = whereToBuy
        self.purchaseUrl = purchaseUrl
        self.whyItFits = whyItFits
        self.emoji = emoji
        self.storeSearchQuery = storeSearchQuery
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
    let genieSecretTouch: GenieSecretTouch
    let packingList: [String]
    let weatherNote: String
    
    // Relationship enhancers
    var giftSuggestions: [GiftSuggestion]?
    var conversationStarters: [ConversationStarter]?
    
    /// When the user added this plan to the calendar; shown on saved-plan cards.
    var scheduledDate: Date?
    
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
        self.genieSecretTouch = genieSecretTouch
        self.packingList = packingList
        self.weatherNote = weatherNote
        self.giftSuggestions = giftSuggestions
        self.conversationStarters = conversationStarters
        self.scheduledDate = scheduledDate
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
