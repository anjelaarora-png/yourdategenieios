import Foundation
import Combine
import Supabase
import UIKit

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
            AppLogger.error("Invalid Supabase URL: \(baseURL)", category: .network)
            assertionFailure("Invalid Supabase URL '\(baseURL)' — check Config.swift / Secrets.xcconfig")
            // Fall back to a no-op placeholder so the app doesn't crash on init
            self.supabaseClient = SupabaseClient(supabaseURL: URL(string: "https://localhost")!, supabaseKey: "")
            let fallbackConfig = URLSessionConfiguration.ephemeral
            self.session = URLSession(configuration: fallbackConfig)
            self.decoder = JSONDecoder()
            self.encoder = JSONEncoder()
            return
        }
        // Opt in to upcoming default: emit cached session first, then refresh (see supabase-swift PR #822).
        self.supabaseClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
            )
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        
        // Single strategy for every `/rest/v1` table row (`users`, `couples`, `preferences`, `date_plans`, `playlists`, etc.).
        self.decoder = JSONDecoder.supabasePostgresREST()
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        loadCachedSessionFromSDK()
    }

    /// `SecItemAdd` / `securityd` can block the main thread for hundreds of ms; persist session off the UI thread.
    private func persistSessionToKeychain(_ session: SecureSession) {
        Task.detached(priority: .utility) {
            try? KeychainManager.shared.saveSession(session)
        }
    }

    private func clearSessionKeychainAsync() {
        Task.detached(priority: .utility) {
            try? KeychainManager.shared.clearSession()
        }
    }
    
    // MARK: - Authentication
    
    /// Email confirmation links must open the app with tokens (`yourdategenie://auth-callback`). Add this URL to Supabase Auth redirect allowlist.
    private static let signUpEmailRedirectURL = URL(string: "yourdategenie://auth-callback")
    
    /// True when the account has no email (e.g. phone-only) or the email is confirmed.
    private static func hasConfirmedEmailIfNeeded(user: User) -> Bool {
        if user.email == nil { return true }
        return user.emailConfirmedAt != nil
    }
    
    /// Sign up with email and password (uses Supabase SDK)
    func signUp(email: String, password: String, name: String) async throws -> EmailPasswordSignUpResult {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let response = try await supabaseClient.auth.signUp(
            email: email.lowercased(),
            password: password,
            data: ["name": .string(name)],
            redirectTo: Self.signUpEmailRedirectURL
        )
        
        let authUser = response.user
        let requiresEmailVerification = authUser.email != nil && authUser.emailConfirmedAt == nil
        
        if let session = response.session {
            if Self.hasConfirmedEmailIfNeeded(user: session.user) {
                await syncSessionFromSDK(session)
            } else {
                try? await supabaseClient.auth.signOut()
                await MainActor.run {
                    accessToken = nil
                    refreshToken = nil
                    clearSessionKeychainAsync()
                    currentUser = nil
                    isAuthenticated = false
                }
            }
        }
        
        let supabaseUser = mapToSupabaseUser(authUser, defaultName: name)
        if let session = response.session, Self.hasConfirmedEmailIfNeeded(user: session.user) {
            try await ensureUserAndCoupleIfMissing(
                userId: supabaseUser.id,
                email: email.lowercased(),
                name: name.isEmpty ? (email.split(separator: "@").first.map { String($0) } ?? "User") : name
            )
        }
        
        return EmailPasswordSignUpResult(user: supabaseUser, requiresEmailVerification: requiresEmailVerification)
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
        clearSessionKeychainAsync()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    /// Send password reset email (uses Supabase SDK)
    func sendPasswordReset(email: String) async throws {
        try await supabaseClient.auth.resetPasswordForEmail(email.lowercased())
    }

    /// Resend sign-up confirmation email for accounts waiting on email verification.
    func resendSignUpConfirmation(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            throw SupabaseError.authFailed("Please enter a valid email address.")
        }

        let base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        guard let url = URL(string: "\(cleanBase)/auth/v1/resend") else {
            throw SupabaseError.authFailed("Invalid server configuration. Please check your connection.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")

        var payload: [String: Any] = [
            "type": "signup",
            "email": normalizedEmail
        ]
        if let redirect = Self.signUpEmailRedirectURL?.absoluteString {
            payload["options"] = ["email_redirect_to": redirect]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error_description"] as? String ?? errorJson["msg"] as? String ?? errorJson["message"] as? String {
                throw SupabaseError.authFailed(errorMessage)
            }
            throw SupabaseError.authFailed("Unable to resend confirmation email right now.")
        }
    }
    
    /// Refresh access token (uses Supabase SDK)
    func refreshSession() async throws {
        _ = try await supabaseClient.auth.session
        if let session = supabaseClient.auth.currentSession {
            await syncSessionFromSDK(session)
        }
    }

    /// Fetches `auth.session` from the Supabase Swift SDK, syncs JWT for REST calls, returns `session.user.id`.
    func syncAuthSessionAndReturnUserId() async throws -> UUID {
        let session = try await supabaseClient.auth.session
        await MainActor.run {
            syncSessionFromSDK(session)
        }
        return session.user.id
    }

    /// Syncs JWT, ensures `public.users` + `public.couples` exist, returns `couple_id` for playlist/date-plan writes.
    func resolveCoupleIdForCurrentUser() async throws -> UUID {
        let userId = try await syncAuthSessionAndReturnUserId()
        await MainActor.run {
            if UserProfileManager.shared.userId == nil {
                UserProfileManager.shared.userId = userId
            }
        }
        var coupleId = await MainActor.run { UserProfileManager.shared.coupleId }
        if coupleId == nil {
            coupleId = try await getCoupleForUser(userId: userId)?.coupleId
            if let cid = coupleId {
                await MainActor.run { UserProfileManager.shared.coupleId = cid }
            }
        }
        if coupleId == nil {
            let context = await MainActor.run { () -> (email: String, name: String) in
                let em = UserProfileManager.shared.currentUser?.email ?? self.currentUser?.email ?? ""
                let fromProfile = UserProfileManager.shared.currentUser?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !fromProfile.isEmpty { return (em, fromProfile) }
                if let n = self.currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
                    return (em, n)
                }
                let fallback: String
                if !em.isEmpty {
                    fallback = em.split(separator: "@").first.map { String($0) } ?? "User"
                } else {
                    fallback = "User"
                }
                return (em, fallback)
            }
            try await ensureUserAndCoupleIfMissing(
                userId: userId,
                email: context.email.trimmingCharacters(in: .whitespaces).lowercased(),
                name: context.name
            )
            coupleId = try await getCoupleForUser(userId: userId)?.coupleId
            if let cid = coupleId {
                await MainActor.run { UserProfileManager.shared.coupleId = cid }
            }
        }
        guard let coupleId = coupleId else {
            throw SupabaseError.queryFailed
        }
        return coupleId
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
        guard Self.hasConfirmedEmailIfNeeded(user: session.user) else {
            Task {
                try? await supabaseClient.auth.signOut()
                await MainActor.run {
                    self.accessToken = nil
                    self.refreshToken = nil
                    self.clearSessionKeychainAsync()
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
            return
        }
        // With emitLocalSessionAsInitialSession, the first session may be expired until refresh runs.
        if session.isExpired {
            Task {
                do {
                    let valid = try await supabaseClient.auth.session
                    await MainActor.run {
                        syncSessionFromSDK(valid)
                    }
                } catch {
                    await MainActor.run {
                        self.accessToken = nil
                        self.refreshToken = nil
                        self.clearSessionKeychainAsync()
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            }
            return
        }
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
        persistSessionToKeychain(secureSession)
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

    /// Calls the `delete-account` Edge Function which uses the service role to permanently
    /// remove the auth.users entry (and cascade-deletes all user data via FK constraints).
    func deleteAccountViaEdgeFunction() async throws {
        try? await refreshRestAuthFromSDK()
        let urlString = baseURL.hasSuffix("/")
            ? "\(baseURL)functions/v1/delete-account"
            : "\(baseURL)/functions/v1/delete-account"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
    }
    
    /// Creates `public.users` and a solo `public.couples` row if missing (trigger may already have created them).
    func ensureUserAndCoupleIfMissing(userId: UUID, email: String, name: String) async throws {
        if try await getUser(userId: userId) == nil {
            let dbUser = DBUser(userId: userId, name: name, email: email, passwordHash: "", createdAt: Date())
            do {
                try await insertUser(dbUser)
            } catch {
                if try await getUser(userId: userId) == nil { throw error }
            }
        }
        if try await getCoupleForUser(userId: userId) == nil {
            let couple = DBCouple(userId1: userId)
            do {
                _ = try await insertCouple(couple)
            } catch {
                if try await getCoupleForUser(userId: userId) == nil { throw error }
            }
        }
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

    func getUserIosSync(userId: UUID) async throws -> DBUserIosSyncPayload? {
        try await selectSingle(table: "user_ios_sync_payload", column: "user_id", value: userId.uuidString)
    }

    func upsertUserIosSync(_ payload: DBUserIosSyncPayload) async throws -> DBUserIosSyncPayload {
        try await upsert(table: "user_ios_sync_payload", data: payload, onConflict: "user_id")
    }
    
    // Date Plans
    func createDatePlan(_ plan: DBDatePlan) async throws -> DBDatePlan {
        return try await insert(table: "date_plans", data: plan)
    }
    
    func getDatePlan(planId: UUID) async throws -> DBDatePlan? {
        return try await selectSingle(table: "date_plans", column: "id", value: planId.uuidString)
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

    /// Fetch all plans for a solo user (no couple) scoped by user_id only.
    func getDatePlans(userId: UUID) async throws -> [DBDatePlan] {
        return try await select(
            table: "date_plans",
            query: "user_id=eq.\(userId.uuidString)&order=created_at.desc"
        )
    }
    
    func updateDatePlan(_ plan: DBDatePlan) async throws -> DBDatePlan {
        return try await update(table: "date_plans", data: plan, column: "id", value: plan.id.uuidString)
    }

    /// Insert or update by primary key (`id`) in one round trip — avoids races with cloud sync and duplicate-key retries.
    func upsertDatePlan(_ plan: DBDatePlan) async throws -> DBDatePlan {
        try await upsert(table: "date_plans", data: plan, onConflict: "id")
    }
    
    func deleteDatePlan(planId: UUID) async throws {
        try await delete(table: "date_plans", column: "id", value: planId.uuidString)
    }

    // MARK: - Experiences Waiting (unsaved generated plans; separate from `date_plans`)

    func getExperiencesWaiting(coupleId: UUID) async throws -> [DBExperiencesWaitingRow] {
        try await select(
            table: "experiences_waiting",
            query: "couple_id=eq.\(coupleId.uuidString)&order=updated_at.desc"
        )
    }

    func getExperiencesWaiting(userId: UUID) async throws -> [DBExperiencesWaitingRow] {
        try await select(
            table: "experiences_waiting",
            query: "user_id=eq.\(userId.uuidString)&order=updated_at.desc"
        )
    }

    func upsertExperiencesWaiting(_ row: DBExperiencesWaitingRow) async throws -> DBExperiencesWaitingRow {
        try await upsert(table: "experiences_waiting", data: row, onConflict: "id")
    }

    func deleteExperiencesWaiting(planId: UUID) async throws {
        try await delete(table: "experiences_waiting", column: "id", value: planId.uuidString)
    }

    // MARK: - Partner Sessions (Plan Together)

    /// Create or update a partner session. If session_id exists, updates; otherwise inserts.
    func createOrUpdatePartnerSession(sessionId: String, inviterName: String?, inviterUserId: UUID?, inviterData: QuestionnaireData?, inviterPlannedDates: [DBProposedDateTime]?, notes: String?) async throws -> DBPartnerSession {
        let enc = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionId
        if let existing = try await getPartnerSession(sessionId: sessionId) {
            var updated = existing
            if inviterName != nil { updated.inviterName = inviterName }
            if inviterUserId != nil { updated.inviterUserId = inviterUserId }
            if inviterData != nil { updated.inviterData = inviterData }
            if inviterPlannedDates != nil { updated.inviterPlannedDates = inviterPlannedDates }
            if notes != nil { updated.notes = notes }
            updated.updatedAt = Date()
            return try await update(table: "partner_sessions", data: updated, column: "session_id", value: enc)
        }
        let row = DBPartnerSession(
            id: nil,
            sessionId: sessionId,
            inviterName: inviterName,
            inviterUserId: inviterUserId,
            inviterData: inviterData,
            partnerData: nil,
            inviterPlannedDates: inviterPlannedDates,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )
        return try await insert(table: "partner_sessions", data: row)
    }

    func getPartnerSession(sessionId: String) async throws -> DBPartnerSession? {
        let encoded = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionId
        return try await selectSingle(table: "partner_sessions", column: "session_id", value: encoded)
    }

    /// List partner sessions where the given user is the inviter (for Pending / Past in Plan Together).
    func listPartnerSessions(inviterUserId: UUID) async throws -> [DBPartnerSession] {
        let list: [DBPartnerSession] = try await select(
            table: "partner_sessions",
            query: "inviter_user_id=eq.\(inviterUserId.uuidString)&order=updated_at.desc"
        )
        return list
    }

    /// Cancel/delete a partner session (inviter cancels invite). Removes the row so it no longer appears in Pending.
    func deletePartnerSession(sessionId: String) async throws {
        let encoded = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionId
        try await delete(table: "partner_sessions", column: "session_id", value: encoded)
    }

    /// Partner submits their questionnaire data (call from partner device).
    func submitPartnerSessionPartnerData(sessionId: String, partnerData: QuestionnaireData) async throws {
        guard let session: DBPartnerSession = try await getPartnerSession(sessionId: sessionId) else { return }
        var updated = session
        updated.partnerData = partnerData
        updated.updatedAt = Date()
        _ = try await update(table: "partner_sessions", data: updated, column: "session_id", value: sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionId)
    }

    /// Inviter updates their data (e.g. after "Fill my preferences").
    func updatePartnerSessionInviterData(sessionId: String, inviterData: QuestionnaireData?, inviterPlannedDates: [DBProposedDateTime]?, notes: String?) async throws {
        guard let session: DBPartnerSession = try await getPartnerSession(sessionId: sessionId) else { return }
        var updated = session
        if let d = inviterData { updated.inviterData = d }
        if let p = inviterPlannedDates { updated.inviterPlannedDates = p }
        if let n = notes { updated.notes = n }
        updated.updatedAt = Date()
        let enc = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionId
        _ = try await update(table: "partner_sessions", data: updated, column: "session_id", value: enc)
    }

    /// Saves the 3 generated plans and returns the created rows (for ranking later).
    func savePartnerSessionPlans(partnerSessionId: UUID, plans: [DatePlan]) async throws -> [DBPartnerSessionPlan] {
        var result: [DBPartnerSessionPlan] = []
        for (index, plan) in plans.prefix(3).enumerated() {
            let row = DBPartnerSessionPlan(
                id: UUID(),
                partnerSessionId: partnerSessionId,
                planIndex: index + 1,
                planJson: plan,
                inviterRank: nil,
                partnerRank: nil,
                createdAt: Date()
            )
            let inserted: DBPartnerSessionPlan = try await insert(table: "partner_session_plans", data: row)
            result.append(inserted)
        }
        return result.sorted(by: { $0.planIndex < $1.planIndex })
    }

    func getPartnerSessionPlans(partnerSessionId: UUID) async throws -> [DBPartnerSessionPlan] {
        let list: [DBPartnerSessionPlan] = try await select(
            table: "partner_session_plans",
            query: "partner_session_id=eq.\(partnerSessionId.uuidString)&order=plan_index.asc"
        )
        return list
    }

    func updatePartnerSessionPlanRank(planId: UUID, inviterRank: Int?, partnerRank: Int?) async throws {
        var updates: [String: Any] = [:]
        if let r = inviterRank { updates["inviter_rank"] = r }
        if let r = partnerRank { updates["partner_rank"] = r }
        guard !updates.isEmpty else { return }
        try await patch(table: "partner_session_plans", column: "id", value: planId.uuidString, updates: updates)
    }

    // MARK: - Phase Management

    /// Updates the `phase` column on `partner_sessions` and writes a history row.
    func updatePartnerSessionPhase(sessionId: String, phase: PlanPhase, triggeredBy: String? = nil) async throws {
        let updates: [String: Any] = ["phase": phase.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())]
        try await patch(table: "partner_sessions", column: "session_id", value: sessionId, updates: updates)
        // Also append to audit log if we have a rowId
        if let session = try? await getPartnerSession(sessionId: sessionId), let rowId = session.id {
            let historyRow: [String: Any] = [
                "id": UUID().uuidString,
                "partner_session_id": rowId.uuidString,
                "phase": phase.rawValue,
                "triggered_by": triggeredBy ?? "system",
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]
            _ = try? await rawInsert(table: "plan_phase_history", body: historyRow)
        }
    }

    /// Updates partner_user_id and partner_name when a partner joins.
    func updatePartnerSessionPartnerIdentity(sessionId: String, partnerUserId: UUID?, partnerName: String?) async throws {
        var updates: [String: Any] = ["updated_at": ISO8601DateFormatter().string(from: Date())]
        if let uid = partnerUserId { updates["partner_user_id"] = uid.uuidString }
        if let name = partnerName { updates["partner_name"] = name }
        guard !updates.isEmpty else { return }
        try await patch(table: "partner_sessions", column: "session_id", value: sessionId, updates: updates)
    }

    // MARK: - Option Rankings

    /// Upserts a user's private ranking list for a session (one row per role per session).
    func upsertOptionRanking(partnerSessionId: UUID, role: PartnerRole, rankings: [RankEntry], userId: UUID?) async throws -> DBOptionRanking {
        let row = DBOptionRanking(
            id: UUID(),
            partnerSessionId: partnerSessionId,
            userId: userId,
            role: role.rawValue,
            rankings: rankings,
            submittedAt: Date()
        )
        return try await upsert(table: "option_rankings", data: row, onConflict: "partner_session_id,role")
    }

    /// Returns all ranking rows for a session (0, 1, or 2 rows).
    func getOptionRankings(partnerSessionId: UUID) async throws -> [DBOptionRanking] {
        let list: [DBOptionRanking] = try await select(
            table: "option_rankings",
            query: "partner_session_id=eq.\(partnerSessionId.uuidString)"
        )
        return list
    }

    // MARK: - Final Option Selection

    /// Inserts or updates the winner record for a session.
    func saveFinalOptionSelection(_ selection: DBFinalOptionSelection) async throws -> DBFinalOptionSelection {
        return try await upsert(table: "final_option_selection", data: selection, onConflict: "partner_session_id")
    }

    func getFinalOptionSelection(partnerSessionId: UUID) async throws -> DBFinalOptionSelection? {
        return try await selectSingle(
            table: "final_option_selection",
            column: "partner_session_id",
            value: partnerSessionId.uuidString
        )
    }

    // MARK: - Notification Events

    /// Writes a notification event row for a user.
    func writeNotificationEvent(userId: UUID?, partnerSessionId: UUID?, type: String, title: String, body: String) async throws {
        let row = DBNotificationEvent(
            id: UUID(),
            userId: userId,
            partnerSessionId: partnerSessionId,
            type: type,
            title: title,
            body: body,
            readAt: nil,
            createdAt: Date()
        )
        _ = try await insert(table: "notification_events", data: row) as DBNotificationEvent
    }

    func getUnreadNotificationEvents(userId: UUID) async throws -> [DBNotificationEvent] {
        let list: [DBNotificationEvent] = try await select(
            table: "notification_events",
            query: "user_id=eq.\(userId.uuidString)&read_at=is.null&order=created_at.desc"
        )
        return list
    }

    func markNotificationEventRead(id: UUID) async throws {
        let updates: [String: Any] = ["read_at": ISO8601DateFormatter().string(from: Date())]
        try await patch(table: "notification_events", column: "id", value: id.uuidString, updates: updates)
    }

    // MARK: - Save partner session plans (up to 5)

    /// Saves up to 5 generated plans and returns the created rows (for ranking later).
    func savePartnerSessionPlansV2(partnerSessionId: UUID, plans: [DatePlan]) async throws -> [DBPartnerSessionPlan] {
        var result: [DBPartnerSessionPlan] = []
        for (index, plan) in plans.prefix(5).enumerated() {
            let row = DBPartnerSessionPlan(
                id: UUID(),
                partnerSessionId: partnerSessionId,
                planIndex: index + 1,
                planJson: plan,
                inviterRank: nil,
                partnerRank: nil,
                createdAt: Date()
            )
            let inserted: DBPartnerSessionPlan = try await insert(table: "partner_session_plans", data: row)
            result.append(inserted)
        }
        return result.sorted(by: { $0.planIndex < $1.planIndex })
    }

    // MARK: - Raw insert helper (for ad-hoc JSON payloads like phase history)

    @discardableResult
    private func rawInsert(table: String, body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: req)
        return data
    }

    /// Legacy Supabase **Storage** bucket (lowercase) for `object path` values in `date_memories.image_url`. Postgres table is always `date_memories`.
    static let dateMemoriesStorageBucket = "date-memories"
    
    // Date Memories — Postgres table `public.date_memories` (not the Storage bucket name `Memories`).
    func createMemory(_ memory: DBDateMemory) async throws -> DBDateMemory {
        return try await insert(table: "date_memories", data: memory)
    }
    
    func getMemory(memoryId: UUID) async throws -> DBDateMemory? {
        return try await selectSingle(table: "date_memories", column: "id", value: memoryId.uuidString)
    }
    
    func getMemories(userId: UUID) async throws -> [DBDateMemory] {
        return try await select(
            table: "date_memories",
            query: "user_id=eq.\(userId.uuidString)&order=taken_at.desc"
        )
    }
    
    func getMemory(planId: UUID) async throws -> DBDateMemory? {
        return try await selectSingle(table: "date_memories", column: "date_plan_id", value: planId.uuidString)
    }
    
    func updateMemory(_ memory: DBDateMemory) async throws -> DBDateMemory {
        return try await update(table: "date_memories", data: memory, column: "id", value: memory.id.uuidString)
    }
    
    func deleteMemory(memoryId: UUID) async throws {
        try await delete(table: "date_memories", column: "id", value: memoryId.uuidString)
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
    
    // MARK: - Standalone Gift Finder rows (plan_id = NULL, owned by user)

    /// Upsert a Gift Finder gift (no plan context) using `gift_id` as the conflict key.
    @discardableResult
    func upsertStandaloneGift(_ gift: DBGiftSuggestion) async throws -> DBGiftSuggestion {
        return try await upsert(table: "gift_suggestions", data: gift, onConflict: "gift_id")
    }

    /// Fetch all standalone Gift Finder gifts for a user (plan_id IS NULL).
    func getStandaloneGifts(userId: UUID) async throws -> [DBGiftSuggestion] {
        return try await select(
            table: "gift_suggestions",
            query: "user_id=eq.\(userId.uuidString)&plan_id=is.null&order=created_at.desc"
        )
    }

    /// Delete a gift row by gift_id.
    func deleteGiftSuggestion(giftId: UUID) async throws {
        try await delete(table: "gift_suggestions", column: "gift_id", value: giftId.uuidString)
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
        try? await refreshRestAuthFromSDK()
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
    
    /// Calls the generate-playlist edge function for fresh, Last.fm–based song suggestions.
    /// Pass era, mood, and energy so the search uses all selected tags.
    func generatePlaylist(
        vibe: String,
        datePlanTitle: String,
        stops: [(name: String, venueType: String)]? = nil,
        era: String? = nil,
        mood: String? = nil,
        energy: String? = nil
    ) async throws -> GeneratePlaylistResult {
        try? await refreshRestAuthFromSDK()
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
        if let era = era, !era.isEmpty, era != "any" { body["era"] = era }
        if let mood = mood, !mood.isEmpty, mood != "none" { body["mood"] = mood }
        if let energy = energy, !energy.isEmpty { body["energy"] = energy }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        if http.statusCode != 200 {
            let errorMessage = Self.parsePlaylistError(from: data, statusCode: http.statusCode)
            if http.statusCode == 429 { throw SupabaseError.authFailed("Rate limit. Try again in a moment.") }
            if http.statusCode == 502 { throw SupabaseError.authFailed("Playlist service temporarily unavailable.") }
            if http.statusCode == 503 { throw SupabaseError.authFailed(errorMessage) }
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
    
    private static func parsePlaylistError(from data: Data, statusCode: Int) -> String {
        if let decoded = try? JSONDecoder().decode(GenerateGiftsErrorResponse.self, from: data),
           let msg = decoded.error, !msg.isEmpty {
            return msg
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = (json["error"] as? String) ?? (json["message"] as? String), !msg.isEmpty {
            return msg
        }
        if statusCode == 503 {
            return "Playlist service unavailable. Add LASTFM_API_KEY in Supabase → Edge Functions → Secrets."
        }
        if statusCode == 401 {
            return "Please sign in to generate playlists."
        }
        if statusCode == 404 {
            return "Playlist function not deployed. In your project run: supabase functions deploy generate-playlist"
        }
        return "Playlist generation failed (\(statusCode)). Try again."
    }
    
    // Playlists
    func createPlaylist(_ playlist: DBPlaylist) async throws -> DBPlaylist {
        return try await insert(table: "playlists", data: playlist)
    }

    /// Single round-trip insert or update by `playlist_id` (preferred for saves so the client does not rely on insert-then-fail).
    func upsertPlaylist(_ playlist: DBPlaylist) async throws -> DBPlaylist {
        try await upsert(table: "playlists", data: playlist, onConflict: "playlist_id")
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

    /// Fetch playlists by user_id (for users who don't yet have a couple record).
    func getPlaylists(userId: UUID) async throws -> [DBPlaylist] {
        return try await select(
            table: "playlists",
            query: "user_id=eq.\(userId.uuidString)&order=generated_at.desc"
        )
    }
    
    func updatePlaylist(_ playlist: DBPlaylist) async throws -> DBPlaylist {
        return try await update(table: "playlists", data: playlist, column: "playlist_id", value: playlist.playlistId.uuidString)
    }
    
    func deletePlaylist(playlistId: UUID) async throws {
        try await delete(table: "playlists", column: "playlist_id", value: playlistId.uuidString)
    }
    
    // MARK: - Storage Operations
    
    /// Supabase **Storage** bucket for iOS `uploadMemoryImage` uploads (case-sensitive). Stored URL is written to Postgres table `date_memories` via `createMemory`.
    static let memoriesStorageBucket = "Memories"

    /// Parses `/storage/v1/object/public/<bucket>/<objectPath>` from a public storage URL so we can delete the object when the user removes a memory.
    static func memoryStorageDeletionTarget(publicImageURL: String?) -> (bucket: String, path: String)? {
        guard let s = publicImageURL?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty,
              let url = URL(string: s) else { return nil }
        let p = url.path
        guard let range = p.range(of: "/object/public/") else { return nil }
        let after = String(p[range.upperBound...])
        guard let slash = after.firstIndex(of: "/") else { return nil }
        let bucket = String(after[..<slash])
        let objectPath = String(after[after.index(after: slash)...])
        guard !bucket.isEmpty, !objectPath.isEmpty else { return nil }
        return (bucket, objectPath)
    }
    
    /// Compresses JPEG (starting at 0.6 quality), then scales down if needed, until data is ≤ 5MB.
    private static func prepareMemoryImageDataUnder5MB(_ data: Data) throws -> Data {
        let maxBytes = 5 * 1024 * 1024
        guard var image = UIImage(data: data) else {
            throw SupabaseError.uploadFailed
        }
        func encodeUnderLimit(_ img: UIImage) -> Data? {
            var q: CGFloat = 0.6
            var result = img.jpegData(compressionQuality: q)
            while let d = result, d.count > maxBytes, q > 0.1 {
                q -= 0.05
                result = img.jpegData(compressionQuality: q)
            }
            if let d = result, d.count <= maxBytes { return d }
            return nil
        }
        if let d = encodeUnderLimit(image) { return d }
        var scale: CGFloat = 0.85
        while scale > 0.2 {
            let w = image.size.width * scale
            let h = image.size.height * scale
            let size = CGSize(width: w, height: h)
            let renderer = UIGraphicsImageRenderer(size: size)
            let scaled = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            image = scaled
            if let d = encodeUnderLimit(image) { return d }
            scale -= 0.1
        }
        throw SupabaseError.uploadFailed
    }
    
    /// Uploads a memory photo to the `Memories` bucket and returns the **public** object URL string.
    func uploadMemoryImage(data: Data, userId: String) async throws -> String {
        AppLogger.debug("uploadMemoryImage: userId=\(userId) rawBytes=\(data.count)", category: .storage)
        do {
            let prepared = try Self.prepareMemoryImageDataUnder5MB(data)
            AppLogger.debug("uploadMemoryImage: compressed to \(prepared.count) bytes", category: .storage)
            let filename = "\(UUID().uuidString).jpg"
            let path = "\(userId)/\(filename)"
            let bucket = Self.memoriesStorageBucket
            _ = try await uploadImage(data: prepared, bucket: bucket, path: path)
            let publicURL = getPublicURL(bucket: bucket, path: path)
            AppLogger.debug("uploadMemoryImage: success url=\(publicURL.absoluteString)", category: .storage)
            return publicURL.absoluteString
        } catch {
            AppLogger.error("uploadMemoryImage failed: \(error)", category: .storage)
            throw error
        }
    }

    /// Upload an image to Supabase Storage
    func uploadImage(data: Data, bucket: String = "memories", path: String) async throws -> String {
        // Pull a fresh token directly from the Supabase SDK (auto-refreshes if expired).
        // Avoids the race in syncSessionFromSDK where it fires a background Task and returns
        // early without setting `accessToken`, causing the guard below to throw .unauthorized.
        let sdkSession = try await supabaseClient.auth.session
        let token = sdkSession.accessToken
        // Keep cached property in sync for other callers
        await MainActor.run { self.accessToken = token }
        AppLogger.debug("uploadImage: access token obtained", category: .storage)

        let url = URL(string: "\(baseURL)/storage/v1/object/\(bucket)/\(path)")!
        print("🌐 uploadImage: POST \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (postBody, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ uploadImage: response is not HTTPURLResponse")
            throw SupabaseError.invalidResponse
        }

        print("📡 uploadImage: POST status=\(httpResponse.statusCode)")

        if (200...299).contains(httpResponse.statusCode) {
            return path
        }

        // Supabase returns 400 when the object already exists — retry with PUT (upsert)
        if httpResponse.statusCode == 400 {
            let bodyStr = String(data: postBody, encoding: .utf8) ?? "<non-utf8>"
            print("⚠️ uploadImage: POST 400 — body: \(bodyStr)")
            print("⚠️ uploadImage: retrying as PUT")
            request.httpMethod = "PUT"
            let (putBody, updateResponse) = try await session.data(for: request)
            guard let updateHttpResponse = updateResponse as? HTTPURLResponse else {
                print("❌ uploadImage: PUT response is not HTTPURLResponse")
                throw SupabaseError.uploadFailed
            }
            print("📡 uploadImage: PUT status=\(updateHttpResponse.statusCode)")
            if (200...299).contains(updateHttpResponse.statusCode) {
                return path
            }
            let putBodyStr = String(data: putBody, encoding: .utf8) ?? "<non-utf8>"
            print("❌ uploadImage: PUT failed — status=\(updateHttpResponse.statusCode) body: \(putBodyStr)")
            throw SupabaseError.uploadFailed
        }

        // Any other non-2xx — log the body so we can see what Supabase said
        let errorBodyStr = String(data: postBody, encoding: .utf8) ?? "<non-utf8>"
        print("❌ uploadImage: POST failed — status=\(httpResponse.statusCode) body: \(errorBodyStr)")
        throw SupabaseError.uploadFailed
    }
    
    /// Generate a public URL for an image
    func getPublicURL(bucket: String = "memories", path: String) -> URL {
        return URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)")!
    }
    
    /// Generate a signed URL for private image access
    func getSignedURL(bucket: String = "memories", path: String, expiresIn: Int = 3600) async throws -> URL {
        try await refreshRestAuthFromSDK()
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
        try await refreshRestAuthFromSDK()
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

    /// PostgREST RLS uses `auth.uid()` from the JWT. Manual `URLRequest` must use the same access token as `supabaseClient.auth` (it can be nil/stale right after launch or in background `Task`s).
    private func refreshRestAuthFromSDK() async throws {
        let s = try await supabaseClient.auth.session
        await MainActor.run {
            syncSessionFromSDK(s)
        }
    }
    
    private func select<T: Decodable>(table: String, query: String) async throws -> [T] {
        try await refreshRestAuthFromSDK()
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
        try await refreshRestAuthFromSDK()
        print("[Supabase] insert called table=\(table)")
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        print("[Supabase] insert before POST table=\(table)")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: responseData, encoding: .utf8) ?? ""
            print("[Supabase] insert error table=\(table) status=\(status) body=\(body)")
            throw SupabaseError.insertFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            print("[Supabase] insert error table=\(table) empty representation")
            throw SupabaseError.insertFailed
        }
        print("[Supabase] insert success table=\(table)")
        return result
    }
    
    private func insert<T: Encodable>(table: String, data: T) async throws {
        try await refreshRestAuthFromSDK()
        print("[Supabase] insert called table=\(table) (no return)")
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        print("[Supabase] insert before POST table=\(table) (no return)")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: responseData, encoding: .utf8) ?? ""
            print("[Supabase] insert error table=\(table) status=\(status) body=\(body)")
            throw SupabaseError.insertFailed
        }
        print("[Supabase] insert success table=\(table) (no return)")
    }
    
    private func update<T: Codable>(table: String, data: T, column: String, value: String) async throws -> T {
        try await refreshRestAuthFromSDK()
        let url = URL(string: "\(baseURL)/rest/v1/\(table)?\(column)=eq.\(value)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addHeaders(to: &request)
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: responseData, encoding: .utf8) ?? ""
            print("[Supabase] update error table=\(table) status=\(status) body=\(body)")
            throw SupabaseError.updateFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            print("[Supabase] update error table=\(table) empty representation")
            throw SupabaseError.updateFailed
        }
        print("[Supabase] update success table=\(table)")
        return result
    }
    
    private func upsert<T: Codable>(table: String, data: T, onConflict: String) async throws -> T {
        try await refreshRestAuthFromSDK()
        print("[Supabase] upsert called table=\(table) onConflict=\(onConflict)")
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)")!
        components.queryItems = [URLQueryItem(name: "on_conflict", value: onConflict)]
        guard let url = components.url else {
            throw SupabaseError.upsertFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)
        request.addValue("return=representation, resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        print("[Supabase] upsert before POST table=\(table)")
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: responseData, encoding: .utf8) ?? ""
            print("[Supabase] upsert error table=\(table) status=\(status) body=\(body)")
            throw SupabaseError.upsertFailed
        }
        
        let results = try decoder.decode([T].self, from: responseData)
        guard let result = results.first else {
            print("[Supabase] upsert error table=\(table) empty representation")
            throw SupabaseError.upsertFailed
        }
        print("[Supabase] upsert success table=\(table)")
        return result
    }
    
    private func patch(table: String, column: String, value: String, updates: [String: Any]) async throws {
        try await refreshRestAuthFromSDK()
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
        try await refreshRestAuthFromSDK()
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
            persistSessionToKeychain(session)
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
                        // Never mark authenticated without a session we can run through `syncSessionFromSDK`
                        // (email confirmation and other invariants live there).
                        clearSessionKeychainAsync()
                        await MainActor.run {
                            accessToken = nil
                            refreshToken = nil
                            currentUser = nil
                            isAuthenticated = false
                        }
                    }
            } catch {
                AppLogger.error("Failed to load cached session: \(error)", category: .auth)
                clearSessionKeychainAsync()
                    await MainActor.run {
                        accessToken = nil
                        refreshToken = nil
                        currentUser = nil
                        isAuthenticated = false
                    }
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

/// Outcome of email/password sign-up; `requiresEmailVerification` is derived from the auth user, not from `isAuthenticated` timing.
struct EmailPasswordSignUpResult {
    let user: SupabaseUser
    /// True when the account has an email address that is not yet confirmed — user must verify before the app treats them as signed in.
    let requiresEmailVerification: Bool
}

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
