import Foundation

// MARK: - Questionnaire Data Model
struct QuestionnaireData: Codable {
    // Step 1: Location & Context
    var city: String
    var neighborhood: String
    var startingAddress: String
    var dateType: String
    var occasion: String
    var dateScheduled: Date?
    var startTime: String
    
    // Step 2: Transportation & Logistics
    var transportationMode: String
    var travelRadius: String
    
    // Step 3: Vibe & Energy
    var energyLevel: String
    var activityPreferences: [String]
    var timeOfDay: String
    var duration: String
    
    // Step 4: Food & Drinks
    var cuisinePreferences: [String]
    var dietaryRestrictions: [String]
    var drinkPreferences: String
    var budgetRange: String
    
    // Step 5: Deal Breakers
    var allergies: [String]
    var hardNos: [String]
    var accessibilityNeeds: [String]
    var smokingPreference: String
    var additionalNotes: String
    
    // Step 6: Relationship Enhancers
    var wantGiftSuggestions: Bool
    var giftRecipient: String
    var partnerInterests: [String]
    var giftBudget: String
    var wantConversationStarters: Bool
    var relationshipStage: String
    var conversationTopics: [String]
    
    init(
        city: String = "",
        neighborhood: String = "",
        startingAddress: String = "",
        dateType: String = "",
        occasion: String = "",
        dateScheduled: Date? = nil,
        startTime: String = "",
        transportationMode: String = "",
        travelRadius: String = "",
        energyLevel: String = "",
        activityPreferences: [String] = [],
        timeOfDay: String = "",
        duration: String = "",
        cuisinePreferences: [String] = [],
        dietaryRestrictions: [String] = [],
        drinkPreferences: String = "",
        budgetRange: String = "",
        allergies: [String] = [],
        hardNos: [String] = [],
        accessibilityNeeds: [String] = [],
        smokingPreference: String = "",
        additionalNotes: String = "",
        wantGiftSuggestions: Bool = false,
        giftRecipient: String = "",
        partnerInterests: [String] = [],
        giftBudget: String = "",
        wantConversationStarters: Bool = false,
        relationshipStage: String = "",
        conversationTopics: [String] = []
    ) {
        self.city = city
        self.neighborhood = neighborhood
        self.startingAddress = startingAddress
        self.dateType = dateType
        self.occasion = occasion
        self.dateScheduled = dateScheduled
        self.startTime = startTime
        self.transportationMode = transportationMode
        self.travelRadius = travelRadius
        self.energyLevel = energyLevel
        self.activityPreferences = activityPreferences
        self.timeOfDay = timeOfDay
        self.duration = duration
        self.cuisinePreferences = cuisinePreferences
        self.dietaryRestrictions = dietaryRestrictions
        self.drinkPreferences = drinkPreferences
        self.budgetRange = budgetRange
        self.allergies = allergies
        self.hardNos = hardNos
        self.accessibilityNeeds = accessibilityNeeds
        self.smokingPreference = smokingPreference
        self.additionalNotes = additionalNotes
        self.wantGiftSuggestions = wantGiftSuggestions
        self.giftRecipient = giftRecipient
        self.partnerInterests = partnerInterests
        self.giftBudget = giftBudget
        self.wantConversationStarters = wantConversationStarters
        self.relationshipStage = relationshipStage
        self.conversationTopics = conversationTopics
    }
}

// MARK: - Stored Questionnaire Progress (for "Pick up where you left off")
struct StoredQuestionnaireProgress: Codable {
    let data: QuestionnaireData
    let step: Int
    let timestamp: TimeInterval
}

enum QuestionnaireProgressStore {
    static let key = "dateGenie_questionnaireProgress"
    static let maxAge: TimeInterval = 24 * 60 * 60
    
