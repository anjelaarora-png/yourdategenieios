export interface QuestionnaireData {
  // Step 1: Location & Context
  city: string;
  neighborhood: string;
  startingAddress: string; // Starting point/departure location
  dateType: string;
  occasion: string;
  dateScheduled: string; // Date of the date (YYYY-MM-DD)
  startTime: string; // Start time (e.g., "19:00")
  /** User's timezone (e.g. Asia/Kolkata) for local currency; set from browser/VPN. */
  timeZone?: string;
  /** User's country code (e.g. IN, US) for local currency when available. */
  countryCode?: string;
  /** Explicit currency code (e.g. INR, USD); overrides timeZone/countryCode if set. */
  currencyCode?: string;

  // Step 2: Transportation & Logistics
  transportationMode: string;
  travelRadius: string;
  
  // Step 3: Vibe & Energy
  energyLevel: string;
  activityPreferences: string[];
  timeOfDay: string;
  duration: string;
  
  // Step 4: Food & Drinks
  cuisinePreferences: string[];
  dietaryRestrictions: string[];
  drinkPreferences: string[];
  budgetRange: string;
  
  // Step 5: Deal Breakers
  allergies: string[];
  hardNos: string[];
  accessibilityNeeds: string[];
  smokingPreference: string;
  smokingActivities: string[];
  additionalNotes: string;
  
  // Step 6: Relationship Enhancers (Optional)
  userIdentity: string;
  partnerIdentity: string;
  userLoveLanguages: string[];
  partnerLoveLanguages: string[];
  wantGiftSuggestions: boolean;
  giftRecipient: string;
  giftRecipientNotes: string;
  partnerInterests: string[];
  giftBudget: string;
  /** Recipient identity for gift personalization (when shopping for partner/date). Reuses partnerIdentity. */
  recipientIdentity?: string;
  /** Gift style preferences e.g. minimal, luxury, quirky */
  giftStyle?: string[];
  /** Favorite brands or stores (optional) */
  favoriteBrandsOrStores?: string;
  /** Sizes if relevant for apparel etc. (optional) */
  recipientSizes?: string;
  wantConversationStarters: boolean;
  relationshipStage: string;
  conversationTopics: string[];
}

export const initialQuestionnaireData: QuestionnaireData = {
  city: "",
  neighborhood: "",
  startingAddress: "",
  dateType: "",
  occasion: "",
  dateScheduled: "",
  startTime: "",
  transportationMode: "",
  travelRadius: "",
  energyLevel: "",
  activityPreferences: [],
  timeOfDay: "",
  duration: "",
  cuisinePreferences: [],
  dietaryRestrictions: [],
  drinkPreferences: [],
  budgetRange: "",
  allergies: [],
  hardNos: [],
  accessibilityNeeds: [],
  smokingPreference: "",
  smokingActivities: [],
  additionalNotes: "",
  // Relationship enhancers
  userIdentity: "",
  partnerIdentity: "",
  userLoveLanguages: [],
  partnerLoveLanguages: [],
  wantGiftSuggestions: false,
  giftRecipient: "",
  giftRecipientNotes: "",
  partnerInterests: [],
  giftBudget: "",
  wantConversationStarters: false,
  relationshipStage: "",
  conversationTopics: [],
  recipientIdentity: "",
  giftStyle: [],
  favoriteBrandsOrStores: "",
  recipientSizes: "",
};

export const LOVE_LANGUAGES = [
  { value: "words", label: "Words of Affirmation", emoji: "💬", desc: "Verbal compliments & encouragement" },
  { value: "acts", label: "Acts of Service", emoji: "🤝", desc: "Helpful actions & support" },
  { value: "gifts", label: "Receiving Gifts", emoji: "🎁", desc: "Thoughtful presents & tokens" },
  { value: "time", label: "Quality Time", emoji: "⏰", desc: "Undivided attention & presence" },
  { value: "touch", label: "Physical Touch", emoji: "🤗", desc: "Affection & closeness" },
];

export const IDENTITY_OPTIONS = [
  { value: "man", label: "Man", emoji: "👨" },
  { value: "woman", label: "Woman", emoji: "👩" },
  { value: "non-binary", label: "Non-binary", emoji: "🧑" },
  { value: "prefer-not-to-say", label: "Prefer not to say", emoji: "🙂" },
];

export const GIFT_RECIPIENTS = [
  { value: "partner", label: "My Partner", emoji: "💕", desc: "Someone special in your life" },
  { value: "date", label: "My Date", emoji: "🌹", desc: "Someone you're getting to know" },
  { value: "myself", label: "Myself", emoji: "✨", desc: "A little self-love treat" },
  { value: "both", label: "Both of Us", emoji: "💑", desc: "Gifts for the couple" },
];

