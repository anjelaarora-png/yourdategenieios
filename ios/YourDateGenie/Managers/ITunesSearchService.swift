import Foundation

struct ITunesSongResult: Codable {
    /// Optional so one malformed iTunes row does not fail the whole decode.
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl60: String?
    let previewUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case trackId
        case trackName
        case artistName
        case collectionName
        case artworkUrl60
        case previewUrl
    }
}

struct ITunesSearchResponse: Codable {
    let resultCount: Int?
    let results: [ITunesSongResult]
}

/// Uses iTunes Search API for song search (no auth, same as web).
enum ITunesSearchService {
    private static let base = "https://itunes.apple.com/search"
    
    /// In-memory cache for preview URLs to reduce API calls and improve repeat taps.
    private static let previewCache = NSMapTable<NSString, NSString>.strongToStrongObjects()
    private static let cacheLock = NSLock()
    
    /// Two-letter storefront (e.g. US, IN). Improves catalog + preview availability vs default.
    private static var searchCountryCode: String {
        let id = Locale.current.region?.identifier.uppercased() ?? "US"
        if id.count == 2 { return id }
        return "US"
    }
    
    static func searchSongs(query: String, limit: Int = 15) async throws -> [ITunesSongResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        guard query.count >= 2 else { return [] }
        
        var comp = URLComponents(string: base)!
        comp.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "country", value: searchCountryCode),
        ]
        guard let url = comp.url else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
        return response.results
    }
    
    /// Returns a 30-second preview URL for the given song (title + artist), or nil if not found.
    /// Uses best-match from results (title + artist similarity) and an in-memory cache.
    static func getPreviewUrl(title: String, artist: String) async -> String? {
        let key = "\(title)|\(artist)".trimmingCharacters(in: .whitespaces)
        guard key.count >= 2 else { return nil }
        let cacheKey = key as NSString
        cacheLock.lock()
        if let cached = previewCache.object(forKey: cacheKey) as String? {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        do {
            let fullQuery = "\(title) \(artist)".trimmingCharacters(in: .whitespaces)
            var results = try await searchSongs(query: fullQuery, limit: 25)
            var withPreview = results.filter { ($0.previewUrl?.isEmpty == false) && $0.trackName != nil && $0.artistName != nil }
            if withPreview.isEmpty, !title.trimmingCharacters(in: .whitespaces).isEmpty {
                results = try await searchSongs(query: title.trimmingCharacters(in: .whitespaces), limit: 25)
                withPreview = results.filter { ($0.previewUrl?.isEmpty == false) && $0.trackName != nil && $0.artistName != nil }
            }
            guard !withPreview.isEmpty else { return nil }
            let best = bestMatch(title: title, artist: artist, from: withPreview)
            let url = best.previewUrl
            if let url = url {
                cacheLock.lock()
                previewCache.setObject(url as NSString, forKey: cacheKey)
                cacheLock.unlock()
            }
            return url
        } catch {
            return nil
        }
    }
    
    /// Pick the result that best matches the requested title and artist (normalized comparison).
    private static func bestMatch(title: String, artist: String, from results: [ITunesSongResult]) -> ITunesSongResult {
        let nTitle = normalizeForMatch(title)
        let nArtist = normalizeForMatch(artist)
        return results.max(by: { a, b in
            scoreMatch(title: nTitle, artist: nArtist, track: a) < scoreMatch(title: nTitle, artist: nArtist, track: b)
        }) ?? results[0]
    }
    
    private static func normalizeForMatch(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "ft.", with: " ")
            .replacingOccurrences(of: "feat.", with: " ")
            .replacingOccurrences(of: "featuring", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private static func scoreMatch(title: String, artist: String, track: ITunesSongResult) -> Int {
        let t = normalizeForMatch(track.trackName ?? "")
        let a = normalizeForMatch(track.artistName ?? "")
        var score = 0
        if t.contains(title) || title.contains(t) { score += 10 }
        if a.contains(artist) || artist.contains(a) { score += 10 }
        if t == title { score += 5 }
        if a == artist { score += 5 }
        return score
    }
}
