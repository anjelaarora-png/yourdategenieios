import SwiftUI
import Combine

// MARK: - App Destination Enum
enum AppDestination: Hashable {
    case landing
    case onboarding
    case questionnaire
    case datePlanResult(plan: DatePlan)
    case giftFinder(datePlan: DatePlan?, dateLocation: String?)
    case routeMap(stops: [DatePlanStop])
    case memoryGallery
    case playlist(planTitle: String)
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
        case .playlist(let title): hasher.combine("playlist-\(title)")
        case .reservation(let name, _, _, _): hasher.combine("reservation-\(name)")
        case .partnerShare(let plan): hasher.combine("share-\(plan.id)")
        case .savedPlans: hasher.combine("savedPlans")
        case .settings: hasher.combine("settings")
        }
    }
    
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Navigation Coordinator
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
    
    private var cancellables = Set<AnyCancellable>()
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case loveNote = "Love Note"
        case gifts = "Gifts"
        case memories = "Memories"
        case profile = "Profile"
        
        /// Short label for tab bar so text doesn’t overflow on small screens.
        var tabBarTitle: String {
            switch self {
            case .home: return "Home"
            case .loveNote: return "Love"
            case .gifts: return "Gifts"
            case .memories: return "Photos"
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
        case playlist(planTitle: String)
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
        case authRequired(PlanIntent)

        var id: String {
            switch self {
            case .questionnaire: return "questionnaire"
            case .datePlanResult: return "datePlanResult"
            case .datePlanOptions: return "datePlanOptions"
            case .giftFinder: return "giftFinder"
            case .playlist: return "playlist"
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
            case .authRequired(let intent): return "authRequired-\(intent)"
            }
        }
    }
    
    private init() {
        loadSavedState()
        setupGeneratorSubscription()
        setupAuthStateSubscription()
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
        }
    }
    
    // MARK: - Navigation Actions
    
    func startDatePlanning() {
        activeSheet = .questionnaire
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
        }
    }
    
    func showGiftFinder(datePlan: DatePlan? = nil, dateLocation: String? = nil) {
        activeSheet = .giftFinder(datePlan: datePlan, dateLocation: dateLocation)
    }
    
    func showPlaylist(for planTitle: String) {
        activeSheet = .playlist(planTitle: planTitle)
    }
    
    func showReservation(venueName: String, venueType: String, address: String?, phone: String?, bookingUrl: String? = nil, websiteUrl: String? = nil, openingHours: [String]? = nil) {
        activeSheet = .reservation(venueName: venueName, venueType: venueType, address: address, phone: phone, bookingUrl: bookingUrl, websiteUrl: websiteUrl, openingHours: openingHours)
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
    }
    
    func savePlan(_ plan: DatePlan) {
        removeFromExperiencesWaiting(planId: plan.id)
        if !savedPlans.contains(where: { $0.id == plan.id }) {
            var planToSave = plan
            if let date = lastQuestionnaireScheduledDate {
                planToSave.scheduledDate = date
            }
            savedPlans.append(planToSave)
            saveState()
            Task { await uploadPlanToCloud(planToSave, status: "planned") }
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
                }
            } catch {
                await MainActor.run {
                    isRegeneratingFromOptions = false
                    activeSheet = .datePlanOptions
                    // Keep previous plans visible; generator.error is shown by loading view or we could present an alert
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
        saveState()
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
        
        if UserProfileManager.shared.hasCompletedPreferences {
            hasCompletedPreferences = true
        }
        saveState()
    }
    
    func completePreferences() {
        hasCompletedPreferences = true
        saveState()
    }
    
    func signOut() {
        UserProfileManager.shared.signOut()
        isLoggedIn = false
        hasCompletedSignUp = false
        hasCompletedPreferences = false
        currentDatePlan = nil
        savedPlans = []
        generatedPlans = []
        pastPlans = []
        currentTab = .home
        navigationPath = NavigationPath()
        saveState()
    }
    
    // MARK: - Persistence
    
    private static let savedPlansKey = "dateGenie_savedPlans"
    private static let pastPlansKey = "dateGenie_pastPlans"
    private static let experiencesWaitingKey = "dateGenie_experiencesWaiting"
    
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
    }
    
    /// Call when home tab appears or app becomes active so "Use & Generate" visibility stays correct after async preference load.
    func refreshPreferencesState() {
        hasCompletedPreferences = UserProfileManager.shared.hasCompletedPreferences || UserDefaults.standard.bool(forKey: "hasCompletedPreferences")
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
    func syncDatePlansFromCloud(coupleId: UUID) {
        Task {
            do {
                let dbPlans = try await SupabaseService.shared.getDatePlans(coupleId: coupleId)
                let planned = dbPlans.filter { $0.status == "planned" }
                let completed = dbPlans.filter { $0.status == "completed" }
                let saved: [DatePlan] = planned.compactMap { DatePlanSyncHelpers.datePlan(from: $0) }
                let past: [DatePlan] = completed.compactMap { DatePlanSyncHelpers.datePlan(from: $0) }
                await MainActor.run {
                    if !saved.isEmpty || !past.isEmpty {
                        savedPlans = saved
                        pastPlans = past
                        saveState()
                    }
                }
            } catch {
                // User may be offline or table may not exist yet
            }
        }
    }
    
    /// Upload or update a single plan on Supabase so history persists across reinstalls.
    private func uploadPlanToCloud(_ plan: DatePlan, status: String) async {
        guard let coupleId = UserProfileManager.shared.coupleId else { return }
        let dbPlan = DatePlanSyncHelpers.dbDatePlan(from: plan, coupleId: coupleId, status: status)
        do {
            if try await SupabaseService.shared.getDatePlan(planId: plan.id) != nil {
                _ = try await SupabaseService.shared.updateDatePlan(dbPlan)
            } else {
                _ = try await SupabaseService.shared.createDatePlan(dbPlan)
            }
        } catch {
            // User may be offline
        }
    }
    
    /// Call when date plan options sheet is dismissed: move any unsaved generated plans into Experiences Waiting, then clear generated plans so the next generation is fresh and we never show sample (e.g. NYC) after saving all three.
    func moveUnsavedPlansToExperiencesWaiting() {
        let savedIds = Set(savedPlans.map(\.id))
        let unsaved = generatedPlans.filter { !savedIds.contains($0.id) }
        if !unsaved.isEmpty {
            var updated = experiencesWaiting
            for plan in unsaved {
                if !updated.contains(where: { $0.id == plan.id }) {
                    updated.append(plan)
                }
            }
            if updated != experiencesWaiting {
                experiencesWaiting = updated
                saveState()
            }
        }
        generatedPlans = []
        generatedPlansSelectedIndex = 0
    }
    
    /// Remove a plan from Experiences Waiting (e.g. after user saves it).
    func removeFromExperiencesWaiting(planId: UUID) {
        experiencesWaiting.removeAll { $0.id == planId }
        saveState()
    }
}

// MARK: - Root Navigation View
struct RootNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @State private var showSplash = true
    
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
                AuthenticationView(onDismiss: { coordinator.skipLogin() })
                    .environmentObject(coordinator)
            } else if !coordinator.isLoggedIn && coordinator.hasSkippedLogin {
                LuxuryMainAppView()
                    .environmentObject(coordinator)
                    .environmentObject(userProfileManager)
            } else if !coordinator.hasCompletedPreferences {
                PreferencesSetupView()
                    .environmentObject(coordinator)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                coordinator.syncOnboardingFromUserDefaults()
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RootNavigationView()
}