export const DATE_TYPES = [
  { value: "first-date", label: "First Date", emoji: "🌟" },
  { value: "anniversary", label: "Anniversary", emoji: "💍" },
  { value: "casual", label: "Casual Night Out", emoji: "🎉" },
  { value: "romantic", label: "Romantic Evening", emoji: "💕" },
  { value: "adventure", label: "Adventure Date", emoji: "🚀" },
  { value: "staycation", label: "Staycation", emoji: "🏠" },
  { value: "solo", label: "Solo Date", emoji: "🧘‍♀️" },
];

// Helper to check if date type is solo
export const isSoloDate = (dateType: string) => dateType === "solo";

export const OCCASIONS = [
  { value: "none", label: "Just Because", emoji: "✨" },
  { value: "birthday", label: "Birthday", emoji: "🎂" },
  { value: "promotion", label: "Celebration", emoji: "🎊" },
  { value: "apology", label: "Making Amends", emoji: "💝" },
  { value: "proposal", label: "Special Question", emoji: "💎" },
  { value: "reunion", label: "Reunion", emoji: "🤗" },
];

export const ENERGY_LEVELS = [
  { value: "chill", label: "Chill & Relaxed", emoji: "🧘", desc: "Low-key, cozy vibes" },
  { value: "moderate", label: "Balanced", emoji: "☕", desc: "Mix of activity and rest" },
  { value: "active", label: "Active & Fun", emoji: "🎮", desc: "Games, walking, exploring" },
  { value: "high-energy", label: "High Energy", emoji: "⚡", desc: "Dancing, sports, adventure" },
];

export const ACTIVITIES = [
  { value: "dining", label: "Fine Dining", emoji: "🍽️" },
  { value: "movies", label: "Movies/Shows", emoji: "🎬" },
  { value: "outdoors", label: "Outdoors", emoji: "🌳" },
  { value: "arts", label: "Arts & Culture", emoji: "🎨" },
  { value: "music", label: "Live Music", emoji: "🎵" },
  { value: "games", label: "Games/Sports", emoji: "🎯" },
  { value: "spa", label: "Spa/Wellness", emoji: "💆" },
  { value: "shopping", label: "Shopping", emoji: "🛍️" },
];

export const TIME_OF_DAY = [
  { value: "morning", label: "Morning", emoji: "🌅", time: "8am - 12pm" },
  { value: "afternoon", label: "Afternoon", emoji: "☀️", time: "12pm - 5pm" },
  { value: "evening", label: "Evening", emoji: "🌆", time: "5pm - 9pm" },
  { value: "night", label: "Late Night", emoji: "🌙", time: "9pm+" },
];

export const DURATIONS = [
  { value: "quick", label: "Quick Date", time: "2-3 hours" },
  { value: "half-day", label: "Half Day", time: "4-6 hours" },
  { value: "full-day", label: "Full Day", time: "8+ hours" },
  { value: "overnight", label: "Overnight", time: "24+ hours" },
];

export const CUISINES = [
  { value: "italian", label: "Italian", emoji: "🍝" },
  { value: "japanese", label: "Japanese", emoji: "🍣" },
  { value: "mexican", label: "Mexican", emoji: "🌮" },
  { value: "french", label: "French", emoji: "🥐" },
  { value: "indian", label: "Indian", emoji: "🍛" },
  { value: "thai", label: "Thai", emoji: "🍜" },
  { value: "american", label: "American", emoji: "🍔" },
  { value: "mediterranean", label: "Mediterranean", emoji: "🥙" },
  { value: "korean", label: "Korean", emoji: "🍖" },
  { value: "chinese", label: "Chinese", emoji: "🥡" },
];

export const DIETARY_RESTRICTIONS = [
  { value: "vegetarian", label: "Vegetarian", emoji: "🥬" },
  { value: "vegan", label: "Vegan", emoji: "🌱" },
  { value: "gluten-free", label: "Gluten-Free", emoji: "🌾" },
  { value: "dairy-free", label: "Dairy-Free", emoji: "🥛" },
  { value: "halal", label: "Halal", emoji: "🍖" },
  { value: "kosher", label: "Kosher", emoji: "✡️" },
  { value: "keto", label: "Keto", emoji: "🥑" },
  { value: "none", label: "No Restrictions", emoji: "✅" },
];

