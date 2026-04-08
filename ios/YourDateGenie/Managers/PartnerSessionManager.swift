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
    
    /// One proposed date/time slot (e.g. "Fri eve", "Sat eve", "Sun noon").
    struct ProposedDateTime: Codable, Equatable {
        var date: Date
        var timeLabel: String
    }

    struct InviteInfo: Codable {
        var partnerName: String
        var partnerEmail: String
        var message: String
        var sentAt: Date
        var plannedDate: Date?
        var plannedTime: String?
        var specialNotes: String?
        var proposedDateTimes: [ProposedDateTime]?
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
        pushSessionToSupabaseIfNeeded()
        return id
    }
    
    /// Returns the shareable join URL for the current session. Prefer app scheme so partner's app opens directly.
    func getJoinURL() -> URL? {
        guard let id = sessionId ?? loadSessionId() else { return nil }
        var comp = URLComponents(string: "yourdategenie://partner/join")!
        comp.queryItems = [URLQueryItem(name: "session", value: id)]
        return comp.url
    }

    /// HTTPS join URL for web fallback or when sharing to users who may not have the app.
    func getJoinURLWeb() -> URL? {
        guard let id = sessionId ?? loadSessionId() else { return nil }
        var comp = URLComponents(string: "https://yourdategenie.com/partner/join")!
        comp.queryItems = [URLQueryItem(name: "session", value: id)]
        return comp.url
    }

    /// Default three date/time slots: this weekend Fri eve, Sat eve, Sun noon.
    static func defaultProposedDateTimes() -> [ProposedDateTime] {
        let cal = Calendar.current
        let now = Date()
        var result: [ProposedDateTime] = []
        guard let nextFriday = cal.nextDate(after: now, matching: DateComponents(weekday: 6), matchingPolicy: .nextTime),
              let nextSaturday = cal.nextDate(after: now, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime),
              let nextSunday = cal.nextDate(after: now, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime) else {
            return [
                ProposedDateTime(date: now, timeLabel: "Fri eve"),
                ProposedDateTime(date: now.addingTimeInterval(86400), timeLabel: "Sat eve"),
                ProposedDateTime(date: now.addingTimeInterval(2 * 86400), timeLabel: "Sun noon")
            ]
        }
        result.append(ProposedDateTime(date: nextFriday, timeLabel: "Fri eve"))
        result.append(ProposedDateTime(date: nextSaturday, timeLabel: "Sat eve"))
        result.append(ProposedDateTime(date: nextSunday, timeLabel: "Sun noon"))
        return result
    }
    
    /// Pre-filled message for share sheet. Includes proposed date times when set.
    func getShareMessage() -> String {
        let link = getJoinURL()?.absoluteString ?? getJoinURLWeb()?.absoluteString ?? ""
        if let slots = inviteInfo?.proposedDateTimes, !slots.isEmpty {
            let labels = slots.map(\.timeLabel).joined(separator: ", ")
            return "Let's plan a date — I'm thinking \(labels). Add your preferences here: \(link)"
        }
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
    
    func saveInvite(partnerName: String, partnerEmail: String, message: String, plannedDate: Date? = nil, plannedTime: String? = nil, specialNotes: String? = nil, proposedDateTimes: [ProposedDateTime]? = nil) {
        let info = InviteInfo(
            partnerName: partnerName,
            partnerEmail: partnerEmail,
            message: message,
            sentAt: Date(),
            plannedDate: plannedDate,
            plannedTime: plannedTime,
            specialNotes: specialNotes,
            proposedDateTimes: proposedDateTimes
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
        pushSessionToSupabaseIfNeeded()
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
        pushSessionToSupabaseIfNeeded()
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

    /// Inviter side: when backend returns partner_data, write it locally and mark both filled so merge/generate can run.
    func setPartnerDataFromBackend(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.partnerDataKey)
        }
        partnerState = .partnerFilled
        updateSessionState(.partnerFilled)
        markBothFilled()
        saveState()
        let partnerName = inviteInfo?.partnerName.trimmingCharacters(in: .whitespaces) ?? inviterName ?? "Your partner"
        NotificationManager.shared.addNotification(AppNotification(
            type: .partnerSubmitted,
            title: "Partner ready!",
            message: "\(partnerName) added their preferences. Tap to generate your date plan.",
            timestamp: Date()
        ))
    }

    /// Partner (on their device) submits their data for a session they joined via link. Posts to backend when available.
    func submitPartnerData(sessionId: String, data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "dateGenie_partnerSubmit_\(sessionId)")
        }
        Task {
            try? await SupabaseService.shared.submitPartnerSessionPartnerData(sessionId: sessionId, partnerData: data)
        }
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
    
    /// Switch to a session from Pending list (invite sent, waiting for partner). Call after fetching session from backend.
    func switchToSession(sessionId: String, inviterName: String?) {
        self.sessionId = sessionId
        self.inviterName = inviterName
        self.partnerState = .inviteSent
        self.inviteInfo = nil
        let session = SessionInfo(sessionId: sessionId, state: .inviteSent, inviterName: inviterName)
        saveSession(session)
        objectWillChange.send()
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
    
    // MARK: - Supabase sync (survives reinstall when logged in)
    
    private func pushSessionToSupabaseIfNeeded() {
        guard let userId = UserProfileManager.shared.userId,
              let sid = sessionId else { return }
        let inviterName = self.inviterName ?? UserProfileManager.shared.currentUser?.firstName ?? "A friend"
        let inviterData = loadInviterData()
        let plannedDates: [DBProposedDateTime]? = inviteInfo?.proposedDateTimes?.map { DBProposedDateTime(date: $0.date, timeLabel: $0.timeLabel) }
        let notes = inviteInfo?.specialNotes
        Task {
            _ = try? await SupabaseService.shared.createOrUpdatePartnerSession(
                sessionId: sid,
                inviterName: inviterName,
                inviterUserId: userId,
                inviterData: inviterData,
                inviterPlannedDates: plannedDates,
                notes: notes
            )
        }
    }
    
    /// Call after login to restore the most recent partner session so Pending/Plan Together state is visible again.
    func restoreFromSupabaseIfNeeded(userId: UUID) {
        Task { await restoreFromSupabaseIfNeededAsync(userId: userId) }
    }

    func restoreFromSupabaseIfNeededAsync(userId: UUID) async {
        guard let list = try? await SupabaseService.shared.listPartnerSessions(inviterUserId: userId),
              !list.isEmpty else { return }
        // Prefer the most recent session that is still in-progress (partner hasn't filled yet,
        // or inviter hasn't filled yet). Fall back to the first session if all are complete.
        let session = list.first(where: { $0.inviterData == nil || $0.partnerData == nil }) ?? list[0]
        await MainActor.run {
            let state: PartnerState
            if session.inviterData != nil && session.partnerData != nil {
                state = .bothFilled
            } else if session.partnerData != nil {
                state = .partnerFilled
            } else if session.inviterData != nil {
                state = .inviterFilled
            } else {
                state = .inviteSent
            }
            sessionId = session.sessionId
            inviterName = session.inviterName
            partnerState = state
            if let data = session.inviterData, let encoded = try? JSONEncoder().encode(data) {
                UserDefaults.standard.set(encoded, forKey: Self.inviterDataKey)
            }
            if let data = session.partnerData, let encoded = try? JSONEncoder().encode(data) {
                UserDefaults.standard.set(encoded, forKey: Self.partnerDataKey)
            }
            let sessionInfo = SessionInfo(sessionId: session.sessionId, state: state, inviterName: session.inviterName)
            saveSession(sessionInfo)
            objectWillChange.send()
        }
    }
}
