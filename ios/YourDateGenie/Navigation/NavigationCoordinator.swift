import SwiftUI
import Combine

/// Runs `experiences_waiting` sync **serially**: at most one network pass in flight, plus **one** trailing rerun if another sync was requested while the first was running (avoids unbounded parallel requests while preserving freshness).
private actor ExperiencesWaitingSyncQueue {
    private var isRunning = false
    private var needsFollowUp = false

    func schedule(_ work: @escaping () async -> Void) async {
        if isRunning {
            needsFollowUp = true
            return
        }
        isRunning = true
        repeat {
            needsFollowUp = false
            await work()
        } while needsFollowUp
        isRunning = false
    }
}

// MARK: - App Destination Enum
enum AppDestination: Hashable {
    case landing
    case onboarding
    case questionnaire
    case datePlanResult(plan: DatePlan)
    case giftFinder(datePlan: DatePlan?, dateLocation: String?)
    case routeMap(stops: [DatePlanStop])
    case memoryGallery
    case playlist(planTitle: String, planId: UUID? = nil)
    case reservation(venueName: String, venueType: String, address: String?, phone: String?)
    case partnerShare(plan: DatePlan)
    case savedPlans
    case settings
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .landing: hasher.combine("landing")
        case .onboarding: hasher.combine("onboarding")
        case .questionnaire: hasher.combine("questionnaire")
        case .datePlanResult(let plan): hasher.combine("datePlan-\(plan.id)")
        case .giftFinder(let plan, _): hasher.combine("giftFinder-\(plan?.id.uuidString ?? "standalone")")
        case .routeMap: hasher.combine("routeMap")
        case .memoryGallery: hasher.combine("memoryGallery")
        case .playlist(let title, let planId): hasher.combine("playlist-\(title)-\(planId?.uuidString ?? "")")
        case .reservation(let name, _, _, _): hasher.combine("reservation-\(name)")
        case .partnerShare(let plan): hasher.combine("share-\(plan.id)")
        case .savedPlans: hasher.combine("savedPlans")
        case .settings: hasher.combine("settings")
        }
    }
    
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.landing, .landing): return true
        case (.onboarding, .onboarding): return true
        case (.questionnaire, .questionnaire): return true
        case (.datePlanResult(let a), .datePlanResult(let b)): return a.id == b.id
        case (.giftFinder(let a, let al), .giftFinder(let b, let bl)): return a?.id == b?.id && al == bl
        case (.routeMap, .routeMap): return true
        case (.memoryGallery, .memoryGallery): return true
        case (.playlist(let a, let ai), .playlist(let b, let bi)): return a == b && ai == bi
        case (.reservation(let a, _, _, _), .reservation(let b, _, _, _)): return a == b
        case (.partnerShare(let a), .partnerShare(let b)): return a.id == b.id
        case (.savedPlans, .savedPlans): return true
        case (.settings, .settings): return true
        default: return false
        }
    }
}

