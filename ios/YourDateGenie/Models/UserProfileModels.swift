import Foundation
import Combine
import CommonCrypto

// MARK: - User Profile Model
struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()

    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    /// Phone number — synced to `public.users.phone_number`.
    var phoneNumber: String = ""
    var dateOfBirth: Date?
    var location: String = ""

    var preferences: DatePreferences = DatePreferences()
    
    var createdAt: Date = Date()
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: createdAt)
    }
    
    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var displayName: String {
        fullName.isEmpty ? "Date Enthusiast" : fullName
    }
    
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year
    }
}

// MARK: - Date Preferences Model
struct DatePreferences: Codable, Equatable {
    // Identity
    var gender: Gender = .preferNotToSay
    var partnerGender: Gender = .preferNotToSay
    var loveLanguages: [LoveLanguage] = [.qualityTime]
    var partnerLoveLanguages: [LoveLanguage] = []
    // Location / travel
    var defaultStartingPoint: String = ""
    var defaultCity: String = ""
    var defaultNeighborhood: String = ""
    var energyLevel: String = ""
    var transportationMode: String = ""
    var travelRadius: String = ""
    // Activity / food
    var favoriteActivities: [String] = []
    var favoriteCuisines: [String] = []
    var dietaryRestrictions: [String] = []
    var allergies: [String] = []
    var beveragePreferences: [String] = []
    // Lifestyle
    var smokingPreference: String = ""
    var smokingActivities: [String] = []
    var accessibilityNeeds: [String] = []
    var hardNos: [String] = []
    var defaultBudget: String = ""
    // Relationship context
    var relationshipStage: String = ""
    var conversationTopics: [String] = []
    var additionalNotes: String = ""
    // Gift preferences
    var giftRecipient: String = ""
    var giftInterests: [String] = []
    var giftBudget: String = ""
    var giftOccasion: String = ""
    var giftNotes: String = ""
    var giftRecipientIdentity: String = ""
    var giftStyle: [String] = []
    var giftFavoriteBrands: String = ""
    var giftSizes: String = ""
}

// MARK: - Gender Enum
enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case nonBinary = "non-binary"
    case preferNotToSay = "prefer-not-to-say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-Binary"
        case .preferNotToSay: return "Prefer Not to Say"
        }
    }
    
    var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        case .nonBinary: return "🧑"
        case .preferNotToSay: return "🙂"
        }
    }
}

// MARK: - Love Language Enum
enum LoveLanguage: String, Codable, CaseIterable {
    case wordsOfAffirmation = "words-of-affirmation"
    case actsOfService = "acts-of-service"
    case receivingGifts = "receiving-gifts"
    case qualityTime = "quality-time"
    case physicalTouch = "physical-touch"
    
    var displayName: String {
        switch self {
        case .wordsOfAffirmation: return "Words of Affirmation"
        case .actsOfService: return "Acts of Service"
        case .receivingGifts: return "Receiving Gifts"
        case .qualityTime: return "Quality Time"
        case .physicalTouch: return "Physical Touch"
        }
    }
    
    var emoji: String {
        switch self {
        case .wordsOfAffirmation: return "💬"
        case .actsOfService: return "🤝"
        case .receivingGifts: return "🎁"
        case .qualityTime: return "⏰"
        case .physicalTouch: return "🤗"
        }
    }
    
    var description: String {
        switch self {
        case .wordsOfAffirmation: return "Compliments and encouragement"
        case .actsOfService: return "Helpful actions speak loudest"
        case .receivingGifts: return "Thoughtful presents and gestures"
        case .qualityTime: return "Undivided attention together"
        case .physicalTouch: return "Affection through closeness"
        }
    }
}

// MARK: - User Credentials Model
struct UserCredentials: Codable {
    var email: String
    var passwordHash: String
}

// MARK: - Authentication Error
enum AuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case userNotFound
    case invalidEmail
    case weakPassword
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password"
        case .emailAlreadyExists: return "An account with this email already exists"
        case .userNotFound: return "No account found with this email"
        case .invalidEmail: return "Please enter a valid email address"
        case .weakPassword: return "Password must be at least 6 characters"
        }
    }
}

