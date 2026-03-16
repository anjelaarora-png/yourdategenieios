import Foundation
import CoreLocation

// MARK: - Places Autocomplete Error

enum PlacesAutocompleteError: LocalizedError {
    case apiError(status: String, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let status, let message):
            return "\(status): \(message)"
        }
    }
}

// MARK: - Google Places Service

/// Service for verifying venues using Google Places API
class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private init() {}
    
    // MARK: - Autocomplete Prediction
    
    struct AutocompletePrediction: Identifiable {
        let id: String
        let placeId: String
        let description: String
        let mainText: String
        let secondaryText: String?
    }
    
    // MARK: - Place Search Result
    
    struct PlaceSearchResult {
        let placeId: String
        let name: String
        let address: String
        let latitude: Double
        let longitude: Double
        let rating: Double?
        let userRatingsTotal: Int?
        let openNow: Bool?
        let phoneNumber: String?
        let website: String?
        let openingHours: [String]?
        let priceLevel: Int?
        /// URL for a place photo from Google Business Profile (built from photo_reference).
        let photoUrl: String?
    }
    
    // MARK: - Booking URL from website
    
    /// If the venue's website is a known booking platform (OpenTable, Resy), use it as the reservation link.
    private static func bookingUrlFromWebsite(_ website: String?) -> String? {
        guard let w = website?.lowercased(), !w.isEmpty else { return nil }
        if w.contains("opentable.com") || w.contains("resy.com") { return website }
        return nil
    }
    
    // MARK: - Verify Venue
    
    /// Verify a venue exists and enrich with real data from Google Places. Biases search to the user's city so we don't replace e.g. Chennai venues with same-named venues in Spain.
    func verifyVenue(_ stop: DatePlanStop, city: String) async throws -> DatePlanStop {
        let query = "\(stop.name) \(city)"
        let cityTrimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        var cityCenter: (lat: Double, lon: Double)?
        if !cityTrimmed.isEmpty, let geo = try? await geocodeAddress(cityTrimmed) {
            cityCenter = (geo.latitude, geo.longitude)
        }
        
        guard let place = try await searchPlace(query: query, locationBias: cityCenter) else {
            return stop
        }
        
        // Reject result if it's clearly in another country/region (e.g. user asked Chennai but got Spain)
        if !cityTrimmed.isEmpty && !isAddressInCity(place.address, city: cityTrimmed, placeLat: place.latitude, placeLon: place.longitude, cityCenter: cityCenter) {
            return stop
        }
        
        // Get detailed place information
        let details = try await getPlaceDetails(placeId: place.placeId)
        let website = details?.website ?? stop.websiteUrl
        let bookingUrl = stop.bookingUrl ?? Self.bookingUrlFromWebsite(website)
        
        return DatePlanStop(
            order: stop.order,
            name: details?.name ?? place.name,
            venueType: stop.venueType,
            timeSlot: stop.timeSlot,
            duration: stop.duration,
            description: stop.description,
            whyItFits: stop.whyItFits,
            romanticTip: stop.romanticTip,
            emoji: stop.emoji,
            travelTimeFromPrevious: stop.travelTimeFromPrevious,
            travelDistanceFromPrevious: stop.travelDistanceFromPrevious,
            travelMode: stop.travelMode,
            validated: true,
            placeId: place.placeId,
            address: details?.address ?? place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            websiteUrl: website,
            phoneNumber: details?.phoneNumber ?? stop.phoneNumber,
            openingHours: details?.openingHours ?? stop.openingHours,
            estimatedCostPerPerson: stop.estimatedCostPerPerson,
            bookingUrl: bookingUrl,
            imageUrl: details?.photoUrl ?? stop.imageUrl
        )
    }
    
    // MARK: - Autocomplete
    
    /// Fetch place autocomplete predictions for city/region search
    func fetchAutocompleteCities(input: String) async throws -> [AutocompletePrediction] {
        try await fetchAutocomplete(input: input, types: "(regions)")
    }
    
    /// Fetch place autocomplete predictions for address search (streets, intersections, establishments)
    /// Uses "geocode" type for broad address coverage per Google Places API docs
    func fetchAutocompleteAddresses(input: String) async throws -> [AutocompletePrediction] {
        try await fetchAutocomplete(input: input, types: "geocode")
    }
    
    func fetchAutocomplete(input: String, types: String) async throws -> [AutocompletePrediction] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        
        guard !Config.googlePlacesAPIKey.isEmpty else {
            #if DEBUG
            print("[PlacesAutocomplete] API key is empty. Add GOOGLE_PLACES_API_KEY to Info.plist via Secrets.xcconfig")
            #endif
            return []
        }
        
        guard let encodedInput = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedTypes = types.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        let urlString = "\(Config.googlePlacesEndpoint)/autocomplete/json?input=\(encodedInput)&types=\(encodedTypes)&key=\(Config.googlePlacesAPIKey)"
        
        guard let url = URL(string: urlString) else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            #if DEBUG
            print("[PlacesAutocomplete] HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            #endif
            return []
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        
        // Check API status - Google returns 200 even for errors like REQUEST_DENIED
        let status = json["status"] as? String ?? ""
        if status != "OK" && status != "ZERO_RESULTS" {
            let errorMessage = json["error_message"] as? String ?? "Unknown error"
            #if DEBUG
            print("[PlacesAutocomplete] API error: \(status) - \(errorMessage)")
            #endif
            throw PlacesAutocompleteError.apiError(status: status, message: errorMessage)
        }
        
        guard let predictions = json["predictions"] as? [[String: Any]] else {
            return []
        }
        
        return predictions.compactMap { parseAutocompletePrediction(from: $0) }
    }
    
    private func parseAutocompletePrediction(from json: [String: Any]) -> AutocompletePrediction? {
        guard let placeId = json["place_id"] as? String,
              let description = json["description"] as? String else {
            return nil
        }
        
        var mainText = description
        var secondaryText: String?
        
        if let structured = json["structured_formatting"] as? [String: Any] {
            mainText = structured["main_text"] as? String ?? description
            secondaryText = structured["secondary_text"] as? String
        }
        
        return AutocompletePrediction(
            id: placeId,
            placeId: placeId,
            description: description,
            mainText: mainText,
            secondaryText: secondaryText
        )
    }
    
    // MARK: - Place Details (full address from place_id)
    
    /// Fetch the canonical formatted address and coordinates for a place_id (e.g. from autocomplete).
    /// Use this when the user selects an address suggestion so the stored value is the full accurate address.
    func fetchFormattedAddress(placeId: String) async throws -> (formattedAddress: String, latitude: Double, longitude: Double)? {
        guard Config.isGooglePlacesConfigured else { return nil }
        guard let details = try await getPlaceDetails(placeId: placeId) else { return nil }
        return (details.address, details.latitude, details.longitude)
    }
    
    // MARK: - Geocode Address
    
    /// Resolve an address string to coordinates using Google Geocoding API (Google-verified).
    /// Returns formatted address and coordinates, or nil if geocoding fails.
    func geocodeAddress(_ address: String) async throws -> (formattedAddress: String, latitude: Double, longitude: Double)? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !Config.googlePlacesAPIKey.isEmpty else { return nil }
        
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(encoded)&key=\(Config.googlePlacesAPIKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["status"] as? String == "OK",
              let results = json["results"] as? [[String: Any]],
              let first = results.first else {
            return nil
        }
        
        let formattedAddress = first["formatted_address"] as? String ?? trimmed
        guard let geometry = first["geometry"] as? [String: Any],
              let location = geometry["location"] as? [String: Any],
              let lat = location["lat"] as? Double,
              let lng = location["lng"] as? Double else {
            return nil
        }
        
        return (formattedAddress, lat, lng)
    }
    
    // MARK: - Search Place
    
    /// Search with optional location bias so results are in the user's city (e.g. Chennai), not same-named venues elsewhere (e.g. Spain).
    private func searchPlace(query: String, locationBias: (lat: Double, lon: Double)? = nil) async throws -> PlaceSearchResult? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        var urlString = "\(Config.googlePlacesEndpoint)/textsearch/json?query=\(encodedQuery)"
        if let bias = locationBias {
            let radiusMeters = 50_000
            urlString += "&location=\(bias.lat),\(bias.lon)&radius=\(radiusMeters)"
        }
        urlString += "&key=\(Config.googlePlacesAPIKey)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = Config.venueVerificationTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let firstResult = results.first else {
            return nil
        }
        
        return parsePlaceResult(from: firstResult)
    }
    
    /// Map ExploreCategory id to Google Places text search terms for trending in city.
    private static func trendingQueryTerms(for categoryId: String?) -> String {
        switch categoryId {
        case "restaurants": return "restaurant"
        case "cafes": return "cafe coffee"
        case "bars": return "bar lounge"
        case "romantic": return "romantic restaurant"
        case "date_night", nil: return "restaurant bar romantic date night"
        case "outdoor": return "parks outdoor activities"
        case "arts": return "museum art gallery"
        case "nightlife": return "nightclub nightlife"
        default: return "restaurant bar romantic date night"
        }
    }
    
    /// Fetch trending / popular places in the given city (e.g. for "Trending in your Area" on home).
    /// Optional `categoryId` from ExploreCategory (e.g. "restaurants", "bars") narrows results; nil = general date-night mix.
    /// Uses Places Text Search; returns up to `limit` results.
    func fetchTrendingPlacesInCity(city: String, categoryId: String? = nil, limit: Int = 6) async throws -> [PlaceSearchResult] {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, Config.isGooglePlacesConfigured else { return [] }
        
        var locationBias: (lat: Double, lon: Double)?
        if let geo = try? await geocodeAddress(trimmed) {
            locationBias = (geo.latitude, geo.longitude)
        }
        
        let queryTerms = Self.trendingQueryTerms(for: categoryId)
        let query = "\(queryTerms) \(trimmed)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        var urlString = "\(Config.googlePlacesEndpoint)/textsearch/json?query=\(encodedQuery)"
        if let bias = locationBias {
            let radiusMeters = 25_000
            urlString += "&location=\(bias.lat),\(bias.lon)&radius=\(radiusMeters)"
        }
        urlString += "&key=\(Config.googlePlacesAPIKey)"
        
        guard let url = URL(string: urlString) else { return [] }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }
        
        var places: [PlaceSearchResult] = []
        for result in results.prefix(limit) {
            if let place = parsePlaceResult(from: result) {
                places.append(place)
            }
        }
        return places
    }
    
    /// Heuristic: address contains city name (or known variation) or place is within maxDistanceKm of city center. Reject e.g. Spain when user asked Chennai.
    private func isAddressInCity(_ address: String, city: String, placeLat: Double, placeLon: Double, cityCenter: (lat: Double, lon: Double)?, maxDistanceKm: Double = 80) -> Bool {
        let addressLower = address.lowercased()
        let cityLower = city.lowercased()
        let cityWords = cityLower.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        let firstCityName = cityWords.first ?? cityLower
        if !firstCityName.isEmpty && addressLower.contains(firstCityName) { return true }
        if cityLower.contains("chennai") && addressLower.contains("madras") { return true }
        if cityLower.contains("madras") && addressLower.contains("chennai") { return true }
        if let c = cityCenter {
            let km = distanceKm(c.lat, c.lon, placeLat, placeLon)
            return km <= maxDistanceKm
        }
        return true
    }
    
    private func distanceKm(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    // MARK: - Get Place Details
    
    private func getPlaceDetails(placeId: String) async throws -> PlaceSearchResult? {
        let fields = "name,formatted_address,geometry,rating,user_ratings_total,opening_hours,formatted_phone_number,website,price_level,photos"
        let urlString = "\(Config.googlePlacesEndpoint)/details/json?place_id=\(placeId)&fields=\(fields)&key=\(Config.googlePlacesAPIKey)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = Config.venueVerificationTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any] else {
            return nil
        }
        
        return parsePlaceDetails(from: result, placeId: placeId)
    }
    
    // MARK: - Parse Results
    
    private func parsePlaceResult(from json: [String: Any]) -> PlaceSearchResult? {
        guard let placeId = json["place_id"] as? String,
              let name = json["name"] as? String,
              let geometry = json["geometry"] as? [String: Any],
              let location = geometry["location"] as? [String: Any],
              let lat = location["lat"] as? Double,
              let lng = location["lng"] as? Double else {
            return nil
        }
        
        let address = json["formatted_address"] as? String ?? ""
        let rating = json["rating"] as? Double
        let userRatingsTotal = json["user_ratings_total"] as? Int
        
        var openNow: Bool?
        if let openingHours = json["opening_hours"] as? [String: Any] {
            openNow = openingHours["open_now"] as? Bool
        }
        
        var photoUrl: String?
        if let photos = json["photos"] as? [[String: Any]], let first = photos.first, let ref = first["photo_reference"] as? String, !Config.googlePlacesAPIKey.isEmpty {
            photoUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=\(ref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ref)&key=\(Config.googlePlacesAPIKey)"
        }
        return PlaceSearchResult(
            placeId: placeId,
            name: name,
            address: address,
            latitude: lat,
            longitude: lng,
            rating: rating,
            userRatingsTotal: userRatingsTotal,
            openNow: openNow,
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            priceLevel: json["price_level"] as? Int,
            photoUrl: photoUrl
        )
    }
    
    private func parsePlaceDetails(from json: [String: Any], placeId: String) -> PlaceSearchResult? {
        let name = json["name"] as? String ?? ""
        let address = json["formatted_address"] as? String ?? ""
        
        var lat: Double = 0
        var lng: Double = 0
        if let geometry = json["geometry"] as? [String: Any],
           let location = geometry["location"] as? [String: Any] {
            lat = location["lat"] as? Double ?? 0
            lng = location["lng"] as? Double ?? 0
        }
        
        let rating = json["rating"] as? Double
        let userRatingsTotal = json["user_ratings_total"] as? Int
        let phoneNumber = json["formatted_phone_number"] as? String
        let website = json["website"] as? String
        let priceLevel = json["price_level"] as? Int
        
        var openingHours: [String]?
        if let hours = json["opening_hours"] as? [String: Any],
           let weekdayText = hours["weekday_text"] as? [String] {
            openingHours = weekdayText
        }
        var photoUrl: String?
        if let photos = json["photos"] as? [[String: Any]], let first = photos.first, let ref = first["photo_reference"] as? String, !Config.googlePlacesAPIKey.isEmpty {
            photoUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=\(ref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ref)&key=\(Config.googlePlacesAPIKey)"
        }
        return PlaceSearchResult(
            placeId: placeId,
            name: name,
            address: address,
            latitude: lat,
            longitude: lng,
            rating: rating,
            userRatingsTotal: userRatingsTotal,
            openNow: nil,
            phoneNumber: phoneNumber,
            website: website,
            openingHours: openingHours,
            priceLevel: priceLevel,
            photoUrl: photoUrl
        )
    }
    
    // MARK: - Calculate Distance
    
    /// Calculate distance between two coordinates
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // MARK: - Format Rating
    
    func formatRating(_ rating: Double?) -> String? {
        guard let rating = rating else { return nil }
        return String(format: "%.1f", rating)
    }
    
    func formatPriceLevel(_ level: Int?) -> String? {
        guard let level = level else { return nil }
        return String(repeating: "$", count: min(level + 1, 4))
    }
}

// MARK: - Venue Verification Badge

extension DatePlanStop {
    var isVerified: Bool {
        validated == true && placeId != nil
    }
    
    var verificationBadge: String {
        isVerified ? "checkmark.seal.fill" : "questionmark.circle"
    }
    
    var formattedAddress: String {
        address ?? "Address unavailable"
    }
}