// MARK: - Navigation Coordinator
@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var navigationPath = NavigationPath()
    @Published var currentTab: Tab = .home
    @Published var showQuestionnaire = false
    @Published var showDatePlanResult = false
    @Published var currentDatePlan: DatePlan?
    @Published var generatedPlans: [DatePlan] = []
    @Published var savedPlans: [DatePlan] = []
    @Published var generatedPlansSelectedIndex: Int = 0
    @Published var isLoggedIn = false
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedSignUp = false
    @Published var hasCompletedPreferences = false
    @Published var showMemoryGallery = false
    @Published var isShowingMemoryCapture = false
    /// When true, user skipped login and can browse the app; creating a date plan will prompt for auth.
    @Published var hasSkippedLogin = false
    /// When auth was required to create a date plan, holds the intent so we open questionnaire after login.
    @Published var authRequiredForIntent: PlanIntent?

    @Published var activeSheet: ActiveSheet?

    /// When set, `LuxuryMainAppView` shows a platform picker (OpenTable / Resy / Call) for this venue.
    @Published var reservationPlatformPickerPayload: ReservationPlatformPickerPayload?

    /// Dates that have already taken place (moved from saved when user marks as done).
    @Published var pastPlans: [DatePlan] = []
    
    /// Unsaved date plan options (moved here when user dismisses options sheet without saving).
    @Published var experiencesWaiting: [DatePlan] = []
    
    /// Scheduled date/time from the last completed questionnaire; applied when user saves a plan so Upcoming Magic shows it.
    private(set) var lastQuestionnaireScheduledDate: Date?
    
    /// When true, questionnaire was opened from Partner Planning "Fill my preferences"; on complete we save to PartnerSessionManager.
    @Published var isPartnerPlanningInviter = false
    
    /// When non-nil, the current date plan result is from partner (merged) flow; show "Made for A & B" badge. Cleared when showing non-partner result.
    @Published var currentPlanPartnerNames: (String, String)?

    /// When app opens via partner/join deep link, holds session id and optional inviter name for PartnerJoinView.
    @Published var pendingPartnerJoinSessionId: String?
    @Published var pendingPartnerJoinInviterName: String?

    /// After partner merge generation, the backend row ids of the plans (for submitting rank).
    @Published var partnerSessionPlanRowIds: [UUID]?

    /// When questionnaire is opened from PartnerJoinView (partner has no prefs), on complete we submit to this session and dismiss.
    @Published var partnerJoinSessionId: String?

    /// The computed winner for the active partner session — populated before showing FinalDateRevealView.
    @Published var finalOptionSelection: DBFinalOptionSelection?

    /// After onboarding, open auth on Sign Up tab once (then cleared).
    @Published var preferSignUpTabOnNextAuth: Bool = false

    /// After email-confirm deep link with session, show hero once before initial preferences questionnaire.
    @Published var presentHeroBeforeInitialPreferences: Bool = false

    /// True while root shows full-screen questionnaire for first-time preferences (replaces PreferencesSetupView).
    @Published var isPresentingInitialPreferencesFlow: Bool = false
    /// User chose "finish later" on initial preferences; allow main tabs without completing the questionnaire.
    @Published var hasDeferredInitialPreferences: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    /// When false, a cloud merge is in flight — we still upsert unsaved plans, but skip orphan deletes on `experiences_waiting`.
    private var experiencesCloudPullCompleted = true
    private let experiencesWaitingSyncQueue = ExperiencesWaitingSyncQueue()
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case loveNote = "Love Notes"
        case gifts = "Gifts"
        case memories = "Memories"
        case profile = "Profile"
        
        /// Short label for tab bar so text doesn’t overflow on small screens.
        var tabBarTitle: String {
            switch self {
            case .home: return "Home"
            case .loveNote: return "Love Notes"
            case .gifts: return "Gifts"
            case .memories: return "Memories"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .loveNote: return "heart.text.square.fill"
            case .gifts: return "gift.fill"
            case .memories: return "photo.stack.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    enum ActiveSheet: Identifiable {
        case questionnaire
        case datePlanResult
        case datePlanOptions
        case giftFinder(datePlan: DatePlan?, dateLocation: String?)
        case playlist(planTitle: String, planId: UUID? = nil)
        case reservation(venueName: String, venueType: String, address: String?, phone: String?, bookingUrl: String?, websiteUrl: String?, openingHours: [String]?)
        case partnerShare(plan: DatePlan)
        case routeMap(stops: [DatePlanStop], startingPoint: StartingPoint?, showRouteLine: Bool = true)
        case memoryGallery
        case conversationStarters
        case pastMagic
        case savedPlansList
        case settings
        case explore
        case playbook
        case partnerPlanning
        case partnerJoin(sessionId: String, inviterName: String?)
        case planGenerating(sessionId: String, role: PartnerRole)
        case partnerRanking
        case finalDateReveal
        case authRequired(PlanIntent)

        var id: String {
            switch self {
            case .questionnaire: return "questionnaire"
            case .datePlanResult: return "datePlanResult"
            case .datePlanOptions: return "datePlanOptions"
            case .giftFinder: return "giftFinder"
            case .playlist(_, _): return "playlist"
            case .reservation(_, _, _, _, _, _, _): return "reservation"
            case .partnerShare: return "partnerShare"
            case .routeMap: return "routeMap"
            case .memoryGallery: return "memoryGallery"
            case .conversationStarters: return "conversationStarters"
            case .pastMagic: return "pastMagic"
            case .savedPlansList: return "savedPlansList"
            case .settings: return "settings"
            case .explore: return "explore"
            case .playbook: return "playbook"
            case .partnerPlanning: return "partnerPlanning"
            case .partnerJoin(let sessionId, _): return "partnerJoin-\(sessionId)"
            case .planGenerating(let sessionId, _): return "planGenerating-\(sessionId)"
            case .partnerRanking: return "partnerRanking"
            case .finalDateReveal: return "finalDateReveal"
            case .authRequired(let intent): return "authRequired-\(intent)"
            }
        }
    }

    /// Present partner join sheet (e.g. from deep link yourdategenie://partner/join?session=XXX).
    func showPartnerJoin(sessionId: String, inviterName: String?) {
        pendingPartnerJoinSessionId = sessionId
        pendingPartnerJoinInviterName = inviterName
        activeSheet = .partnerJoin(sessionId: sessionId, inviterName: inviterName)
        let inviter = inviterName ?? "Someone"
        NotificationManager.shared.addNotification(AppNotification(
            type: .partnerInvite,
            title: "\(inviter) invited you to plan a date!",
            message: "Tap to join and share your preferences.",
            timestamp: Date()
        ))
    }

    /// Open a past Plan Together session: load saved plans and present DatePlanOptionsView (e.g. from Plan Together → Past list).
    func showPastPartnerPlans(partnerSessionId: UUID, inviterName: String?) {
        activeSheet = nil
        Task {
            do {
                let planRows = try await SupabaseService.shared.getPartnerSessionPlans(partnerSessionId: partnerSessionId)
                let plans = planRows.map(\.planJson)
                await MainActor.run {
                    generatedPlans = plans
                    generatedPlansSelectedIndex = 0
                    currentDatePlan = plans.first
                    currentPlanPartnerNames = (inviterName ?? "You", "Partner")
                    partnerSessionPlanRowIds = planRows.map(\.id)
                    activeSheet = .datePlanOptions
                    scheduleSyncAllUnsavedExperiencesToCloud()
                }
            } catch { }
        }
    }

    private init() {
        loadSavedState()
        setupGeneratorSubscription()
        setupAuthStateSubscription()
        setupPartnerPhaseObservation()
    }
    
    // MARK: - Partner Phase Observation

    /// Observes PartnerSessionManager's phase and routes to the correct screen automatically.
    private func setupPartnerPhaseObservation() {
        PartnerSessionManager.shared.$currentPhase
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in self?.handlePartnerPhaseChange(phase) }
            .store(in: &cancellables)
    }

    private func handlePartnerPhaseChange(_ phase: PlanPhase) {
        switch phase {
        case .preferencesComplete:
            // Inviter device triggers generation when both preferences are in
            guard PartnerSessionManager.shared.currentRole == .inviter,
                  PartnerSessionManager.shared.mergedQuestionnaireData() != nil else { return }
            partnerDataReceivedMergeAndGenerate()
        case .generatingDateOptions:
            // Show generating screen if not already in partner-plan flow
            guard let sid = PartnerSessionManager.shared.sessionId else { return }
            let role = PartnerSessionManager.shared.currentRole ?? .inviter
            let targetId = ActiveSheet.planGenerating(sessionId: sid, role: role).id
            if activeSheet?.id != targetId {
                activeSheet = .planGenerating(sessionId: sid, role: role)
            }
        case .optionsReadyForRanking:
            // For the partner device: fetch plans from DB, then show ranking
            let role = PartnerSessionManager.shared.currentRole ?? .inviter
            if role == .partner {
                loadPartnerPlansAndShowRanking()
            } else {
                // Inviter already has plans in generatedPlans — just route
                if !generatedPlans.isEmpty {
                    activeSheet = .partnerRanking
                }
            }
        case .waitingForPartnerRanking:
            // Stay on ranking screen if still showing; the view handles this state
            break
        case .finalOptionSelected:
            loadFinalOptionAndShowReveal()
        default:
            break
        }
    }

    private func loadPartnerPlansAndShowRanking() {
        guard let rowId = PartnerSessionManager.shared.activeSessionRowId else { return }
        Task {
            do {
                let planRows = try await SupabaseService.shared.getPartnerSessionPlans(partnerSessionId: rowId)
                let plans = planRows.map(\.planJson)
                await MainActor.run {
                    generatedPlans = plans
                    generatedPlansSelectedIndex = 0
                    currentDatePlan = plans.first
                    partnerSessionPlanRowIds = planRows.map(\.id)
                    activeSheet = .partnerRanking
                }
            } catch { }
        }
    }

    func loadFinalOptionAndShowReveal() {
        guard let rowId = PartnerSessionManager.shared.activeSessionRowId else { return }
        Task {
            do {
                if let selection = try await SupabaseService.shared.getFinalOptionSelection(partnerSessionId: rowId) {
                    await MainActor.run {
                        finalOptionSelection = selection
                        activeSheet = .finalDateReveal
                    }
                }
            } catch { }
        }
    }

    // MARK: - Phase-aware generation

    /// Updated generation entry-point: sets phase correctly and routes to ranking instead of options view.
    func partnerDataReceivedMergeAndGenerate() {
        guard let merged = PartnerSessionManager.shared.mergedQuestionnaireData(),
              let sessionId = PartnerSessionManager.shared.sessionId else { return }
        let inviterDisplayName = PartnerSessionManager.shared.inviteInfo?.partnerName.trimmingCharacters(in: .whitespaces)
            ?? PartnerSessionManager.shared.inviterName ?? "You"

        // Transition to generating phase and show loading screen
        PartnerSessionManager.shared.transitionPhase(to: .generatingDateOptions, triggeredBy: "inviter")

        isRegeneratingFromOptions = true
        activeSheet = .planGenerating(sessionId: sessionId, role: .inviter)

        Task {
            do {
                let generator = DatePlanGeneratorService.shared
                let plans = try await generator.generateDatePlan(from: merged)
                let session = try await SupabaseService.shared.getPartnerSession(sessionId: sessionId)
                var planRowIds: [UUID]?
                if let rowId = session?.id {
                    let saved = try await SupabaseService.shared.savePartnerSessionPlansV2(partnerSessionId: rowId, plans: plans)
                    planRowIds = saved.map(\.id)
                }
                await MainActor.run {
                    generatedPlans = plans
                    generatedPlansSelectedIndex = 0
                    currentDatePlan = plans.first
                    currentPlanPartnerNames = (inviterDisplayName, "Partner")
                    partnerSessionPlanRowIds = planRowIds
                    isRegeneratingFromOptions = false
                    // Transition phase → options ready (triggers routing in handlePartnerPhaseChange)
                    PartnerSessionManager.shared.transitionPhase(to: .optionsReadyForRanking, triggeredBy: "system")
                }
                // Notify inviter in-app
                NotificationManager.shared.addNotification(AppNotification(
                    type: .optionsReadyToRank,
                    title: "Your date options are ready.",
                    message: "Rank your favorites to reveal your perfect match.",
                    timestamp: Date()
                ))
                // Notify partner via notification_events
                if let rowId = session?.id, let partnerUserId = session?.partnerUserId {
                    try? await SupabaseService.shared.writeNotificationEvent(
                        userId: partnerUserId,
                        partnerSessionId: rowId,
                        type: PlanPhaseNotification.optionsReady.rawValue,
                        title: "Your date options are ready.",
                        body: "Rank your favorites to reveal your perfect match."
                    )
                }
            } catch {
                AppLogger.error("regenerateFromOptions failed: \(error)")
                await MainActor.run { isRegeneratingFromOptions = false }
            }
        }
    }

    /// When session is restored asynchronously (e.g. from keychain), coordinator must reflect auth state so we don't show login.
    private func setupAuthStateSubscription() {
        UserProfileManager.shared.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                guard let self = self else { return }
                if self.isLoggedIn != isLoggedIn {
                    self.isLoggedIn = isLoggedIn
                    if isLoggedIn { self.hasCompletedSignUp = true }
                    if !isLoggedIn {
                        self.experiencesCloudPullCompleted = true
                    }
                    self.saveState()
                }
            }
            .store(in: &cancellables)
        UserProfileManager.shared.$hasCompletedPreferences
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasCompletedPreferences in
                guard let self = self else { return }
                if self.hasCompletedPreferences != hasCompletedPreferences {
                    self.hasCompletedPreferences = hasCompletedPreferences
                    if hasCompletedPreferences {
                        self.hasDeferredInitialPreferences = false
                    }
                    self.saveState()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sync coordinator.generatedPlans when generator updates (e.g. background verification of options 2 and 3).
    private func setupGeneratorSubscription() {
        DatePlanGeneratorService.shared.$generatedPlans
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPlans in
                self?.mergeGeneratedPlans(from: newPlans)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($generatedPlans, $experiencesWaiting)
            .sink { [weak self] _, _ in
                self?.scheduleSyncAllUnsavedExperiencesToCloud()
            }
            .store(in: &cancellables)
    }
    
    /// Merge in verified plans from the generator. Match by index so verified B/C (new structs with new ids) replace the originals.
    private func mergeGeneratedPlans(from newPlans: [DatePlan]) {
        guard !newPlans.isEmpty else { return }
        var updated = generatedPlans
        for (index, genPlan) in newPlans.enumerated() {
            if index < updated.count {
                updated[index] = genPlan
            } else if index == updated.count {
                updated.append(genPlan)
            }
        }
        if updated != generatedPlans {
            generatedPlans = updated
            scheduleSyncAllUnsavedExperiencesToCloud()
        }
    }
    
    // MARK: - Navigation Actions
    
    func startDatePlanning() {
        startDatePlanning(mode: .fresh)
    }
    
    /// Intent for questionnaire: fresh (new), useLast (prefill from saved preferences), or resume (restore from stored progress).
    enum PlanIntent {
        case fresh
        case useLast
        case resume
    }
    
    @Published var planIntent: PlanIntent = .fresh
    
    /// When true, questionnaire shows "Save preferences" and only saves; no date plan generation.
    @Published var questionnairePreferencesOnly = false
    
    /// True when user tapped Regenerate from options sheet; we generate from last questionnaire without showing the form.
    @Published var isRegeneratingFromOptions = false
    
    func startDatePlanning(mode: PlanIntent) {
        guard UserProfileManager.shared.isLoggedIn else {
            authRequiredForIntent = mode
            planIntent = mode
            questionnairePreferencesOnly = false
            if mode == .fresh {
                lastQuestionnaireScheduledDate = nil
            }
            activeSheet = .authRequired(mode)
            return
        }
        planIntent = mode
        questionnairePreferencesOnly = false
        if mode == .fresh {
            lastQuestionnaireScheduledDate = nil
        }
        activeSheet = .questionnaire
    }
    
    /// Open questionnaire to edit and save preferences only (no plan generation).
    func startEditPreferencesOnly() {
        planIntent = .useLast
        questionnairePreferencesOnly = true
        activeSheet = .questionnaire
    }
    
    func completeQuestionnaire(with data: QuestionnaireData) {
        if isPartnerPlanningInviter {
            PartnerSessionManager.shared.setInviterFilled(data)
            isPartnerPlanningInviter = false
        }
        currentPlanPartnerNames = nil
        lastQuestionnaireScheduledDate = Self.scheduledDate(from: data)
        activeSheet = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let generator = DatePlanGeneratorService.shared
            if !generator.generatedPlans.isEmpty {
                self.currentDatePlan = generator.generatedPlans.first
                self.generatedPlans = generator.generatedPlans
                self.generatedPlansSelectedIndex = 0
            } else {
                self.currentDatePlan = DatePlan.sample
                self.generatedPlans = [DatePlan.sample, DatePlan.sampleOptionB, DatePlan.sampleOptionC]
            }
            
            if self.generatedPlans.count >= 3 {
                self.activeSheet = .datePlanOptions
            } else {
                self.activeSheet = .datePlanResult
            }
            self.scheduleSyncAllUnsavedExperiencesToCloud()
        }
    }
    
    func showGiftFinder(datePlan: DatePlan? = nil, dateLocation: String? = nil) {
        activeSheet = .giftFinder(datePlan: datePlan, dateLocation: dateLocation)
    }
    
    func showPlaylist(for planTitle: String, planId: UUID? = nil) {
        activeSheet = .playlist(planTitle: planTitle, planId: planId)
    }
    
    func showReservation(venueName: String, venueType: String, address: String?, phone: String?, bookingUrl: String? = nil, websiteUrl: String? = nil, openingHours: [String]? = nil, reservationPlatforms: [String]? = nil) {
        reservationPlatformPickerPayload = ReservationPlatformPickerPayload(
            venueName: venueName,
            phoneNumber: phone,
            address: address,
            reservationPlatforms: reservationPlatforms
        )
    }
    
    func showPartnerShare(for plan: DatePlan) {
        activeSheet = .partnerShare(plan: plan)
    }
    
    func showRouteMap(stops: [DatePlanStop], startingPoint: StartingPoint? = nil, showRouteLine: Bool = true) {
        activeSheet = .routeMap(stops: stops, startingPoint: startingPoint, showRouteLine: showRouteLine)
    }
    
    func presentMemoryGallery() {
        activeSheet = .memoryGallery
    }

    func showConversationStarters() {
        activeSheet = .conversationStarters
    }

    func showPastMagic() {
        activeSheet = .pastMagic
    }

    func showExplore() {
        activeSheet = .explore
    }

    func showPlaybook() {
        activeSheet = .playbook
    }

    func showPartnerPlanning() {
        activeSheet = .partnerPlanning
    }

    /// Load most recent plan and show result (for "Reuse Last Plan" from partner sheet).
    func showReuseLastPlan() {
        currentPlanPartnerNames = nil
        if let plan = generatedPlans.last {
            currentDatePlan = plan
            generatedPlansSelectedIndex = max(0, generatedPlans.count - 1)
            activeSheet = .datePlanResult
        } else if let plan = savedPlans.last {
            currentDatePlan = plan
            activeSheet = .datePlanResult
        }
    }

    /// Move a saved plan to Past Dates (date already happened).
    func markPlanAsPast(_ plan: DatePlan) {
        savedPlans.removeAll { $0.id == plan.id }
        if !pastPlans.contains(where: { $0.id == plan.id }) {
            pastPlans.append(plan)
        }
        saveState()
        Task { await uploadPlanToCloud(plan, status: "completed") }
        NotificationManager.shared.addNotification(AppNotification(
            type: .memoryCapture,
            title: "Capture your memory from \"\(plan.title)\"",
            message: "Add a photo and note to remember this special night.",
            timestamp: Date()
        ))
    }
    
    func savePlan(_ plan: DatePlan) {
        removeFromExperiencesWaiting(planId: plan.id)
        var planToSave = plan
        if let date = lastQuestionnaireScheduledDate {
            planToSave.scheduledDate = date
        }
        let isNewSave = !savedPlans.contains(where: { $0.id == plan.id })
        if let idx = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[idx] = planToSave
        } else {
            savedPlans.append(planToSave)
        }
        saveState()
        // Always sync to Supabase (retries first-time failures; RLS/JWT must succeed on each save).
        Task { await uploadPlanToCloud(planToSave, status: "planned") }
        // Notify inbox that a new plan was saved
        if isNewSave {
            NotificationManager.shared.addNotification(AppNotification(
                type: .datePlanReady,
                title: "Date plan saved!",
                message: "\"\(planToSave.title)\" is saved to your upcoming dates.",
                timestamp: Date()
            ))
            let milestones = [1, 3, 5, 10, 25]
            let count = savedPlans.count
            if milestones.contains(count) {
                let ordinal = count == 1 ? "1st" : "\(count)th"
                NotificationManager.shared.addNotification(AppNotification(
                    type: .dateMilestone,
                    title: "\(ordinal) date plan saved!",
                    message: count == 1
                        ? "Your first date plan is ready. Let the magic begin!"
                        : "You\'ve planned \(count) dates. Your romance game is strong!",
                    timestamp: Date()
                ))
            }
        }
        // Do not remove from generatedPlans here — keeps the options sheet on the same plan and avoids showing sample (e.g. NYC) when all three are saved. Cleared on sheet dismiss.
    }
    
    /// Update the scheduled date for a saved plan (e.g. after adding to calendar).
    func updateScheduledDate(for planId: UUID, date: Date) {
        guard let idx = savedPlans.firstIndex(where: { $0.id == planId }) else { return }
        var plan = savedPlans[idx]
        plan.scheduledDate = date
        savedPlans[idx] = plan
        saveState()
        Task { await uploadPlanToCloud(plan, status: "planned") }
    }
    
    /// Permanently delete a saved plan (local + backend if synced).
    func deletePlan(_ plan: DatePlan) {
        savedPlans.removeAll { $0.id == plan.id }
        removeFromExperiencesWaiting(planId: plan.id)
        saveState()
        Task {
            try? await SupabaseService.shared.deleteDatePlan(planId: plan.id)
        }
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
    
    /// Called from Date Plan Options sheet when user taps Regenerate: generate three new plans using the last submitted questionnaire data (no questionnaire UI).
    func requestRegenerateFromOptions() {
        guard let data = LastQuestionnaireStore.load() else {
            // No saved questionnaire; fall back to opening questionnaire prefilled from profile so they can submit again.
            planIntent = .useLast
            questionnairePreferencesOnly = false
            activeSheet = .questionnaire
            return
        }
        isRegeneratingFromOptions = true
        activeSheet = nil
        let generator = DatePlanGeneratorService.shared
        Task {
            do {
                _ = try await generator.generateDatePlan(from: data)
                await MainActor.run {
                    generatedPlans = generator.generatedPlans
                    generatedPlansSelectedIndex = 0
                    currentDatePlan = generator.generatedPlans.first
                    activeSheet = .datePlanOptions
                    isRegeneratingFromOptions = false
                    scheduleSyncAllUnsavedExperiencesToCloud()
                }
            } catch {
                AppLogger.error("regenerateWithModifiedPreferences failed: \(error)")
                await MainActor.run {
                    isRegeneratingFromOptions = false
                    activeSheet = .datePlanOptions
                }
            }
        }
    }
    
    func dismissToHome() {
        activeSheet = nil
        currentTab = .home
        navigationPath = NavigationPath()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        preferSignUpTabOnNextAuth = true
        saveState()
    }

    func consumePreferSignUpTab() {
        preferSignUpTabOnNextAuth = false
    }

    /// Re-read onboarding state from UserDefaults. Call when splash ends so we use current storage state (avoids stale value after reinstall).
    func syncOnboardingFromUserDefaults() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    #if DEBUG
    /// Reset onboarding so it shows again (for testing after reinstall or to replay the flow).
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        saveState()
    }
    #endif
    
    func completeSignUp() {
        hasCompletedSignUp = true
        isLoggedIn = true
        if !hasCompletedOnboarding {
            hasCompletedOnboarding = true
        }
        saveState()

        if let intent = authRequiredForIntent {
            authRequiredForIntent = nil
            activeSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else { return }
                self.planIntent = intent
                self.questionnairePreferencesOnly = false
                if intent == .fresh {
                    self.lastQuestionnaireScheduledDate = nil
                }
                self.activeSheet = .questionnaire
            }
        }
    }
    
    func skipLogin() {
        hasSkippedLogin = true
        saveState()
    }
    
    /// Dismiss auth-required sheet and clear intent so user is not stuck.
    func dismissAuthRequiredSheet() {
        authRequiredForIntent = nil
        activeSheet = nil
    }
    
    func completeSignIn() {
        hasCompletedSignUp = true
        isLoggedIn = true
        if !hasCompletedOnboarding {
            hasCompletedOnboarding = true
        }
        if UserProfileManager.shared.hasCompletedPreferences {
            hasCompletedPreferences = true
        }
        saveState()

        if let intent = authRequiredForIntent {
            authRequiredForIntent = nil
            activeSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else { return }
                self.planIntent = intent
                self.questionnairePreferencesOnly = false
                if intent == .fresh {
                    self.lastQuestionnaireScheduledDate = nil
                }
                self.activeSheet = .questionnaire
            }
        }
    }
    
    func completePreferences() {
        hasCompletedPreferences = true
        hasDeferredInitialPreferences = false
        saveState()
    }
    
    /// Close initial preferences (hero or questionnaire) without saving; user can finish from Profile later.
    func deferInitialPreferences() {
        hasDeferredInitialPreferences = true
        presentHeroBeforeInitialPreferences = false
        isPresentingInitialPreferencesFlow = false
        questionnairePreferencesOnly = false
        saveState()
    }

    /// Call from post-email-confirm hero CTA: show full-screen preferences questionnaire at root.
    func transitionFromHeroToInitialPreferences() {
        presentHeroBeforeInitialPreferences = false
        isPresentingInitialPreferencesFlow = true
        planIntent = .fresh
        questionnairePreferencesOnly = true
    }

    /// First-time prefs at root without hero (straight to questionnaire).
    func startInitialPreferencesQuestionnaireAtRoot() {
        isPresentingInitialPreferencesFlow = true
        planIntent = .fresh
        questionnairePreferencesOnly = true
    }
    
    func signOut() {
        print("[Auth][SignOut] NavigationCoordinator.signOut() — routing to login screen")

        // 1. Flip the flag that `RootNavigationView` switches on — view tree starts routing to the
        //    login screen within this main-actor tick. Do this BEFORE the heavier resets below so
        //    the user sees an instant transition, even if JSON-encode / UserDefaults writes hiccup.
        isLoggedIn = false
        activeSheet = nil

        // 2. Kick off profile manager sign-out (also flips its `isLoggedIn` and fires network teardown
        //    in the background — see `SupabaseService.signOut`).
        UserProfileManager.shared.signOut()

        // 3. Remaining state resets — all cheap, but run after the auth flag is already false.
        hasCompletedSignUp = false
        hasCompletedPreferences = false
        hasDeferredInitialPreferences = false
        hasSkippedLogin = false
        questionnairePreferencesOnly = false
        authRequiredForIntent = nil
        currentDatePlan = nil
        savedPlans = []
        generatedPlans = []
        pastPlans = []
        experiencesWaiting = []
        experiencesCloudPullCompleted = true
        currentTab = .home
        navigationPath = NavigationPath()
        UserDefaults.standard.removeObject(forKey: "hasSkippedLogin")
        saveState()

        print("[Auth][SignOut] State reset complete — isLoggedIn=\(isLoggedIn), hasSkippedLogin=\(hasSkippedLogin)")
    }
    
    // MARK: - Persistence
    
    private static let savedPlansKey = "dateGenie_savedPlans"
    private static let pastPlansKey = "dateGenie_pastPlans"
    private static let experiencesWaitingKey = "dateGenie_experiencesWaiting"
    private static let deferredInitialPreferencesKey = "dateGenie_deferredInitialPreferences"
    
    private func loadSavedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedSignUp = UserDefaults.standard.bool(forKey: "hasCompletedSignUp")
        hasSkippedLogin = UserDefaults.standard.bool(forKey: "hasSkippedLogin")
        
        isLoggedIn = UserProfileManager.shared.isLoggedIn
        hasCompletedPreferences = UserProfileManager.shared.hasCompletedPreferences
        
        if !hasCompletedPreferences {
            hasCompletedPreferences = UserDefaults.standard.bool(forKey: "hasCompletedPreferences")
        }
        
        if let data = UserDefaults.standard.data(forKey: Self.savedPlansKey),
           let plans = try? JSONDecoder().decode([DatePlan].self, from: data) {
            savedPlans = plans
        }
        if let data = UserDefaults.standard.data(forKey: Self.pastPlansKey),
           let plans = try? JSONDecoder().decode([DatePlan].self, from: data) {
            pastPlans = plans
        }
        if let data = UserDefaults.standard.data(forKey: Self.experiencesWaitingKey),
           let plans = try? JSONDecoder().decode([DatePlan].self, from: data) {
            experiencesWaiting = plans
        }
        
        hasDeferredInitialPreferences = UserDefaults.standard.bool(forKey: Self.deferredInitialPreferencesKey)
        
        // If there is no account session but prefs were never finished, do not skip onboarding just
        // because UserDefaults survived an app update — otherwise users land on the questionnaire
        // without auth. Guard with `getHasEverLoggedIn()` so users who deliberately signed out are
        // never sent back through onboarding on their next launch.
        if !UserProfileManager.shared.isLoggedIn && !hasSkippedLogin && !hasCompletedPreferences && hasCompletedOnboarding,
           !SupabaseService.shared.hasCachedSession(),
           !KeychainManager.shared.getHasEverLoggedIn() {
            hasCompletedOnboarding = false
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            saveState()
        }
        migratePastDuePlans()
    }
    
    /// Call when home tab appears or app becomes active so "Use & Generate" visibility stays correct after async preference load.
    func refreshPreferencesState() {
        hasCompletedPreferences = UserProfileManager.shared.hasCompletedPreferences || UserDefaults.standard.bool(forKey: "hasCompletedPreferences")
        migratePastDuePlans()
    }

    /// Moves any saved plan whose date has already passed into pastPlans automatically.
    /// Primary signal: scheduledDate is in the past.
    /// Fallback: no scheduledDate but the plan was created 30+ days ago.
    func migratePastDuePlans() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday
        let overdue = savedPlans.filter { plan in
            if let scheduled = plan.scheduledDate {
                return scheduled < startOfToday
            }
            return plan.createdAt < thirtyDaysAgo
        }
        guard !overdue.isEmpty else { return }
        let overdueIds = Set(overdue.map(\.id))
        savedPlans = savedPlans.filter { !overdueIds.contains($0.id) }
        let existingPastIds = Set(pastPlans.map(\.id))
        pastPlans = pastPlans + overdue.filter { !existingPastIds.contains($0.id) }
        saveState()
    }
    
    /// Build a single Date from questionnaire date + start time for display and calendar.
    static func scheduledDate(from data: QuestionnaireData) -> Date? {
        guard let day = data.dateScheduled else { return nil }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: day)
        let (hour, minute) = parseTimeString(data.startTime)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps)
    }
    
    private static func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return (18, 0) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        if let date = formatter.date(from: trimmed) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (c.hour ?? 18, c.minute ?? 0)
        }
        formatter.dateFormat = "h a"
        if let date = formatter.date(from: trimmed) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (c.hour ?? 18, c.minute ?? 0)
        }
        return (18, 0)
    }
    
    private func saveState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(hasCompletedSignUp, forKey: "hasCompletedSignUp")
        UserDefaults.standard.set(hasCompletedPreferences, forKey: "hasCompletedPreferences")
        UserDefaults.standard.set(hasSkippedLogin, forKey: "hasSkippedLogin")
        UserDefaults.standard.set(hasDeferredInitialPreferences, forKey: Self.deferredInitialPreferencesKey)
        
        if let data = try? JSONEncoder().encode(savedPlans) {
            UserDefaults.standard.set(data, forKey: Self.savedPlansKey)
        }
        if let data = try? JSONEncoder().encode(pastPlans) {
            UserDefaults.standard.set(data, forKey: Self.pastPlansKey)
        }
        if let data = try? JSONEncoder().encode(experiencesWaiting) {
            UserDefaults.standard.set(data, forKey: Self.experiencesWaitingKey)
        }
    }
    
    // MARK: - Cloud sync (restore history after reinstall / login)
    
    /// Call after login when coupleId is available to restore saved and past plans from Supabase.
    /// Merges with local state: rows that exist only locally (e.g. just saved, upload still in flight) are kept.
    /// Replacing wholesale would drop those plans when sync wins the race against `uploadPlanToCloud`.
    func syncDatePlansFromCloud(coupleId: UUID) {
        Task { await syncDatePlansFromCloudAsync(coupleId: coupleId) }
    }

    func syncDatePlansFromCloudAsync(coupleId: UUID) async {
        do {
            let dbPlans = try await SupabaseService.shared.getDatePlans(coupleId: coupleId)
            await applyRemoteDatePlans(dbPlans)
        } catch {
            await uploadAllLocalDatePlansToCloud()
        }
    }

    /// Solo-user (no couple) variant — pulls date_plans scoped by user_id only.
    func syncDatePlansFromCloudAsync(userId: UUID) async {
        do {
            let dbPlans = try await SupabaseService.shared.getDatePlans(userId: userId)
            await applyRemoteDatePlans(dbPlans)
        } catch {
            await uploadAllLocalDatePlansToCloud()
        }
    }

    /// Shared merge + upload logic for both couple and solo date plan pull paths.
    private func applyRemoteDatePlans(_ dbPlans: [DBDatePlan]) async {
        let planned = dbPlans.filter { $0.status == "planned" }
        let completed = dbPlans.filter { $0.status == "completed" }
        let remoteSaved: [DatePlan] = planned.map { DatePlanSyncHelpers.datePlan(from: $0) }
        let remotePast: [DatePlan] = completed.map { DatePlanSyncHelpers.datePlan(from: $0) }
        await MainActor.run {
            let remoteIds = Set(remoteSaved.map(\.id)).union(Set(remotePast.map(\.id)))
            let unsyncedSaved = savedPlans.filter { !remoteIds.contains($0.id) }
            let unsyncedPast = pastPlans.filter { !remoteIds.contains($0.id) }
            savedPlans = remoteSaved + unsyncedSaved
            pastPlans = remotePast + unsyncedPast
            saveState()
            migratePastDuePlans()
        }
        await uploadAllLocalDatePlansToCloud()
    }

    /// Upserts every saved and past plan so offline-only or failed uploads reach `date_plans` after login.
    private func uploadAllLocalDatePlansToCloud() async {
        let isLoggedIn = await MainActor.run { UserProfileManager.shared.isLoggedIn }
        guard isLoggedIn else { return }
        let sampleIds: Set<UUID> = [DatePlan.sample.id, DatePlan.sampleOptionB.id, DatePlan.sampleOptionC.id]
        let snapshot = await MainActor.run { () -> [(DatePlan, String)] in
            savedPlans.map { ($0, "planned") } + pastPlans.map { ($0, "completed") }
        }
        for (plan, status) in snapshot where !sampleIds.contains(plan.id) {
            await uploadPlanToCloud(plan, status: status)
        }
    }

    /// Call when logged in but there is no `couple_id` so `syncExperiencesWaitingFromCloud` never runs — unblocks cloud upload.
    func markExperiencesWaitingCloudPullFinished() {
        experiencesCloudPullCompleted = true
        scheduleSyncAllUnsavedExperiencesToCloud()
    }

    /// Restore Experiences Waiting from `public.experiences_waiting` (not mixed with `date_plans`).
    /// Merges with local rows that are not on the server yet (upload in flight).
    func syncExperiencesWaitingFromCloud(coupleId: UUID) {
        Task { await syncExperiencesWaitingFromCloudAsync(coupleId: coupleId) }
    }

    func syncExperiencesWaitingFromCloudAsync(coupleId: UUID) async {
        await MainActor.run { self.experiencesCloudPullCompleted = false }
        do {
            let rows = try await SupabaseService.shared.getExperiencesWaiting(coupleId: coupleId)
            let remote = rows.map(\.plan)
            let remoteIds = Set(remote.map(\.id))
            await MainActor.run {
                let unsynced = experiencesWaiting.filter { !remoteIds.contains($0.id) }
                experiencesWaiting = remote + unsynced
                saveState()
                self.experiencesCloudPullCompleted = true
                self.scheduleSyncAllUnsavedExperiencesToCloud()
            }
        } catch {
            await MainActor.run {
                self.experiencesCloudPullCompleted = true
                self.scheduleSyncAllUnsavedExperiencesToCloud()
            }
        }
    }

    /// Solo-user (no couple) variant — pulls experiences_waiting scoped by user_id only.
    func syncExperiencesWaitingFromCloudAsync(userId: UUID) async {
        await MainActor.run { self.experiencesCloudPullCompleted = false }
        do {
            let rows = try await SupabaseService.shared.getExperiencesWaiting(userId: userId)
            let remote = rows.map(\.plan)
            let remoteIds = Set(remote.map(\.id))
            await MainActor.run {
                let unsynced = experiencesWaiting.filter { !remoteIds.contains($0.id) }
                experiencesWaiting = remote + unsynced
                saveState()
                self.experiencesCloudPullCompleted = true
                self.scheduleSyncAllUnsavedExperiencesToCloud()
            }
        } catch {
            await MainActor.run {
                self.experiencesCloudPullCompleted = true
                self.scheduleSyncAllUnsavedExperiencesToCloud()
            }
        }
    }
    
    /// Upload or update a single plan on Supabase so history persists across reinstalls.
    private func uploadPlanToCloud(_ plan: DatePlan, status: String) async {
        AppLogger.debug("uploadPlanToCloud planId=\(plan.id) status=\(status)")
        do {
            let userId = try await SupabaseService.shared.syncAuthSessionAndReturnUserId()
            await MainActor.run {
                if UserProfileManager.shared.userId == nil {
                    UserProfileManager.shared.userId = userId
                }
            }
            var coupleId = await MainActor.run { UserProfileManager.shared.coupleId }
            if coupleId == nil {
                coupleId = try await SupabaseService.shared.getCoupleForUser(userId: userId)?.coupleId
                if let cid = coupleId {
                    await MainActor.run { UserProfileManager.shared.coupleId = cid }
                }
            }
            if coupleId == nil {
                let context = await MainActor.run { () -> (email: String, name: String) in
                    let em = UserProfileManager.shared.currentUser?.email ?? SupabaseService.shared.currentUser?.email ?? ""
                    let fromProfile = UserProfileManager.shared.currentUser?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !fromProfile.isEmpty { return (em, fromProfile) }
                    if let n = SupabaseService.shared.currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
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
                print("[uploadPlanToCloud] no coupleId yet; calling ensureUserAndCoupleIfMissing")
                try await SupabaseService.shared.ensureUserAndCoupleIfMissing(
                    userId: userId,
                    email: context.email.trimmingCharacters(in: .whitespaces).lowercased(),
                    name: context.name
                )
                coupleId = try await SupabaseService.shared.getCoupleForUser(userId: userId)?.coupleId
                if let cid = coupleId {
                    await MainActor.run { UserProfileManager.shared.coupleId = cid }
                }
            }
            guard let coupleId = coupleId else {
                print("[uploadPlanToCloud] error: no coupleId for user_id=\(userId) after ensure")
                return
            }
            AppLogger.debug("uploadPlanToCloud upserting planId=\(plan.id)")
            let dbPlan = DatePlanSyncHelpers.dbDatePlan(from: plan, userId: userId, coupleId: coupleId, status: status)
            _ = try await SupabaseService.shared.upsertDatePlan(dbPlan)
            AppLogger.debug("uploadPlanToCloud success planId=\(plan.id)")
        } catch {
            AppLogger.error("uploadPlanToCloud failed: \(error)")
        }
    }

    /// Enqueues a full sync (latest state after any in-flight pass completes). Bounded work: no parallel duplicate full syncs.
    private func scheduleSyncAllUnsavedExperiencesToCloud() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.experiencesWaitingSyncQueue.schedule { [weak self] in
                await self?.performSyncAllUnsavedExperiencesToCloud()
            }
        }
    }

    private func performSyncAllUnsavedExperiencesToCloud() async {
        let isLoggedIn = await MainActor.run { UserProfileManager.shared.isLoggedIn }
        guard isLoggedIn else { return }

        let snapshot = await MainActor.run { () -> (generated: [DatePlan], waiting: [DatePlan], savedIds: Set<UUID>, pastIds: Set<UUID>, pullDone: Bool) in
            (generatedPlans, experiencesWaiting, Set(savedPlans.map(\.id)), Set(pastPlans.map(\.id)), experiencesCloudPullCompleted)
        }

        let savedOrPast = snapshot.savedIds.union(snapshot.pastIds)
        let sampleIds: Set<UUID> = [DatePlan.sample.id, DatePlan.sampleOptionB.id, DatePlan.sampleOptionC.id]

        var combined: [DatePlan] = []
        var seen = Set<UUID>()
        for p in snapshot.generated + snapshot.waiting {
            guard !savedOrPast.contains(p.id), !sampleIds.contains(p.id), seen.insert(p.id).inserted else { continue }
            combined.append(p)
        }
        let localIds = Set(combined.map(\.id))
        guard !combined.isEmpty else { return }

        do {
            let userId = try await SupabaseService.shared.syncAuthSessionAndReturnUserId()
            await MainActor.run {
                if UserProfileManager.shared.userId == nil {
                    UserProfileManager.shared.userId = userId
                }
            }
            let coupleId = try await SupabaseService.shared.resolveCoupleIdForCurrentUser()

            for plan in combined {
                let row = DBExperiencesWaitingRow(id: plan.id, userId: userId, coupleId: coupleId, plan: plan)
                _ = try await SupabaseService.shared.upsertExperiencesWaiting(row)
            }

            let remoteRows = try await SupabaseService.shared.getExperiencesWaiting(coupleId: coupleId)
            // Only trim server rows after the initial merge finished — avoids deleting remote data while pull is in flight.
            if snapshot.pullDone && !localIds.isEmpty {
                for row in remoteRows where !localIds.contains(row.id) {
                    try await SupabaseService.shared.deleteExperiencesWaiting(planId: row.id)
                }
            }
            print("[syncExperiences] upserted \(combined.count) unsaved plans (generated + waiting)")
        } catch {
            print("[syncExperiences] error: \(error)")
        }
    }
    
    /// Call when date plan options sheet is dismissed: move any unsaved generated plans into Experiences Waiting, then clear generated plans so the next generation is fresh and we never show sample (e.g. NYC) after saving all three.
    func moveUnsavedPlansToExperiencesWaiting() {
        let savedIds = Set(savedPlans.map(\.id))
        let unsaved = generatedPlans.filter { !savedIds.contains($0.id) }
        if !unsaved.isEmpty {
            var updated = experiencesWaiting
            var newlyAdded: [DatePlan] = []
            for plan in unsaved {
                if !updated.contains(where: { $0.id == plan.id }) {
                    updated.append(plan)
                    newlyAdded.append(plan)
                }
            }
            if updated != experiencesWaiting {
                experiencesWaiting = updated
                saveState()
            }
            if !newlyAdded.isEmpty {
                let count = newlyAdded.count
                let label = count == 1 ? "1 unsaved date idea" : "\(count) unsaved date ideas"
                NotificationManager.shared.addNotification(AppNotification(
                    type: .unsavedDateWaiting,
                    title: "\(label) waiting for you",
                    message: "Save them before they disappear — your perfect date is in there!",
                    timestamp: Date()
                ))
            }
        }
        generatedPlans = []
        generatedPlansSelectedIndex = 0
        scheduleSyncAllUnsavedExperiencesToCloud()
    }
    
    /// Remove a plan from Experiences Waiting (e.g. after user saves it or dismisses from list).
    func removeFromExperiencesWaiting(planId: UUID) {
        experiencesWaiting.removeAll { $0.id == planId }
        saveState()
        Task {
            try? await SupabaseService.shared.deleteExperiencesWaiting(planId: planId)
        }
        scheduleSyncAllUnsavedExperiencesToCloud()
    }

    // MARK: - Upcoming Date Check

    /// Fires an in-app notification when a saved plan is scheduled today or tomorrow.
    /// Deduplicates per plan per day using UserDefaults so it fires at most once per calendar day.
    func checkUpcomingDates() {
        let key = "dateGenie_upcomingDateNotifiedIds"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) ?? tomorrow

        var notifiedIds = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

        for plan in savedPlans {
            guard let scheduled = plan.scheduledDate else { continue }
            let planDay = calendar.startOfDay(for: scheduled)
            let isUpcoming = planDay >= today && planDay < dayAfterTomorrow
            guard isUpcoming else { continue }

            let dedupeKey = "\(plan.id.uuidString)_\(today.timeIntervalSince1970)"
            guard !notifiedIds.contains(dedupeKey) else { continue }

            let isToday = planDay == today
            NotificationManager.shared.addNotification(AppNotification(
                type: .upcomingDate,
                title: isToday ? "Your date is tonight! 🌹" : "Your date is tomorrow! ✨",
                message: "\"\(plan.title)\" — are you ready for a magical night?",
                timestamp: Date()
            ))
            notifiedIds.insert(dedupeKey)
        }

        UserDefaults.standard.set(Array(notifiedIds), forKey: key)
    }
}