// MARK: - User Profile Manager
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentUser: UserProfile? {
        didSet {
            saveProfileLocally()
        }
    }
    
    @Published var isProfileComplete: Bool = false
    @Published var hasCompletedPreferences: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var userId: UUID?
    @Published var coupleId: UUID?
    /// True after sign up when email confirmation is required; cleared when user confirms (deep link) or signs in.
    @Published var pendingEmailConfirmation: Bool = false
    @Published var pendingConfirmationEmail: String?
    
    private let supabase = SupabaseService.shared
    private let keychain = KeychainManager.shared
    
    /// Latest `public.preferences.updated_at` from a row we know is current (saves + fresh fetches). Used to ignore stale parallel profile loads that would overwrite a just-saved starting point.
    private var lastServerPreferencesUpdatedAt: Date?
    
    private let userProfileKey = "userProfile"
    private let preferencesCompleteKey = "hasCompletedPreferences"
    private let loggedInKey = "isLoggedIn"
    private let pendingEmailConfirmationKey = "dateGenie_pendingEmailConfirmation"
    private let pendingConfirmationEmailKey = "dateGenie_pendingConfirmationEmail"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthListener()
        loadLocalState()
    }
    
    // MARK: - Auth Listener
    
    private func setupAuthListener() {
        supabase.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                if self.pendingEmailConfirmation && !isAuthenticated {
                    self.isLoggedIn = false
                    return
                }
                if isAuthenticated {
                    self.isLoggedIn = true
                    UserDefaults.standard.set(true, forKey: self.loggedInKey)
                    self.pendingEmailConfirmation = false
                    self.pendingConfirmationEmail = nil
                    self.persistPendingEmailConfirmationToDisk()
                    self.userId = self.supabase.currentUser?.id
                    self.keychain.setHasEverLoggedIn(true)
                    self.loadProfileFromDatabase()
                } else {
                    // Do not trust keychain alone: stale tokens skip auth and can show the preferences
                    // questionnaire without a valid Supabase session (e.g. after reinstall / failed restore).
                    self.isLoggedIn = false
                    UserDefaults.standard.set(false, forKey: self.loggedInKey)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication
    
    func signUp(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        phoneNumber: String = "",
        dateOfBirth: Date? = nil,
        location: String = ""
    ) async throws {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let signUpResult = try await supabase.signUp(
            email: email,
            password: password,
            name: name
        )
        let supabaseUser = signUpResult.user
        
        await MainActor.run {
            var profile = UserProfile()
            profile.firstName = firstName
            profile.lastName = lastName
            profile.email = email
            profile.phoneNumber = phoneNumber
            profile.dateOfBirth = dateOfBirth
            profile.location = location
            self.currentUser = profile
            
            if signUpResult.requiresEmailVerification {
                self.userId = nil
                self.isLoggedIn = false
                UserDefaults.standard.set(false, forKey: self.loggedInKey)
                self.pendingEmailConfirmation = true
                self.pendingConfirmationEmail = email.lowercased()
            } else if self.supabase.isAuthenticated {
                self.userId = supabaseUser.id
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: self.loggedInKey)
                self.pendingEmailConfirmation = false
                self.pendingConfirmationEmail = nil
                self.keychain.setHasEverLoggedIn(true)
            } else {
                self.userId = nil
                self.isLoggedIn = false
                UserDefaults.standard.set(false, forKey: self.loggedInKey)
                self.pendingEmailConfirmation = false
                self.pendingConfirmationEmail = nil
            }
            self.persistPendingEmailConfirmationToDisk()
        }
        
        if !signUpResult.requiresEmailVerification, supabase.isAuthenticated, let uid = userId {
            let couple = try await supabase.getCoupleForUser(userId: uid)
            await MainActor.run {
                self.coupleId = couple?.coupleId
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await setLoading(true)
        defer { Task { await setLoading(false) } }
        
        let supabaseUser = try await supabase.signIn(email: email, password: password)
        let name = [supabaseUser.firstName, supabaseUser.lastName].filter { !$0.isEmpty }.joined(separator: " ")
        
        // Ensure user + couple exist (e.g. after reinstall or if backend trigger didn't run when they signed up)
        do {
            try await supabase.ensureUserAndCoupleIfMissing(
                userId: supabaseUser.id,
                email: supabaseUser.email ?? email,
                name: name.isEmpty ? (supabaseUser.email ?? email) : name
            )
        } catch {
            print("ensureUserAndCoupleIfMissing after signIn: \(error)")
        }
        
        let dbUser = try await supabase.getUser(userId: supabaseUser.id)
        let preferences = try await supabase.getPreferences(userId: supabaseUser.id)
        let couple = try await supabase.getCoupleForUser(userId: supabaseUser.id)
        
        await MainActor.run {
            var profile = UserProfile()
            if let dbUser = dbUser {
                let nameParts = dbUser.name.components(separatedBy: " ")
                profile.firstName = nameParts.first ?? ""
                profile.lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
                profile.email = dbUser.email
                profile.dateOfBirth = dbUser.birthday
                profile.location = dbUser.homeAddress ?? ""
            } else {
                profile.firstName = supabaseUser.firstName
                profile.lastName = supabaseUser.lastName
                profile.email = supabaseUser.email ?? email
            }
            if let existing = self.currentUser, !existing.phoneNumber.isEmpty {
                profile.phoneNumber = existing.phoneNumber
            }
            if let prefs = preferences {
                profile.preferences = self.convertToDatePreferences(prefs)
                self.hasCompletedPreferences = true
                self.lastServerPreferencesUpdatedAt = prefs.updatedAt
            }
            self.currentUser = profile
            self.userId = supabaseUser.id
            self.coupleId = couple?.coupleId
            self.isLoggedIn = true
            UserDefaults.standard.set(true, forKey: self.loggedInKey)
            UserDefaults.standard.set(self.hasCompletedPreferences, forKey: self.preferencesCompleteKey)
            self.keychain.setHasEverLoggedIn(true)
        }
        await PostLoginCloudSync.run(coupleId: couple?.coupleId, userId: supabaseUser.id)
    }
    
    /// Called after a social (Google/Apple) OAuth flow completes with a valid Supabase session.
    ///
    /// Mirrors the post-login bookkeeping `signIn(email:password:)` does: ensures the
    /// `public.users` / `couples` rows exist, pulls profile + preferences, flips `isLoggedIn`, and
    /// kicks the cloud sync so the coordinator routes past the auth screen. Without this, the
    /// Supabase session is authenticated but `UserProfileManager` state never updates, so
    /// `RootNavigationView` keeps showing `AuthenticationView`.
    func refreshAfterSocialSignIn() async {
        guard let supabaseUser = supabase.currentUser else { return }

        let email = supabaseUser.email ?? ""
        let name = [supabaseUser.firstName, supabaseUser.lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let nameForRow = name.isEmpty ? (email.isEmpty ? "Guest" : email) : name

        do {
            try await supabase.ensureUserAndCoupleIfMissing(
                userId: supabaseUser.id,
                email: email.lowercased(),
                name: nameForRow
            )
        } catch {
            print("ensureUserAndCoupleIfMissing after social sign in: \(error)")
        }

        let dbUser = try? await supabase.getUser(userId: supabaseUser.id)
        let preferences = try? await supabase.getPreferences(userId: supabaseUser.id)
        let couple = try? await supabase.getCoupleForUser(userId: supabaseUser.id)

        await MainActor.run {
            var profile = UserProfile()
            if let dbUser = dbUser {
                let nameParts = dbUser.name.components(separatedBy: " ")
                profile.firstName = nameParts.first ?? ""
                profile.lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
                profile.email = dbUser.email
                profile.dateOfBirth = dbUser.birthday
                profile.location = dbUser.homeAddress ?? ""
            } else {
                profile.firstName = supabaseUser.firstName
                profile.lastName = supabaseUser.lastName
                profile.email = email
            }
            if let existing = self.currentUser, !existing.phoneNumber.isEmpty {
                profile.phoneNumber = existing.phoneNumber
            }
            if let prefs = preferences {
                profile.preferences = self.convertToDatePreferences(prefs)
                self.hasCompletedPreferences = true
                self.lastServerPreferencesUpdatedAt = prefs.updatedAt
            }
            self.currentUser = profile
            self.userId = supabaseUser.id
            self.coupleId = couple?.coupleId
            self.isLoggedIn = true
            self.pendingEmailConfirmation = false
            self.pendingConfirmationEmail = nil
            UserDefaults.standard.set(true, forKey: self.loggedInKey)
            UserDefaults.standard.set(self.hasCompletedPreferences, forKey: self.preferencesCompleteKey)
            self.keychain.setHasEverLoggedIn(true)
        }

        await PostLoginCloudSync.run(coupleId: couple?.coupleId, userId: supabaseUser.id)
    }

    func signOut() {
        // Flip the observable auth flag first so any view tree dependent on `isLoggedIn`
        // starts transitioning to the login screen immediately — before keychain/network work.
        isLoggedIn = false
        userId = nil
        coupleId = nil
        hasCompletedPreferences = false
        currentUser = nil
        lastServerPreferencesUpdatedAt = nil
        pendingEmailConfirmation = false
        pendingConfirmationEmail = nil

        // Use userInitiated priority so the SDK session clear finishes before iOS can suspend.
        Task(priority: .userInitiated) { try? await supabase.signOut() }

        // Remaining disk/state work runs synchronously but is cheap.
        persistPendingEmailConfirmationToDisk()
        UserDefaults.standard.set(false, forKey: loggedInKey)
        UserDefaults.standard.set(false, forKey: preferencesCompleteKey)
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        PartnerSessionManager.shared.clearSession()
    }
    
    /// Call when user wants to go back from "Confirm your email" to the sign-up form.
    func clearPendingEmailConfirmation() {
        pendingEmailConfirmation = false
        pendingConfirmationEmail = nil
        persistPendingEmailConfirmationToDisk()
    }
    
    func sendPasswordReset(to email: String) async throws {
        try await supabase.sendPasswordReset(email: email)
    }

    func resendEmailConfirmation(to email: String) async throws {
        try await supabase.resendSignUpConfirmation(email: email)
    }
    
    func deleteAccount(password: String) async throws {
        // Call the delete-account Edge Function which uses the service role to remove
        // the auth.users entry — all user data cascades via FK ON DELETE CASCADE.
        try await supabase.deleteAccountViaEdgeFunction()
        try? await supabase.signOut()
        await MainActor.run {
            clearProfile()
        }
    }
    
    // MARK: - Profile Operations
    
    private struct FetchedRemoteProfile {
        let dbUser: DBUser
        let preferences: DBPreferences?
        let couple: DBCouple?
    }
    
    /// Loads remote profile after auth. Network + parsing run off the main thread; only `@Published` updates use the main actor.
    private func loadProfileFromDatabase() {
        guard let uid = userId else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await self.performLoadProfileFromDatabase(userId: uid)
        }
    }
    
    /// Fetches `users` / `preferences` / `couples` rows (and ensures user row if missing). No UI work.
    private func fetchRemoteProfile(for userId: UUID) async throws -> FetchedRemoteProfile? {
        var dbUser = try await supabase.getUser(userId: userId)
        if dbUser == nil {
            let context = await MainActor.run { () -> (email: String, name: String) in
                let em = self.currentUser?.email ?? self.supabase.currentUser?.email ?? ""
                let fromProfile = self.currentUser?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !fromProfile.isEmpty { return (em, fromProfile) }
                if let n = self.supabase.currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
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
            do {
                try await supabase.ensureUserAndCoupleIfMissing(
                    userId: userId,
                    email: context.email.lowercased(),
                    name: context.name
                )
            } catch {
                print("ensureUserAndCoupleIfMissing in loadProfileFromDatabase: \(error)")
            }
            dbUser = try await supabase.getUser(userId: userId)
        }
        
        guard let dbUser = dbUser else {
            print("loadProfileFromDatabase: no public.users row for \(userId) after ensure")
            return nil
        }
        
        let preferences = try await supabase.getPreferences(userId: userId)
        let couple = try await supabase.getCoupleForUser(userId: userId)
        return FetchedRemoteProfile(dbUser: dbUser, preferences: preferences, couple: couple)
    }
    
    /// Applies fetched data to `ObservableObject` state only.
    @MainActor
    private func updateUI(with fetched: FetchedRemoteProfile) {
        var profile = UserProfile()
        let nameParts = fetched.dbUser.name.components(separatedBy: " ")
        profile.firstName = nameParts.first ?? ""
        profile.lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        profile.email = fetched.dbUser.email
        profile.dateOfBirth = fetched.dbUser.birthday
        profile.location = fetched.dbUser.homeAddress ?? ""
        // Prefer the DB value so phone number survives reinstalls; fall back to
        // whatever is in memory (e.g. typed during sign-up before the DB row exists).
        let dbPhone = fetched.dbUser.phoneNumber ?? ""
        if !dbPhone.isEmpty {
            profile.phoneNumber = dbPhone
        } else if let existing = currentUser, !existing.phoneNumber.isEmpty {
            profile.phoneNumber = existing.phoneNumber
        }
        
        if let prefs = fetched.preferences {
            let remoteNewerOrEqual = lastServerPreferencesUpdatedAt.map { prefs.updatedAt >= $0 } ?? true
            if !remoteNewerOrEqual, let existing = currentUser {
                profile.preferences = existing.preferences
            } else {
                profile.preferences = convertToDatePreferences(prefs)
                lastServerPreferencesUpdatedAt = prefs.updatedAt
            }
            hasCompletedPreferences = true
        } else if let existing = currentUser {
            profile.preferences = existing.preferences
            if !existing.preferences.defaultCity.isEmpty || !existing.preferences.defaultStartingPoint.isEmpty {
                hasCompletedPreferences = true
            }
        }
        
        currentUser = profile
        coupleId = fetched.couple?.coupleId
        isProfileComplete = !profile.firstName.isEmpty
    }
    
    private func performLoadProfileFromDatabase(userId: UUID) async {
        do {
            guard let fetched = try await fetchRemoteProfile(for: userId) else {
                await MainActor.run { self.loadLocalProfile() }
                return
            }
            await updateUI(with: fetched)
            await PostLoginCloudSync.run(coupleId: fetched.couple?.coupleId, userId: userId)
        } catch {
            print("Failed to load profile from database: \(error)")
            await MainActor.run { self.loadLocalProfile() }
        }
    }
    
    func updatePreferences(_ preferences: DatePreferences) {
        // Snapshot pre-edit location values for the server-wins merge check later.
        // When currentUser is nil (profile fetch hasn't completed yet — common on first
        // save right after sign-up), all three snapshots are empty strings which is
        // correct: the user is setting these values for the first time, so user always wins.
        let savedCity          = currentUser?.preferences.defaultCity          ?? ""
        let savedNeighborhood  = currentUser?.preferences.defaultNeighborhood  ?? ""
        let savedStartingPoint = currentUser?.preferences.defaultStartingPoint ?? ""

        // Update local state only when the profile is already loaded.
        // Do NOT hard-return here: the DB write (below) must always fire so preferences
        // are persisted to Supabase even when currentUser hasn't been populated yet
        // (e.g. InitialPreferencesGateView shown before loadProfileFromDatabase finishes).
        if var profile = currentUser {
            profile.preferences = preferences
            currentUser = profile
        }
        hasCompletedPreferences = true
        UserDefaults.standard.set(true, forKey: preferencesCompleteKey)
        
        Task {
            print("[updatePreferences] called")
            do {
                let sessionUserId = try await supabase.syncAuthSessionAndReturnUserId()
                await MainActor.run {
                    if self.userId == nil { self.userId = sessionUserId }
                }
                let uid = sessionUserId
                print("[updatePreferences] using user_id from auth.session: \(uid)")
                let context = await MainActor.run { () -> (email: String, name: String) in
                    let em = self.currentUser?.email ?? self.supabase.currentUser?.email ?? ""
                    let fromProfile = self.currentUser?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !fromProfile.isEmpty { return (em, fromProfile) }
                    if let n = self.supabase.currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
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
                print("[updatePreferences] before ensureUserAndCoupleIfMissing")
                try await supabase.ensureUserAndCoupleIfMissing(
                    userId: uid,
                    email: context.email.lowercased(),
                    name: context.name
                )
                let couple = try await supabase.getCoupleForUser(userId: uid)
                let existingPrefs = try await supabase.getPreferences(userId: uid)
                let cid = couple?.coupleId
                await MainActor.run {
                    if let cid = cid { self.coupleId = cid }
                }

                // Guard against overwriting a more recent web-side location edit.
                //
                // Problem: iOS always sends the full preferences struct with
                // updatedAt = Date() (current device time). If the web app updated
                // the location after the last iOS sync, the iOS upsert would clobber
                // it with whatever city is still in local UserDefaults.
                //
                // Fix: check whether the server row is newer than what iOS last
                // acknowledged. If so, keep the server's location value — BUT only
                // for fields the user did NOT change in this edit session.
                //
                // "User changed" is determined by comparing `preferences` (the new
                // value passed in) against `savedCity/Neighborhood/StartingPoint` —
                // the snapshot taken synchronously on the main actor before this Task
                // started. If they differ the user explicitly edited that field, so
                // the user's intent wins regardless of server state.
                var prefsToSave = preferences
                if let serverPrefs = existingPrefs {
                    let lastKnown = await MainActor.run { self.lastServerPreferencesUpdatedAt }
                    // serverIsNewer is true when:
                    //   • we have a watermark and the server row is more recent, OR
                    //   • we have no watermark yet (no prior sync this session).
                    let serverIsNewer = lastKnown.map { serverPrefs.updatedAt > $0 } ?? true
                    if serverIsNewer {
                        // Only apply the server value for fields the user did NOT change.
                        // If the user explicitly typed a new address/city, their input wins.
                        let userEditedCity          = preferences.defaultCity          != savedCity
                        let userEditedNeighborhood  = preferences.defaultNeighborhood  != savedNeighborhood
                        let userEditedStartingPoint = preferences.defaultStartingPoint != savedStartingPoint

                        if !userEditedCity {
                            prefsToSave.defaultCity = serverPrefs.defaultCity ?? preferences.defaultCity
                        }
                        if !userEditedNeighborhood {
                            prefsToSave.defaultNeighborhood = serverPrefs.defaultNeighborhood ?? preferences.defaultNeighborhood
                        }
                        if !userEditedStartingPoint {
                            prefsToSave.defaultStartingPoint = serverPrefs.defaultStartingPoint ?? preferences.defaultStartingPoint
                        }

                        print("[updatePreferences] server-wins merge: " +
                              "city=\(userEditedCity ? "user" : "server"), " +
                              "neighborhood=\(userEditedNeighborhood ? "user" : "server"), " +
                              "startingPoint=\(userEditedStartingPoint ? "user" : "server")")

                        // Advance the watermark so subsequent saves in this session
                        // don't keep treating the same server row as "newer".
                        await MainActor.run {
                            self.lastServerPreferencesUpdatedAt = serverPrefs.updatedAt
                            if var p = self.currentUser {
                                p.preferences.defaultCity          = prefsToSave.defaultCity
                                p.preferences.defaultNeighborhood  = prefsToSave.defaultNeighborhood
                                p.preferences.defaultStartingPoint = prefsToSave.defaultStartingPoint
                                self.currentUser = p
                            }
                        }
                    }
                }

                let dbPrefs = convertToDBPreferences(
                    prefsToSave,
                    userId: uid,
                    coupleId: cid,
                    existingPreferenceId: existingPrefs?.preferenceId
                )
                print("[updatePreferences] before savePreferences (upsert)")
                let saved = try await supabase.savePreferences(dbPrefs)
                print("[updatePreferences] savePreferences success user_id=\(uid)")
                await MainActor.run {
                    self.lastServerPreferencesUpdatedAt = saved.updatedAt
                    guard var p = self.currentUser else { return }
                    p.preferences = self.convertToDatePreferences(saved)
                    self.currentUser = p
                }
            } catch {
                print("[updatePreferences] error: \(error)")
            }
        }
    }
    
    /// Save preferences from questionnaire data only (no date plan). Used when user edits preferences from Profile.
    func savePreferencesFromQuestionnaire(_ data: QuestionnaireData) {
        // Use existing preferences as the base so fields not covered by the questionnaire
        // (e.g. gift preferences set elsewhere) are preserved. If currentUser hasn't loaded
        // yet (can happen on first save right after sign-up), start from defaults — all
        // questionnaire fields will be written below anyway, and updatePreferences() will
        // fire the DB write regardless of currentUser state.
        var prefs = currentUser?.preferences ?? DatePreferences()
        // Identity
        prefs.gender = Gender(rawValue: data.userGender) ?? .preferNotToSay
        prefs.partnerGender = Gender(rawValue: data.partnerGender) ?? .preferNotToSay
        let langs = (data.loveLanguageRaws ?? []).compactMap { LoveLanguage(rawValue: $0) }
        prefs.loveLanguages = langs.isEmpty ? [.qualityTime] : langs
        // Location
        prefs.defaultCity = data.city
        prefs.defaultNeighborhood = data.neighborhood
        prefs.defaultStartingPoint = data.startingAddress
        prefs.energyLevel = data.energyLevel
        prefs.transportationMode = data.transportationMode
        prefs.travelRadius = data.travelRadius
        // Activity / food
        prefs.favoriteActivities = data.activityPreferences
        prefs.favoriteCuisines = data.cuisinePreferences
        prefs.beveragePreferences = data.drinkPreferences
        prefs.defaultBudget = data.budgetRange
        prefs.dietaryRestrictions = data.dietaryRestrictions
        prefs.allergies = data.allergies
        prefs.hardNos = data.hardNos
        prefs.accessibilityNeeds = data.accessibilityNeeds
        prefs.smokingPreference = data.smokingPreference
        prefs.additionalNotes = data.additionalNotes
        // Relationship context
        prefs.relationshipStage = data.relationshipStage
        prefs.conversationTopics = data.conversationTopics
        // Gift preferences
        prefs.giftRecipient = data.giftRecipient
        prefs.giftInterests = data.partnerInterests
        prefs.giftBudget = data.giftBudget
        updatePreferences(prefs)
    }
    
    func createProfile(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        dateOfBirth: Date?,
        location: String
    ) {
        var profile = UserProfile()
        profile.firstName = firstName
        profile.lastName = lastName
        profile.email = email
        profile.phoneNumber = phoneNumber
        profile.dateOfBirth = dateOfBirth
        profile.location = location
        currentUser = profile

        if let uid = userId {
            Task {
                let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                let dbUser = DBUser(
                    userId: uid,
                    name: name,
                    email: email,
                    passwordHash: "",
                    gender: nil,
                    birthday: dateOfBirth,
                    homeAddress: location.isEmpty ? nil : location,
                    travelMode: nil,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                try? await supabase.updateUser(dbUser)
            }
        }
    }

    /// Update account display info (name, email, phone). Synced to `public.users`.
    func updateAccountInfo(firstName: String, lastName: String, email: String, phoneNumber: String) {
        guard var profile = currentUser else { return }
        profile.firstName = firstName
        profile.lastName = lastName
        profile.email = email
        profile.phoneNumber = phoneNumber
        currentUser = profile

        if let uid = userId {
            Task {
                do {
                    guard let existing = try await supabase.getUser(userId: uid) else { return }
                    let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                    let dbUser = DBUser(
                        userId: uid,
                        name: name,
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        passwordHash: existing.passwordHash,
                        gender: existing.gender,
                        birthday: existing.birthday,
                        homeAddress: existing.homeAddress,
                        travelMode: existing.travelMode,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        createdAt: existing.createdAt
                    )
                    try await supabase.updateUser(dbUser)
                } catch {
                    print("Failed to update account in database: \(error)")
                }
            }
        }
    }
    
    func clearProfile() {
        currentUser = nil
        hasCompletedPreferences = false
        isLoggedIn = false
        userId = nil
        coupleId = nil
        lastServerPreferencesUpdatedAt = nil
        
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.set(false, forKey: preferencesCompleteKey)
        UserDefaults.standard.set(false, forKey: loggedInKey)
        
        try? keychain.clearSession()
    }
    
    // MARK: - Local Storage Helpers
    
    private func loadLocalState() {
        pendingEmailConfirmation = UserDefaults.standard.bool(forKey: pendingEmailConfirmationKey)
        pendingConfirmationEmail = pendingEmailConfirmation
            ? UserDefaults.standard.string(forKey: pendingConfirmationEmailKey)
            : nil
        
        if pendingEmailConfirmation {
            isLoggedIn = false
            UserDefaults.standard.set(false, forKey: loggedInKey)
        } else {
            // Only the Supabase SDK session counts as logged in (not UserDefaults, not keychain hints).
            isLoggedIn = supabase.isAuthenticated
            if UserDefaults.standard.bool(forKey: loggedInKey) && !supabase.isAuthenticated {
                UserDefaults.standard.set(false, forKey: loggedInKey)
            }
        }
        hasCompletedPreferences = UserDefaults.standard.bool(forKey: preferencesCompleteKey)
        loadLocalProfile()
    }
    
    private func persistPendingEmailConfirmationToDisk() {
        UserDefaults.standard.set(pendingEmailConfirmation, forKey: pendingEmailConfirmationKey)
        if pendingEmailConfirmation, let email = pendingConfirmationEmail {
            UserDefaults.standard.set(email, forKey: pendingConfirmationEmailKey)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingConfirmationEmailKey)
        }
    }
    
    private func loadLocalProfile() {
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
            isProfileComplete = isBasicInfoComplete(profile)
        }
    }
    
    private func saveProfileLocally() {
        guard let profile = currentUser else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
        }
        isProfileComplete = isBasicInfoComplete(profile)
    }
    
    private func isBasicInfoComplete(_ profile: UserProfile) -> Bool {
        !profile.firstName.isEmpty && !profile.email.isEmpty
    }
    
    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToDBPreferences(
        _ prefs: DatePreferences,
        userId: UUID,
        coupleId explicitCoupleId: UUID? = nil,
        existingPreferenceId: UUID? = nil
    ) -> DBPreferences {
        DBPreferences(
            preferenceId: existingPreferenceId ?? UUID(),
            userId: userId,
            coupleId: explicitCoupleId ?? coupleId,
            defaultCity: prefs.defaultCity.isEmpty ? nil : prefs.defaultCity,
            defaultStartingPoint: prefs.defaultStartingPoint.isEmpty ? nil : prefs.defaultStartingPoint,
            defaultNeighborhood: prefs.defaultNeighborhood.isEmpty ? nil : prefs.defaultNeighborhood,
            energyLevel: prefs.energyLevel.isEmpty ? nil : prefs.energyLevel,
            transportationMode: prefs.transportationMode.isEmpty ? nil : prefs.transportationMode,
            travelRadius: prefs.travelRadius.isEmpty ? nil : prefs.travelRadius,
            cuisineTypes: prefs.favoriteCuisines.isEmpty ? nil : prefs.favoriteCuisines,
            activityTypes: prefs.favoriteActivities.isEmpty ? nil : prefs.favoriteActivities,
            drinkPreferences: prefs.beveragePreferences.isEmpty ? nil : prefs.beveragePreferences,
            dietaryRestrictions: prefs.dietaryRestrictions.isEmpty ? nil : prefs.dietaryRestrictions,
            budgetRange: prefs.defaultBudget.isEmpty ? nil : prefs.defaultBudget,
            loveLanguages: prefs.loveLanguages.isEmpty ? nil : prefs.loveLanguages.map { $0.rawValue },
            partnerLoveLanguages: prefs.partnerLoveLanguages.isEmpty ? nil : prefs.partnerLoveLanguages.map { $0.rawValue },
            foodAllergies: prefs.allergies.isEmpty ? nil : prefs.allergies,
            hardNos: prefs.hardNos.isEmpty ? nil : prefs.hardNos,
            accessibilityNeeds: prefs.accessibilityNeeds.isEmpty ? nil : prefs.accessibilityNeeds,
            smokingPreference: prefs.smokingPreference.isEmpty ? nil : prefs.smokingPreference,
            smokingActivities: prefs.smokingActivities.isEmpty ? nil : prefs.smokingActivities,
            gender: prefs.gender.rawValue,
            partnerGender: prefs.partnerGender.rawValue,
            relationshipStage: prefs.relationshipStage.isEmpty ? nil : prefs.relationshipStage,
            conversationTopics: prefs.conversationTopics.isEmpty ? nil : prefs.conversationTopics,
            additionalNotes: prefs.additionalNotes.isEmpty ? nil : prefs.additionalNotes,
            giftRecipient: prefs.giftRecipient.isEmpty ? nil : prefs.giftRecipient,
            giftInterests: prefs.giftInterests.isEmpty ? nil : prefs.giftInterests,
            giftBudget: prefs.giftBudget.isEmpty ? nil : prefs.giftBudget,
            giftOccasion: prefs.giftOccasion.isEmpty ? nil : prefs.giftOccasion,
            giftNotes: prefs.giftNotes.isEmpty ? nil : prefs.giftNotes,
            giftRecipientIdentity: prefs.giftRecipientIdentity.isEmpty ? nil : prefs.giftRecipientIdentity,
            giftStyle: prefs.giftStyle.isEmpty ? nil : prefs.giftStyle,
            giftFavoriteBrands: prefs.giftFavoriteBrands.isEmpty ? nil : prefs.giftFavoriteBrands,
            giftSizes: prefs.giftSizes.isEmpty ? nil : prefs.giftSizes
        )
    }

    private func convertToDatePreferences(_ dbPrefs: DBPreferences) -> DatePreferences {
        var prefs = DatePreferences()
        prefs.defaultCity = dbPrefs.defaultCity ?? ""
        prefs.defaultStartingPoint = dbPrefs.defaultStartingPoint ?? ""
        prefs.defaultNeighborhood = dbPrefs.defaultNeighborhood ?? ""
        prefs.energyLevel = dbPrefs.energyLevel ?? ""
        prefs.transportationMode = dbPrefs.transportationMode ?? ""
        prefs.travelRadius = dbPrefs.travelRadius ?? ""
        prefs.favoriteCuisines = dbPrefs.cuisineTypes ?? []
        prefs.favoriteActivities = dbPrefs.activityTypes ?? []
        prefs.beveragePreferences = dbPrefs.drinkPreferences ?? []
        prefs.dietaryRestrictions = dbPrefs.dietaryRestrictions ?? []
        prefs.defaultBudget = dbPrefs.budgetRange ?? ""
        prefs.loveLanguages = (dbPrefs.loveLanguages ?? []).compactMap { LoveLanguage(rawValue: $0) }
        if prefs.loveLanguages.isEmpty { prefs.loveLanguages = [.qualityTime] }
        prefs.partnerLoveLanguages = (dbPrefs.partnerLoveLanguages ?? []).compactMap { LoveLanguage(rawValue: $0) }
        prefs.allergies = dbPrefs.foodAllergies ?? []
        prefs.hardNos = dbPrefs.hardNos ?? []
        prefs.accessibilityNeeds = dbPrefs.accessibilityNeeds ?? []
        prefs.smokingPreference = dbPrefs.smokingPreference ?? ""
        prefs.smokingActivities = dbPrefs.smokingActivities ?? []
        prefs.gender = Gender(rawValue: dbPrefs.gender ?? "") ?? .preferNotToSay
        prefs.partnerGender = Gender(rawValue: dbPrefs.partnerGender ?? "") ?? .preferNotToSay
        prefs.relationshipStage = dbPrefs.relationshipStage ?? ""
        prefs.conversationTopics = dbPrefs.conversationTopics ?? []
        prefs.additionalNotes = dbPrefs.additionalNotes ?? ""
        prefs.giftRecipient = dbPrefs.giftRecipient ?? ""
        prefs.giftInterests = dbPrefs.giftInterests ?? []
        prefs.giftBudget = dbPrefs.giftBudget ?? ""
        prefs.giftOccasion = dbPrefs.giftOccasion ?? ""
        prefs.giftNotes = dbPrefs.giftNotes ?? ""
        prefs.giftRecipientIdentity = dbPrefs.giftRecipientIdentity ?? ""
        prefs.giftStyle = dbPrefs.giftStyle ?? []
        prefs.giftFavoriteBrands = dbPrefs.giftFavoriteBrands ?? ""
        prefs.giftSizes = dbPrefs.giftSizes ?? ""
        return prefs
    }
    
    // MARK: - Questionnaire Pre-population
    
    func prePopulateQuestionnaireData(_ data: inout QuestionnaireData) {
        guard let profile = currentUser else { return }
        let prefs = profile.preferences
        // Location
        data.city = prefs.defaultCity
        data.neighborhood = prefs.defaultNeighborhood
        data.startingAddress = prefs.defaultStartingPoint
        if !prefs.energyLevel.isEmpty { data.energyLevel = prefs.energyLevel }
        if !prefs.transportationMode.isEmpty { data.transportationMode = prefs.transportationMode }
        if !prefs.travelRadius.isEmpty { data.travelRadius = prefs.travelRadius }
        // Activity / food
        if !prefs.favoriteActivities.isEmpty { data.activityPreferences = prefs.favoriteActivities }
        if !prefs.favoriteCuisines.isEmpty { data.cuisinePreferences = prefs.favoriteCuisines }
        if !prefs.dietaryRestrictions.isEmpty { data.dietaryRestrictions = prefs.dietaryRestrictions }
        if !prefs.allergies.isEmpty { data.allergies = prefs.allergies }
        if !prefs.beveragePreferences.isEmpty { data.drinkPreferences = prefs.beveragePreferences }
        if !prefs.defaultBudget.isEmpty { data.budgetRange = prefs.defaultBudget }
        // Lifestyle
        if !prefs.smokingPreference.isEmpty { data.smokingPreference = prefs.smokingPreference }
        if !prefs.accessibilityNeeds.isEmpty { data.accessibilityNeeds = prefs.accessibilityNeeds }
        if !prefs.hardNos.isEmpty { data.hardNos = prefs.hardNos }
        if !prefs.additionalNotes.isEmpty { data.additionalNotes = prefs.additionalNotes }
        // Identity
        data.userGender = prefs.gender.rawValue
        data.partnerGender = prefs.partnerGender.rawValue
        data.loveLanguageRaws = prefs.loveLanguages.map(\.rawValue)
        // Relationship context
        if !prefs.relationshipStage.isEmpty { data.relationshipStage = prefs.relationshipStage }
        if !prefs.conversationTopics.isEmpty { data.conversationTopics = prefs.conversationTopics }
        // Gift preferences
        if !prefs.giftRecipient.isEmpty { data.giftRecipient = prefs.giftRecipient }
        if !prefs.giftInterests.isEmpty { data.partnerInterests = prefs.giftInterests }
        if !prefs.giftBudget.isEmpty { data.giftBudget = prefs.giftBudget }
    }

    /// Applies saved profile preferences into questionnaire data (alias intent: single entry point for planning pre-fill).
    func applySavedPreferences(to data: inout QuestionnaireData) {
        prePopulateQuestionnaireData(&data)
    }
}

// MARK: - Preference Options
struct PreferenceOptions {
    static let accessibilityNeeds: [OptionItem] = [
        OptionItem(value: "wheelchair", label: "Wheelchair Access", emoji: "♿"),
        OptionItem(value: "hearing", label: "Hearing Assistance", emoji: "🦻"),
        OptionItem(value: "visual", label: "Visual Assistance", emoji: "👁️"),
        OptionItem(value: "mobility", label: "Limited Mobility", emoji: "🦯"),
        OptionItem(value: "sensory", label: "Sensory Friendly", emoji: "🧠"),
        OptionItem(value: "none", label: "None", emoji: "✅"),
    ]
    
    static let genderOptions: [OptionItem] = Gender.allCases.map { gender in
        OptionItem(value: gender.rawValue, label: gender.displayName, emoji: gender.emoji)
    }
    
    static let loveLanguageOptions: [OptionItem] = LoveLanguage.allCases.map { language in
        OptionItem(value: language.rawValue, label: language.displayName, emoji: language.emoji, desc: language.description)
    }
}
