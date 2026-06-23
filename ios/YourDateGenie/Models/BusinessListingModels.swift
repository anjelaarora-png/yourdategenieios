import Foundation

enum BusinessVenueCategory: String, CaseIterable, Identifiable {
    case restaurant
    case barLounge = "bar_lounge"
    case cafeBakery = "cafe_bakery"
    case wineTasting = "wine_tasting"
    case activity
    case entertainment
    case spaWellness = "spa_wellness"
    case hotelStay = "hotel_stay"
    case retailGifts = "retail_gifts"
    case eventVenue = "event_venue"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .barLounge: return "Bar & lounge"
        case .cafeBakery: return "Café / bakery"
        case .wineTasting: return "Wine bar / tasting room"
        case .activity: return "Activity / experience"
        case .entertainment: return "Entertainment (comedy, jazz, live music)"
        case .spaWellness: return "Spa / wellness"
        case .hotelStay: return "Hotel / boutique stay"
        case .retailGifts: return "Retail / gifts"
        case .eventVenue: return "Event venue"
        case .other: return "Other (describe below)"
        }
    }

    var legacyVenueType: String {
        switch self {
        case .restaurant, .cafeBakery: return "restaurant"
        case .barLounge, .wineTasting: return "bar"
        case .activity, .entertainment, .eventVenue: return "activity"
        case .retailGifts: return "retail"
        default: return "other"
        }
    }
}

enum BusinessPromotionInterest: String, CaseIterable, Identifiable {
    case featuredItinerary = "featured_itinerary"
    case sponsoredPlan = "sponsored_plan"
    case eventPromo = "event_promo"
    case ongoingAds = "ongoing_ads"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .featuredItinerary: return "Featured stop inside AI date itineraries"
        case .sponsoredPlan: return "Sponsored date plan / takeover night"
        case .eventPromo: return "Promote a specific event or special"
        case .ongoingAds: return "Ongoing local advertising"
        case .other: return "Other (describe below)"
        }
    }
}

enum BusinessBudgetRange: String, CaseIterable, Identifiable {
    case under200 = "under_200"
    case range200_500 = "200_500"
    case over500 = "500_plus"
    case unsure

    var id: String { rawValue }

    var label: String {
        switch self {
        case .under200: return "Under $200 / month"
        case .range200_500: return "$200 – $500 / month"
        case .over500: return "$500+ / month"
        case .unsure: return "Not sure yet — send options"
        }
    }
}

struct BusinessListingApplication: Equatable {
    var businessName = ""
    var contactName = ""
    var contactRole = ""
    var email = ""
    var phone = ""
    var website = ""
    var streetAddress = ""
    var city = ""
    var state = ""
    var zip = ""
    var venueCategory: BusinessVenueCategory = .restaurant
    var venueCategoryOther = ""
    var aboutVenue = ""
    var coupleExperience = ""
    var promotionInterest: BusinessPromotionInterest = .featuredItinerary
    var promotionOther = ""
    var budgetRange: BusinessBudgetRange = .unsure
    var additionalNotes = ""
}

enum BusinessListingSubmitStatus: Equatable {
    case idle
    case submitting
    case success
    case duplicate
    case error(String)
}

// MARK: - Validation

/// Client-side validation that mirrors the Firestore `business_listings` create rule
/// (see `firestore.rules`). Keeping these in lockstep means the submit button never
/// fails at the network layer for a reason the user could have fixed up front.
extension BusinessListingApplication {
    enum ValidationField: Hashable, CaseIterable {
        case businessName, contactName, email, phone, streetAddress, city, state
        case venueCategoryOther, aboutVenue, coupleExperience, promotionOther
    }

    /// Matches the Firestore rule `email.matches('.+@.+\\..+')` exactly (full-string match).
    static func isValidEmail(_ raw: String) -> Bool {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return false }
        return email.range(of: "^.+@.+\\..+$", options: [.regularExpression]) != nil
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Field -> human-readable message for every requirement the Firestore rule enforces.
    var validationErrors: [ValidationField: String] {
        var errors: [ValidationField: String] = [:]

        if trimmed(businessName).isEmpty {
            errors[.businessName] = "Enter your business name."
        }
        if trimmed(contactName).isEmpty {
            errors[.contactName] = "Enter a contact name."
        }

        let email = trimmed(self.email)
        if email.isEmpty {
            errors[.email] = "Enter a work email."
        } else if !Self.isValidEmail(email) {
            errors[.email] = "Enter a valid email like you@business.com."
        }

        if trimmed(phone).count < 7 {
            errors[.phone] = "Enter a phone number (at least 7 digits)."
        }
        if trimmed(streetAddress).count < 3 {
            errors[.streetAddress] = "Enter a street address."
        }
        if trimmed(city).isEmpty {
            errors[.city] = "Enter a city."
        }
        if trimmed(state).count < 2 {
            errors[.state] = "Enter a state (2+ letters, e.g. NY)."
        }
        if venueCategory == .other && trimmed(venueCategoryOther).count < 2 {
            errors[.venueCategoryOther] = "Describe your category."
        }
        if trimmed(aboutVenue).count < 10 {
            errors[.aboutVenue] = "Tell us a bit more (at least 10 characters)."
        }
        if trimmed(coupleExperience).count < 10 {
            errors[.coupleExperience] = "Tell us a bit more (at least 10 characters)."
        }
        if promotionInterest == .other && trimmed(promotionOther).count < 2 {
            errors[.promotionOther] = "Describe what you’re looking for."
        }

        return errors
    }

    var isValid: Bool { validationErrors.isEmpty }
}
