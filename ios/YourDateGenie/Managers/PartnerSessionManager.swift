import Foundation
import Combine

// MARK: - Partner Session Manager

/// Manages partner invite state and combined questionnaire flow. Persists in UserDefaults.
final class PartnerSessionManager: ObservableObject {
    static let shared = PartnerSessionManager()
    
    private static let inviteKey = "dateGenie_partnerInvite"
    private static let sessionKey = "dateGenie_partnerSession"
    private static let inviterDataKey = "dateGenie_partnerInviterData"
    private static let partnerDataKey = "dateGenie_partnerPartnerData"
    
    enum PartnerState: String, Codable {
        case none
        case inviteSent
        case partnerJoined
        case inviterFilled
        case partnerFilled
        case bothFilled
    }
    
    struct InviteInfo: Codable {
        var partnerName: String
        var partnerEmail: String
        var message: String
        var sentAt: Date
        var plannedDate: Date?
        var plannedTime: String?
    }
    
    struct SessionInfo: Codable {
        var sessionId: String
        var state: PartnerState
        var inviterName: String?
    }
    
    @Published private(set) var inviteInfo: InviteInfo?
    @Published private(set) var sessionId: String?
    @Published private(set) var partnerState: PartnerState = .none
    @Published private(set) var inviterName: String?
    
    private init() {
        loadState()
    }
    
    // MARK: - Session & URL
    
    /// Creates a new partner session and returns the session id.
    func createSession(inviterName: String? = nil) -> String {
        let id = UUID().uuidString
        sessionId = id
        self.inviterName = inviterName
        partnerState = .none
        let session = SessionInfo(sessionId: id, state: .none, inviterName: inviterName)
        saveSession(session)
        saveState()
        return id
    }
    
    /// Returns the shareable join URL for the current session. Call after createSession or when invite was already sent.
    func getJoinURL() -> URL? {
        guard let id = sessionId ?? loadSessionId() else { return nil }
        var comp = URLComponents(string: "https://yourdategenie.com/partner/join")!
        comp.queryItems = [URLQueryItem(name: "session", value: id)]
        return comp.url
    }
    
