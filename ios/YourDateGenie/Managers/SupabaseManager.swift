import Foundation
import Supabase

/// Shared access to `SupabaseClient`. Replace the placeholder URL and anon key with your project values
/// (for example via `Secrets.xcconfig` / Info.plist or your own configuration layer).
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseURLString = AppConfig.supabaseURL
        let anonKey = AppConfig.supabaseAnonKey

        let normalizedURL = supabaseURLString.hasPrefix("http")
            ? supabaseURLString
            : "https://\(supabaseURLString)"

        guard let url = URL(string: normalizedURL) else {
            assertionFailure("SupabaseManager: invalid Supabase URL '\(normalizedURL)'")
            // Provide a non-fatal no-op client to avoid crashing in edge cases
            client = SupabaseClient(
                supabaseURL: URL(string: "https://localhost")!,
                supabaseKey: ""
            )
            return
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: JSONDecoder.supabasePostgresREST()),
                auth: SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
