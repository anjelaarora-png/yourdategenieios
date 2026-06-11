import Foundation

/// Style for rewriting a love note. Used in the UI and in the AI prompt.
enum LoveNoteRewriteStyle: String, CaseIterable, Identifiable {
    case romantic
    case poetic
    case funny
    case sweet
    case playful

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .romantic: return "Romantic"
        case .poetic: return "Poetic"
        case .funny: return "Funny"
        case .sweet: return "Sweet"
        case .playful: return "Playful"
        }
    }

    var emoji: String {
        switch self {
        case .romantic: return "💕"
        case .poetic: return "✨"
        case .funny: return "😄"
        case .sweet: return "🍬"
        case .playful: return "🎉"
        }
    }

    /// SF Symbol name for nav-style golden icon (like tab bar icons).
    var icon: String {
        switch self {
        case .romantic: return "heart.fill"
        case .poetic: return "sparkles"
        case .funny: return "face.smiling.fill"
        case .sweet: return "heart.circle.fill"
        case .playful: return "party.popper.fill"
        }
    }

    var styleInstruction: String {
        switch self {
        case .romantic:
            return "Rewrite into a short, romantic love note—heartfelt and tender, warm and sincere but natural (not overly flowery). Same meaning, warmer tone."
        case .poetic:
            return "Rewrite into a short, poetic love note—elegant and lyrical, tender language that could appear on a beautiful letter. Same meaning, more poetic and refined."
        case .funny:
            return "Rewrite into a short, funny love note—playful, witty, and lighthearted while still being affectionate. Same meaning but with humor and inside-joke energy. Keep it sweet underneath the jokes."
        case .sweet:
            return "Rewrite into a short, sweet love note—warm, gentle, and cozy. Same meaning, soft and caring tone, like a hug in words."
        case .playful:
            return "Rewrite into a short, playful love note—flirty, fun, and upbeat while still romantic. Same meaning, with a light and cheeky vibe."
        }
    }

    var systemRole: String {
        switch self {
        case .romantic:
            return "You are a warm, romantic writer. Your task is to take someone's raw thoughts and rewrite them into a short love note for a card or letter. Keep it heartfelt and natural."
        case .poetic:
            return "You are a romantic poet. Your task is to take someone's raw thoughts and rewrite them into a short, poetic love note—elegant and lyrical but still genuine."
        case .funny:
            return "You are a witty, affectionate writer. Your task is to take someone's raw thoughts and rewrite them into a short, funny-yet-sweet love note. Humor first, but the love should still come through."
        case .sweet:
            return "You are a warm, gentle writer. Your task is to take someone's raw thoughts and rewrite them into a short, sweet love note—cozy, caring, and soft."
        case .playful:
            return "You are a flirty, fun writer. Your task is to take someone's raw thoughts and rewrite them into a short, playful love note—upbeat and cheeky but still romantic."
        }
    }
}

/// Rewrites the user's raw words into a short love note in the chosen style via the rewrite-love-note Edge Function.
enum LoveNoteAIService {

    static func rewrite(userText: String, style: LoveNoteRewriteStyle) async throws -> String {
        guard Config.isSupabaseConfigured else {
            throw LoveNoteAIError.notConfigured
        }
        do {
            return try await SupabaseService.shared.rewriteLoveNote(
                originalText: userText,
                systemRole: style.systemRole,
                styleInstruction: style.styleInstruction
            )
        } catch SupabaseError.unauthorized {
            throw LoveNoteAIError.notConfigured
        } catch SupabaseError.authFailed(let msg) {
            if msg.lowercased().contains("rate") { throw LoveNoteAIError.rateLimited }
            throw LoveNoteAIError.apiError(msg)
        } catch SupabaseError.invalidResponse {
            throw LoveNoteAIError.noContent
        } catch {
            throw LoveNoteAIError.apiError(error.localizedDescription)
        }
    }
}

enum LoveNoteAIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case noContent
    case rateLimited
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Please sign in to rewrite love notes."
        case .invalidURL: return "Invalid API endpoint."
        case .invalidResponse: return "Invalid response from server."
        case .noContent: return "Could not generate a rewritten version. Try again."
        case .rateLimited: return "Too many requests. Try again in a moment."
        case .apiError(let msg): return msg
        }
    }
}
