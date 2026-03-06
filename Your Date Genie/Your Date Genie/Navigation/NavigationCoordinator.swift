import SwiftUI
import Combine

// MARK: - App Notification Model
struct AppNotification: Identifiable, Equatable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool = false
    var imageUrl: String?
    
    enum NotificationType: String {
        case datePlanReady = "plan_ready"
        case dateReminder = "reminder"
        case newInspiration = "inspiration"
        case giftIdea = "gift"
        case specialOccasion = "occasion"
        case weekendSuggestion = "weekend"
    }
    
    var icon: String {
        switch type {
        case .datePlanReady: return "sparkles"
        case .dateReminder: return "calendar.badge.clock"
        case .newInspiration: return "lightbulb.fill"
        case .giftIdea: return "gift.fill"
        case .specialOccasion: return "star.fill"
        case .weekendSuggestion: return "sun.max.fill"
        }
    }
    
    var accentColor: Color {
        switch type {
        case .datePlanReady: return Color.luxuryGold
        case .dateReminder: return Color.luxuryGoldLight
        case .newInspiration: return Color(hex: "FFD700")
        case .giftIdea: return Color(hex: "FF69B4")
        case .specialOccasion: return Color(hex: "FFB347")
        case .weekendSuggestion: return Color(hex: "87CEEB")
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var showNotificationsSheet = false
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private init() {
        loadSampleNotifications()
    }
    
    private func loadSampleNotifications() {
        notifications = [
            AppNotification(
                type: .weekendSuggestion,
                title: "Weekend Magic Awaits!",
                message: "The weather looks perfect for a rooftop dinner. Want us to plan something special?",
                timestamp: Date(),
                imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .newInspiration,
                title: "New Experience Unlocked",
                message: "A hidden speakeasy just opened nearby - perfect for your next adventure!",
                timestamp: Date().addingTimeInterval(-3600),
                imageUrl: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .datePlanReady,
                title: "Your Genie Has Ideas!",
                message: "Based on your preferences, we've crafted 3 magical evening plans for you.",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true,
                imageUrl: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .giftIdea,
                title: "Thoughtful Gesture Alert",
                message: "We found the perfect surprise to make your next date unforgettable.",
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                imageUrl: "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=100&h=100&fit=crop"
            )
        ]
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
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
    @Published var isLoggedIn = false
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedSignUp = false
    @Published var hasCompletedPreferences = false
    @Published var showMemoryGallery = false
    @Published var showMemoryCapture = false
    
    @Published var activeSheet: ActiveSheet?
    
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
        case memoryCapture
        
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
            case .memoryCapture: return "memoryCapture"
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
    
    func completeQuestionnaire(with data: QuestionnaireData) {
        activeSheet = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let generator = DatePlanGeneratorService.shared
            if !generator.generatedPlans.isEmpty {
                self.currentDatePlan = generator.generatedPlans.first
                self.generatedPlans = generator.generatedPlans
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
    
    func showMemoryCapture() {
        activeSheet = .memoryCapture
    }
    
    func savePlan(_ plan: DatePlan) {
        if !savedPlans.contains(where: { $0.id == plan.id }) {
            savedPlans.append(plan)
            saveState()
        }
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
        currentTab = .home
        navigationPath = NavigationPath()
        saveState()
    }
    
    // MARK: - Persistence
    
    private func loadSavedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedSignUp = UserDefaults.standard.bool(forKey: "hasCompletedSignUp")
        hasCompletedPreferences = UserDefaults.standard.bool(forKey: "hasCompletedPreferences")
        isLoggedIn = UserProfileManager.shared.isLoggedIn
    }
    
    private func saveState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(hasCompletedSignUp, forKey: "hasCompletedSignUp")
        UserDefaults.standard.set(hasCompletedPreferences, forKey: "hasCompletedPreferences")
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

// MARK: - Luxury Splash View
struct LuxurySplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var sparkleRotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            // Subtle gold glow in center
            RadialGradient.goldGlow
                .opacity(0.4)
                .scaleEffect(1.5)
            
            VStack(spacing: 24) {
                // Animated sparkle logo
                ZStack {
                    // Outer glow
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundColor(Color.luxuryGold.opacity(0.3))
                        .blur(radius: 20)
                    
                    // Main icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundStyle(LinearGradient.goldShimmer)
                        .rotationEffect(.degrees(sparkleRotation))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Your Date")
                            .font(Font.header(24, weight: .regular))
                            .foregroundColor(Color.luxuryGold)
                        Text("Genie")
                            .font(Font.tangerine(48, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                    
                    HStack(spacing: 6) {
                        Text("Date nights,")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                        Text("planned")
                            .font(Font.tangerine(28, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("for you.")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
}

// MARK: - Luxury Main App View (Tab-based)
struct LuxuryMainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            LuxuryHomeTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.home.rawValue, systemImage: NavigationCoordinator.Tab.home.icon)
                }
                .tag(NavigationCoordinator.Tab.home)
            
            LuxuryExploreTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.explore.rawValue, systemImage: NavigationCoordinator.Tab.explore.icon)
                }
                .tag(NavigationCoordinator.Tab.explore)
            
            MemoriesTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.memories.rawValue, systemImage: NavigationCoordinator.Tab.memories.icon)
                }
                .tag(NavigationCoordinator.Tab.memories)
            
            LuxuryProfileTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.profile.rawValue, systemImage: NavigationCoordinator.Tab.profile.icon)
                }
                .tag(NavigationCoordinator.Tab.profile)
        }
        .tint(Color.luxuryGold)
        .onAppear {
            // Style tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.luxuryMaroon)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.luxuryMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.luxuryMuted)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.luxuryGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.luxuryGold)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .sheet(isPresented: $coordinator.showMemoryGallery) {
            MemoryGalleryView(showCloseButton: true)
        }
        .sheet(isPresented: $coordinator.showMemoryCapture) {
            AddMemorySheet()
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: NavigationCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .questionnaire:
            QuestionnaireView { data in
                coordinator.completeQuestionnaire(with: data)
            }
        case .datePlanOptions:
            DatePlanOptionsView(
                plans: coordinator.generatedPlans,
                onSave: { plan in coordinator.savePlan(plan) },
                onRegenerate: { /* Regenerate logic */ }
            )
            .environmentObject(coordinator)
        case .datePlanResult:
            if let plan = coordinator.currentDatePlan {
                DatePlanResultView(
                    plan: plan,
                    onSave: { coordinator.savePlan(plan) },
                    onRegenerate: { /* Regenerate logic */ }
                )
                .environmentObject(coordinator)
            }
        case .giftFinder(let datePlan, let dateLocation):
            GiftFinderView(datePlan: datePlan, dateLocation: dateLocation)
        case .playlist(let title):
            PlaylistWidgetView(planTitle: title)
        case .reservation(let name, let type, let address, let phone):
            ReservationWidgetView(
                venueName: name,
                venueType: type,
                address: address,
                phoneNumber: phone
            )
        case .partnerShare(let plan):
            PartnerShareView(plan: plan)
        case .routeMap(let stops):
            NavigationStack {
                RouteMapView(stops: stops)
                    .navigationTitle("Your Route")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                coordinator.dismissSheet()
                            } label: {
                                HStack(spacing: 8) {
                                    AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=40&h=40&fit=crop")) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Circle().fill(Color.luxuryGold.opacity(0.3))
                                        }
                                    }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    
                                    Text("Done")
                                }
                                .foregroundColor(Color.luxuryGold)
                            }
                        }
                    }
            }
        case .memoryCapture:
            MemoryGalleryView(showCloseButton: true)
        }
    }
}

