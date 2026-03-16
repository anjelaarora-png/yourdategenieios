import Foundation

// MARK: - DatePlan ↔ DBDatePlan conversion for cloud sync

enum DatePlanSyncHelpers {
    
    /// Convert a plan from the database into the app's DatePlan model (e.g. after fetch on login).
    static func datePlan(from db: DBDatePlan) -> DatePlan? {
        let stops = (db.itinerary ?? []).map { itineraryStopToDatePlanStop($0) }
        let secretTouch: GenieSecretTouch
        if let gstJson = db.geniesSecretTouch?.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: gstJson) as? [String: String] {
            secretTouch = GenieSecretTouch(
                title: dict["title"] ?? "",
                description: dict["description"] ?? "",
                emoji: dict["emoji"] ?? "✨"
            )
        } else {
            secretTouch = GenieSecretTouch(title: "", description: "", emoji: "✨")
        }
        return DatePlan(
            id: db.planId,
            optionLabel: db.selectedOption,
            title: db.planTitle ?? db.planTagline ?? "Date Plan",
            tagline: db.planTagline ?? "",
            totalDuration: db.totalTravelTime ?? "—",
            estimatedCost: db.budgetRange ?? db.budget?.description ?? "—",
            stops: stops,
            genieSecretTouch: secretTouch,
            packingList: db.whatToBring ?? [],
            weatherNote: db.weatherNote ?? "",
            giftSuggestions: db.giftSuggestions,
            conversationStarters: conversationStartersFromDB(db.conversationStarters),
            scheduledDate: db.scheduledAt
        )
    }
    
    /// Convert the app's DatePlan to a database model for upload.
    static func dbDatePlan(from plan: DatePlan, coupleId: UUID, status: String = "planned") -> DBDatePlan {
        let itinerary = plan.stops.map { datePlanStopToItineraryStop($0) }
        let gstString: String? = {
            let g = plan.genieSecretTouch
            guard !g.title.isEmpty || !g.description.isEmpty else { return nil }
            if let data = try? JSONEncoder().encode(["title": g.title, "description": g.description, "emoji": g.emoji]),
               let s = String(data: data, encoding: .utf8) { return s }
            return nil
        }()
        return DBDatePlan(
            planId: plan.id,
            coupleId: coupleId,
            scheduledAt: plan.scheduledDate,
            planTitle: plan.title,
            planTagline: plan.tagline,
            selectedOption: plan.optionLabel,
            planOptions: nil,
            location: nil,
            activityType: nil,
            budget: nil,
            budgetRange: plan.estimatedCost,
            outfitSuggestion: nil,
            whatToBring: plan.packingList.isEmpty ? nil : plan.packingList,
            weatherNote: plan.weatherNote,
            geniesSecretTouch: gstString,
            conversationStarters: conversationStartersToDB(plan.conversationStarters),
            giftSuggestions: plan.giftSuggestions,
            itinerary: itinerary.isEmpty ? nil : itinerary,
            totalTravelTime: plan.totalDuration,
            venueCount: plan.stops.count,
            routeMapUrl: nil,
            status: status
        )
    }
    
    // MARK: - Stop conversion
    
    private static func itineraryStopToDatePlanStop(_ s: ItineraryStop) -> DatePlanStop {
        let durationStr = s.durationMinutes <= 0 ? "" : (s.durationMinutes >= 60 ? "\(s.durationMinutes / 60) hr" : "\(s.durationMinutes) min")
        let travelInfo = s.travelToNext
        return DatePlanStop(
            order: s.stopNumber,
            name: s.name,
            venueType: s.category,
            timeSlot: s.arrivalTime,
            duration: durationStr.isEmpty ? "—" : durationStr,
            description: s.description,
            whyItFits: s.whyThisFits,
            romanticTip: s.romanticTip ?? "",
            emoji: "📍",
            travelTimeFromPrevious: travelInfo?.duration,
            travelDistanceFromPrevious: travelInfo?.distance,
            travelMode: travelInfo?.mode,
            validated: s.verified,
            placeId: s.placeId,
            address: s.address.isEmpty ? nil : s.address,
            websiteUrl: s.website,
            phoneNumber: s.phone,
            estimatedCostPerPerson: s.costPerPerson
        )
    }
    
    private static func datePlanStopToItineraryStop(_ s: DatePlanStop) -> ItineraryStop {
        let minutes = parseDurationToMinutes(s.duration)
        let travelToNext: TravelInfo?
        if let dur = s.travelTimeFromPrevious, let dist = s.travelDistanceFromPrevious {
            let mode = s.travelMode ?? "drive"
            travelToNext = TravelInfo(duration: dur, distance: dist, mode: mode)
        } else {
            travelToNext = nil
        }
        return ItineraryStop(
            stopNumber: s.order,
            arrivalTime: s.timeSlot,
            durationMinutes: minutes,
            placeId: s.placeId,
            name: s.name,
            category: s.venueType,
            address: s.address ?? "",
            phone: s.phoneNumber,
            website: s.websiteUrl,
            description: s.description,
            whyThisFits: s.whyItFits,
            romanticTip: s.romanticTip.isEmpty ? nil : s.romanticTip,
            costPerPerson: s.estimatedCostPerPerson,
            verified: s.validated ?? false,
            travelToNext: travelToNext
        )
    }
    
    private static func parseDurationToMinutes(_ duration: String) -> Int {
        let trimmed = duration.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty { return 0 }
        let numPart = trimmed.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        guard let num = Double(numPart) else { return 60 }
        if trimmed.contains("hour") || trimmed.contains("hr") { return Int(num * 60) }
        return Int(num)
    }
    
    private static func conversationStartersFromDB(_ arr: [String]?) -> [ConversationStarter]? {
        guard let arr = arr, !arr.isEmpty else { return nil }
        return arr.prefix(5).enumerated().map { i, q in
            ConversationStarter(question: q, category: "Conversation", emoji: "💭")
        }
    }
    
    private static func conversationStartersToDB(_ starters: [ConversationStarter]?) -> [String]? {
        guard let s = starters, !s.isEmpty else { return nil }
        return s.map { $0.question }
    }
}