export const DRINK_PREFERENCES = [
  { value: "cocktails", label: "Cocktails", emoji: "🍸" },
  { value: "wine", label: "Wine", emoji: "🍷" },
  { value: "beer", label: "Beer", emoji: "🍺" },
  { value: "spirits", label: "Whiskey/Spirits", emoji: "🥃" },
  { value: "champagne", label: "Champagne/Bubbles", emoji: "🥂" },
  { value: "sake", label: "Sake", emoji: "🍶" },
  { value: "mocktails", label: "Mocktails", emoji: "🍹" },
  { value: "coffee", label: "Coffee/Tea", emoji: "☕" },
  { value: "smoothies", label: "Smoothies/Juices", emoji: "🥤" },
  { value: "non-alcoholic", label: "No Alcohol", emoji: "🚫" },
];

export const BUDGET_RANGES = [
  { value: "budget", label: "$", desc: "Under $50", range: "$0-50" },
  { value: "moderate", label: "$$", desc: "$50-150", range: "$50-150" },
  { value: "upscale", label: "$$$", desc: "$150-300", range: "$150-300" },
  { value: "luxury", label: "$$$$", desc: "$300+", range: "$300+" },
];

export const COMMON_ALLERGIES = [
  { value: "peanuts", label: "Peanuts", emoji: "🥜" },
  { value: "tree-nuts", label: "Tree Nuts", emoji: "🌰" },
  { value: "shellfish", label: "Shellfish", emoji: "🦐" },
  { value: "fish", label: "Fish", emoji: "🐟" },
  { value: "eggs", label: "Eggs", emoji: "🥚" },
  { value: "soy", label: "Soy", emoji: "🫘" },
  { value: "wheat", label: "Wheat", emoji: "🌾" },
  { value: "none", label: "No Allergies", emoji: "✅" },
];

export const HARD_NOS = [
  { value: "loud-venues", label: "Loud Venues", emoji: "🔊" },
  { value: "crowds", label: "Crowded Places", emoji: "👥" },
  { value: "heights", label: "Heights", emoji: "🏔️" },
  { value: "water", label: "Water Activities", emoji: "🌊" },
  { value: "spicy-food", label: "Spicy Food", emoji: "🌶️" },
  { value: "dark-venues", label: "Dark Venues", emoji: "🌑" },
  { value: "physical", label: "Physical Activity", emoji: "🏃" },
  { value: "late-night", label: "Late Nights", emoji: "🌙" },
];

export const ACCESSIBILITY_OPTIONS = [
  { value: "wheelchair", label: "Wheelchair Access", emoji: "♿", desc: "Ramps, elevators, accessible entrances" },
  { value: "mobility-aid", label: "Mobility Aid Friendly", emoji: "🦯", desc: "Space for walkers, canes, scooters" },
  { value: "limited-walking", label: "Limited Walking", emoji: "🚶", desc: "Minimize distances between venues" },
  { value: "seating", label: "Frequent Seating", emoji: "🪑", desc: "Rest stops and seating available" },
  { value: "quiet-environment", label: "Quiet Environment", emoji: "🤫", desc: "Low noise, sensory-friendly spaces" },
  { value: "low-light", label: "Sensory-Friendly Lighting", emoji: "💡", desc: "Avoid bright/flashing lights" },
  { value: "service-animal", label: "Service Animal", emoji: "🐕‍🦺", desc: "Service animal accommodations" },
  { value: "asl-friendly", label: "ASL/Deaf-Friendly", emoji: "🤟", desc: "Visual menus, good lighting for signing" },
  { value: "none", label: "No Specific Needs", emoji: "✅", desc: "No accessibility accommodations needed" },
];

export const SMOKING_PREFERENCES = [
  { value: "smoke-free", label: "100% Smoke-Free", emoji: "🌿", desc: "No smoking of any kind nearby" },
  { value: "outdoor-ok", label: "Outdoor Patios OK", emoji: "🌤️", desc: "Outdoor areas with smoking are fine" },
  { value: "flexible", label: "Flexible", emoji: "👌", desc: "No strong preference" },
];

export const SMOKING_ACTIVITIES = [
  { value: "hookah", label: "Hookah/Shisha", emoji: "💨", desc: "Hookah lounge or bar with shisha" },
  { value: "cigar", label: "Cigar Lounge", emoji: "🪵", desc: "Upscale cigar bar or lounge" },
  { value: "cannabis", label: "Cannabis-Friendly", emoji: "🌿", desc: "420-friendly venues or lounges" },
  { value: "vape", label: "Vape-Friendly", emoji: "💭", desc: "Venues that allow vaping" },
  { value: "pipe", label: "Pipe/Tobacco Bar", emoji: "🎩", desc: "Classic tobacco pipe experience" },
  { value: "none", label: "None of These", emoji: "🚭", desc: "Not interested in any smoking activities" },
];

