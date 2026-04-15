import Foundation
import Combine

// MARK: - Partner Session Manager

/// Manages partner invite state, phase transitions, rankings, and winner computation.
/// Persists in UserDefaults; syncs with Supabase. Acts as the single source of truth
/// for the Plan Together flow — both views and NavigationCoordinator observe this manager.
final class PartnerSessionManager: ObservableObject {
    static let shared = PartnerSessionManager()

    // MARK: - UserDefaults keys
    private static let inviteKey      = "dateGenie_partnerInvite"
    private static let sessionKey     = "dateGenie_partnerSession"
    private static let inviterDataKey = "dateGenie_partnerInviterData"
    private static let partnerDataKey = "dateGenie_partnerPartnerData"
    private static let phaseKey       = "dateGenie_partnerPhase"
    private static let roleKey        = "dateGenie_partnerRole"
    private static let rowIdKey       = "dateGenie_partnerSessionRowId"

    // MARK: - Legacy PartnerState (kept for backward compat with callsites)
    enum PartnerState: String, Codable {
        case none
        case inviteSent
        case partnerJoined
        case inviterFilled
        case partnerFilled
        case bothFilled
    }

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

    // MARK: - Published state

    @Published private(set) var inviteInfo: InviteInfo?
    @Published private(set) var sessionId: String?
    @Published private(set) var partnerState: PartnerState = .none
    @Published private(set) var inviterName: String?

    /// Current authoritative phase — drives all UI routing.
    @Published private(set) var currentPhase: PlanPhase = .preferencesPending

    /// Whether this device is the inviter or the partner in the active session.
    @Published private(set) var currentRole: PartnerRole?

    /// DB UUID of the partner_sessions row (needed for ranking calls).
    @Published private(set) var activeSessionRowId: UUID?

    // MARK: - Phase polling
    private var pollTask: Task<Void, Never>?
    private var lastPolledPhase: PlanPhase = .preferencesPending

    private init() {
        loadState()
    }

    // MARK: - Session & URL

    func createSession(inviterName: String? = nil) -> String {
        let id = UUID().uuidString
        sessionId = id
        self.inviterName = inviterName
        partnerState = .none
        currentPhase = .preferencesPending
        currentRole = .inviter
        let session = SessionInfo(sessionId: id, state: .none, inviterName: inviterName)
        saveSession(session)
        saveState()
        pushSessionToSupabaseIfNeeded()
        return id
    }

    func getJoinURL() -> URL? {
        guard let id = sessionId ?? loadSessionId() else { return nil }
        var comp = URLComponents(string: "yourdategenie://partner/join")!
        comp.queryItems = [URLQueryItem(name: "session", value: id)]
        return comp.url
    }

    func getJoinURLWeb() -> URL? {
        guard let id = sessionId ?? loadSessionId() else { return nil }
        var comp = URLComponents(string: "https://yourdategenie.com/partner/join")!
        comp.queryItems = [URLQueryItem(name: "session", value: id)]
        return comp.url
    }

    static func defaultProposedDateTimes() -> [ProposedDateTime] {
        let cal = Calendar.current
        let now = Date()
        guard let nextFriday   = cal.nextDate(after: now, matching: DateComponents(weekday: 6), matchingPolicy: .nextTime),
              let nextSaturday = cal.nextDate(after: now, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime),
              let nextSunday   = cal.nextDate(after: now, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime) else {
            return [
                ProposedDateTime(date: now,                               timeLabel: "Fri eve"),
                ProposedDateTime(date: now.addingTimeInterval(86400),     timeLabel: "Sat eve"),
                ProposedDateTime(date: now.addingTimeInterval(2*86400),   timeLabel: "Sun noon")
            ]
        }
        return [
            ProposedDateTime(date: nextFriday,   timeLabel: "Fri eve"),
            ProposedDateTime(date: nextSaturday, timeLabel: "Sat eve"),
            ProposedDateTime(date: nextSunday,   timeLabel: "Sun noon")
        ]
    }

