import Foundation
import Supabase

enum SupabaseDatabaseError: LocalizedError {
    case notAuthorized
    case postgrest(PostgrestError)
    case decode(Error)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "You must be signed in to load this data."
        case .postgrest(let error):
            return error.localizedDescription
        case .decode(let error):
            return error.localizedDescription
        case .unexpected(let message):
            return message
        }
    }
}

/// Reads from Supabase PostgREST using `SupabaseManager.shared.client` and existing `DBPreferences` / `DBDatePlan` models.
final class SupabaseDatabaseService {
    static let shared = SupabaseDatabaseService()

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    func fetchPreferences(userId: UUID) async throws -> DBPreferences? {
        do {
            let response: PostgrestResponse<[DBPreferences]> = try await client
                .from("preferences")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
            return response.value.first
        } catch {
            throw mapError(error)
        }
    }

    func fetchDatePlans(coupleId: UUID) async throws -> [DBDatePlan] {
        do {
            let response: PostgrestResponse<[DBDatePlan]> = try await client
                .from("date_plans")
                .select()
                .eq("couple_id", value: coupleId)
                .execute()
            return response.value
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> SupabaseDatabaseError {
        if let postgrest = error as? PostgrestError {
            return .postgrest(postgrest)
        }
        if let http = error as? HTTPError {
            let code = http.response.statusCode
            if code == 401 || code == 403 {
                return .notAuthorized
            }
            return .unexpected(http.localizedDescription)
        }
        if error is DecodingError {
            return .decode(error)
        }
        return .unexpected(error.localizedDescription)
    }
}
