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
    // Reads from Info.plist (populated by Secrets.xcconfig at build time).
    // No hardcoded fallbacks — if the xcconfig is missing, the app fails fast with a clear message.
    static let supabaseURL: String = {
        let fromPlist = resolvedPlistString(key: "SUPABASE_URL", placeholderSuffix: ".supabase.co")
        guard !fromPlist.isEmpty, fromPlist.hasPrefix("https://") else {
            fatalError("SUPABASE_URL missing or invalid in Info.plist. Set it in ios/Secrets.xcconfig and rebuild.")
        }
        return fromPlist
    }()
    static let supabaseAnonKey: String = {
        guard let raw = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !raw.hasPrefix("$("),
              raw != "your_supabase_anon_key_here" else {
            fatalError("SUPABASE_ANON_KEY missing from Info.plist. Set it in ios/Secrets.xcconfig and rebuild.")
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }()
    
    // MARK: - Google Sign-In (native)
    // Native Google sign-in uses the iOS OAuth client ID (type "iOS" in Google Cloud).
    // Set GOOGLE_IOS_CLIENT_ID + GOOGLE_REVERSED_CLIENT_ID in Secrets.xcconfig; the SDK reads
    // GIDClientID from Info.plist and the reversed ID is registered as a URL scheme.
    // The resulting Google ID token is exchanged for a Supabase session (signInWithIdToken).
    static let googleIOSClientID: String = {
        resolvedPlistString(key: "GIDClientID", placeholderSuffix: ".apps.googleusercontent.com")
    }()

    static var isGoogleSignInConfigured: Bool {
        !googleIOSClientID.isEmpty && googleIOSClientID.hasSuffix(".apps.googleusercontent.com")
    }

    // MARK: - Firebase (business partner listings only)
    // iOS uses Firebase solely to write the `business_listings` collection (project
    // `your-date-genie`). Configuration ships as GoogleService-Info.plist in the app bundle.
    // Couple app data stays on Supabase.
    static var isFirebaseConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    // MARK: - Configuration Validation

    static var isGooglePlacesConfigured: Bool {
        !googlePlacesAPIKey.isEmpty && googlePlacesAPIKey != "your_google_places_api_key_here"
    }

    /// True when the required Supabase URL and anon key are present and valid.
    static var isSupabaseConfigured: Bool {
        let rawURL = (Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawKey = (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return rawURL.hasPrefix("https://") && !rawURL.hasPrefix("$(")
            && !rawKey.isEmpty && !rawKey.hasPrefix("$(") && rawKey != "your_supabase_anon_key_here"
    }

    /// Returns a list of missing/invalid configuration key names.
    /// Reads raw plist values so this method can report problems without triggering
    /// the fatalError on the main properties above.
    static func validateConfiguration() -> [String] {
        var missingKeys: [String] = []

        let rawURL = (Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if rawURL.isEmpty || rawURL.hasPrefix("$(") || !rawURL.hasPrefix("https://") {
            missingKeys.append("SUPABASE_URL — set it in ios/Secrets.xcconfig")
        }

        let rawAnonKey = (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if rawAnonKey.isEmpty || rawAnonKey.hasPrefix("$(") || rawAnonKey == "your_supabase_anon_key_here" {
            missingKeys.append("SUPABASE_ANON_KEY — set it in ios/Secrets.xcconfig")
        }

        if !isGooglePlacesConfigured {
            missingKeys.append("GOOGLE_PLACES_API_KEY — set it in ios/Secrets.xcconfig")
        }

        return missingKeys
    }
}

// Type alias for backward compatibility
typealias AppConfig = Config
