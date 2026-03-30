import Foundation

// MARK: - API Configuration
// API keys are loaded from Info.plist at runtime, which gets values from Secrets.xcconfig at build time.
// See Secrets.xcconfig.example for setup instructions.

struct Config {
    /// Resolves a build setting from Info.plist. Empty if missing, blank, unsubstituted `$(VAR)`, or obvious placeholder.
    private static func resolvedPlistString(key: String, placeholderSuffix: String? = nil) -> String {
        let raw = Bundle.main.infoDictionary?[key] as? String ?? ""
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "" }
        if t.hasPrefix("$(") { return "" }
        if let suffix = placeholderSuffix, t.hasSuffix(suffix), t.contains("your_") { return "" }
        return t
    }
    
    // MARK: - OpenAI API
    static let openAIAPIKey: String = {
        resolvedPlistString(key: "OPENAI_API_KEY", placeholderSuffix: "_here")
    }()
    static let openAIAPIEndpoint = "https://api.openai.com/v1/chat/completions"
    static let openAIModel = "gpt-4o"
    
    // MARK: - Google Places & Geocoding API
    /// Same key is used for: Places API (autocomplete, place details) and Geocoding API.
    /// In Google Cloud Console enable: Places API, Geocoding API.
    static let googlePlacesAPIKey: String = {
        let env = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !env.isEmpty, !env.hasPrefix("$("), env != "your_google_places_api_key_here" {
            return env
        }
        return resolvedPlistString(key: "GOOGLE_PLACES_API_KEY", placeholderSuffix: "_here")
    }()
    static let googlePlacesEndpoint = "https://maps.googleapis.com/maps/api/place"
    
    // MARK: - API Timeouts
    static let apiTimeout: TimeInterval = 90.0
    static let venueVerificationTimeout: TimeInterval = 10.0
    
    // MARK: - Supabase
    // Use hardcoded values to avoid xcconfig/Info.plist loading issues (hostname resolution)
    static let supabaseURL = "https://jhpwacmsocjmzhimtbxj.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocHdhY21zb2NqbXpoaW10YnhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzY5OTMsImV4cCI6MjA4ODY1Mjk5M30.-CN9vCUtTl3M8nkrYmcWtQguMQgH7qmL9lqrf7q_UJQ"
    
    // MARK: - Configuration Validation
    static var isOpenAIConfigured: Bool {
        !openAIAPIKey.isEmpty && openAIAPIKey != "your_openai_api_key_here"
    }
    
    static var isGooglePlacesConfigured: Bool {
        !googlePlacesAPIKey.isEmpty && googlePlacesAPIKey != "your_google_places_api_key_here"
    }
    
    static var isSupabaseConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty &&
        supabaseURL != "https://your-project-id.supabase.co"
    }
    
    /// Validates that all required configuration keys are present
    /// Returns an array of missing key names, empty if all configured
    static func validateConfiguration() -> [String] {
        var missingKeys: [String] = []
        
        if !isSupabaseConfigured {
            if supabaseURL.isEmpty { missingKeys.append("SUPABASE_URL") }
            if supabaseAnonKey.isEmpty { missingKeys.append("SUPABASE_ANON_KEY") }
        }
        
        if !isOpenAIConfigured {
            missingKeys.append("OPENAI_API_KEY")
        }
        
        if !isGooglePlacesConfigured {
            missingKeys.append("GOOGLE_PLACES_API_KEY")
        }
        
        return missingKeys
    }
}

// Type alias for backward compatibility
typealias AppConfig = Config
