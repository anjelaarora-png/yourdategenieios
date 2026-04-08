import Foundation
import Supabase

/// Shared access to `SupabaseClient`. Replace the placeholder URL and anon key with your project values
/// (for example via `Secrets.xcconfig` / Info.plist or your own configuration layer).
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseURLString = "https://jhpwacmsocjmzhimtbxj.supabase.co"
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocHdhY21zb2NqbXpoaW10YnhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzY5OTMsImV4cCI6MjA4ODY1Mjk5M30.-CN9vCUtTl3M8nkrYmcWtQguMQgH7qmL9lqrf7q_UJQ"

        let normalizedURL = supabaseURLString.hasPrefix("http")
            ? supabaseURLString
            : "https://\(supabaseURLString)"

        guard let url = URL(string: normalizedURL) else {
            fatalError("SupabaseManager: invalid Supabase URL")
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