    /// Pre-filled message for share sheet. Includes planned date/time when set.
    func getShareMessage() -> String {
        let link = getJoinURL()?.absoluteString ?? ""
        if let date = inviteInfo?.plannedDate, let time = inviteInfo?.plannedTime, !time.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            let dateStr = formatter.string(from: date)
            return "We're planning a date for \(dateStr) at \(time). Add your preferences here: \(link)"
        }
        if let date = inviteInfo?.plannedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            let dateStr = formatter.string(from: date)
            return "We're planning a date for \(dateStr). Add your preferences here: \(link)"
        }
        return "Plan our next date with me on Your Date Genie! \(link)"
    }
    
    private func loadSessionId() -> String? {
        guard let data = UserDefaults.standard.data(forKey: Self.sessionKey),
              let session = try? JSONDecoder().decode(SessionInfo.self, from: data) else {
            return nil
        }
        return session.sessionId
    }
    
    private func saveSession(_ session: SessionInfo) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }
    
    // MARK: - Invite
    
    func saveInvite(partnerName: String, partnerEmail: String, message: String, plannedDate: Date? = nil, plannedTime: String? = nil) {
        let info = InviteInfo(
            partnerName: partnerName,
            partnerEmail: partnerEmail,
            message: message,
            sentAt: Date(),
            plannedDate: plannedDate,
            plannedTime: plannedTime
        )
        inviteInfo = info
        if sessionId == nil {
            _ = createSession()
        }
        partnerState = .inviteSent
        if let sid = sessionId {
            var session = SessionInfo(sessionId: sid, state: .inviteSent, inviterName: inviterName)
            session.state = .inviteSent
            saveSession(session)
        }
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.inviteKey)
        }
        saveState()
    }
    
    // MARK: - Partner state
    
    func setPartnerJoined() {
        partnerState = .partnerJoined
        updateSessionState(.partnerJoined)
        saveState()
    }
    
    func setInviterFilled(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.inviterDataKey)
        }
        partnerState = .inviterFilled
        updateSessionState(.inviterFilled)
        saveState()
    }
    
    func setPartnerFilled(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.partnerDataKey)
        }
        partnerState = .partnerFilled
        updateSessionState(.partnerFilled)
        saveState()
    }
    
    func markBothFilled() {
        partnerState = .bothFilled
        updateSessionState(.bothFilled)
        saveState()
    }
    
    private func updateSessionState(_ state: PartnerState) {
        guard let sid = sessionId else { return }
        let session = SessionInfo(sessionId: sid, state: state, inviterName: inviterName)
        saveSession(session)
    }
    
    // MARK: - Merge
    
    /// Returns merged QuestionnaireData when both inviter and partner have filled. Nil if not both filled.
    func mergedQuestionnaireData() -> QuestionnaireData? {
        guard let inviterData = loadInviterData(),
              let partnerData = loadPartnerData() else {
            return nil
        }
        return Self.merge(inviterData, partnerData)
    }
    
    func loadInviterData() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: Self.inviterDataKey),
              let decoded = try? JSONDecoder().decode(QuestionnaireData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func loadPartnerData() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: Self.partnerDataKey),
              let decoded = try? JSONDecoder().decode(QuestionnaireData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    /// Merge two questionnaire responses: union arrays, prefer non-empty single values.
    static func merge(_ a: QuestionnaireData, _ b: QuestionnaireData) -> QuestionnaireData {
        var result = QuestionnaireData()
        result.city = a.city.isEmpty ? b.city : a.city
        result.neighborhood = a.neighborhood.isEmpty ? b.neighborhood : a.neighborhood
        result.startingAddress = a.startingAddress.isEmpty ? b.startingAddress : a.startingAddress
        result.dateType = a.dateType.isEmpty ? b.dateType : a.dateType
        result.occasion = a.occasion.isEmpty ? b.occasion : a.occasion
        result.dateScheduled = a.dateScheduled ?? b.dateScheduled
        result.startTime = a.startTime.isEmpty ? b.startTime : a.startTime
        result.transportationMode = a.transportationMode.isEmpty ? b.transportationMode : a.transportationMode
        result.travelRadius = a.travelRadius.isEmpty ? b.travelRadius : a.travelRadius
        result.energyLevel = a.energyLevel.isEmpty ? b.energyLevel : a.energyLevel
        result.activityPreferences = Array(Set(a.activityPreferences + b.activityPreferences)).sorted()
        result.timeOfDay = a.timeOfDay.isEmpty ? b.timeOfDay : a.timeOfDay
        result.duration = a.duration.isEmpty ? b.duration : a.duration
        result.cuisinePreferences = Array(Set(a.cuisinePreferences + b.cuisinePreferences)).sorted()
        result.dietaryRestrictions = Array(Set(a.dietaryRestrictions + b.dietaryRestrictions)).sorted()
        result.drinkPreferences = Array(Set(a.drinkPreferences + b.drinkPreferences)).sorted()
        result.budgetRange = a.budgetRange.isEmpty ? b.budgetRange : a.budgetRange
        result.allergies = Array(Set(a.allergies + b.allergies)).sorted()
        result.hardNos = Array(Set(a.hardNos + b.hardNos)).sorted()
        result.accessibilityNeeds = Array(Set(a.accessibilityNeeds + b.accessibilityNeeds)).sorted()
        result.smokingPreference = a.smokingPreference.isEmpty ? b.smokingPreference : a.smokingPreference
        result.additionalNotes = [a.additionalNotes, b.additionalNotes].filter { !$0.isEmpty }.joined(separator: " ")
        result.userGender = a.userGender.isEmpty ? b.userGender : a.userGender
        result.partnerGender = a.partnerGender.isEmpty ? b.partnerGender : a.partnerGender
        result.wantGiftSuggestions = a.wantGiftSuggestions || b.wantGiftSuggestions
        result.giftRecipient = a.giftRecipient.isEmpty ? b.giftRecipient : a.giftRecipient
        result.partnerInterests = Array(Set(a.partnerInterests + b.partnerInterests)).sorted()
        result.giftBudget = a.giftBudget.isEmpty ? b.giftBudget : a.giftBudget
        result.wantConversationStarters = a.wantConversationStarters || b.wantConversationStarters
        result.relationshipStage = a.relationshipStage.isEmpty ? b.relationshipStage : a.relationshipStage
        result.conversationTopics = Array(Set(a.conversationTopics + b.conversationTopics)).sorted()
        return result
    }
    
    // MARK: - Reset
    
    func clearSession() {
        inviteInfo = nil
        sessionId = nil
        partnerState = .none
        inviterName = nil
        UserDefaults.standard.removeObject(forKey: Self.inviteKey)
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
        UserDefaults.standard.removeObject(forKey: Self.inviterDataKey)
        UserDefaults.standard.removeObject(forKey: Self.partnerDataKey)
    }
    
    // MARK: - Persistence
    
    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: Self.inviteKey),
           let info = try? JSONDecoder().decode(InviteInfo.self, from: data) {
            inviteInfo = info
        }
        if let data = UserDefaults.standard.data(forKey: Self.sessionKey),
           let session = try? JSONDecoder().decode(SessionInfo.self, from: data) {
            sessionId = session.sessionId
            partnerState = session.state
            inviterName = session.inviterName
        }
    }
    
    private func saveState() {
        if let info = inviteInfo, let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.inviteKey)
        }
        if let sid = sessionId {
            let session = SessionInfo(sessionId: sid, state: partnerState, inviterName: inviterName)
            saveSession(session)
        }
        objectWillChange.send()
    }
}
