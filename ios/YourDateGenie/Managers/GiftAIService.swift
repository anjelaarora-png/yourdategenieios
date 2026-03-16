import Foundation

/// Generates gift suggestions by calling the configured OpenAI-compatible API directly. No Lovable or Supabase edge function.
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
        guard Config.isOpenAIConfigured else {
            throw GiftAIError.notConfigured
        }
        
        let prompt = buildPrompt(
            occasion: occasion,
            budget: budget,
            interests: interests,
            notes: notes,
            location: location,
            planTitle: planTitle,
            existingGiftNames: existingGiftNames,
            recipient: recipient,
            giftStyle: giftStyle,
            count: count
        )
        
        var body: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                ["role": "system", "content": "You are a gift suggestion expert. Respond only with valid JSON: a single object with key \"gifts\" (array). No markdown, no code blocks, no extra text."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2048
        ]
        if Config.openAIAPIEndpoint.contains("openai.com") {
            body["response_format"] = ["type": "json_object"]
        }
        
        guard let url = URL(string: Config.openAIAPIEndpoint) else {
            throw GiftAIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GiftAIError.invalidResponse
        }
        if http.statusCode != 200 {
            let err = (try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data))?.error?.message
            if http.statusCode == 429 { throw GiftAIError.rateLimited }
            throw GiftAIError.apiError(err ?? "HTTP \(http.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard var content = decoded.choices.first?.message.content else {
            throw GiftAIError.noContent
        }
        content = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let contentData = content.data(using: .utf8) else {
            throw GiftAIError.noContent
        }
        
        let json = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        guard let giftsArray = json?["gifts"] as? [[String: Any]] else {
            throw GiftAIError.parseFailed
        }
        
        let locationHint = location.isEmpty ? "United States" : location
        let isUK = locationHint.lowercased().contains("uk") || locationHint.lowercased().contains("united kingdom")
        let amazonBase = isUK ? "https://www.amazon.co.uk/s?k=" : "https://www.amazon.com/s?k="
        
        return giftsArray.compactMap { item -> GiftSuggestion? in
            guard let name = item["name"] as? String, !name.isEmpty else { return nil }
            let description = (item["description"] as? String) ?? ""
            let priceRange = (item["priceRange"] as? String) ?? ""
            let whereToBuy = (item["whereToBuy"] as? String) ?? ""
            var purchaseUrl = item["purchaseUrl"] as? String
            if purchaseUrl == nil || purchaseUrl?.isEmpty == true || !(purchaseUrl?.hasPrefix("http") ?? false) {
                let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
                purchaseUrl = "\(amazonBase)\(query)"
            }
            let whyItFits = (item["whyItFits"] as? String) ?? ""
            let emoji = (item["emoji"] as? String) ?? "🎁"
            let imageUrl = item["imageUrl"] as? String
            if let url = imageUrl, (!url.hasPrefix("http") || url.isEmpty) { _ = imageUrl } // ignore invalid
            let finalImageUrl = (imageUrl != nil && imageUrl!.hasPrefix("http")) ? imageUrl : nil
            
            return GiftSuggestion(
                name: name,
                description: description,
                priceRange: priceRange,
                whereToBuy: whereToBuy,
                purchaseUrl: purchaseUrl,
                whyItFits: whyItFits,
                emoji: emoji,
                storeSearchQuery: nil,
                imageUrl: finalImageUrl
            )
        }
    }
    
    private static func buildPrompt(
        occasion: String,
        budget: String,
        interests: String,
        notes: String,
        location: String,
        planTitle: String?,
        existingGiftNames: [String],
        recipient: String?,
        giftStyle: [String]?,
        count: Int
    ) -> String {
        let locationHint = location.isEmpty ? "United States" : location
        let existingLine = existingGiftNames.isEmpty ? "" : "\nALREADY SUGGESTED (do NOT suggest these again): \(existingGiftNames.joined(separator: ", "))"
        let styleLine = (giftStyle?.isEmpty == false) ? "\nGift style: \(giftStyle!.joined(separator: ", "))" : ""
        let recipientLine = (recipient.map { $0.isEmpty ? nil : $0 } ?? nil).map { "\nRecipient: \($0)" } ?? ""
        
        return """
        Generate exactly \(count) personalized, UNIQUE gift suggestions as a JSON object with a single key "gifts" (array of objects).
        
        Context:
        Occasion: \(occasion.isEmpty ? "just because" : occasion)
        Budget: \(budget.isEmpty ? "any" : budget)
        Interests: \(interests.isEmpty ? "not specified" : interests)
        Notes: \(notes.isEmpty ? "none" : notes)
        Location (for where to buy): \(locationHint)
        \(planTitle.map { "Theme: \($0)" } ?? "")\(recipientLine)\(styleLine)\(existingLine)
        
        Rules:
        - Each gift must have: name, description, priceRange, whereToBuy, purchaseUrl, whyItFits, emoji. Optionally imageUrl (only if you have a real product image URL).
        - purchaseUrl must be a real link: use Amazon search (US or UK based on location), Etsy search, or Target/search URLs. Example: https://www.amazon.com/s?k=QUERY
        - Be specific and personal; use the interests and notes. Vary retailers (Etsy, Amazon, local, experiences).
        - Output only valid JSON: {"gifts": [{"name":"...","description":"...","priceRange":"...","whereToBuy":"...","purchaseUrl":"...","whyItFits":"...","emoji":"..."}, ...]}
        """
    }
}

// MARK: - Response types

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
        case .notConfigured: return "OpenAI API key not set. Add OPENAI_API_KEY in Secrets."
        case .invalidURL: return "Invalid API endpoint."
        case .invalidResponse: return "Invalid response from server."
        case .noContent: return "No suggestions in response."
        case .parseFailed: return "Could not read gift suggestions."
        case .rateLimited: return "Too many requests. Try again in a moment."
        case .apiError(let msg): return msg
        }
    }
}