export const TRANSPORTATION_MODES = [
  { value: "walking", label: "Walking", emoji: "🚶", desc: "Keep it close, no car needed" },
  { value: "rideshare", label: "Rideshare/Taxi", emoji: "🚕", desc: "Uber, Lyft, or taxi" },
  { value: "driving", label: "Personal Car", emoji: "🚗", desc: "We'll drive ourselves" },
  { value: "public-transit", label: "Public Transit", emoji: "🚇", desc: "Subway, bus, or train" },
  { value: "biking", label: "Biking", emoji: "🚴", desc: "Cycle between spots" },
];

export const TRAVEL_RADIUS = [
  { value: "walkable", label: "Walkable", distance: "< 1 mile", emoji: "👣", desc: "Everything within walking distance" },
  { value: "neighborhood", label: "Neighborhood", distance: "1-5 miles", emoji: "🏘️", desc: "Stay in one area" },
  { value: "city-wide", label: "City-wide", distance: "5-15 miles", emoji: "🌆", desc: "Explore different neighborhoods" },
  { value: "metro", label: "Metro Area", distance: "15-30 miles", emoji: "🚗", desc: "Greater metro region" },
  { value: "regional", label: "Regional", distance: "30-50 miles", emoji: "🗺️", desc: "Day trip adventure" },
  { value: "road-trip", label: "Road Trip", distance: "50+ miles", emoji: "🛣️", desc: "Go the distance" },
];

export const RELATIONSHIP_STAGES = [
  { value: "new", label: "New Relationship", emoji: "🌱", desc: "Still getting to know each other" },
  { value: "dating", label: "Dating (1-2 years)", emoji: "💑", desc: "Building something special" },
  { value: "established", label: "Established (3+ years)", emoji: "💍", desc: "Deep connection" },
  { value: "rekindling", label: "Rekindling", emoji: "🔥", desc: "Reigniting the spark" },
  { value: "long-distance", label: "Long Distance", emoji: "✈️", desc: "Making moments count" },
];

export const PARTNER_INTERESTS = [
  { value: "tech", label: "Technology", emoji: "💻" },
  { value: "fashion", label: "Fashion", emoji: "👗" },
  { value: "sports", label: "Sports", emoji: "⚽" },
  { value: "books", label: "Books/Reading", emoji: "📚" },
  { value: "music", label: "Music", emoji: "🎵" },
  { value: "art", label: "Art & Design", emoji: "🎨" },
  { value: "cooking", label: "Cooking/Food", emoji: "👨‍🍳" },
  { value: "travel", label: "Travel", emoji: "✈️" },
  { value: "fitness", label: "Fitness/Wellness", emoji: "💪" },
  { value: "gaming", label: "Gaming", emoji: "🎮" },
  { value: "nature", label: "Nature/Outdoors", emoji: "🌿" },
  { value: "movies", label: "Movies/TV", emoji: "🎬" },
];

export const GIFT_BUDGETS = [
  { value: "thoughtful", label: "$", desc: "Under $50", range: "$0-50" },
  { value: "moderate", label: "$$", desc: "$50-150", range: "$50-150" },
  { value: "special", label: "$$$", desc: "$150-300", range: "$150-300" },
  { value: "luxury", label: "$$$$", desc: "$300+", range: "$300+" },
];

export const GIFT_STYLES = [
  { value: "minimal", label: "Minimal", emoji: "⬜" },
  { value: "luxury", label: "Luxury", emoji: "✨" },
  { value: "quirky", label: "Quirky", emoji: "🎭" },
  { value: "practical", label: "Practical", emoji: "🛠️" },
  { value: "sentimental", label: "Sentimental", emoji: "💝" },
  { value: "experiential", label: "Experiential", emoji: "🎟️" },
];

export const CONVERSATION_TOPICS = [
  { value: "dreams", label: "Dreams & Goals", emoji: "⭐", desc: "Future aspirations" },
  { value: "memories", label: "Memories", emoji: "📸", desc: "Sharing the past" },
  { value: "values", label: "Values & Beliefs", emoji: "💭", desc: "What matters most" },
  { value: "fun", label: "Fun & Playful", emoji: "😄", desc: "Light-hearted topics" },
  { value: "deep", label: "Deep Connection", emoji: "💞", desc: "Intimate questions" },
  { value: "adventure", label: "Adventures", emoji: "🗺️", desc: "Bucket list items" },
];