    func getShareMessage() -> String {
        let link = getJoinURL()?.absoluteString ?? getJoinURLWeb()?.absoluteString ?? ""
        if let slots = inviteInfo?.proposedDateTimes, !slots.isEmpty {
            let labels = slots.map(\.timeLabel).joined(separator: ", ")
            return "Let's plan a date — I'm thinking \(labels). Add your preferences here: \(link)"
        }
        if let date = inviteInfo?.plannedDate, let time = inviteInfo?.plannedTime, !time.isEmpty {
            let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"
            return "We're planning a date for \(f.string(from: date)) at \(time). Add your preferences here: \(link)"
        }
        if let date = inviteInfo?.plannedDate {
            let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"
            return "We're planning a date for \(f.string(from: date)). Add your preferences here: \(link)"
        }
        return "Plan our next date with me on Your Date Genie! \(link)"
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
        if sessionId == nil { _ = createSession() }
        partnerState = .inviteSent
        currentRole = .inviter
        if let sid = sessionId {
            saveSession(SessionInfo(sessionId: sid, state: .inviteSent, inviterName: inviterName))
        }
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.inviteKey)
        }
        saveState()
        pushSessionToSupabaseIfNeeded()
        startPhasePolling()
    }

    // MARK: - Partner state mutations

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

    /// Called on the inviter's device when backend returns partner_data.
    func setPartnerDataFromBackend(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.partnerDataKey)
        }
        partnerState = .partnerFilled
        updateSessionState(.partnerFilled)
        markBothFilled()
        saveState()
        let name = inviteInfo?.partnerName.trimmingCharacters(in: .whitespaces) ?? inviterName ?? "Your partner"
        NotificationManager.shared.addNotification(AppNotification(
            type: .partnerPreferencesIn,
            title: "Preferences received",
            message: "\(name) added their preferences — generating your date options now.",
            timestamp: Date()
        ))
    }

    /// Partner side: submit questionnaire data for a joined session.
    func submitPartnerData(sessionId: String, data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "dateGenie_partnerSubmit_\(sessionId)")
        }
        currentRole = .partner
        self.sessionId = sessionId
        saveState()
        Task {
            // Register partner identity so inviter can see name
            let userId = UserProfileManager.shared.userId
            let partnerDisplayName = UserProfileManager.shared.currentUser?.firstName
            if let uid = userId {
                try? await SupabaseService.shared.updatePartnerSessionPartnerIdentity(
                    sessionId: sessionId,
                    partnerUserId: uid,
                    partnerName: partnerDisplayName
                )
            }
            try? await SupabaseService.shared.submitPartnerSessionPartnerData(sessionId: sessionId, partnerData: data)

            // Advance phase to preferences_complete so inviter's poll triggers generation
            try? await SupabaseService.shared.updatePartnerSessionPhase(
                sessionId: sessionId,
                phase: .preferencesComplete,
                triggeredBy: PartnerRole.partner.rawValue
            )
            await MainActor.run {
                currentPhase = .preferencesComplete
                UserDefaults.standard.set(PlanPhase.preferencesComplete.rawValue, forKey: Self.phaseKey)
            }

            // Write notification event for inviter
            if let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sessionId),
               let inviterUserId = session.inviterUserId {
                try? await SupabaseService.shared.writeNotificationEvent(
                    userId: inviterUserId,
                    partnerSessionId: session.id,
                    type: PlanPhaseNotification.partnerPreferencesIn.rawValue,
                    title: "Preferences received",
                    body: "\(partnerDisplayName ?? "Your partner") added their preferences — generating your date options now."
                )
            }
        }
        startPhasePolling()
    }

    // MARK: - Phase transitions (server + local)

    func transitionPhase(to phase: PlanPhase, triggeredBy: String? = nil) {
        guard currentPhase != phase else { return }
        currentPhase = phase
        UserDefaults.standard.set(phase.rawValue, forKey: Self.phaseKey)
        if !phase.requiresPolling { stopPhasePolling() }
        guard let sid = sessionId else { return }
        Task {
            try? await SupabaseService.shared.updatePartnerSessionPhase(
                sessionId: sid,
                phase: phase,
                triggeredBy: triggeredBy ?? currentRole?.rawValue ?? "system"
            )
        }
    }

    // MARK: - Ranking Submission

    /// Submits the current user's private rankings. If the other user has already submitted,
    /// this automatically computes and stores the winner.
    func submitRankings(_ rankings: [RankEntry], plans: [DatePlan], completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sid = sessionId else {
            completion(.failure(NSError(domain: "PartnerSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        let role = currentRole ?? .inviter
        Task {
            do {
                // 1. Persist rankings to option_rankings table
                let rowId = await fetchOrCacheSessionRowId(sessionId: sid)
                guard let partnerSessionId = rowId else { throw NSError(domain: "PartnerSession", code: 1) }
                let userId = UserProfileManager.shared.userId
                _ = try await SupabaseService.shared.upsertOptionRanking(
                    partnerSessionId: partnerSessionId,
                    role: role,
                    rankings: rankings,
                    userId: userId
                )

                // 2. Also update legacy inviter_rank / partner_rank columns for backwards compat
                if let planRowIds = await fetchPlanRowIds(partnerSessionId: partnerSessionId) {
                    for entry in rankings {
                        let idx = entry.planIndex - 1
                        guard idx < planRowIds.count else { continue }
                        switch role {
                        case .inviter:
                            try? await SupabaseService.shared.updatePartnerSessionPlanRank(planId: planRowIds[idx], inviterRank: entry.rankPosition, partnerRank: nil)
                        case .partner:
                            try? await SupabaseService.shared.updatePartnerSessionPlanRank(planId: planRowIds[idx], inviterRank: nil, partnerRank: entry.rankPosition)
                        }
                    }
                }

                // 3. Check if both have ranked
                let allRankings = try await SupabaseService.shared.getOptionRankings(partnerSessionId: partnerSessionId)
                let bothRanked = allRankings.count >= 2

                await MainActor.run {
                    if bothRanked {
                        self.currentPhase = .rankingsComplete
                        UserDefaults.standard.set(PlanPhase.rankingsComplete.rawValue, forKey: Self.phaseKey)
                    } else {
                        self.currentPhase = .waitingForPartnerRanking
                        UserDefaults.standard.set(PlanPhase.waitingForPartnerRanking.rawValue, forKey: Self.phaseKey)
                    }
                }

                // 4. Notify other user that ranking was submitted
                if let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sid) {
                    let otherUserId: UUID? = (role == .inviter) ? session.partnerUserId : session.inviterUserId
                    let myName = UserProfileManager.shared.currentUser?.firstName ?? "Your partner"
                    if let otherUserId {
                        try? await SupabaseService.shared.writeNotificationEvent(
                            userId: otherUserId,
                            partnerSessionId: partnerSessionId,
                            type: PlanPhaseNotification.rankingSubmitted.rawValue,
                            title: "Rankings submitted",
                            body: "\(myName) has ranked the date options. Rank yours to reveal your perfect match."
                        )
                    }
                }

                // 5. If both ranked, compute and save winner
                if bothRanked {
                    try await computeAndSaveWinner(partnerSessionId: partnerSessionId, plans: plans, sessionId: sid)
                } else {
                    try await SupabaseService.shared.updatePartnerSessionPhase(
                        sessionId: sid,
                        phase: .waitingForPartnerRanking,
                        triggeredBy: role.rawValue
                    )
                }

                await MainActor.run { completion(.success(bothRanked)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Winner Computation

    /// Computes the winning plan from both users' rankings using a points-based algorithm
    /// and saves the result to `final_option_selection`.
    func computeAndSaveWinner(partnerSessionId: UUID, plans: [DatePlan], sessionId: String) async throws {
        let allRankings = try await SupabaseService.shared.getOptionRankings(partnerSessionId: partnerSessionId)
        guard allRankings.count >= 2 else { return }

        let planCount = plans.count
        var scores = [Int: Int]()

        // Points: rank 1 = planCount pts, rank 2 = planCount-1 pts, etc.
        for rankingRow in allRankings {
            for entry in rankingRow.rankings {
                let pts = max(1, planCount + 1 - entry.rankPosition)
                scores[entry.planIndex, default: 0] += pts
            }
        }

        let sorted = scores.sorted { $0.value > $1.value }
        guard let winner = sorted.first else { return }
        let runnerUp = sorted.count > 1 ? sorted[1] : nil

        let maxPossible = planCount * 2 * planCount
        let reason = "Chosen with \(winner.value) combined points out of \(maxPossible) possible — the strongest match for both of you."
        let scoringPayload = Dictionary(uniqueKeysWithValues: sorted.map { ("\($0.key)", $0.value) })

        var selection = DBFinalOptionSelection(
            id: nil,
            partnerSessionId: partnerSessionId,
            winningPlanIndex: winner.key,
            runnerUpPlanIndex: runnerUp?.key,
            selectionReason: reason,
            scoringPayload: scoringPayload,
            selectedAt: Date()
        )
        _ = try await SupabaseService.shared.saveFinalOptionSelection(selection)

        // Update phase → final_option_selected
        try await SupabaseService.shared.updatePartnerSessionPhase(
            sessionId: sessionId,
            phase: .finalOptionSelected,
            triggeredBy: "system"
        )

        await MainActor.run {
            currentPhase = .finalOptionSelected
            UserDefaults.standard.set(PlanPhase.finalOptionSelected.rawValue, forKey: Self.phaseKey)
            stopPhasePolling()
        }

        // Notify both users
        if let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sessionId) {
            for uid in [session.inviterUserId, session.partnerUserId].compactMap({ $0 }) {
                try? await SupabaseService.shared.writeNotificationEvent(
                    userId: uid,
                    partnerSessionId: partnerSessionId,
                    type: PlanPhaseNotification.finalOptionSelected.rawValue,
                    title: "Your final date plan is ready.",
                    body: "Both rankings are in — we've found your perfect match. Tap to reveal."
                )
            }
        }

        // In-app notification
        await MainActor.run {
            NotificationManager.shared.addNotification(AppNotification(
                type: .finalOptionSelected,
                title: "Your final date plan is ready.",
                message: "Both rankings are in — we've found your perfect match.",
                timestamp: Date()
            ))
        }
    }

    // MARK: - Phase Polling (smart, phase-aware)

    func startPhasePolling() {
        stopPhasePolling()
        guard let sid = sessionId else { return }
        pollTask = Task { [weak self] in
            guard let self else { return }
            var interval: UInt64 = 3_000_000_000 // 3s default
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                guard !Task.isCancelled else { break }
                guard let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sid) else { continue }
                let remotePhase = session.planPhase
                await MainActor.run {
                    if remotePhase != self.currentPhase {
                        self.applyRemotePhase(remotePhase, from: session)
                    }
                    // Cache row ID
                    if let rowId = session.id, self.activeSessionRowId != rowId {
                        self.activeSessionRowId = rowId
                        if let data = rowId.uuidString.data(using: .utf8) {
                            UserDefaults.standard.set(data, forKey: Self.rowIdKey)
                        }
                    }
                }
                // Adjust poll interval based on phase urgency
                switch remotePhase {
                case .preferencesPending:                 interval = 5_000_000_000  // 5s
                case .preferencesComplete,
                     .generatingDateOptions:              interval = 2_000_000_000  // 2s
                case .optionsReadyForRanking,
                     .waitingForPartnerRanking,
                     .rankingsComplete:                   interval = 3_000_000_000  // 3s
                default:
                    // Terminal or handled phases — stop polling
                    await MainActor.run { self.stopPhasePolling() }
                    return
                }
                // Stop if phase transitioned away from an active state
                if !remotePhase.isActive { await MainActor.run { self.stopPhasePolling() }; return }
            }
        }
    }

    func stopPhasePolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Applies a phase change received from the server.
    @MainActor
    private func applyRemotePhase(_ phase: PlanPhase, from session: DBPartnerSession) {
        guard phase != currentPhase else { return }
        currentPhase = phase
        UserDefaults.standard.set(phase.rawValue, forKey: Self.phaseKey)

        // Mirror partner_data detection so existing generation logic still works
        if phase == .preferencesComplete || (session.partnerData != nil && partnerState != .bothFilled) {
            if let data = session.partnerData {
                setPartnerDataFromBackend(data)
            }
        }

        // Notify for options ready
        if phase == .optionsReadyForRanking {
            NotificationManager.shared.addNotification(AppNotification(
                type: .optionsReadyToRank,
                title: "Your date options are ready.",
                message: "Rank your favorites to reveal your perfect match.",
                timestamp: Date()
            ))
        }

        // Notify for final reveal
        if phase == .finalOptionSelected {
            NotificationManager.shared.addNotification(AppNotification(
                type: .finalOptionSelected,
                title: "Your final date plan is ready.",
                message: "Both rankings are in — tap to reveal.",
                timestamp: Date()
            ))
        }
    }

    // MARK: - Merge

    func mergedQuestionnaireData() -> QuestionnaireData? {
        guard let a = loadInviterData(), let b = loadPartnerData() else { return nil }
        return Self.merge(a, b)
    }

    func loadInviterData() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: Self.inviterDataKey),
              let decoded = try? JSONDecoder().decode(QuestionnaireData.self, from: data) else { return nil }
        return decoded
    }

    func loadPartnerData() -> QuestionnaireData? {
        guard let data = UserDefaults.standard.data(forKey: Self.partnerDataKey),
              let decoded = try? JSONDecoder().decode(QuestionnaireData.self, from: data) else { return nil }
        return decoded
    }

    static func merge(_ a: QuestionnaireData, _ b: QuestionnaireData) -> QuestionnaireData {
        var result = QuestionnaireData()
        result.city                  = a.city.isEmpty ? b.city : a.city
        result.neighborhood          = a.neighborhood.isEmpty ? b.neighborhood : a.neighborhood
        result.startingAddress       = a.startingAddress.isEmpty ? b.startingAddress : a.startingAddress
        result.dateType              = a.dateType.isEmpty ? b.dateType : a.dateType
        result.occasion              = a.occasion.isEmpty ? b.occasion : a.occasion
        result.dateScheduled         = a.dateScheduled ?? b.dateScheduled
        result.startTime             = a.startTime.isEmpty ? b.startTime : a.startTime
        result.transportationMode    = a.transportationMode.isEmpty ? b.transportationMode : a.transportationMode
        result.travelRadius          = a.travelRadius.isEmpty ? b.travelRadius : a.travelRadius
        result.energyLevel           = a.energyLevel.isEmpty ? b.energyLevel : a.energyLevel
        result.activityPreferences   = Array(Set(a.activityPreferences + b.activityPreferences)).sorted()
        result.timeOfDay             = a.timeOfDay.isEmpty ? b.timeOfDay : a.timeOfDay
        result.duration              = a.duration.isEmpty ? b.duration : a.duration
        result.cuisinePreferences    = Array(Set(a.cuisinePreferences + b.cuisinePreferences)).sorted()
        result.dietaryRestrictions   = Array(Set(a.dietaryRestrictions + b.dietaryRestrictions)).sorted()
        result.drinkPreferences      = Array(Set(a.drinkPreferences + b.drinkPreferences)).sorted()
        result.budgetRange           = a.budgetRange.isEmpty ? b.budgetRange : a.budgetRange
        result.allergies             = Array(Set(a.allergies + b.allergies)).sorted()
        result.hardNos               = Array(Set(a.hardNos + b.hardNos)).sorted()
        result.accessibilityNeeds    = Array(Set(a.accessibilityNeeds + b.accessibilityNeeds)).sorted()
        result.smokingPreference     = a.smokingPreference.isEmpty ? b.smokingPreference : a.smokingPreference
        result.additionalNotes       = [a.additionalNotes, b.additionalNotes].filter { !$0.isEmpty }.joined(separator: " ")
        result.userGender            = a.userGender.isEmpty ? b.userGender : a.userGender
        result.partnerGender         = a.partnerGender.isEmpty ? b.partnerGender : a.partnerGender
        result.wantGiftSuggestions   = a.wantGiftSuggestions || b.wantGiftSuggestions
        result.giftRecipient         = a.giftRecipient.isEmpty ? b.giftRecipient : a.giftRecipient
        result.partnerInterests      = Array(Set(a.partnerInterests + b.partnerInterests)).sorted()
        result.giftBudget            = a.giftBudget.isEmpty ? b.giftBudget : a.giftBudget
        result.wantConversationStarters = a.wantConversationStarters || b.wantConversationStarters
        result.relationshipStage     = a.relationshipStage.isEmpty ? b.relationshipStage : a.relationshipStage
        result.conversationTopics    = Array(Set(a.conversationTopics + b.conversationTopics)).sorted()
        return result
    }

    // MARK: - Session switching / hub

    func switchToSession(sessionId: String, inviterName: String?) {
        self.sessionId = sessionId
        self.inviterName = inviterName
        self.partnerState = .inviteSent
        self.inviteInfo = nil
        saveSession(SessionInfo(sessionId: sessionId, state: .inviteSent, inviterName: inviterName))
        objectWillChange.send()
    }

    // MARK: - Reset

    func clearSession() {
        stopPhasePolling()
        inviteInfo = nil
        sessionId = nil
        partnerState = .none
        currentPhase = .preferencesPending
        currentRole = nil
        activeSessionRowId = nil
        UserDefaults.standard.removeObject(forKey: Self.inviteKey)
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
        UserDefaults.standard.removeObject(forKey: Self.inviterDataKey)
        UserDefaults.standard.removeObject(forKey: Self.partnerDataKey)
        UserDefaults.standard.removeObject(forKey: Self.phaseKey)
        UserDefaults.standard.removeObject(forKey: Self.roleKey)
        UserDefaults.standard.removeObject(forKey: Self.rowIdKey)
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
        if let raw = UserDefaults.standard.string(forKey: Self.phaseKey),
           let phase = PlanPhase(rawValue: raw) {
            currentPhase = phase
        }
        if let raw = UserDefaults.standard.string(forKey: Self.roleKey),
           let role = PartnerRole(rawValue: raw) {
            currentRole = role
        }
        if let data = UserDefaults.standard.data(forKey: Self.rowIdKey),
           let str = String(data: data, encoding: .utf8),
           let rowId = UUID(uuidString: str) {
            activeSessionRowId = rowId
        }
    }

    private func saveState() {
        if let info = inviteInfo, let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.inviteKey)
        }
        if let sid = sessionId {
            saveSession(SessionInfo(sessionId: sid, state: partnerState, inviterName: inviterName))
        }
        if let role = currentRole {
            UserDefaults.standard.set(role.rawValue, forKey: Self.roleKey)
        }
        objectWillChange.send()
    }

    private func loadSessionId() -> String? {
        guard let data = UserDefaults.standard.data(forKey: Self.sessionKey),
              let session = try? JSONDecoder().decode(SessionInfo.self, from: data) else { return nil }
        return session.sessionId
    }

    private func saveSession(_ session: SessionInfo) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }

    private func updateSessionState(_ state: PartnerState) {
        guard let sid = sessionId else { return }
        saveSession(SessionInfo(sessionId: sid, state: state, inviterName: inviterName))
    }

    // MARK: - Supabase sync

    private func pushSessionToSupabaseIfNeeded() {
        guard let userId = UserProfileManager.shared.userId, let sid = sessionId else { return }
        let name = inviterName ?? UserProfileManager.shared.currentUser?.firstName ?? "A friend"
        let inviterData = loadInviterData()
        let plannedDates = inviteInfo?.proposedDateTimes?.map { DBProposedDateTime(date: $0.date, timeLabel: $0.timeLabel) }
        let notes = inviteInfo?.specialNotes
        Task {
            _ = try? await SupabaseService.shared.createOrUpdatePartnerSession(
                sessionId: sid,
                inviterName: name,
                inviterUserId: userId,
                inviterData: inviterData,
                inviterPlannedDates: plannedDates,
                notes: notes
            )
        }
    }

    /// Restore the most recent partner session after login.
    func restoreFromSupabaseIfNeeded(userId: UUID) {
        Task { await restoreFromSupabaseIfNeededAsync(userId: userId) }
    }

    func restoreFromSupabaseIfNeededAsync(userId: UUID) async {
        guard let list = try? await SupabaseService.shared.listPartnerSessions(inviterUserId: userId),
              !list.isEmpty else { return }
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
            currentPhase = session.planPhase
            currentRole = (session.inviterUserId == userId) ? .inviter : .partner
            if let rowId = session.id { activeSessionRowId = rowId }
            if let data = session.inviterData, let encoded = try? JSONEncoder().encode(data) {
                UserDefaults.standard.set(encoded, forKey: Self.inviterDataKey)
            }
            if let data = session.partnerData, let encoded = try? JSONEncoder().encode(data) {
                UserDefaults.standard.set(encoded, forKey: Self.partnerDataKey)
            }
            saveSession(SessionInfo(sessionId: session.sessionId, state: state, inviterName: session.inviterName))
            objectWillChange.send()
            // Resume polling if needed
            if currentPhase.requiresPolling { startPhasePolling() }
        }
    }

    // MARK: - Helpers

    private func fetchOrCacheSessionRowId(sessionId: String) async -> UUID? {
        if let cached = activeSessionRowId { return cached }
        if let session = try? await SupabaseService.shared.getPartnerSession(sessionId: sessionId),
           let rowId = session.id {
            await MainActor.run { activeSessionRowId = rowId }
            return rowId
        }
        return nil
    }

    private func fetchPlanRowIds(partnerSessionId: UUID) async -> [UUID]? {
        guard let plans = try? await SupabaseService.shared.getPartnerSessionPlans(partnerSessionId: partnerSessionId),
              !plans.isEmpty else { return nil }
        return plans.sorted { $0.planIndex < $1.planIndex }.map(\.id)
    }
}

// MARK: - Plan Phase Notification Types

/// Canonical notification type strings — mirrors notification_events.type column.
enum PlanPhaseNotification: String {
    case inviteReceived       = "invite_received"
    case partnerJoined        = "partner_joined"
    case partnerDeclined      = "partner_declined"
    case partnerPreferencesIn = "partner_preferences_in"
    case optionsReady         = "options_ready"
    case rankingSubmitted     = "ranking_submitted"
    case waitingForRanking    = "waiting_for_ranking"
    case rankingsComplete     = "rankings_complete"
    case finalOptionSelected  = "final_option_selected"
    case planConfirmed        = "plan_confirmed"
}
