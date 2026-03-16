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
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "OpenAI API key is not configured. Please add your API key in Xcode scheme environment variables."
            case .networkError(let msg): return "Network error: \(msg)"
            case .apiError(let msg): return "API error: \(msg)"
            case .parsingError(let msg): return "Parsing error: \(msg)"
            case .invalidResponse: return "Invalid response from AI"
            case .timeout: return "Request timed out. Please try again."
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .missingAPIKey:
                return "Go to Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables, then add OPENAI_API_KEY with your OpenAI API key."
            case .networkError:
                return "Please check your internet connection and try again."
            case .apiError(let msg):
                if msg.contains("401") {
                    return "Your API key may be invalid. Please verify it at platform.openai.com."
                } else if msg.contains("429") {
                    return "API rate limit reached. Please wait a moment and try again."
                }
                return "Please try again later."
            case .timeout:
                return "The request took too long. Please try again with a simpler query."
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
            
            let prompt = buildPrompt(from: questionnaire)
            
            await updateProgress(0.2, message: "Finding hidden gems...")
            
            await MainActor.run {
                startProgressSimulation()
            }
            
            let response = try await callOpenAIAPI(prompt: prompt)
            
            await MainActor.run {
                stopProgressSimulation()
            }
            await updateProgress(0.6, message: "Adding the magic touches...")
            
            let plans = try parseResponse(response)
            
            await updateProgress(0.85, message: "Almost ready...")
            
            var resultPlans: [DatePlan] = plans
            
            // Starting point from user-provided address (required). Use the user's exact input for display so "11 Lisa Ct, Colonia" appears as entered; use geocoding only for coordinates.
            let startingPoint: StartingPoint?
            if Config.isGooglePlacesConfigured,
               let startResult = try? await GooglePlacesService.shared.geocodeAddress(startingAddress) {
                startingPoint = StartingPoint(
                    name: "Your location",
                    address: startingAddress,
                    latitude: startResult.latitude,
                    longitude: startResult.longitude
                )
            } else {
                startingPoint = nil
            }
            resultPlans = resultPlans.map { plan in
                let itineraryStops = plan.stops.enumerated().map { index, stop in
                    let legMode = questionnaire.transportationMode
                    return DatePlanStop(
                        order: index + 1,
                        name: stop.name,
                        venueType: stop.venueType,
                        timeSlot: stop.timeSlot,
                        duration: stop.duration,
                        description: stop.description,
                        whyItFits: stop.whyItFits,
                        romanticTip: stop.romanticTip,
                        emoji: stop.emoji,
                        travelTimeFromPrevious: stop.travelTimeFromPrevious,
                        travelDistanceFromPrevious: stop.travelDistanceFromPrevious,
                        travelMode: legMode,
                        validated: stop.validated,
                        placeId: stop.placeId,
                        address: stop.address,
                        latitude: stop.latitude,
                        longitude: stop.longitude,
                        websiteUrl: stop.websiteUrl,
                        phoneNumber: stop.phoneNumber,
                        openingHours: stop.openingHours,
                        estimatedCostPerPerson: stop.estimatedCostPerPerson,
                        bookingUrl: stop.bookingUrl,
                        imageUrl: stop.imageUrl
                    )
                }
                return DatePlan(
                    optionLabel: plan.optionLabel,
                    title: plan.title,
                    tagline: plan.tagline,
                    totalDuration: plan.totalDuration,
                    estimatedCost: plan.estimatedCost,
                    stops: itineraryStops,
                    startingPoint: startingPoint,
                    genieSecretTouch: plan.genieSecretTouch,
                    packingList: plan.packingList,
                    weatherNote: plan.weatherNote,
                    giftSuggestions: plan.giftSuggestions,
                    conversationStarters: plan.conversationStarters
                )
            }
            
            // Verify option A only so we can show it immediately; B and C verify in background while user reviews A.
            let city = questionnaire.city
            await updateProgress(0.88, message: "Almost ready...")
            var verifiedPlan0: DatePlan = resultPlans[0]
            var verifiedStops0: [DatePlanStop] = []
            for stop in resultPlans[0].stops {
                if let verifiedStop = try? await GooglePlacesService.shared.verifyVenue(stop, city: city) {
                    verifiedStops0.append(verifiedStop)
                } else {
                    verifiedStops0.append(stop)
                }
            }
            verifiedPlan0 = DatePlan(
                optionLabel: resultPlans[0].optionLabel,
                title: resultPlans[0].title,
                tagline: resultPlans[0].tagline,
                totalDuration: resultPlans[0].totalDuration,
                estimatedCost: resultPlans[0].estimatedCost,
                stops: verifiedStops0,
                startingPoint: resultPlans[0].startingPoint,
                genieSecretTouch: resultPlans[0].genieSecretTouch,
                packingList: resultPlans[0].packingList,
                weatherNote: resultPlans[0].weatherNote,
                giftSuggestions: resultPlans[0].giftSuggestions,
                conversationStarters: resultPlans[0].conversationStarters
            )
            await updateProgress(1.0, message: "Your magical evening awaits!")
            let initialPlans: [DatePlan] = [verifiedPlan0, resultPlans[1], resultPlans[2]]
            await MainActor.run {
                self.generatedPlans = initialPlans
                self.isGenerating = false
                self.loadingPlanIndices = [1, 2]
            }
            // Verify options B and C in background; user sees option A and preview of B/C until done.
            for index in [1, 2] {
                let planToVerify = resultPlans[index]
                Task {
                    var verifiedStops: [DatePlanStop] = []
                    for stop in planToVerify.stops {
                        if let verifiedStop = try? await GooglePlacesService.shared.verifyVenue(stop, city: city) {
                            verifiedStops.append(verifiedStop)
                        } else {
                            verifiedStops.append(stop)
                        }
                    }
                    let verifiedPlan = DatePlan(
                        optionLabel: planToVerify.optionLabel,
                        title: planToVerify.title,
                        tagline: planToVerify.tagline,
                        totalDuration: planToVerify.totalDuration,
                        estimatedCost: planToVerify.estimatedCost,
                        stops: verifiedStops,
                        startingPoint: planToVerify.startingPoint,
                        genieSecretTouch: planToVerify.genieSecretTouch,
                        packingList: planToVerify.packingList,
                        weatherNote: planToVerify.weatherNote,
                        giftSuggestions: planToVerify.giftSuggestions,
                        conversationStarters: planToVerify.conversationStarters
                    )
                    await MainActor.run {
                        if index < self.generatedPlans.count {
                            var updated = self.generatedPlans
                            updated[index] = verifiedPlan
                            self.generatedPlans = updated
                        }
                        self.loadingPlanIndices.remove(index)
                    }
                }
            }
            return initialPlans
            
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
    
    // MARK: - Build Prompt
    
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
    
    // MARK: - Call OpenAI API
    
    private func callOpenAIAPI(prompt: String) async throws -> String {
        // Pre-flight validation: Check for API key before making request
        guard Config.isOpenAIConfigured else {
            throw GenerationError.missingAPIKey
        }
        
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
                    "content": "You are a romantic date planning expert. Always respond with valid JSON only, no markdown code blocks or additional text. Create distinctly different plans and creative, non-generic titles every time."
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
        // Handle empty response
        guard !response.isEmpty else {
            throw GenerationError.parsingError("Empty response received")
        }
        
        // Extract JSON from response (AI might include markdown code blocks)
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Safely extract JSON object from response
        if let jsonStart = jsonString.firstIndex(of: "{"),
           let jsonEnd = jsonString.lastIndex(of: "}") {
            // Ensure valid range (start must come before end)
            guard jsonStart <= jsonEnd else {
                throw GenerationError.parsingError("Invalid JSON structure in response")
            }
            jsonString = String(jsonString[jsonStart...jsonEnd])
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
