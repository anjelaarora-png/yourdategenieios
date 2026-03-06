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
    @Published var error: GenerationError?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum GenerationError: Error, LocalizedError, Equatable {
        case networkError(String)
        case apiError(String)
        case parsingError(String)
        case invalidResponse
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg): return "Network error: \(msg)"
            case .apiError(let msg): return "API error: \(msg)"
            case .parsingError(let msg): return "Parsing error: \(msg)"
            case .invalidResponse: return "Invalid response from AI"
            case .timeout: return "Request timed out"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Generate Date Plan
    
    /// Generate a personalized date plan using OpenAI GPT
    func generateDatePlan(from questionnaire: QuestionnaireData) async throws -> [DatePlan] {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0
            currentStatusMessage = "Crafting your perfect evening..."
            error = nil
        }
        
        do {
            await updateProgress(0.1, message: "Consulting the stars...")
            
            let prompt = buildPrompt(from: questionnaire)
            
            await updateProgress(0.2, message: "Finding hidden gems...")
            
            let response = try await callOpenAIAPI(prompt: prompt)
            
            await updateProgress(0.6, message: "Adding the magic touches...")
            
            let plans = try parseResponse(response)
            
            await updateProgress(0.8, message: "Almost ready...")
            
            // Verify venues with Google Places
            var verifiedPlans: [DatePlan] = []
            for var plan in plans {
                var verifiedStops: [DatePlanStop] = []
                for var stop in plan.stops {
                    if let verifiedStop = try? await GooglePlacesService.shared.verifyVenue(stop, city: questionnaire.city) {
                        verifiedStops.append(verifiedStop)
                    } else {
                        verifiedStops.append(stop)
                    }
                }
                plan = DatePlan(
                    optionLabel: plan.optionLabel,
                    title: plan.title,
                    tagline: plan.tagline,
                    totalDuration: plan.totalDuration,
                    estimatedCost: plan.estimatedCost,
                    stops: verifiedStops,
                    genieSecretTouch: plan.genieSecretTouch,
                    packingList: plan.packingList,
                    weatherNote: plan.weatherNote,
                    giftSuggestions: plan.giftSuggestions,
                    conversationStarters: plan.conversationStarters
                )
                verifiedPlans.append(plan)
            }
            
            await updateProgress(1.0, message: "Your magical evening awaits!")
            
            await MainActor.run {
                self.generatedPlans = verifiedPlans
                self.isGenerating = false
            }
            
            return verifiedPlans
            
        } catch {
            await MainActor.run {
                self.error = error as? GenerationError ?? .networkError(error.localizedDescription)
                self.isGenerating = false
            }
            throw error
        }
    }
    
    // MARK: - Build Prompt
    
    private func buildPrompt(from data: QuestionnaireData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        let scheduledDateStr = data.dateScheduled.map { dateFormatter.string(from: $0) } ?? "Flexible"
        let optionThemes = buildOptionThemes(from: data)
        
        let allergyWarning = data.allergies.isEmpty ? "" : """
        
        ⚠️ CRITICAL FOOD ALLERGIES - LIFE-THREATENING ⚠️
        The user has the following allergies: \(data.allergies.joined(separator: ", "))
        EVERY restaurant/food venue MUST be able to accommodate these allergies.
        In the "whyItFits" field, you MUST explicitly state how the venue handles these allergies.
        DO NOT recommend any venue that cannot guarantee allergy-safe food preparation.
        
        """
        
        let dietaryWarning = data.dietaryRestrictions.isEmpty ? "" : """
        
        🥗 DIETARY RESTRICTIONS - MANDATORY
        The user follows these dietary restrictions: \(data.dietaryRestrictions.joined(separator: ", "))
        EVERY food venue MUST have menu options that comply with ALL of these restrictions.
        In the "whyItFits" field, mention specific dishes or menu sections that work.
        
        """
        
        let accessibilityWarning = data.accessibilityNeeds.isEmpty ? "" : """
        
        ♿ ACCESSIBILITY REQUIREMENTS - MANDATORY
        The user has these accessibility needs: \(data.accessibilityNeeds.joined(separator: ", "))
        EVERY venue MUST be fully accessible and accommodate these needs.
        In the "whyItFits" field, confirm the venue's accessibility features.
        
        """
        
        let hardNosWarning = data.hardNos.isEmpty ? "" : """
        
        🚫 HARD NO'S - ABSOLUTE DEAL BREAKERS
        The user has specified these as absolute deal breakers: \(data.hardNos.joined(separator: ", "))
        DO NOT include ANY venue or activity that involves these items.
        
        """
        
        return """
        You are a romantic date planning expert. Create 3 unique, personalized date plans based on ALL of these preferences:

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
        • Total Duration: \(data.duration) ← Plan must fit within this timeframe

        ════════════════════════════════════════════════════════════════
        STEP 4: FOOD & DRINKS (Select restaurants matching ALL of these)
        ════════════════════════════════════════════════════════════════
        • Preferred Cuisines: \(data.cuisinePreferences.isEmpty ? "Open to all cuisines" : data.cuisinePreferences.joined(separator: ", "))
        • Dietary Restrictions: \(data.dietaryRestrictions.isEmpty ? "None" : data.dietaryRestrictions.joined(separator: ", "))
        • Drink Preferences: \(data.drinkPreferences.isEmpty ? "Any" : data.drinkPreferences)
        • Budget Per Person: \(data.budgetRange) ← Total date cost must stay within this
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

        ════════════════════════════════════════════════════════════════
        MANDATORY REQUIREMENTS FOR ALL 3 PLANS
        ════════════════════════════════════════════════════════════════
        
        ✓ Every venue MUST be a real, currently operating business in \(data.city)
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

        ════════════════════════════════════════════════════════════════
        JSON RESPONSE FORMAT
        ════════════════════════════════════════════════════════════════
        
        Return ONLY a valid JSON object with this exact structure:
        {
            "plans": [
                {
                    "optionLabel": "Option A",
                    "title": "Creative, descriptive title",
                    "tagline": "One-line description of the date vibe",
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
                    "giftSuggestions": \(data.wantGiftSuggestions ? """
[
                        {
                            "name": "Specific Product Name",
                            "description": "Why this gift is meaningful given their interests: \(data.partnerInterests.joined(separator: ", "))",
                            "priceRange": "Within \(data.giftBudget.isEmpty ? "$30-60" : data.giftBudget)",
                            "whereToBuy": "Amazon or specific store name",
                            "whyItFits": "Connection to their interests or the date theme",
                            "emoji": "🎁"
                        }
                    ]
""" : "null"),
                    "conversationStarters": \(data.wantConversationStarters ? """
[
                        {
                            "question": "Thoughtful question appropriate for \(data.relationshipStage.isEmpty ? "their relationship" : data.relationshipStage) stage, related to: \(data.conversationTopics.isEmpty ? "getting to know each other" : data.conversationTopics.joined(separator: ", "))",
                            "category": "Dreams/Connection/Fun/Deep",
                            "emoji": "💭"
                        }
                    ]
""" : "null")
                }
            ]
        }

        Generate exactly 3 complete plans. Each MUST fully respect ALL preferences listed above.
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
    
    // MARK: - Call OpenAI API
    
    private func callOpenAIAPI(prompt: String) async throws -> String {
        guard let url = URL(string: Config.openAIAPIEndpoint) else {
            throw GenerationError.networkError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.apiTimeout
        
        let body: [String: Any] = [
            "model": Config.openAIModel,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a romantic date planning expert. Always respond with valid JSON only, no markdown code blocks or additional text."
                ],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GenerationError.apiError("Status \(httpResponse.statusCode): \(errorBody)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GenerationError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Parse Response
    
    private func parseResponse(_ response: String) throws -> [DatePlan] {
        // Extract JSON from response (AI might include markdown code blocks)
        var jsonString = response
        
        if let jsonStart = response.range(of: "{"),
           let jsonEnd = response.range(of: "}", options: .backwards) {
            jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GenerationError.parsingError("Could not convert response to data")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let plansArray = json["plans"] as? [[String: Any]] else {
            throw GenerationError.parsingError("Invalid JSON structure")
        }
        
        var plans: [DatePlan] = []
        
        for planJson in plansArray {
            let plan = try parseDatePlan(from: planJson)
            plans.append(plan)
        }
        
        return plans
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
        
        // Parse gift suggestions
        var giftSuggestions: [GiftSuggestion]?
        if let giftsArray = json["giftSuggestions"] as? [[String: Any]] {
            giftSuggestions = giftsArray.compactMap { giftJson in
                GiftSuggestion(
                    name: giftJson["name"] as? String ?? "",
                    description: giftJson["description"] as? String ?? "",
                    priceRange: giftJson["priceRange"] as? String ?? "",
                    whereToBuy: giftJson["whereToBuy"] as? String ?? "",
                    whyItFits: giftJson["whyItFits"] as? String ?? "",
                    emoji: giftJson["emoji"] as? String ?? "🎁"
                )
            }
        }
        
        // Parse conversation starters
        var conversationStarters: [ConversationStarter]?
        if let startersArray = json["conversationStarters"] as? [[String: Any]] {
            conversationStarters = startersArray.compactMap { starterJson in
                ConversationStarter(
                    question: starterJson["question"] as? String ?? "",
                    category: starterJson["category"] as? String ?? "",
                    emoji: starterJson["emoji"] as? String ?? "💭"
                )
            }
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
            websiteUrl: nil,
            phoneNumber: nil,
            openingHours: nil,
            estimatedCostPerPerson: json["estimatedCostPerPerson"] as? String
        )
    }
    
    // MARK: - Progress Updates
    
    @MainActor
    private func updateProgress(_ progress: Double, message: String) {
        self.generationProgress = progress
        self.currentStatusMessage = message
    }
}
