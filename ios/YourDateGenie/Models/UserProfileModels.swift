import Foundation
import Combine
import CommonCrypto

// MARK: - User Profile Model
struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
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
    var gender: Gender = .preferNotToSay
    var partnerGender: Gender = .preferNotToSay
    var loveLanguages: [LoveLanguage] = [.qualityTime]
    
    var defaultStartingPoint: String = ""
    var defaultCity: String = ""
    
    var favoriteActivities: [String] = []
    
    var favoriteCuisines: [String] = []
    var dietaryRestrictions: [String] = []
    var allergies: [String] = []
    var beveragePreferences: [String] = []
    
    var accessibilityNeeds: [String] = []
    var hardNos: [String] = []
    
    var defaultBudget: String = ""
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
    
    private let userProfileKey = "userProfile"
    private let preferencesCompleteKey = "hasCompletedPreferences"
    private let loggedInKey = "isLoggedIn"
    
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
                self?.isLoggedIn = isAuthenticated
                if isAuthenticated {
                    self?.pendingEmailConfirmation = false
                    self?.pendingConfirmationEmail = nil
                    self?.userId = self?.supabase.currentUser?.id
                    self?.loadProfileFromDatabase()
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
        let supabaseUser = try await supabase.signUp(
            email: email,
            password: password,
            name: name
        )
        
        let hasSession = supabase.isAuthenticated
        await MainActor.run {
            var profile = UserProfile()
            profile.firstName = firstName
            profile.lastName = lastName
            profile.email = email
            profile.phoneNumber = phoneNumber
            profile.dateOfBirth = dateOfBirth
            profile.location = location
            self.currentUser = profile
            self.userId = supabaseUser.id
            if hasSession {
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: self.loggedInKey)
                self.pendingEmailConfirmation = false
                self.pendingConfirmationEmail = nil
            } else {
                self.isLoggedIn = false
                UserDefaults.standard.set(false, forKey: self.loggedInKey)
                self.pendingEmailConfirmation = true
                self.pendingConfirmationEmail = email.lowercased()
            }
        }
        
        if hasSession, let uid = userId {
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
        
        if let dbUser = try await supabase.getUser(userId: supabaseUser.id) {
            let preferences = try await supabase.getPreferences(userId: supabaseUser.id)
            let couple = try await supabase.getCoupleForUser(userId: supabaseUser.id)
            
                await MainActor.run {
                var profile = UserProfile()
                profile.firstName = supabaseUser.firstName
                profile.lastName = supabaseUser.lastName
                profile.email = dbUser.email
                profile.dateOfBirth = dbUser.birthday
                profile.location = dbUser.homeAddress ?? ""
                // Preserve phone from local profile if present (not in DB)
                if let existing = self.currentUser, !existing.phoneNumber.isEmpty {
                    profile.phoneNumber = existing.phoneNumber
                }
                
                if let prefs = preferences {
                    profile.preferences = self.convertToDatePreferences(prefs)
                    self.hasCompletedPreferences = true
                }
                
                self.currentUser = profile
                self.userId = supabaseUser.id
                self.coupleId = couple?.coupleId
                self.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: self.loggedInKey)
                UserDefaults.standard.set(self.hasCompletedPreferences, forKey: self.preferencesCompleteKey)
            }
        }
    }
    
    func signOut() {
        Task {
            try? await supabase.signOut()
        }
        
        isLoggedIn = false
        userId = nil
        coupleId = nil
        pendingEmailConfirmation = false
        pendingConfirmationEmail = nil
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }
    
    /// Call when user wants to go back from "Confirm your email" to the sign-up form.
    func clearPendingEmailConfirmation() {
        pendingEmailConfirmation = false
        pendingConfirmationEmail = nil
    }
    
    func sendPasswordReset(to email: String) async throws {
        try await supabase.sendPasswordReset(email: email)
    }
    
    func deleteAccount(password: String) async throws {
        guard let uid = userId else { return }
        
        try await supabase.deleteUser(userId: uid)
        try await supabase.signOut()
        
        await MainActor.run {
            clearProfile()
        }
    }
    
    // MARK: - Profile Operations
    
    private func loadProfileFromDatabase() {
        guard let uid = userId else { return }
        
        Task {
            do {
                if let dbUser = try await supabase.getUser(userId: uid) {
                    let preferences = try await supabase.getPreferences(userId: uid)
                    let couple = try await supabase.getCoupleForUser(userId: uid)
                    
                    await MainActor.run {
                        var profile = UserProfile()
                        let nameParts = dbUser.name.components(separatedBy: " ")
                        profile.firstName = nameParts.first ?? ""
                        profile.lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
                        profile.email = dbUser.email
                        profile.dateOfBirth = dbUser.birthday
                        profile.location = dbUser.homeAddress ?? ""
                        // Preserve phone from local profile (not stored in DB yet)
                        if let existing = self.currentUser, !existing.phoneNumber.isEmpty {
                            profile.phoneNumber = existing.phoneNumber
                        }
                        
                        if let prefs = preferences {
                            profile.preferences = self.convertToDatePreferences(prefs)
                            self.hasCompletedPreferences = true
                        }
                        
                        self.currentUser = profile
                        self.coupleId = couple?.coupleId
                        if let cid = couple?.coupleId {
                            NavigationCoordinator.shared.syncDatePlansFromCloud(coupleId: cid)
                            MemoryManager.shared.syncMemoriesFromCloud(coupleId: cid)
                        }
                        self.isProfileComplete = !profile.firstName.isEmpty
                    }
                }
            } catch {
                print("Failed to load profile from database: \(error)")
                loadLocalProfile()
            }
        }
    }
    
    func updatePreferences(_ preferences: DatePreferences) {
        guard var profile = currentUser else { return }
        profile.preferences = preferences
        currentUser = profile
        hasCompletedPreferences = true
        UserDefaults.standard.set(true, forKey: preferencesCompleteKey)
        
        if let uid = userId {
            Task {
                let dbPrefs = convertToDBPreferences(preferences, userId: uid)
                _ = try? await supabase.savePreferences(dbPrefs)
            }
        }
    }
    
    /// Save preferences from questionnaire data only (no date plan). Used when user edits preferences from Profile.
    func savePreferencesFromQuestionnaire(_ data: QuestionnaireData) {
        guard var profile = currentUser else { return }
        var prefs = profile.preferences
        prefs.gender = Gender(rawValue: data.userGender) ?? .preferNotToSay
        prefs.partnerGender = Gender(rawValue: data.partnerGender) ?? .preferNotToSay
        prefs.defaultCity = data.city
        prefs.defaultStartingPoint = data.startingAddress
        prefs.favoriteActivities = data.activityPreferences
        prefs.favoriteCuisines = data.cuisinePreferences
        prefs.beveragePreferences = data.drinkPreferences
        prefs.defaultBudget = data.budgetRange
        prefs.allergies = data.allergies
        prefs.hardNos = data.hardNos
        prefs.accessibilityNeeds = data.accessibilityNeeds
        prefs.dietaryRestrictions = data.dietaryRestrictions
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
                    travelMode: nil
                )
                try? await supabase.updateUser(dbUser)
            }
        }
    }
    
    func clearProfile() {
        currentUser = nil
        hasCompletedPreferences = false
        isLoggedIn = false
        userId = nil
        coupleId = nil
        
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.set(false, forKey: preferencesCompleteKey)
        UserDefaults.standard.set(false, forKey: loggedInKey)
        
        try? keychain.clearSession()
    }
    
    // MARK: - Local Storage Helpers
    
    private func loadLocalState() {
        isLoggedIn = supabase.isAuthenticated || UserDefaults.standard.bool(forKey: loggedInKey)
        hasCompletedPreferences = UserDefaults.standard.bool(forKey: preferencesCompleteKey)
        loadLocalProfile()
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
    
    private func convertToDBPreferences(_ prefs: DatePreferences, userId: UUID) -> DBPreferences {
        DBPreferences(
            userId: userId,
            coupleId: coupleId,
            cuisineTypes: prefs.favoriteCuisines.isEmpty ? nil : prefs.favoriteCuisines,
            activityTypes: prefs.favoriteActivities.isEmpty ? nil : prefs.favoriteActivities,
            drinkPreferences: prefs.beveragePreferences.isEmpty ? nil : prefs.beveragePreferences,
            budgetRange: prefs.defaultBudget.isEmpty ? nil : prefs.defaultBudget,
            loveLanguages: prefs.loveLanguages.map { $0.rawValue },
            foodAllergies: prefs.allergies.isEmpty ? nil : prefs.allergies,
            hardNos: prefs.hardNos.isEmpty ? nil : prefs.hardNos,
            accessibilityNeeds: prefs.accessibilityNeeds.isEmpty ? nil : prefs.accessibilityNeeds,
            gender: prefs.gender.rawValue,
            partnerGender: prefs.partnerGender.rawValue
        )
    }
    
    private func convertToDatePreferences(_ dbPrefs: DBPreferences) -> DatePreferences {
        var prefs = DatePreferences()
        prefs.favoriteCuisines = dbPrefs.cuisineTypes ?? []
        prefs.favoriteActivities = dbPrefs.activityTypes ?? []
        prefs.beveragePreferences = dbPrefs.drinkPreferences ?? []
        prefs.defaultBudget = dbPrefs.budgetRange ?? ""
        prefs.loveLanguages = (dbPrefs.loveLanguages ?? []).compactMap { LoveLanguage(rawValue: $0) }
        if prefs.loveLanguages.isEmpty { prefs.loveLanguages = [.qualityTime] }
        prefs.allergies = dbPrefs.foodAllergies ?? []
        prefs.hardNos = dbPrefs.hardNos ?? []
        prefs.accessibilityNeeds = dbPrefs.accessibilityNeeds ?? []
        prefs.gender = Gender(rawValue: dbPrefs.gender ?? "") ?? .preferNotToSay
        prefs.partnerGender = Gender(rawValue: dbPrefs.partnerGender ?? "") ?? .preferNotToSay
        return prefs
    }
    
    // MARK: - Questionnaire Pre-population
    
    func prePopulateQuestionnaireData(_ data: inout QuestionnaireData) {
        guard let profile = currentUser else { return }
        let prefs = profile.preferences
        
        if !prefs.defaultCity.isEmpty {
            data.city = prefs.defaultCity
        }
        if !prefs.defaultStartingPoint.isEmpty {
            data.startingAddress = prefs.defaultStartingPoint
        }
        if !prefs.favoriteActivities.isEmpty {
            data.activityPreferences = prefs.favoriteActivities
        }
        if !prefs.favoriteCuisines.isEmpty {
            data.cuisinePreferences = prefs.favoriteCuisines
        }
        if !prefs.dietaryRestrictions.isEmpty {
            data.dietaryRestrictions = prefs.dietaryRestrictions
        }
        if !prefs.allergies.isEmpty {
            data.allergies = prefs.allergies
        }
        if !prefs.beveragePreferences.isEmpty {
            data.drinkPreferences = prefs.beveragePreferences
        }
        if !prefs.accessibilityNeeds.isEmpty {
            data.accessibilityNeeds = prefs.accessibilityNeeds
        }
        if !prefs.hardNos.isEmpty {
            data.hardNos = prefs.hardNos
        }
        if !prefs.defaultBudget.isEmpty {
            data.budgetRange = prefs.defaultBudget
        }
        data.userGender = prefs.gender.rawValue
        data.partnerGender = prefs.partnerGender.rawValue
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
