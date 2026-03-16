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

/// Rewrites the user's raw words into a short love note in the chosen style using the configured OpenAI API.
enum LoveNoteAIService {

    static func rewrite(userText: String, style: LoveNoteRewriteStyle) async throws -> String {
        guard Config.isOpenAIConfigured else {
            throw LoveNoteAIError.notConfigured
        }

        let systemPrompt = """
        \(style.systemRole)

        Rules:
        - Keep the same meaning and sentiment; do not add new facts or make things up.
        - Keep it concise: 2–5 sentences or one short paragraph. No lists or bullets.
        - Write in second person ("you") as if the author is speaking to their loved one.
        - Do not use clichés or generic phrases; keep their voice and their specific message.
        - Output only the rewritten love note, no quotes, no preamble, no "Here's your love note:".
        """

        let userPrompt = """
        \(style.styleInstruction)

        "\(userText)"
        """

        var body: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.8,
            "max_tokens": 400
        ]

        guard let url = URL(string: Config.openAIAPIEndpoint) else {
            throw LoveNoteAIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LoveNoteAIError.invalidResponse
        }
        if http.statusCode != 200 {
            let err = (try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data))?.error?.message
            if http.statusCode == 429 { throw LoveNoteAIError.rateLimited }
            throw LoveNoteAIError.apiError(err ?? "HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard var content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw LoveNoteAIError.noContent
        }
        content = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^[\"']|[\"']$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return content
    }
}

// MARK: - Response types (shared shape with GiftAIService)

private struct OpenAIChatResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: Message
        struct Message: Decodable {
            let content: String?
        }
    }
}

private struct OpenAIErrorResponse: Decodable {
    let error: ErrorDetail?
    struct ErrorDetail: Decodable {
        let message: String?
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
        case .notConfigured: return "OpenAI API key not set. Add OPENAI_API_KEY in Secrets to rewrite love notes."
        case .invalidURL: return "Invalid API endpoint."
        case .invalidResponse: return "Invalid response from server."
        case .noContent: return "Could not generate a poetic version. Try again."
        case .rateLimited: return "Too many requests. Try again in a moment."
        case .apiError(let msg): return msg
        }
    }
}