// MARK: - Luxury Home Tab View
struct LuxuryHomeTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var sparkleAnimation = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                // Magical floating particles
                FloatingParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        magicalCTASection
                        upcomingExperiencesSection
                        quickActionsSection
                        
                        if !coordinator.savedPlans.isEmpty {
                            savedPlansSection
                        }
                        
                        featuresSection
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient.goldShimmer)
                            .rotationEffect(.degrees(sparkleAnimation ? 10 : -10))
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: sparkleAnimation)
                        Text("Your Date")
                            .font(Font.header(14, weight: .regular))
                            .foregroundColor(Color.luxuryGold)
                        Text("Genie")
                            .font(Font.tangerine(26, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellButton(notificationManager: notificationManager)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                sparkleAnimation = true
            }
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(greeting)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
            
            Text(magicalGreeting)
                .font(Font.header(26, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var magicalCTASection: some View {
        Button {
            coordinator.startDatePlanning()
        } label: {
            ZStack {
                // Background image
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600&h=300&fit=crop")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 180)
                .clipped()
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.luxuryMaroon.opacity(0.3),
                        Color.luxuryMaroon.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Animated sparkles
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 14))
                                .foregroundColor(Color.luxuryGold)
                                .opacity(pulseAnimation ? 1 : 0.5)
                                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.3),
                                    value: pulseAnimation
                                )
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text("Create Your Next")
                            .font(Font.header(22, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                        Text("Adventure")
                            .font(Font.tangerine(36, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Let your")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                        Text("Genie")
                            .font(Font.tangerine(26, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("craft an unforgettable experience")
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 16))
                        Text("Start Planning")
                            .font(Font.bodySans(15, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(25)
                    .shadow(color: Color.luxuryGold.opacity(0.4), radius: 12, y: 4)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.luxuryGold.opacity(0.6), Color.luxuryGold.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.luxuryGold.opacity(0.2), radius: 20, y: 10)
        }
        .padding(.horizontal, 20)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var upcomingExperiencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(Color.luxuryGold)
                Text("Experiences")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Waiting")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ExperienceCard(
                        title: "Rooftop Sunset",
                        subtitle: "This Weekend",
                        emoji: "🌅",
                        imageUrl: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop"
                    )
                    ExperienceCard(
                        title: "Jazz & Wine",
                        subtitle: "Perfect for evenings",
                        emoji: "🎷",
                        imageUrl: "https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=200&h=200&fit=crop"
                    )
                    ExperienceCard(
                        title: "Starlit Picnic",
                        subtitle: "Under the stars",
                        emoji: "✨",
                        imageUrl: "https://images.unsplash.com/photo-1528495612343-9ca9f4a4de28?w=200&h=200&fit=crop"
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private var magicalGreeting: String {
        let greetings = [
            "What magic shall we create?",
            "Ready for something wonderful?",
            "Let's make tonight special",
            "Adventure awaits you",
            "Time for something magical"
        ]
        return greetings.randomElement() ?? "What magic shall we create?"
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Quick")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                Text("Magic")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    LuxuryQuickTile(icon: "gift.fill", title: "Surprises", color: Color.luxuryGold) {
                        coordinator.showGiftFinder(
                            datePlan: coordinator.currentDatePlan,
                            dateLocation: coordinator.currentDatePlan?.stops.first?.address
                        )
                    }
                    
                    LuxuryQuickTile(icon: "photo.stack.fill", title: "Memories", color: Color.luxuryGoldLight) {
                        coordinator.currentTab = .memories
                    }
                    
                    LuxuryQuickTile(icon: "bookmark.fill", title: "Favorites", color: Color.luxuryGold) {
                        // Show saved plans
                    }
                    
                    LuxuryQuickTile(icon: "clock.fill", title: "Past Magic", color: Color.luxuryGoldLight) {
                        // Show history
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var savedPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Text("Your Planned")
                        .font(Font.header(17, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Adventures")
                        .font(Font.tangerine(28, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Spacer()
                
                Button {
                    // Show all saved plans
                } label: {
                    HStack(spacing: 6) {
                        Text("See All")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11))
                    }
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(coordinator.savedPlans) { plan in
                        LuxurySavedPlanCard(plan: plan) {
                            coordinator.currentDatePlan = plan
                            coordinator.activeSheet = .datePlanResult
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Magical")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Tools")
                    .font(Font.header(17, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                LuxuryFeatureTile(icon: "wand.and.stars", title: "AI Genie", subtitle: "Personalized magic")
                LuxuryFeatureTile(icon: "map.fill", title: "Journey Map", subtitle: "Navigate your night")
                LuxuryFeatureTile(icon: "music.note", title: "Mood Music", subtitle: "Set the vibe")
                LuxuryFeatureTile(icon: "heart.circle.fill", title: "Share Joy", subtitle: "Send to your love")
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Notification Bell Button
struct NotificationBellButton: View {
    @ObservedObject var notificationManager: NotificationManager
    @State private var bellAnimation = false
    
    var body: some View {
        Button {
            notificationManager.showNotificationsSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Glow effect
                    if notificationManager.unreadCount > 0 {
                        Circle()
                            .fill(Color.luxuryGold.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)
                    }
                    
                    Image(systemName: notificationManager.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.luxuryGold)
                        .rotationEffect(.degrees(bellAnimation && notificationManager.unreadCount > 0 ? 15 : 0))
                        .animation(
                            notificationManager.unreadCount > 0 ?
                            .easeInOut(duration: 0.15).repeatCount(6, autoreverses: true) : .default,
                            value: bellAnimation
                        )
                }
                
                // Badge
                if notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount)")
                        .font(Font.bodySans(10, weight: .bold))
                        .foregroundColor(Color.luxuryMaroon)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(LinearGradient.goldShimmer)
                        )
                        .offset(x: 8, y: -8)
                }
            }
        }
        .onAppear {
            if notificationManager.unreadCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    bellAnimation = true
                }
            }
        }
    }
}

// MARK: - Notifications Sheet View
struct NotificationsSheetView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if notificationManager.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(Color.luxuryMuted)
                        
                        Text("No notifications yet")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                        
                        HStack(spacing: 4) {
                            Text("We'll let you know when there's something")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                            Text("magical!")
                                .font(Font.tangerine(26, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationManager.notifications) { notification in
                                NotificationRow(notification: notification) {
                                    notificationManager.markAsRead(notification)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationManager.unreadCount > 0 {
                        Button {
                            notificationManager.markAllAsRead()
                        } label: {
                            Text("Mark All Read")
                                .font(Font.bodySans(13, weight: .medium))
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.luxuryGold.opacity(0.8))
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Image or icon
                ZStack {
                    if let imageUrl = notification.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty, .failure:
                                notification.accentColor.opacity(0.3)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        notification.accentColor.opacity(0.3)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(notification.accentColor.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: notification.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(Font.bodySans(14, weight: notification.isRead ? .medium : .bold))
                            .foregroundColor(notification.isRead ? Color.luxuryCreamMuted : Color.luxuryCream)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.luxuryGold)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(2)
                    
                    Text(timeAgo(notification.timestamp))
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.luxuryMuted.opacity(0.7))
                }
            }
            .padding(14)
            .background(
                notification.isRead ? Color.luxuryMaroonLight.opacity(0.5) : Color.luxuryMaroonLight
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        notification.isRead ? Color.clear : notification.accentColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Floating Particles View
struct FloatingParticlesView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: particle.size))
                        .foregroundColor(Color.luxuryGold)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 20...60)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                for i in particles.indices {
                    particles[i].y -= CGFloat(particles[i].speed)
                    particles[i].opacity = Double.random(in: 0.1...0.4)
                    
                    if particles[i].y < -20 {
                        particles[i].y = size.height + 20
                        particles[i].x = CGFloat.random(in: 0...size.width)
                    }
                }
            }
        }
    }
}

// MARK: - Experience Card
struct ExperienceCard: View {
    let title: String
    let subtitle: String
    let emoji: String
    let imageUrl: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 140, height: 100)
                .clipped()
                
                LinearGradient(
                    colors: [.clear, Color.luxuryMaroon.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Text(emoji)
                    .font(.system(size: 28))
                    .padding(10)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.header(14, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .frame(width: 140)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views
struct LuxuryQuickTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    var imageUrl: String? = nil
    
    private var defaultImageUrl: String {
        switch icon {
        case "gift.fill": return "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=120&h=120&fit=crop"
        case "photo.stack.fill": return "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=120&h=120&fit=crop"
        case "bookmark.fill": return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        case "clock.fill": return "https://images.unsplash.com/photo-1501139083538-0139583c060f?w=120&h=120&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: imageUrl ?? defaultImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                
                Text(title)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
            .frame(width: 80)
        }
    }
}

struct LuxurySavedPlanCard: View {
    let plan: DatePlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(plan.stops.prefix(3)) { stop in
                        Text(stop.emoji)
                            .font(.system(size: 22))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(Font.header(15, weight: .bold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(1)
                    
                    Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            .padding(18)
            .frame(width: 190)
            .luxuryCard()
        }
    }
}

struct LuxuryFeatureTile: View {
    let icon: String
    let title: String
    let subtitle: String
    
    private var imageUrl: String {
        switch icon {
        case "wand.and.stars": return "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"
        case "map.fill": return "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=100&h=100&fit=crop"
        case "music.note": return "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&h=100&fit=crop"
        case "heart.circle.fill": return "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=100&h=100&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=100&h=100&fit=crop"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient.goldShimmer)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                
                Text(subtitle)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
            
            Spacer()
        }
        .padding(16)
        .luxuryCard(hasBorder: false)
    }
}

// MARK: - Luxury Explore Tab View
struct LuxuryExploreTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Explore")
                                .font(Font.tangerine(52, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            
                            Text("Discover new date ideas")
                                .font(Font.bodySans(15, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        .padding(.top, 16)
                        
                        // Date Types
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Date")
                                    .font(Font.header(17, weight: .regular))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Types")
                                    .font(Font.tangerine(28, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    LuxuryDateTypeTile(emoji: "🌹", title: "Romantic")
                                    LuxuryDateTypeTile(emoji: "🎉", title: "Fun")
                                    LuxuryDateTypeTile(emoji: "🏠", title: "Cozy")
                                    LuxuryDateTypeTile(emoji: "🚀", title: "Adventure")
                                    LuxuryDateTypeTile(emoji: "✨", title: "Special")
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Inspiration
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Get")
                                    .font(Font.header(17, weight: .regular))
                                    .foregroundColor(Color.luxuryCream)
                                Text("Inspired")
                                    .font(Font.tangerine(28, weight: .bold))
                                    .italic()
                                    .foregroundColor(Color.luxuryGold)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                LuxuryInspirationCard(
                                    title: "Wine & Dine",
                                    description: "Elegant evening with wine tasting",
                                    emoji: "🍷"
                                )
                                
                                LuxuryInspirationCard(
                                    title: "Outdoor Adventure",
                                    description: "Hiking, picnic, and sunset views",
                                    emoji: "🌄"
                                )
                                
                                LuxuryInspirationCard(
                                    title: "Arts & Culture",
                                    description: "Museums, galleries, and live shows",
                                    emoji: "🎨"
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
}

struct LuxuryDateTypeTile: View {
    let emoji: String
    let title: String
    
    private var imageUrl: String {
        switch title {
        case "Romantic": return "https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?w=140&h=140&fit=crop"
        case "Fun": return "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=140&h=140&fit=crop"
        case "Cozy": return "https://images.unsplash.com/photo-1558171813-4c088753af8f?w=140&h=140&fit=crop"
        case "Adventure": return "https://images.unsplash.com/photo-1533130061792-64b345e4a833?w=140&h=140&fit=crop"
        case "Special": return "https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=140&h=140&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=140&h=140&fit=crop"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
        }
    }
}

struct LuxuryInspirationCard: View {
    let title: String
    let description: String
    let emoji: String
    
    private var imageUrl: String {
        switch title {
        case "Wine & Dine": return "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=120&h=120&fit=crop"
        case "Outdoor Adventure": return "https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=120&h=120&fit=crop"
        case "Arts & Culture": return "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=120&h=120&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=120&h=120&fit=crop"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color.luxuryMaroonLight
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Text(emoji)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryGold)
                
                Text(description)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.luxuryGold.opacity(0.6))
        }
        .padding(20)
        .luxuryCard()
    }
}

// MARK: - Memories Tab View
struct MemoriesTabView: View {
    var body: some View {
        MemoryGalleryView()
    }
}

// MARK: - Luxury Profile Tab View
struct LuxuryProfileTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showSignOutAlert = false
    
    private var userProfile: UserProfile? {
        profileManager.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.goldShimmer.opacity(0.2))
                                    .frame(width: 90, height: 90)
                                
                                Text(userInitials)
                                    .font(Font.header(32, weight: .bold))
                                    .foregroundColor(Color.luxuryGold)
                            }
                            
                            VStack(spacing: 4) {
                                Text(userProfile?.displayName ?? "Date Enthusiast")
                                    .font(Font.header(22, weight: .bold))
                                    .foregroundColor(Color.luxuryCream)
                                
                                if let email = userProfile?.email, !email.isEmpty {
                                    Text(email)
                                        .font(Font.bodySans(13, weight: .regular))
                                        .foregroundColor(Color.luxuryMuted)
                                }
                                
                                Text("Member since \(userProfile?.memberSince ?? "2024")")
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted.opacity(0.7))
                            }
                        }
                        .padding(.top, 16)
                        
                        // Stats
                        HStack(spacing: 0) {
                            LuxuryStatItem(value: "\(coordinator.savedPlans.count)", label: "Saved")
                            
                            Rectangle()
                                .fill(Color.luxuryGold.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            LuxuryStatItem(value: "0", label: "Completed")
                            
                            Rectangle()
                                .fill(Color.luxuryGold.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            LuxuryStatItem(value: "0", label: "Memories")
                        }
                        .padding(.vertical, 16)
                        .luxuryCard()
                        .padding(.horizontal, 20)
                        
                        // Preferences Summary
                        if let prefs = userProfile?.preferences {
                            PreferencesSummaryCard(preferences: prefs)
                                .padding(.horizontal, 20)
                        }
                        
                        // Menu Items
                        VStack(spacing: 2) {
                            LuxuryProfileMenuItem(icon: "bookmark.fill", title: "Saved Plans")
                            LuxuryProfileMenuItem(icon: "clock.fill", title: "Date History")
                            LuxuryProfileMenuItem(icon: "heart.fill", title: "Preferences")
                            LuxuryProfileMenuItem(icon: "bell.fill", title: "Notifications")
                            LuxuryProfileMenuItem(icon: "gearshape.fill", title: "Settings")
                        }
                        .luxuryCard(hasBorder: false)
                        .padding(.horizontal, 20)
                        
                        // Sign Out
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1516534775068-ba3e7458af70?w=40&h=40&fit=crop")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(Color.luxuryError.opacity(0.3))
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.luxuryError.opacity(0.5), lineWidth: 1)
                                )
                                
                                Text("Sign Out")
                            }
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.luxuryError.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    coordinator.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var userInitials: String {
        guard let profile = userProfile else { return "DG" }
        let first = profile.firstName.prefix(1).uppercased()
        let last = profile.lastName.prefix(1).uppercased()
        return first.isEmpty ? "DG" : "\(first)\(last)"
    }
}

// MARK: - Preferences Summary Card
struct PreferencesSummaryCard: View {
    let preferences: DatePreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Text("Your")
                        .font(Font.header(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                    Text("Preferences")
                        .font(Font.tangerine(26, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                }
                
                Spacer()
                
                Button {
                    // Edit preferences action
                } label: {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=40&h=40&fit=crop")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(Color.luxuryGold.opacity(0.3))
                            }
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        
                        Text("Edit")
                    }
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                }
            }
            
            VStack(spacing: 12) {
                if !preferences.favoriteActivities.isEmpty {
                    PreferenceSummaryRow(
                        icon: "sparkles",
                        title: "Activities",
                        values: preferences.favoriteActivities.prefix(3).joined(separator: ", ")
                    )
                }
                
                if !preferences.favoriteCuisines.isEmpty {
                    PreferenceSummaryRow(
                        icon: "fork.knife",
                        title: "Cuisines",
                        values: preferences.favoriteCuisines.prefix(3).joined(separator: ", ")
                    )
                }
                
                if !preferences.beveragePreferences.isEmpty {
                    PreferenceSummaryRow(
                        icon: "wineglass.fill",
                        title: "Beverages",
                        values: preferences.beveragePreferences.prefix(2).joined(separator: ", ")
                    )
                }
                
                PreferenceSummaryRow(
                    icon: "heart.fill",
                    title: "Love Language",
                    values: preferences.loveLanguage.displayName
                )
                
                if !preferences.hardNos.isEmpty {
                    PreferenceSummaryRow(
                        icon: "xmark.circle.fill",
                        title: "Avoids",
                        values: preferences.hardNos.prefix(2).joined(separator: ", ")
                    )
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }
}

struct PreferenceSummaryRow: View {
    let icon: String
    let title: String
    let values: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.luxuryGold.opacity(0.8))
                .frame(width: 20)
            
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryCream)
            
            Spacer()
            
            Text(values)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .lineLimit(1)
        }
    }
}

struct LuxuryStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Font.header(26, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            
            Text(label)
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LuxuryProfileMenuItem: View {
    let icon: String
    let title: String
    
    private var imageUrl: String {
        switch icon {
        case "bookmark.fill": return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=80&h=80&fit=crop"
        case "clock.fill": return "https://images.unsplash.com/photo-1501139083538-0139583c060f?w=80&h=80&fit=crop"
        case "heart.fill": return "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=80&h=80&fit=crop"
        case "bell.fill": return "https://images.unsplash.com/photo-1577563908411-5077b6dc7624?w=80&h=80&fit=crop"
        case "gearshape.fill": return "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=80&h=80&fit=crop"
        default: return "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=80&h=80&fit=crop"
        }
    }
    
    var body: some View {
        Button {
            // Action
        } label: {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color.luxuryGold)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
                
                Text(title)
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Preview
#Preview {
    RootNavigationView()
}
