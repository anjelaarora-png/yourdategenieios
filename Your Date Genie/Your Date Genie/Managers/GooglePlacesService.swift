import Foundation
import CoreLocation

// MARK: - Google Places Service

/// Service for verifying venues using Google Places API
class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private init() {}
    
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
    }
    
    // MARK: - Verify Venue
    
    /// Verify a venue exists and enrich with real data from Google Places
    func verifyVenue(_ stop: DatePlanStop, city: String) async throws -> DatePlanStop {
        let query = "\(stop.name) \(city)"
        
        guard let place = try await searchPlace(query: query) else {
            return stop
        }
        
        // Get detailed place information
        let details = try await getPlaceDetails(placeId: place.placeId)
        
        return DatePlanStop(
            order: stop.order,
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
            travelMode: stop.travelMode,
            validated: true,
            placeId: place.placeId,
            address: details?.address ?? place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            websiteUrl: details?.website,
            phoneNumber: details?.phoneNumber,
            openingHours: details?.openingHours,
            estimatedCostPerPerson: stop.estimatedCostPerPerson
        )
    }
    
    // MARK: - Search Place
    
    private func searchPlace(query: String) async throws -> PlaceSearchResult? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let urlString = "\(Config.googlePlacesEndpoint)/textsearch/json?query=\(encodedQuery)&key=\(Config.googlePlacesAPIKey)"
        
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
    
    // MARK: - Get Place Details
    
    private func getPlaceDetails(placeId: String) async throws -> PlaceSearchResult? {
        let fields = "name,formatted_address,geometry,rating,user_ratings_total,opening_hours,formatted_phone_number,website,price_level"
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
            priceLevel: json["price_level"] as? Int
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
            priceLevel: priceLevel
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
