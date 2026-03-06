import Foundation

// MARK: - API Configuration
// Add your API keys here. Do NOT commit this file with real keys to version control.

struct Config {
    // OpenAI API
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    static let openAIAPIEndpoint = "https://api.openai.com/v1/chat/completions"
    static let openAIModel = "gpt-4o"
    
    // Google Places API
    static let googlePlacesAPIKey = "YOUR_GOOGLE_PLACES_API_KEY_HERE"
    static let googlePlacesEndpoint = "https://maps.googleapis.com/maps/api/place"
    
    // API Timeouts
    static let apiTimeout: TimeInterval = 60.0
    static let venueVerificationTimeout: TimeInterval = 10.0
}