// MARK: - Root Navigation View
struct RootNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @EnvironmentObject private var accessManager: AccessManager
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            if showSplash {
                LuxurySplashView()
                    .transition(.opacity)
            } else if !coordinator.hasCompletedOnboarding {
                MobileOnboardingView()
                    .environmentObject(coordinator)
            } else if !coordinator.isLoggedIn && !coordinator.hasSkippedLogin {
                AuthenticationView(isReinstallFlow: false, onDismiss: nil, allowSkipToExplore: false)
                    .environmentObject(coordinator)
            } else if !coordinator.isLoggedIn && coordinator.hasSkippedLogin {
                LuxuryMainAppView()
                    .environmentObject(coordinator)
                    .environmentObject(userProfileManager)
            } else if !coordinator.hasCompletedPreferences && !coordinator.hasDeferredInitialPreferences {
                InitialPreferencesGateView()
                    .environmentObject(coordinator)
                    .environmentObject(userProfileManager)
            } else {
                LuxuryMainAppView()
                    .environmentObject(coordinator)
                    .environmentObject(userProfileManager)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: coordinator.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: coordinator.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: coordinator.hasSkippedLogin)
        .animation(.easeInOut(duration: 0.4), value: coordinator.hasCompletedPreferences)
        .animation(.easeInOut(duration: 0.4), value: coordinator.hasDeferredInitialPreferences)
        .onAppear {
            Task {
                // Record when the splash appeared so we can enforce a minimum display duration.
                let launchTime = Date()

                // Await the session check before making any routing decision.
                // `restoreSessionOnLaunch` calls `supabase.auth.session`, syncs the result into
                // `SupabaseService.isAuthenticated`, and logs the outcome. The reactive chain
                // (SupabaseService → UserProfileManager → NavigationCoordinator) then updates
                // `coordinator.isLoggedIn` synchronously within this same Task, so by the time
                // the splash is dismissed below, the correct screen is already determined.
                await SupabaseService.shared.restoreSessionOnLaunch()

                // Enforce a minimum splash duration (visual polish). If the session restore
                // finished quickly the remaining time is topped up; if it was slow the splash
                // already covered the wait and we dismiss immediately.
                let elapsed = Date().timeIntervalSince(launchTime)
                let minimumSplashSeconds: Double = 2.5
                let remaining = minimumSplashSeconds - elapsed
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }

                coordinator.syncOnboardingFromUserDefaults()
                withAnimation {
                    showSplash = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await PurchaseManager.shared.refreshEntitlements() }
                coordinator.checkUpcomingDates()
            }
        }
        .sheet(isPresented: $accessManager.isPaywallPresented, onDismiss: {
            accessManager.paywallSheetDismissed()
        }) {
            PaywallView(onSubscribed: {
                accessManager.handleSubscriptionResolved()
            }, showsNotNowButton: true)
        }
    }
}

// MARK: - Preview
#Preview {
    RootNavigationView()
        .environmentObject(AccessManager.shared)
}