    static func save(data: QuestionnaireData, step: Int) {
        let stored = StoredQuestionnaireProgress(data: data, step: step, timestamp: Date().timeIntervalSince1970)
        if let encoded = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> (data: QuestionnaireData, step: Int)? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(StoredQuestionnaireProgress.self, from: data),
              Date().timeIntervalSince1970 - stored.timestamp < maxAge else {
            return nil
        }
        return (stored.data, stored.step)
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static var hasValidProgress: Bool {
        load() != nil
    }
}

// MARK: - Last Questionnaire Data (for "Use & Generate from Last Plan")
enum LastQuestionnaireStore {
    static let key = "dateGenie_lastQuestionnaireData"
    
    static func save(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(QuestionnaireData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static var hasLastData: Bool {
        load() != nil
    }
}

// MARK: - Option Item Model
struct OptionItem: Identifiable, Hashable {
    let id: String
    let value: String
    let label: String
    let emoji: String
    var desc: String?
    var time: String?
    var distance: String?
    var range: String?
    
    init(value: String, label: String, emoji: String, desc: String? = nil, time: String? = nil, distance: String? = nil, range: String? = nil) {
        self.id = value
        self.value = value
        self.label = label
        self.emoji = emoji
        self.desc = desc
        self.time = time
        self.distance = distance
        self.range = range
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
    
    static func == (lhs: OptionItem, rhs: OptionItem) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Questionnaire Options
struct QuestionnaireOptions {
    
    static let dateTypes: [OptionItem] = [
        OptionItem(value: "first-date", label: "First Date", emoji: "🌟"),
        OptionItem(value: "anniversary", label: "Anniversary", emoji: "💍"),
        OptionItem(value: "casual", label: "Casual Night", emoji: "🎉"),
        OptionItem(value: "romantic", label: "Romantic", emoji: "💕"),
        OptionItem(value: "adventure", label: "Adventure", emoji: "🚀"),
        OptionItem(value: "staycation", label: "Staycation", emoji: "🏠"),
        OptionItem(value: "solo", label: "Solo Date", emoji: "🧘‍♀️"),
    ]
    
    static let occasions: [OptionItem] = [
        OptionItem(value: "none", label: "Just Because", emoji: "✨"),
        OptionItem(value: "birthday", label: "Birthday", emoji: "🎂"),
        OptionItem(value: "promotion", label: "Celebration", emoji: "🎊"),
        OptionItem(value: "apology", label: "Making Amends", emoji: "💝"),
        OptionItem(value: "proposal", label: "Special Question", emoji: "💎"),
        OptionItem(value: "reunion", label: "Reunion", emoji: "🤗"),
    ]
    
    static let energyLevels: [OptionItem] = [
        OptionItem(value: "chill", label: "Chill & Relaxed", emoji: "🧘", desc: "Low-key, cozy vibes"),
        OptionItem(value: "moderate", label: "Balanced", emoji: "☕", desc: "Mix of activity and rest"),
        OptionItem(value: "active", label: "Active & Fun", emoji: "🎮", desc: "Games, walking, exploring"),
        OptionItem(value: "high-energy", label: "High Energy", emoji: "⚡", desc: "Dancing, sports, adventure"),
    ]
    
    static let activities: [OptionItem] = [
        OptionItem(value: "dining", label: "Fine Dining", emoji: "🍽️"),
        OptionItem(value: "movies", label: "Movies", emoji: "🎬"),
        OptionItem(value: "outdoors", label: "Outdoors", emoji: "🌳"),
        OptionItem(value: "arts", label: "Arts & Culture", emoji: "🎨"),
        OptionItem(value: "music", label: "Live Music", emoji: "🎵"),
        OptionItem(value: "games", label: "Games/Sports", emoji: "🎯"),
        OptionItem(value: "spa", label: "Spa/Wellness", emoji: "💆"),
        OptionItem(value: "shopping", label: "Shopping", emoji: "🛍️"),
    ]
    
    static let timeOfDay: [OptionItem] = [
        OptionItem(value: "morning", label: "Morning", emoji: "🌅", time: "8am - 12pm"),
        OptionItem(value: "afternoon", label: "Afternoon", emoji: "☀️", time: "12pm - 5pm"),
        OptionItem(value: "evening", label: "Evening", emoji: "🌆", time: "5pm - 9pm"),
        OptionItem(value: "night", label: "Late Night", emoji: "🌙", time: "9pm+"),
    ]
    
    static let durations: [OptionItem] = [
        OptionItem(value: "quick", label: "Quick Date", emoji: "⏱️", time: "2-3 hours"),
        OptionItem(value: "half-day", label: "Half Day", emoji: "🕐", time: "4-6 hours"),
        OptionItem(value: "full-day", label: "Full Day", emoji: "📅", time: "8+ hours"),
        OptionItem(value: "overnight", label: "Overnight", emoji: "🌙", time: "24+ hours"),
    ]
    
    static let cuisines: [OptionItem] = [
        OptionItem(value: "italian", label: "Italian", emoji: "🍝"),
        OptionItem(value: "japanese", label: "Japanese", emoji: "🍣"),
        OptionItem(value: "mexican", label: "Mexican", emoji: "🌮"),
        OptionItem(value: "french", label: "French", emoji: "🥐"),
        OptionItem(value: "indian", label: "Indian", emoji: "🍛"),
        OptionItem(value: "thai", label: "Thai", emoji: "🍜"),
        OptionItem(value: "american", label: "American", emoji: "🍔"),
        OptionItem(value: "mediterranean", label: "Mediterranean", emoji: "🥙"),
        OptionItem(value: "korean", label: "Korean", emoji: "🍖"),
        OptionItem(value: "chinese", label: "Chinese", emoji: "🥡"),
    ]
    
    static let dietaryRestrictions: [OptionItem] = [
        OptionItem(value: "vegetarian", label: "Vegetarian", emoji: "🥬"),
        OptionItem(value: "vegan", label: "Vegan", emoji: "🌱"),
        OptionItem(value: "gluten-free", label: "Gluten-Free", emoji: "🌾"),
        OptionItem(value: "dairy-free", label: "Dairy-Free", emoji: "🥛"),
        OptionItem(value: "halal", label: "Halal", emoji: "🍖"),
        OptionItem(value: "kosher", label: "Kosher", emoji: "✡️"),
        OptionItem(value: "keto", label: "Keto", emoji: "🥑"),
        OptionItem(value: "none", label: "None", emoji: "✅"),
    ]
    
    static let drinkPreferences: [OptionItem] = [
        OptionItem(value: "cocktails", label: "Cocktails", emoji: "🍸"),
        OptionItem(value: "wine", label: "Wine", emoji: "🍷"),
        OptionItem(value: "beer", label: "Beer", emoji: "🍺"),
        OptionItem(value: "spirits", label: "Whiskey", emoji: "🥃"),
        OptionItem(value: "mocktails", label: "Mocktails", emoji: "🍹"),
        OptionItem(value: "coffee", label: "Coffee/Tea", emoji: "☕"),
        OptionItem(value: "non-alcoholic", label: "No Alcohol", emoji: "🚫"),
    ]
    
    static let budgetRanges: [OptionItem] = [
        OptionItem(value: "budget", label: "$", emoji: "💵", desc: "Under $50", range: "$0-50"),
        OptionItem(value: "moderate", label: "$$", emoji: "💰", desc: "$50-150", range: "$50-150"),
        OptionItem(value: "upscale", label: "$$$", emoji: "💎", desc: "$150-300", range: "$150-300"),
        OptionItem(value: "luxury", label: "$$$$", emoji: "👑", desc: "$300+", range: "$300+"),
    ]
    
    static let allergies: [OptionItem] = [
        OptionItem(value: "peanuts", label: "Peanuts", emoji: "🥜"),
        OptionItem(value: "tree-nuts", label: "Tree Nuts", emoji: "🌰"),
        OptionItem(value: "shellfish", label: "Shellfish", emoji: "🦐"),
        OptionItem(value: "fish", label: "Fish", emoji: "🐟"),
        OptionItem(value: "eggs", label: "Eggs", emoji: "🥚"),
        OptionItem(value: "soy", label: "Soy", emoji: "🫘"),
        OptionItem(value: "wheat", label: "Wheat", emoji: "🌾"),
        OptionItem(value: "none", label: "None", emoji: "✅"),
    ]
    
    static let hardNos: [OptionItem] = [
        OptionItem(value: "loud-venues", label: "Loud Venues", emoji: "🔊"),
        OptionItem(value: "crowds", label: "Crowds", emoji: "👥"),
        OptionItem(value: "heights", label: "Heights", emoji: "🏔️"),
        OptionItem(value: "water", label: "Water", emoji: "🌊"),
        OptionItem(value: "spicy-food", label: "Spicy Food", emoji: "🌶️"),
        OptionItem(value: "physical", label: "Physical Activity", emoji: "🏃"),
        OptionItem(value: "late-night", label: "Late Nights", emoji: "🌙"),
    ]
    
    static let transportationModes: [OptionItem] = [
        OptionItem(value: "walking", label: "Walking", emoji: "🚶", desc: "Keep it close"),
        OptionItem(value: "rideshare", label: "Rideshare", emoji: "🚕", desc: "Uber, Lyft, taxi"),
        OptionItem(value: "driving", label: "Driving", emoji: "🚗", desc: "Personal car"),
        OptionItem(value: "public-transit", label: "Transit", emoji: "🚇", desc: "Subway, bus, train"),
        OptionItem(value: "biking", label: "Biking", emoji: "🚴", desc: "Cycle around"),
    ]
    
    static let travelRadius: [OptionItem] = [
        OptionItem(value: "walkable", label: "Walkable", emoji: "👣", distance: "< 1 mile"),
        OptionItem(value: "neighborhood", label: "Neighborhood", emoji: "🏘️", distance: "1-5 miles"),
        OptionItem(value: "city-wide", label: "City-wide", emoji: "🌆", distance: "5-15 miles"),
        OptionItem(value: "metro", label: "Metro Area", emoji: "🚗", distance: "15-30 miles"),
        OptionItem(value: "road-trip", label: "Road Trip", emoji: "🛣️", distance: "50+ miles"),
    ]
    
    static let relationshipStages: [OptionItem] = [
        OptionItem(value: "new", label: "New", emoji: "🌱", desc: "Getting to know each other"),
        OptionItem(value: "dating", label: "Dating", emoji: "💑", desc: "1-2 years"),
        OptionItem(value: "established", label: "Established", emoji: "💍", desc: "3+ years"),
        OptionItem(value: "rekindling", label: "Rekindling", emoji: "🔥", desc: "Reigniting the spark"),
        OptionItem(value: "long-distance", label: "Long Distance", emoji: "✈️", desc: "Making moments count"),
    ]
    
    static let partnerInterests: [OptionItem] = [
        OptionItem(value: "tech", label: "Tech", emoji: "💻"),
        OptionItem(value: "fashion", label: "Fashion", emoji: "👗"),
        OptionItem(value: "sports", label: "Sports", emoji: "⚽"),
        OptionItem(value: "books", label: "Books", emoji: "📚"),
        OptionItem(value: "music", label: "Music", emoji: "🎵"),
        OptionItem(value: "art", label: "Art", emoji: "🎨"),
        OptionItem(value: "cooking", label: "Cooking", emoji: "👨‍🍳"),
        OptionItem(value: "travel", label: "Travel", emoji: "✈️"),
        OptionItem(value: "fitness", label: "Fitness", emoji: "💪"),
        OptionItem(value: "gaming", label: "Gaming", emoji: "🎮"),
        OptionItem(value: "nature", label: "Nature", emoji: "🌿"),
        OptionItem(value: "movies", label: "Movies", emoji: "🎬"),
    ]
    
    static let conversationTopics: [OptionItem] = [
        OptionItem(value: "dreams", label: "Dreams & Goals", emoji: "⭐"),
        OptionItem(value: "memories", label: "Memories", emoji: "📸"),
        OptionItem(value: "values", label: "Values", emoji: "💭"),
        OptionItem(value: "fun", label: "Fun & Playful", emoji: "😄"),
        OptionItem(value: "deep", label: "Deep Connection", emoji: "💞"),
        OptionItem(value: "adventure", label: "Adventures", emoji: "🗺️"),
    ]
}
