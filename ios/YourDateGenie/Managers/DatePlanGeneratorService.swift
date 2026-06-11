import Foundation
import Combine

// MARK: - Date Plan Generator Service

/// Service responsible for generating date plans using OpenAI GPT
class DatePlanGeneratorService: ObservableObject {
    static let shared = DatePlanGeneratorService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var currentStatusMessage = "Starting..."
    @Published var generatedPlans: [DatePlan] = []
    @Published var loadingPlanIndices: Set<Int> = []
    @Published var error: GenerationError?
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer that simulates progress from 20% toward 85% while the API call runs, so the UI never appears stuck.
    private var progressSimulationTimer: Timer?
    
    enum GenerationError: Error, LocalizedError, Equatable {
        case missingAPIKey
        case networkError(String)
        case apiError(String)
        case parsingError(String)
        case invalidResponse
        case timeout
        case unauthorized
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Supabase is not configured. Please check your setup."
            case .networkError(let msg): return "Network error: \(msg)"
            case .apiError(let msg): return "Error: \(msg)"
            case .parsingError(let msg): return "Parsing error: \(msg)"
            case .invalidResponse: return "Invalid response from AI"
            case .timeout: return "Request timed out. Please try again."
            case .unauthorized: return "Please sign in to generate date plans."
            case .rateLimited: return "Too many requests. Please wait a moment and try again."
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .missingAPIKey:
                return "Check that SUPABASE_URL and SUPABASE_ANON_KEY are set in Secrets.xcconfig."
            case .networkError:
                return "Please check your internet connection and try again."
            case .apiError(let msg):
                if msg.contains("429") {
                    return "Rate limit reached. Please wait a moment and try again."
                }
                return "Please try again later."
            case .timeout:
                return "The request took too long. Please try again."
            case .rateLimited:
                return "Please wait a minute before generating another plan."
            default:
                return "Please try again."
            }
        }
    }
    
    private init() {}
    
    // MARK: - Generate Date Plan
    
    /// Generate a date plan from two partners' questionnaire data (merged and balanced). Use when both have filled in Partner Planning flow.
    func generateDatePlan(partnerA: QuestionnaireData, partnerB: QuestionnaireData) async throws -> [DatePlan] {
        let merged = PartnerSessionManager.merge(partnerA, partnerB)
        return try await generateDatePlan(from: merged)
    }
    
    /// Generate a personalized date plan using OpenAI GPT. Starting point (user-provided address) is required.
    func generateDatePlan(from questionnaire: QuestionnaireData) async throws -> [DatePlan] {
        let startingAddress = questionnaire.startingAddress.trimmingCharacters(in: .whitespaces)
        guard !startingAddress.isEmpty else {
            throw GenerationError.apiError("Starting address is required for your route and map. Please enter where you're leaving from.")
        }
        
        await MainActor.run {
            isGenerating = true
            generationProgress = 0
            currentStatusMessage = "Crafting your perfect evening..."
            error = nil
            loadingPlanIndices = []
            stopProgressSimulation()
        }
        
        do {
            await updateProgress(0.1, message: "Consulting the stars...")
            await updateProgress(0.2, message: "Finding hidden gems...")

            await MainActor.run { startProgressSimulation() }

            // All generation, venue verification, and directions enrichment happen server-side.
            let plans = try await callEdgeFunction(preferences: questionnaire)

            await MainActor.run { stopProgressSimulation() }
            await updateProgress(1.0, message: "Your magical evening awaits!")

            await MainActor.run {
                self.generatedPlans = plans
                self.isGenerating = false
                self.loadingPlanIndices = []
            }
            return plans
            
        } catch {
            await MainActor.run {
                stopProgressSimulation()
                self.generationProgress = 0
                self.error = error as? GenerationError ?? .networkError(error.localizedDescription)
                self.isGenerating = false
            }
            throw error
        }
    }
    
    // MARK: - Edge Function Call

    /// Calls the generate-date-plan Edge Function and parses the returned datePlans array.
    private func callEdgeFunction(preferences: QuestionnaireData) async throws -> [DatePlan] {
        guard Config.isSupabaseConfigured else {
            throw GenerationError.missingAPIKey
        }
        do {
            let data = try await SupabaseService.shared.generateDatePlanEdge(preferences: preferences)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let plansArray = json["datePlans"] as? [[String: Any]], !plansArray.isEmpty else {
                throw GenerationError.invalidResponse
            }
            return try plansArray.map { try parseDatePlan(from: $0) }
        } catch let supabaseError as SupabaseError {
            switch supabaseError {
            case .unauthorized: throw GenerationError.unauthorized
            case .authFailed(let msg):
                if msg.lowercased().contains("rate") { throw GenerationError.rateLimited }
                throw GenerationError.apiError(msg)
            default: throw GenerationError.networkError(supabaseError.localizedDescription)
            }
        }
    }

    // MARK: - Legacy Prompt Builder (kept for reference — no longer used at runtime)

    /// Currency for the user's region/VPN so costs display in local currency.
    private static var deviceCurrencyInstruction: String {
        let region = Locale.current.region?.identifier ?? ""
        let code = Locale.current.currency?.identifier ?? "USD"
        let symbol: String = {
            switch code {
            case "INR": return "₹"
            case "GBP": return "£"
            case "EUR": return "€"
            case "AUD": return "A$"
            case "CAD": return "C$"
            case "JPY", "CNY": return "¥"
            case "SGD": return "S$"
            case "AED", "SAR": return code
            default: return "$"
            }
        }()
        return """
        CURRENCY (IMPORTANT): The user's device region is \(region); use \(code) for all costs. Format estimatedCost, estimatedCostPerPerson, and gift priceRange using "\(symbol)" and local amounts (e.g. \(symbol)50-100, \(symbol)1,500-2,000). Do NOT use $ unless the user is in the US.
        """
    }
    
    private func buildPrompt(from data: QuestionnaireData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        let scheduledDateStr = data.dateScheduled.map { dateFormatter.string(from: $0) } ?? "Flexible"
        let optionThemes = buildOptionThemes(from: data)
        
        var allergyWarning = ""
        if !data.allergies.isEmpty {
            allergyWarning = "\n\n⚠️ CRITICAL FOOD ALLERGIES - LIFE-THREATENING ⚠️\nThe user has the following allergies: \(data.allergies.joined(separator: ", "))\nEVERY restaurant/food venue MUST be able to accommodate these allergies.\nIn the \"whyItFits\" field, you MUST explicitly state how the venue handles these allergies.\nDO NOT recommend any venue that cannot guarantee allergy-safe food preparation.\n"
        }
        
        var dietaryWarning = ""
        if !data.dietaryRestrictions.isEmpty {
            dietaryWarning = "\n\n🥗 DIETARY RESTRICTIONS - MANDATORY\nThe user follows these dietary restrictions: \(data.dietaryRestrictions.joined(separator: ", "))\nEVERY food venue MUST have menu options that comply with ALL of these restrictions.\nIn the \"whyItFits\" field, mention specific dishes or menu sections that work.\n"
        }
        
        var accessibilityWarning = ""
        if !data.accessibilityNeeds.isEmpty {
            accessibilityWarning = "\n\n♿ ACCESSIBILITY REQUIREMENTS - MANDATORY\nThe user has these accessibility needs: \(data.accessibilityNeeds.joined(separator: ", "))\nEVERY venue MUST be fully accessible and accommodate these needs.\nIn the \"whyItFits\" field, confirm the venue's accessibility features.\n"
        }
        
        var hardNosWarning = ""
        if !data.hardNos.isEmpty {
            hardNosWarning = "\n\n🚫 HARD NO'S - ABSOLUTE DEAL BREAKERS\nThe user has specified these as absolute deal breakers: \(data.hardNos.joined(separator: ", "))\nDO NOT include ANY venue or activity that involves these items.\n"
        }
        
        let giftSuggestionsJson: String
        if data.wantGiftSuggestions {
            giftSuggestionsJson = "[{\"name\": \"Specific Product Name\", \"description\": \"Why this gift is meaningful given their interests: \(data.partnerInterests.joined(separator: ", "))\", \"priceRange\": \"Within \(data.giftBudget.isEmpty ? "$30-60" : data.giftBudget)\", \"whereToBuy\": \"Amazon or specific store name\", \"whyItFits\": \"Connection to their interests or the date theme\", \"emoji\": \"🎁\"}]"
        } else {
            giftSuggestionsJson = "null"
        }
        
        let conversationStartersJson: String
        if data.wantConversationStarters {
            conversationStartersJson = "[{\"question\": \"Thoughtful question appropriate for \(data.relationshipStage.isEmpty ? "their relationship" : data.relationshipStage) stage, related to: \(data.conversationTopics.isEmpty ? "getting to know each other" : data.conversationTopics.joined(separator: ", "))\", \"category\": \"Dreams/Connection/Fun/Deep\", \"emoji\": \"💭\"}]"
        } else {
            conversationStartersJson = "null"
        }
        
        return """
        You are a romantic date planning expert. Create 3 UNIQUE, personalized date plans based on ALL of these preferences.
        
        CRITICAL: Make every generation feel fresh and one-of-a-kind:
        - Vary the 3 options strongly: different neighborhoods, cuisines, venue types, and vibes (e.g. one elegant, one playful, one adventurous).
        - Do NOT reuse the same title formulas. Invent creative, memorable titles every time.
        - Titles must be distinctive and evocative—never generic (avoid "Romantic Evening", "A Night to Remember", "Perfect Date"). Instead use: whimsical wordplay, location-inspired names, activity-driven phrases, or mood-based one-liners (e.g. "Under the Neon & Noodles", "Secret Garden Hour", "Midnight Bites & Bright Lights", "Two Hours in the Village").
        - Each plan's title and tagline should capture that option's specific vibe so the user can tell the three apart at a glance.

        ════════════════════════════════════════════════════════════════
        STEP 1: LOCATION & CONTEXT (Use this to select the area)
        ════════════════════════════════════════════════════════════════
        • City: \(data.city)
        • Preferred Neighborhood: \(data.neighborhood.isEmpty ? "Any area in the city" : data.neighborhood)
        • Starting Point Address: \(data.startingAddress.isEmpty ? "Not specified - start from city center" : data.startingAddress)
        • Type of Date: \(data.dateType) ← Match the overall vibe to this
        • Special Occasion: \(data.occasion.isEmpty ? "Just because - casual date" : data.occasion)
        • Scheduled Date: \(scheduledDateStr) ← Consider weather/season
        • Preferred Start Time: \(data.startTime.isEmpty ? "Evening" : data.startTime)

        ════════════════════════════════════════════════════════════════
        STEP 2: TRANSPORTATION & LOGISTICS (Plan routes accordingly)
        ════════════════════════════════════════════════════════════════
        • Transportation Mode: \(data.transportationMode) ← Only suggest venues reachable this way
        • Maximum Travel Radius: \(data.travelRadius) ← Do NOT exceed this distance between stops

        ════════════════════════════════════════════════════════════════
        STEP 3: VIBE & ENERGY LEVEL (Match the pace and atmosphere)
        ════════════════════════════════════════════════════════════════
        • Energy Level: \(data.energyLevel) ← This determines how active the date should be
        • Desired Activities: \(data.activityPreferences.isEmpty ? "Open to suggestions" : data.activityPreferences.joined(separator: ", "))
        • Time of Day: \(data.timeOfDay)
        • Total Duration: \(data.duration) ← Plan must fit within this timeframe. Aim for 3 stops when duration allows; otherwise use at least 2 stops (starting address does not count as a stop).

        ════════════════════════════════════════════════════════════════
        STEP 4: FOOD & DRINKS (Select restaurants matching ALL of these)
        ════════════════════════════════════════════════════════════════
        • Preferred Cuisines: \(data.cuisinePreferences.isEmpty ? "Open to all cuisines" : data.cuisinePreferences.joined(separator: ", "))
        • Dietary Restrictions: \(data.dietaryRestrictions.isEmpty ? "None" : data.dietaryRestrictions.joined(separator: ", "))
        • Drink Preferences: \(data.drinkPreferences.isEmpty ? "Any" : data.drinkPreferences.joined(separator: ", "))
        • Budget Per Person: \(data.budgetRange) ← Total date cost must stay within this
        • \(Self.deviceCurrencyInstruction)
        \(dietaryWarning)
        ════════════════════════════════════════════════════════════════
        STEP 5: DEAL BREAKERS - MUST BE STRICTLY FOLLOWED
        ════════════════════════════════════════════════════════════════
        • FOOD ALLERGIES: \(data.allergies.isEmpty ? "None reported" : data.allergies.joined(separator: ", "))
        • HARD NO'S (Absolute Avoids): \(data.hardNos.isEmpty ? "None" : data.hardNos.joined(separator: ", "))
        • ACCESSIBILITY NEEDS: \(data.accessibilityNeeds.isEmpty ? "None" : data.accessibilityNeeds.joined(separator: ", "))
        • SMOKING PREFERENCE: \(data.smokingPreference.isEmpty ? "Non-smoking venues only" : data.smokingPreference)
        • ADDITIONAL NOTES FROM USER: \(data.additionalNotes.isEmpty ? "None" : data.additionalNotes)
        \(allergyWarning)\(accessibilityWarning)\(hardNosWarning)
        ════════════════════════════════════════════════════════════════
        STEP 6: RELATIONSHIP ENHANCERS (Personalize the experience)
        ════════════════════════════════════════════════════════════════
        • Relationship Stage: \(data.relationshipStage.isEmpty ? "Not specified" : data.relationshipStage) ← Tailor intimacy level
        • Partner's Interests/Hobbies: \(data.partnerInterests.isEmpty ? "Not specified" : data.partnerInterests.joined(separator: ", "))
        • Include Gift Suggestions: \(data.wantGiftSuggestions ? "YES - Include 2-3 gift ideas" : "NO")
        • Gift Recipient: \(data.giftRecipient.isEmpty ? "Partner" : data.giftRecipient)
        • Gift Budget: \(data.giftBudget.isEmpty ? "Moderate ($30-60)" : data.giftBudget)
        • Include Conversation Starters: \(data.wantConversationStarters ? "YES - Include 2-3 questions" : "NO")
        • Conversation Topics They Enjoy: \(data.conversationTopics.isEmpty ? "General/varied" : data.conversationTopics.joined(separator: ", "))

        ════════════════════════════════════════════════════════════════
        HOW TO CREATE THE 3 DIFFERENT OPTIONS
        ════════════════════════════════════════════════════════════════
        \(optionThemes)
        
        UNIQUENESS: For each run, imagine you are creating plans that have never been generated before. Vary neighborhoods within the city, pick different restaurant styles (e.g. intimate vs lively, classic vs trendy), and give each option a clearly different feel. Titles and taglines should be creative and specific—not interchangeable between options.

        ════════════════════════════════════════════════════════════════
        MANDATORY REQUIREMENTS FOR ALL 3 PLANS
        ════════════════════════════════════════════════════════════════
        
        ✓ GLOBAL ADDRESSES: The plan is for the user's city: \(data.city). Every venue MUST be in that city/country only—e.g. if the city is Chennai, India, do NOT suggest venues in Spain, the USA, or any other country. Suggest only real, currently operating businesses in or near \(data.city).
        ✓ Every address MUST be real and verifiable on Google Maps
        ✓ Every restaurant MUST accommodate: \(data.dietaryRestrictions.isEmpty ? "no specific restrictions" : data.dietaryRestrictions.joined(separator: ", "))
        ✓ Every restaurant MUST be safe for allergies: \(data.allergies.isEmpty ? "no allergies" : data.allergies.joined(separator: ", "))
        ✓ Every venue MUST be accessible for: \(data.accessibilityNeeds.isEmpty ? "standard access" : data.accessibilityNeeds.joined(separator: ", "))
        ✓ Total cost MUST stay within: \(data.budgetRange) per person
        ✓ All venues MUST be reachable via: \(data.transportationMode)
        ✓ All venues MUST be within: \(data.travelRadius) of each other
        ✓ The date MUST fit within: \(data.duration)
        ✓ NEVER include anything from the Hard No's list
        ✓ Match the energy level: \(data.energyLevel)
        ✓ Each plan MUST have 3 stops (venues/activities) when the requested duration allows; otherwise at least 2 stops. The starting address from the questionnaire is NOT a stop—count only the itinerary venues (e.g. restaurant, bar, activity).

        ════════════════════════════════════════════════════════════════
        JSON RESPONSE FORMAT
        ════════════════════════════════════════════════════════════════
        
        Return ONLY a valid JSON object with this exact structure:
        {
            "plans": [
                {
                    "optionLabel": "Option A",
                    "title": "Invent a short, creative title (e.g. whimsical, location-based, or mood-driven—never generic like 'Romantic Evening')",
                    "tagline": "One evocative line that captures this option's specific vibe so it feels distinct from B and C",
                    "totalDuration": "X-Y hours",
                    "estimatedCost": "$XXX-YYY per person",
                    "stops": [
                        {
                            "order": 1,
                            "name": "Real Venue Name",
                            "venueType": "Restaurant/Bar/Activity Type",
                            "timeSlot": "X:XX PM",
                            "duration": "X hour(s)",
                            "description": "What you'll experience here and why it's special",
                            "whyItFits": "MUST mention: 1) How it matches their preferences, 2) How it handles dietary restrictions/allergies if food venue, 3) Accessibility confirmation if needed",
                            "romanticTip": "Specific insider tip to enhance the experience",
                            "emoji": "🍷",
                            "address": "123 Street Name, City, State ZIP",
                            "travelTimeFromPrevious": "X mins walking/driving",
                            "estimatedCostPerPerson": "$XX-YY/person"
                        }
                    ],
                    "genieSecretTouch": {
                        "title": "Special Romantic Gesture",
                        "description": "A unique way to make this date memorable, tailored to their relationship stage and partner interests",
                        "emoji": "💐"
                    },
                    "packingList": ["Weather-appropriate item", "Activity-specific item", "Romantic touch item", "Practical item"],
                    "weatherNote": "Specific weather advice for \(scheduledDateStr) in \(data.city)",
                    "giftSuggestions": \(giftSuggestionsJson),
                    "conversationStarters": \(conversationStartersJson)
                }
            ]
        }

        Generate exactly 3 complete plans. Each MUST fully respect ALL preferences listed above. Each plan must have 3 stops when the user's duration allows, or at least 2 stops (starting address is not a stop).
        """
    }
    
    private func buildOptionThemes(from data: QuestionnaireData) -> String {
        let activities = data.activityPreferences
        let cuisines = data.cuisinePreferences
        let energyLevel = data.energyLevel
        let dateType = data.dateType
        let partnerInterests = data.partnerInterests
        
        var optionA = "OPTION A - "
        var optionB = "OPTION B - "
        var optionC = "OPTION C - "
        
        if activities.count >= 2 {
            optionA += "Lead with '\(activities[0])'"
            optionB += "Lead with '\(activities[1])'"
            if activities.count >= 3 {
                optionC += "Blend '\(activities[0])' + '\(activities[1])' + '\(activities[2])'"
            } else {
                optionC += "Equal mix of '\(activities[0])' and '\(activities[1])'"
            }
        } else if let mainActivity = activities.first {
            optionA += "Classic \(mainActivity) at an upscale venue"
            optionB += "Hidden gem \(mainActivity) experience"
            optionC += "Casual/trendy \(mainActivity) vibe"
        } else {
            optionA += "Classic romantic dinner date"
            optionB += "Activity-focused with dinner"
            optionC += "Relaxed, intimate evening"
        }
        
        if cuisines.count >= 2 {
            optionA += " + \(cuisines[0]) cuisine"
            optionB += " + \(cuisines[1]) cuisine"
            optionC += " + mixed/fusion cuisines"
        } else if let mainCuisine = cuisines.first {
            optionA += " with fine \(mainCuisine) dining"
            optionB += " with cozy \(mainCuisine) spot"
            optionC += " with casual \(mainCuisine) eatery"
        }
        
        if !partnerInterests.isEmpty {
            optionA += ". Incorporate their love of \(partnerInterests.first ?? "")."
            if partnerInterests.count > 1 {
                optionB += ". Feature their interest in \(partnerInterests[1])."
            }
            optionC += ". Weave in multiple interests: \(partnerInterests.prefix(3).joined(separator: ", "))."
        }
        
        switch energyLevel.lowercased() {
        case "chill", "relaxed":
            optionA += " | Pace: Leisurely, intimate."
            optionB += " | Pace: Slow exploration."
            optionC += " | Pace: Very relaxed, connection-focused."
        case "active", "high-energy":
            optionA += " | Pace: High-energy, multiple activities."
            optionB += " | Pace: Adventure-filled."
            optionC += " | Pace: Dynamic with strategic breaks."
        case "moderate", "balanced":
            optionA += " | Pace: Balanced activity and relaxation."
            optionB += " | Pace: Moderate with spontaneous moments."
            optionC += " | Pace: Flexible, mood-based."
        default:
            optionA += " | Pace: Well-rounded."
            optionB += " | Pace: Moderate."
            optionC += " | Pace: Adaptive."
        }
        
        switch dateType.lowercased() {
        case "first-date":
            optionA += " Great first impression, classic choices."
            optionB += " Unique venues that spark conversation."
            optionC += " Low-pressure, easy-going atmosphere."
        case "anniversary":
            optionA += " Celebratory and luxurious."
            optionB += " Nostalgic with fresh elements."
            optionC += " Deeply intimate and personal."
        case "romantic":
            optionA += " All the romantic touches."
            optionB += " Unexpected romantic moments."
            optionC += " Quiet, cozy romance."
        case "adventure":
            optionA += " Bold, exciting experiences."
            optionB += " Discovery and exploration."
            optionC += " Adventure with comfort elements."
        case "casual":
            optionA += " Relaxed but thoughtful."
            optionB += " Fun, low-key vibes."
            optionC += " Easygoing and comfortable."
        default:
            optionA += " Classic date experience."
            optionB += " Something memorable."
            optionC += " Comfortable and enjoyable."
        }
        
        return """
        \(optionA)
        
        \(optionB)
        
        \(optionC)
        
        ALL 3 OPTIONS MUST:
        - Use the same dietary restrictions: \(data.dietaryRestrictions.isEmpty ? "None" : data.dietaryRestrictions.joined(separator: ", "))
        - Avoid ALL allergies: \(data.allergies.isEmpty ? "None" : data.allergies.joined(separator: ", "))
        - Meet accessibility needs: \(data.accessibilityNeeds.isEmpty ? "Standard" : data.accessibilityNeeds.joined(separator: ", "))
        - Stay within budget: \(data.budgetRange)
        - Never include Hard No's: \(data.hardNos.isEmpty ? "None" : data.hardNos.joined(separator: ", "))
        - Match transportation mode: \(data.transportationMode)
        - Stay within travel radius: \(data.travelRadius)
        """
    }
    
    // MARK: - Parse Response
    
    private func parseResponse(_ response: String) throws -> [DatePlan] {
        guard !response.isEmpty else {
            throw GenerationError.parsingError("Empty response received")
        }

        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonStart = jsonString.firstIndex(of: "{"),
           let jsonEnd = jsonString.lastIndex(of: "}") {
            guard jsonStart <= jsonEnd else {
                throw GenerationError.parsingError("Invalid JSON structure in response")
            }
            jsonString = String(jsonString[jsonStart...jsonEnd])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GenerationError.parsingError("Could not convert response to data")
        }

        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              // Accept both "plans" (legacy) and "datePlans" (Edge Function response)
              let plansArray = (json["plans"] ?? json["datePlans"]) as? [[String: Any]] else {
            throw GenerationError.parsingError("Invalid JSON structure")
        }

        return try plansArray.map { try parseDatePlan(from: $0) }
    }
    
    private func parseDatePlan(from json: [String: Any]) throws -> DatePlan {
        guard let title = json["title"] as? String,
              let tagline = json["tagline"] as? String,
              let totalDuration = json["totalDuration"] as? String,
              let estimatedCost = json["estimatedCost"] as? String,
              let stopsArray = json["stops"] as? [[String: Any]],
              let secretTouchJson = json["genieSecretTouch"] as? [String: Any],
              let packingList = json["packingList"] as? [String],
              let weatherNote = json["weatherNote"] as? String else {
            throw GenerationError.parsingError("Missing required fields in plan")
        }
        
        // Parse stops
        var stops: [DatePlanStop] = []
        for stopJson in stopsArray {
            let stop = try parseDatePlanStop(from: stopJson)
            stops.append(stop)
        }
        
        // Parse secret touch
        let secretTouch = GenieSecretTouch(
            title: secretTouchJson["title"] as? String ?? "",
            description: secretTouchJson["description"] as? String ?? "",
            emoji: secretTouchJson["emoji"] as? String ?? "✨"
        )
        
        // Parse gift suggestions (camelCase or snake_case from LLM)
        var giftSuggestions: [GiftSuggestion]?
        let giftsArray = (json["giftSuggestions"] ?? json["gift_suggestions"]) as? [[String: Any]]
        if let arr = giftsArray, !arr.isEmpty {
            giftSuggestions = arr.compactMap { giftJson in
                let name = giftJson["name"] as? String ?? ""
                guard !name.isEmpty else { return nil }
                return GiftSuggestion(
                    name: name,
                    description: giftJson["description"] as? String ?? "",
                    priceRange: giftJson["priceRange"] as? String ?? giftJson["price_range"] as? String ?? "",
                    whereToBuy: giftJson["whereToBuy"] as? String ?? giftJson["where_to_buy"] as? String ?? "",
                    purchaseUrl: giftJson["purchaseUrl"] as? String ?? giftJson["purchase_url"] as? String,
                    whyItFits: giftJson["whyItFits"] as? String ?? giftJson["why_it_fits"] as? String ?? "",
                    emoji: giftJson["emoji"] as? String ?? "🎁"
                )
            }
            if giftSuggestions?.isEmpty == true { giftSuggestions = nil }
        }
        
        // Parse conversation starters (camelCase or snake_case from LLM)
        var conversationStarters: [ConversationStarter]?
        let startersArray = (json["conversationStarters"] ?? json["conversation_starters"]) as? [[String: Any]]
        if let arr = startersArray, !arr.isEmpty {
            conversationStarters = arr.compactMap { starterJson in
                let question = starterJson["question"] as? String ?? ""
                guard !question.isEmpty else { return nil }
                return ConversationStarter(
                    question: question,
                    category: starterJson["category"] as? String ?? "Conversation",
                    emoji: starterJson["emoji"] as? String ?? "💭"
                )
            }
            if conversationStarters?.isEmpty == true { conversationStarters = nil }
        }
        
        return DatePlan(
            optionLabel: json["optionLabel"] as? String,
            title: title,
            tagline: tagline,
            totalDuration: totalDuration,
            estimatedCost: estimatedCost,
            stops: stops,
            genieSecretTouch: secretTouch,
            packingList: packingList,
            weatherNote: weatherNote,
            giftSuggestions: giftSuggestions,
            conversationStarters: conversationStarters
        )
    }
    
    private func parseDatePlanStop(from json: [String: Any]) throws -> DatePlanStop {
        let openingHoursArray = json["openingHours"] as? [String]
        return DatePlanStop(
            order: json["order"] as? Int ?? 1,
            name: json["name"] as? String ?? "",
            venueType: json["venueType"] as? String ?? "",
            timeSlot: json["timeSlot"] as? String ?? "",
            duration: json["duration"] as? String ?? "",
            description: json["description"] as? String ?? "",
            whyItFits: json["whyItFits"] as? String ?? "",
            romanticTip: json["romanticTip"] as? String ?? "",
            emoji: json["emoji"] as? String ?? "📍",
            travelTimeFromPrevious: json["travelTimeFromPrevious"] as? String,
            travelDistanceFromPrevious: json["travelDistanceFromPrevious"] as? String,
            travelMode: json["travelMode"] as? String,
            validated: false,
            placeId: nil,
            address: json["address"] as? String,
            latitude: nil,
            longitude: nil,
            websiteUrl: json["websiteUrl"] as? String,
            phoneNumber: json["phoneNumber"] as? String,
            openingHours: openingHoursArray,
            estimatedCostPerPerson: json["estimatedCostPerPerson"] as? String,
            bookingUrl: json["bookingUrl"] as? String,
            imageUrl: nil
        )
    }
    
    // MARK: - Progress Updates
    
    @MainActor
    private func updateProgress(_ progress: Double, message: String) {
        self.generationProgress = progress
        self.currentStatusMessage = message
    }
    
    /// Advances generationProgress from current value toward 0.85 over ~55 seconds so the loading UI never appears stuck during long API calls.
    private func startProgressSimulation() {
        stopProgressSimulation()
        let targetCap: Double = 0.85
        let steps = 110
        let increment = (targetCap - 0.2) / Double(steps)
        progressSimulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            DispatchQueue.main.async {
                if self.generationProgress < targetCap {
                    self.generationProgress = min(targetCap, self.generationProgress + increment)
                } else {
                    self.stopProgressSimulation()
                }
            }
        }
        progressSimulationTimer?.tolerance = 0.1
        RunLoop.main.add(progressSimulationTimer!, forMode: .common)
    }
    
    private func stopProgressSimulation() {
        progressSimulationTimer?.invalidate()
        progressSimulationTimer = nil
    }
}
