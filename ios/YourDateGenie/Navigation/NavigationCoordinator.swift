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

    @Published var activeSheet: ActiveSheet?

    /// Dates that have already taken place (moved from saved when user marks as done).
    @Published var pastPlans: [DatePlan] = []
    
    /// Scheduled date/time from the last completed questionnaire; applied when user saves a plan so Upcoming Magic shows it.
    private(set) var lastQuestionnaireScheduledDate: Date?
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case explore = "Explore"
        case memories = "Memories"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .explore: return "sparkles"
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
        case reservation(venueName: String, venueType: String, address: String?, phone: String?)
        case partnerShare(plan: DatePlan)
        case routeMap(stops: [DatePlanStop])
        case memoryGallery
        case conversationStarters
        case pastMagic
        case savedPlansList
        case settings

        var id: String {
            switch self {
            case .questionnaire: return "questionnaire"
            case .datePlanResult: return "datePlanResult"
            case .datePlanOptions: return "datePlanOptions"
            case .giftFinder: return "giftFinder"
            case .playlist: return "playlist"
            case .reservation: return "reservation"
            case .partnerShare: return "partnerShare"
            case .routeMap: return "routeMap"
            case .memoryGallery: return "memoryGallery"
            case .conversationStarters: return "conversationStarters"
            case .pastMagic: return "pastMagic"
            case .savedPlansList: return "savedPlansList"
            case .settings: return "settings"
            }
        }
    }
    
    private init() {
        loadSavedState()
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
    
    func startDatePlanning(mode: PlanIntent) {
        planIntent = mode
        if mode == .fresh {
            lastQuestionnaireScheduledDate = nil
        }
        activeSheet = .questionnaire
    }
    
    func completeQuestionnaire(with data: QuestionnaireData) {
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
    
    func showReservation(venueName: String, venueType: String, address: String?, phone: String?) {
        activeSheet = .reservation(venueName: venueName, venueType: venueType, address: address, phone: phone)
    }
    
    func showPartnerShare(for plan: DatePlan) {
        activeSheet = .partnerShare(plan: plan)
    }
    
    func showRouteMap(stops: [DatePlanStop]) {
        activeSheet = .routeMap(stops: stops)
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

    /// Move a saved plan to Past Magic (date already happened).
    func markPlanAsPast(_ plan: DatePlan) {
        savedPlans.removeAll { $0.id == plan.id }
        if !pastPlans.contains(where: { $0.id == plan.id }) {
            pastPlans.append(plan)
        }
        saveState()
    }
    
    func savePlan(_ plan: DatePlan) {
        if !savedPlans.contains(where: { $0.id == plan.id }) {
            var planToSave = plan
            if let date = lastQuestionnaireScheduledDate {
                planToSave.scheduledDate = date
            }
            savedPlans.append(planToSave)
            saveState()
        }
        generatedPlans.removeAll { $0.id == plan.id }
    }
    
    /// Update the scheduled date for a saved plan (e.g. after adding to calendar).
    func updateScheduledDate(for planId: UUID, date: Date) {
        guard let idx = savedPlans.firstIndex(where: { $0.id == planId }) else { return }
        var plan = savedPlans[idx]
        plan.scheduledDate = date
        savedPlans[idx] = plan
        saveState()
    }
    
    func dismissSheet() {
        activeSheet = nil
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
    
    func completeSignUp() {
        hasCompletedSignUp = true
        isLoggedIn = true
        saveState()
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
    
    private func loadSavedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedSignUp = UserDefaults.standard.bool(forKey: "hasCompletedSignUp")
        
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
        
        if let data = try? JSONEncoder().encode(savedPlans) {
            UserDefaults.standard.set(data, forKey: Self.savedPlansKey)
        }
        if let data = try? JSONEncoder().encode(pastPlans) {
            UserDefaults.standard.set(data, forKey: Self.pastPlansKey)
        }
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
            } else if !coordinator.isLoggedIn {
                AuthenticationView()
                    .environmentObject(coordinator)
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
        .animation(.easeInOut(duration: 0.4), value: coordinator.hasCompletedPreferences)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
