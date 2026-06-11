import Foundation

/// Gift generation is handled server-side via the generate-more-gifts Edge Function.
/// Call `SupabaseService.shared.generateMoreGifts(...)` directly instead of using this type.
/// This file is kept for backward compatibility only.
enum GiftAIService {
    static func generateGifts(
        occasion: String,
        budget: String,
        interests: String,
        notes: String,
        location: String,
        planTitle: String?,
        existingGiftNames: [String],
        recipient: String?,
        giftStyle: [String]?,
        count: Int = 6
    ) async throws -> [GiftSuggestion] {
        return try await SupabaseService.shared.generateMoreGifts(
            occasion: occasion.isEmpty ? nil : occasion,
            budget: budget.isEmpty ? nil : budget,
            interests: interests.isEmpty ? nil : interests,
            notes: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            planTitle: planTitle,
            existingGiftNames: existingGiftNames,
            count: count,
            recipient: recipient,
            giftStyle: giftStyle
        )
    }
}

enum GiftAIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case noContent
    case parseFailed
    case rateLimited
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Please sign in to generate gift suggestions."
        case .invalidURL: return "Invalid API endpoint."
        case .invalidResponse: return "Invalid response from server."
        case .noContent: return "No suggestions in response."
        case .parseFailed: return "Could not read gift suggestions."
        case .rateLimited: return "Too many requests. Try again in a moment."
        case .apiError(let msg): return msg
        }
    }
}
