import Foundation
import Combine
import Supabase

/// Unified Supabase service for database, auth, and storage operations
/// Uses official Supabase Swift SDK for auth (more reliable networking)
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    @Published private(set) var currentUser: SupabaseUser?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    
    private let baseURL: String
    private let anonKey: String
    private let supabaseClient: SupabaseClient
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private var accessToken: String?
    private var refreshToken: String?
    private let keychain = KeychainManager.shared
    
    private init() {
        self.baseURL = AppConfig.supabaseURL
        self.anonKey = AppConfig.supabaseAnonKey
        
        guard let url = URL(string: baseURL.hasPrefix("http") ? baseURL : "https://\(baseURL)") else {
            fatalError("Invalid Supabase URL")
        }
        self.supabaseClient = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatters = [
                ISO8601DateFormatter(),
                { () -> DateFormatter in
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                    return f
                }(),
                { () -> DateFormatter in
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return f
                }(),
                { () -> DateFormatter in
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    return f
                }()
            ]
            
            for formatter in formatters {
                if let iso = formatter as? ISO8601DateFormatter {
                    if let date = iso.date(from: dateString) { return date }
                } else if let df = formatter as? DateFormatter {
                    if let date = df.date(from: dateString) { return date }
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        loadCachedSessionFromSDK()
    }
    
    // MARK: - Authentication
    
    /// Sign up with email and password (uses Supabase SDK)
    func signUp(email: String, password: String, name: String) async throws -> SupabaseUser {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let response = try await supabaseClient.auth.signUp(
            email: email.lowercased(),
            password: password,
            data: ["name": .string(name)]
        )
        
        if let session = response.session {
            await syncSessionFromSDK(session)
        }
        
        let supabaseUser = mapToSupabaseUser(response.user, defaultName: name)
        if response.session != nil {
            let dbUser = DBUser(
                userId: supabaseUser.id,
                name: name,
                email: email.lowercased(),
                passwordHash: "",
                createdAt: Date()
            )
            try? await insertUser(dbUser)
            let couple = DBCouple(userId1: supabaseUser.id)
            _ = try? await insertCouple(couple)
        }
        
        return supabaseUser
    }
    
    /// Sign in with email and password (uses Supabase SDK)
    func signIn(email: String, password: String) async throws -> SupabaseUser {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let session = try await supabaseClient.auth.signIn(
            email: email.lowercased(),
            password: password
        )
        
        await syncSessionFromSDK(session)
        
        return mapToSupabaseUser(session.user, defaultName: nil)
    }
    
    /// Sign out (uses Supabase SDK)
    func signOut() async throws {
        try await supabaseClient.auth.signOut()
        accessToken = nil
        refreshToken = nil
        try? keychain.clearSession()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    /// Send password reset email (uses Supabase SDK)
    func sendPasswordReset(email: String) async throws {
        try await supabaseClient.auth.resetPasswordForEmail(email.lowercased())
    }
    
    /// Refresh access token (uses Supabase SDK)
    func refreshSession() async throws {
        _ = try await supabaseClient.auth.session
        if let session = supabaseClient.auth.currentSession {
            await syncSessionFromSDK(session)
        }
    }
    
    /// Handle auth callback from deep link (email confirmation)
    func handleAuthCallback(accessToken: String, refreshToken: String) async throws {
        try await supabaseClient.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        if let session = supabaseClient.auth.currentSession {
            await syncSessionFromSDK(session)
        }
    }
    
    @MainActor
    private func syncSessionFromSDK(_ session: Session) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        currentUser = mapToSupabaseUser(session.user, defaultName: nil)
        isAuthenticated = true
        
        let secureSession = SecureSession(
            userId: session.user.id.uuidString,
            email: session.user.email ?? "",
            idToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date().addingTimeInterval(session.expiresIn)
        )
        try? keychain.saveSession(secureSession)
    }
    
    private func mapToSupabaseUser(_ user: User, defaultName: String?) -> SupabaseUser {
        let name = user.userMetadata["name"]?.stringValue ?? defaultName
        return SupabaseUser(
            id: user.id,
            email: user.email,
            userMetadata: name.map { SupabaseUser.UserMetadata(name: $0) }
        )
    }
    
    /// Get current user (uses SDK session when available)
    func getCurrentUser() async throws -> SupabaseUser? {
        if let session = supabaseClient.auth.currentSession {
            return mapToSupabaseUser(session.user, defaultName: nil)
        }
        return currentUser
    }
    
    // MARK: - Database Operations
    
    // Users
    func insertUser(_ user: DBUser) async throws {
        _ = try await insert(table: "users", data: user)
    }
    
    func getUser(userId: UUID) async throws -> DBUser? {
        return try await selectSingle(table: "users", column: "user_id", value: userId.uuidString)
    }
    
    func getUserByEmail(email: String) async throws -> DBUser? {
        return try await selectSingle(table: "users", column: "email", value: email.lowercased())
    }
    
    func updateUser(_ user: DBUser) async throws {
        _ = try await update(table: "users", data: user, column: "user_id", value: user.userId.uuidString)
    }
    
    func deleteUser(userId: UUID) async throws {
        try await delete(table: "users", column: "user_id", value: userId.uuidString)
    }
    
    // Couples
    func insertCouple(_ couple: DBCouple) async throws -> DBCouple {
        return try await insert(table: "couples", data: couple)
    }
    
    func getCouple(coupleId: UUID) async throws -> DBCouple? {
        return try await selectSingle(table: "couples", column: "couple_id", value: coupleId.uuidString)
    }
    
    func getCoupleForUser(userId: UUID) async throws -> DBCouple? {
        let couples: [DBCouple] = try await select(
            table: "couples",
            query: "user_id_1=eq.\(userId.uuidString)"
        )
        if let couple = couples.first { return couple }
        
        let couplesAsUser2: [DBCouple] = try await select(
            table: "couples",
            query: "user_id_2=eq.\(userId.uuidString)"
        )
        return couplesAsUser2.first
    }
    
    // Preferences
    func savePreferences(_ preferences: DBPreferences) async throws -> DBPreferences {
        return try await upsert(table: "preferences", data: preferences, onConflict: "user_id")
    }
    
    func getPreferences(userId: UUID) async throws -> DBPreferences? {
        return try await selectSingle(table: "preferences", column: "user_id", value: userId.uuidString)
    }
    
    func getPreferences(coupleId: UUID) async throws -> DBPreferences? {
        return try await selectSingle(table: "preferences", column: "couple_id", value: coupleId.uuidString)
    }
    
    // Date Plans
    func createDatePlan(_ plan: DBDatePlan) async throws -> DBDatePlan {
        return try await insert(table: "date_plans", data: plan)
    }
    
    func getDatePlan(planId: UUID) async throws -> DBDatePlan? {
        return try await selectSingle(table: "date_plans", column: "plan_id", value: planId.uuidString)
    }
    
    func getDatePlans(coupleId: UUID) async throws -> [DBDatePlan] {
        return try await select(
            table: "date_plans",
            query: "couple_id=eq.\(coupleId.uuidString)&order=created_at.desc"
        )
    }
    
    func getDatePlans(coupleId: UUID, status: String) async throws -> [DBDatePlan] {
        return try await select(
            table: "date_plans",
            query: "couple_id=eq.\(coupleId.uuidString)&status=eq.\(status)&order=created_at.desc"
        )
    }
    
    func updateDatePlan(_ plan: DBDatePlan) async throws -> DBDatePlan {
        return try await update(table: "date_plans", data: plan, column: "plan_id", value: plan.planId.uuidString)
    }
    
    func deleteDatePlan(planId: UUID) async throws {
        try await delete(table: "date_plans", column: "plan_id", value: planId.uuidString)
    }
    
    // Date Memories
    func createMemory(_ memory: DBDateMemory) async throws -> DBDateMemory {
        return try await insert(table: "date_memories", data: memory)
    }
    
    func getMemory(memoryId: UUID) async throws -> DBDateMemory? {
        return try await selectSingle(table: "date_memories", column: "memory_id", value: memoryId.uuidString)
    }
    
    func getMemories(coupleId: UUID) async throws -> [DBDateMemory] {
        return try await select(
            table: "date_memories",
            query: "couple_id=eq.\(coupleId.uuidString)&order=created_at.desc"
        )
    }
    
    func getMemory(planId: UUID) async throws -> DBDateMemory? {
        return try await selectSingle(table: "date_memories", column: "plan_id", value: planId.uuidString)
    }
    
    func updateMemory(_ memory: DBDateMemory) async throws -> DBDateMemory {
        return try await update(table: "date_memories", data: memory, column: "memory_id", value: memory.memoryId.uuidString)
    }
    
    func deleteMemory(memoryId: UUID) async throws {
        try await delete(table: "date_memories", column: "memory_id", value: memoryId.uuidString)
    }
    
    // Gift Suggestions
    func createGiftSuggestion(_ gift: DBGiftSuggestion) async throws -> DBGiftSuggestion {
        return try await insert(table: "gift_suggestions", data: gift)
    }
    
    func getFreshGiftSuggestions(coupleId: UUID) async throws -> [DBGiftSuggestion] {
        return try await select(
            table: "gift_suggestions",
            query: "couple_id=eq.\(coupleId.uuidString)&purchased=eq.false&or=(liked.is.null,liked.eq.true)&order=created_at.desc"
        )
    }
    
    func getLikedGifts(coupleId: UUID) async throws -> [DBGiftSuggestion] {
        return try await select(
            table: "gift_suggestions",
            query: "couple_id=eq.\(coupleId.uuidString)&liked=eq.true&order=created_at.desc"
        )
    }
    
    func updateGiftSuggestion(_ gift: DBGiftSuggestion) async throws -> DBGiftSuggestion {
        return try await update(table: "gift_suggestions", data: gift, column: "gift_id", value: gift.giftId.uuidString)
    }
    
    func likeGift(giftId: UUID) async throws {
        try await patch(table: "gift_suggestions", column: "gift_id", value: giftId.uuidString, updates: ["liked": true])
    }
    
    func skipGift(giftId: UUID) async throws {
        try await patch(table: "gift_suggestions", column: "gift_id", value: giftId.uuidString, updates: ["liked": false])
    }
    
    func markGiftPurchased(giftId: UUID, forPlanId: UUID) async throws {
        try await patch(
            table: "gift_suggestions",
            column: "gift_id",
            value: giftId.uuidString,
            updates: [
                "purchased": true,
                "purchased_at": ISO8601DateFormatter().string(from: Date()),
                "purchased_for_plan_id": forPlanId.uuidString
            ]
        )
    }
    
    // MARK: - Generate More Gifts (Edge Function)
    /// Calls the generate-more-gifts edge function for personalized, unique gift suggestions.
    func generateMoreGifts(
        occasion: String? = nil,
        budget: String? = nil,
        interests: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        planTitle: String? = nil,
        existingGiftNames: [String] = [],
        count: Int = 6,
        recipient: String? = nil,
        giftStyle: [String]? = nil
    ) async throws -> [GiftSuggestion] {
        let urlString = baseURL.hasSuffix("/") ? "\(baseURL)functions/v1/generate-more-gifts" : "\(baseURL)/functions/v1/generate-more-gifts"
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: Any] = [
            "occasion": occasion ?? "just-because",
            "priceRange": budget ?? "any",
            "interests": interests ?? "",
            "partnerDescription": notes ?? "",
            "location": location ?? "",
            "planTitle": planTitle ?? "",
            "existingGifts": existingGiftNames.map { ["name": $0] },
            "count": count
        ]
        if let recipient = recipient, !recipient.isEmpty {
            body["giftRecipient"] = recipient
        }
        if let style = giftStyle, !style.isEmpty {
            body["giftStyle"] = style
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        if http.statusCode != 200 {
            let errorMessage = (try? JSONDecoder().decode(GenerateGiftsErrorResponse.self, from: data))?.error ?? "Request failed"
            if http.statusCode == 429 { throw SupabaseError.authFailed("Rate limit. Try again in a moment.") }
            if http.statusCode == 503 || http.statusCode == 502 { throw SupabaseError.authFailed("Gift service temporarily unavailable.") }
            throw SupabaseError.authFailed(errorMessage)
        }
        let decoded = try decoder.decode(GenerateGiftsAPIResponse.self, from: data)
        return decoded.gifts.map { api in
            GiftSuggestion(
                name: api.name,
                description: api.description ?? "",
                priceRange: api.priceRange ?? "",
                whereToBuy: api.whereToBuy ?? "",
                purchaseUrl: api.purchaseUrl,
                whyItFits: api.whyItFits ?? "",
                emoji: api.emoji ?? "🎁",
                storeSearchQuery: nil,
                imageUrl: api.imageUrl
            )
        }
    }
    
    // MARK: - Generate Playlist (Edge Function – fresh AI-generated songs)
    struct GeneratePlaylistSongItem {
        let title: String
        let artist: String
        let year: Int?
        let genre: String?
    }
    
    struct GeneratePlaylistResult {
        let playlistName: String
        let vibeDescription: String
        let songs: [GeneratePlaylistSongItem]
    }
    
    /// Calls the generate-playlist edge function for fresh, AI-generated song suggestions.
    func generatePlaylist(vibe: String, datePlanTitle: String, stops: [(name: String, venueType: String)]? = nil) async throws -> GeneratePlaylistResult {
        let urlString = baseURL.hasSuffix("/") ? "\(baseURL)functions/v1/generate-playlist" : "\(baseURL)/functions/v1/generate-playlist"
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: Any] = [
            "vibe": vibe,
            "datePlanTitle": datePlanTitle
        ]
        if let stops = stops, !stops.isEmpty {
            body["stops"] = stops.map { ["name": $0.name, "venueType": $0.venueType] }
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        if http.statusCode != 200 {
            let errorMessage = (try? JSONDecoder().decode(GenerateGiftsErrorResponse.self, from: data))?.error ?? "Playlist generation failed"
            if http.statusCode == 429 { throw SupabaseError.authFailed("Rate limit. Try again in a moment.") }
            if http.statusCode == 503 || http.statusCode == 502 { throw SupabaseError.authFailed("Playlist service temporarily unavailable.") }
            throw SupabaseError.authFailed(errorMessage)
        }
        let decoded = try decoder.decode(GeneratePlaylistAPIResponse.self, from: data)
        let songs = decoded.songs
            .compactMap { s -> GeneratePlaylistSongItem? in
                let t = s.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let a = s.artist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !t.isEmpty, !a.isEmpty else { return nil }
                return GeneratePlaylistSongItem(title: t, artist: a, year: s.year, genre: s.genre)
            }
        return GeneratePlaylistResult(
            playlistName: decoded.playlistName ?? "\(vibe.capitalized) Playlist",
            vibeDescription: decoded.vibeDescription ?? vibe,
            songs: songs
        )
    }
    
    // Playlists
    func createPlaylist(_ playlist: DBPlaylist) async throws -> DBPlaylist {
        return try await insert(table: "playlists", data: playlist)
    }
    
    func getPlaylist(planId: UUID) async throws -> DBPlaylist? {
        return try await selectSingle(table: "playlists", column: "plan_id", value: planId.uuidString)
    }
    
    func getPlaylists(coupleId: UUID) async throws -> [DBPlaylist] {
        return try await select(
            table: "playlists",
            query: "couple_id=eq.\(coupleId.uuidString)&order=generated_at.desc"
        )
    }
    
    func updatePlaylist(_ playlist: DBPlaylist) async throws -> DBPlaylist {
        return try await update(table: "playlists", data: playlist, column: "playlist_id", value: playlist.playlistId.uuidString)
    }
    
    // MARK: - Storage Operations
    
    /// Upload an image to Supabase Storage
    func uploadImage(data: Data, bucket: String = "memories", path: String) async throws -> String {
        guard let token = accessToken else {
            throw SupabaseError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/storage/v1/object/\(bucket)/\(path)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode == 400 {
            request.httpMethod = "PUT"
            let (_, updateResponse) = try await session.data(for: request)
            guard let updateHttpResponse = updateResponse as? HTTPURLResponse,
                  (200...299).contains(updateHttpResponse.statusCode) else {
                throw SupabaseError.uploadFailed
            }
        } else if !(200...299).contains(httpResponse.statusCode) {
            throw SupabaseError.uploadFailed
        }
        
        return path
    }
    
    /// Generate a public URL for an image
    func getPublicURL(bucket: String = "memories", path: String) -> URL {
        return URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)")!
    }
    
    /// Generate a signed URL for private image access
    func getSignedURL(bucket: String = "memories", path: String, expiresIn: Int = 3600) async throws -> URL {
        guard let token = accessToken else {
            throw SupabaseError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/storage/v1/object/sign/\(bucket)/\(path)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["expiresIn": expiresIn])
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let signedURL = json["signedURL"] as? String else {
            throw SupabaseError.invalidResponse
        }
        
        return URL(string: "\(baseURL)\(signedURL)")!
    }
    
    /// Delete an image from storage
    func deleteImage(bucket: String = "memories", path: String) async throws {
        guard let token = accessToken else {
            throw SupabaseError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/storage/v1/object/\(bucket)/\(path)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.deleteFailed
        }
    }
    
    // MARK: - Generic Database Operations
    
    private func select<T: Decodable>(table: String, query: String) async throws -> [T] {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)?\(query)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.queryFailed
        }
        
        return try decoder.decode([T].self, from: data)
    }
    
    private func selectSingle<T: Decodable>(table: String, column: String, value: String) async throws -> T? {
        let results: [T] = try await select(table: table, query: "\(column)=eq.\(value)&limit=1")
        return results.first
    }
    
    private func insert<T: Codable>(table: String, data: T) async throws -> T {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.insertFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            throw SupabaseError.insertFailed
        }
        return result
    }
    
    private func insert<T: Encodable>(table: String, data: T) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.httpBody = try encoder.encode(data)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.insertFailed
        }
    }
    
    private func update<T: Codable>(table: String, data: T, column: String, value: String) async throws -> T {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)?\(column)=eq.\(value)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addHeaders(to: &request)
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.updateFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            throw SupabaseError.updateFailed
        }
        return result
    }
    
    private func upsert<T: Codable>(table: String, data: T, onConflict: String) async throws -> T {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.addValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.upsertFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            throw SupabaseError.upsertFailed
        }
        return result
    }
    
    private func patch(table: String, column: String, value: String, updates: [String: Any]) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)?\(column)=eq.\(value)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addHeaders(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: updates)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.updateFailed
        }
    }
    
    private func delete(table: String, column: String, value: String) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)?\(column)=eq.\(value)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.deleteFailed
        }
    }
    
    // MARK: - Helpers
    
    private func addHeaders(to request: inout URLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func authRequest<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        let base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else {
            throw SupabaseError.authFailed("Server configuration missing. Please rebuild the app.")
        }
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        guard let url = URL(string: "\(cleanBase)\(endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)")") else {
            throw SupabaseError.authFailed("Invalid server configuration. Please check your connection.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error_description"] as? String ?? errorJson["msg"] as? String ?? errorJson["message"] as? String {
                    throw SupabaseError.authFailed(errorMessage)
                }
                throw SupabaseError.authFailed("Authentication failed with status \(httpResponse.statusCode)")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as SupabaseError {
            throw error
        } catch let error as URLError where error.code == .cannotFindHost {
            throw SupabaseError.authFailed("Cannot reach server. Please check your internet connection.")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw SupabaseError.authFailed("No internet connection. Please connect and try again.")
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    @MainActor
    private func handleAuthResponse(_ response: AuthResponse) {
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        currentUser = response.user
        isAuthenticated = response.user != nil
        
        if let user = response.user,
           let access = response.accessToken,
           let refresh = response.refreshToken,
           let expiresIn = response.expiresIn {
            let session = SecureSession(
                userId: user.id.uuidString,
                email: user.email ?? "",
                idToken: access,
                refreshToken: refresh,
                expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
            )
            try? keychain.saveSession(session)
        }
    }
    
    private func loadCachedSessionFromSDK() {
        Task {
            do {
                let session = try await supabaseClient.auth.session
                await MainActor.run {
                    syncSessionFromSDK(session)
                }
            } catch {
                // No valid session - try our keychain as fallback and restore into SDK so API calls work
                do {
                    guard let session = try keychain.getSession(), !session.isExpired,
                          let access = session.idToken, let refresh = session.refreshToken else {
                        return
                    }
                    try await supabaseClient.auth.setSession(accessToken: access, refreshToken: refresh)
                    if let s = supabaseClient.auth.currentSession {
                        await MainActor.run {
                            syncSessionFromSDK(s)
                        }
                    } else {
                        await MainActor.run {
                            accessToken = access
                            refreshToken = refresh
                            isAuthenticated = true
                            if let userId = UUID(uuidString: session.userId) {
                                currentUser = SupabaseUser(
                                    id: userId,
                                    email: session.email,
                                    userMetadata: nil
                                )
                            }
                        }
                    }
                } catch {
                    print("Failed to load cached session: \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func hasCachedSession() -> Bool {
        do {
            if let session = try keychain.getSession() {
                return !session.isExpired
            }
        } catch {}
        return false
    }
    
    var currentAuthToken: String? {
        accessToken
    }
}

// MARK: - Supabase Models

struct SupabaseUser: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String?
    let userMetadata: UserMetadata?
    
    var name: String? {
        userMetadata?.name
    }
    
    var firstName: String {
        guard let name = name else { return "" }
        return name.components(separatedBy: " ").first ?? name
    }
    
    var lastName: String {
        guard let name = name else { return "" }
        let components = name.components(separatedBy: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
    }
    
    struct UserMetadata: Codable, Equatable {
        let name: String?
    }
}

struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: SupabaseUser?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

// MARK: - Generate Gifts API

private struct GenerateGiftsAPIResponse: Decodable {
    let gifts: [GenerateGiftsAPIItem]
}

private struct GenerateGiftsAPIItem: Decodable {
    let name: String
    let description: String?
    let priceRange: String?
    let whereToBuy: String?
    let purchaseUrl: String?
    let whyItFits: String?
    let emoji: String?
    let imageUrl: String?
}

private struct GenerateGiftsErrorResponse: Decodable {
    let error: String?
}

private struct GeneratePlaylistAPIResponse: Decodable {
    let songs: [GeneratePlaylistAPISong]
    let playlistName: String?
    let vibeDescription: String?
}

private struct GeneratePlaylistAPISong: Decodable {
    let title: String?
    let artist: String?
    let year: Int?
    let genre: String?
}

// MARK: - Supabase Errors

enum SupabaseError: LocalizedError {
    case invalidResponse
    case unauthorized
    case authFailed(String)
    case sessionExpired
    case queryFailed
    case insertFailed
    case updateFailed
    case upsertFailed
    case deleteFailed
    case uploadFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please sign in again"
        case .authFailed(let message):
            return message
        case .sessionExpired:
            return "Session expired. Please sign in again"
        case .queryFailed:
            return "Failed to fetch data"
        case .insertFailed:
            return "Failed to save data"
        case .updateFailed:
            return "Failed to update data"
        case .upsertFailed:
            return "Failed to save data"
        case .deleteFailed:
            return "Failed to delete data"
        case .uploadFailed:
            return "Failed to upload file"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
