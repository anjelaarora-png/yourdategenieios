import Foundation
import Combine
import CommonCrypto

// MARK: - User Profile Model
struct UserProfile: Codable, Equatable {
    var id: UUID = UUID()
    
    // Basic Info
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var dateOfBirth: Date?
    var location: String = ""
    
    // Date Preferences (saved for future date plans)
    var preferences: DatePreferences = DatePreferences()
    
    // Account
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
    // Personal
    var gender: Gender = .preferNotToSay
    var partnerGender: Gender = .preferNotToSay
    var loveLanguage: LoveLanguage = .qualityTime
    
    // Location defaults
    var defaultStartingPoint: String = ""
    var defaultCity: String = ""
    
    // Activities
    var favoriteActivities: [String] = []
    
    // Food & Dining
    var favoriteCuisines: [String] = []
    var dietaryRestrictions: [String] = []
    var allergies: [String] = []
    var beveragePreferences: [String] = []
    
    // Accessibility & Comfort
    var accessibilityNeeds: [String] = []
    var hardNos: [String] = []
    
    // Budget default
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
            saveProfile()
        }
    }
    
    @Published var isProfileComplete: Bool = false
    @Published var hasCompletedPreferences: Bool = false
    @Published var isLoggedIn: Bool = false
    
    private let userProfileKey = "userProfile"
    private let preferencesCompleteKey = "hasCompletedPreferences"
    private let credentialsKey = "userCredentials"
    private let loggedInKey = "isLoggedIn"
    
    private init() {
        loadProfile()
    }
    
    // MARK: - Persistence
    
    private func loadProfile() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loggedInKey)
        
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
            isProfileComplete = isBasicInfoComplete(profile)
        }
        hasCompletedPreferences = UserDefaults.standard.bool(forKey: preferencesCompleteKey)
    }
    
    private func saveProfile() {
        guard let profile = currentUser else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
        }
        isProfileComplete = isBasicInfoComplete(profile)
    }
    
    private func isBasicInfoComplete(_ profile: UserProfile) -> Bool {
        !profile.firstName.isEmpty &&
        !profile.email.isEmpty
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
    ) throws {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthenticationError.weakPassword
        }
        
        if let existingCreds = loadCredentials(), existingCreds.email.lowercased() == email.lowercased() {
            throw AuthenticationError.emailAlreadyExists
        }
        
        let credentials = UserCredentials(
            email: email.lowercased(),
            passwordHash: hashPassword(password)
        )
        saveCredentials(credentials)
        
        var profile = UserProfile()
        profile.firstName = firstName
        profile.lastName = lastName
        profile.email = email
        profile.phoneNumber = phoneNumber
        profile.dateOfBirth = dateOfBirth
        profile.location = location
        currentUser = profile
        
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loggedInKey)
    }
    
    func signIn(email: String, password: String) throws {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard let credentials = loadCredentials() else {
            throw AuthenticationError.userNotFound
        }
        
        guard credentials.email.lowercased() == email.lowercased() else {
            throw AuthenticationError.userNotFound
        }
        
        guard credentials.passwordHash == hashPassword(password) else {
            throw AuthenticationError.invalidCredentials
        }
        
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loggedInKey)
    }
    
    func signOut() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }
    
    func accountExists(for email: String) -> Bool {
        guard let credentials = loadCredentials() else { return false }
        return credentials.email.lowercased() == email.lowercased()
    }
    
    private func loadCredentials() -> UserCredentials? {
        guard let data = UserDefaults.standard.data(forKey: credentialsKey),
              let credentials = try? JSONDecoder().decode(UserCredentials.self, from: data) else {
            return nil
        }
        return credentials
    }
    
    private func saveCredentials(_ credentials: UserCredentials) {
        if let data = try? JSONEncoder().encode(credentials) {
            UserDefaults.standard.set(data, forKey: credentialsKey)
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // MARK: - Profile Actions
    
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
    }
    
    func updatePreferences(_ preferences: DatePreferences) {
        guard var profile = currentUser else { return }
        profile.preferences = preferences
        currentUser = profile
        hasCompletedPreferences = true
        UserDefaults.standard.set(true, forKey: preferencesCompleteKey)
    }
    
    func clearProfile() {
        currentUser = nil
        hasCompletedPreferences = false
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        UserDefaults.standard.removeObject(forKey: credentialsKey)
        UserDefaults.standard.set(false, forKey: preferencesCompleteKey)
        UserDefaults.standard.set(false, forKey: loggedInKey)
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
            data.drinkPreferences = prefs.beveragePreferences.first ?? ""
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
