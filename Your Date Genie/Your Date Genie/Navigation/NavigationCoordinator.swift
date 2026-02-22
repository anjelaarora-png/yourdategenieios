import SwiftUI
import Combine

// MARK: - App Destination Enum
enum AppDestination: Hashable {
    case landing
    case onboarding
    case questionnaire
    case datePlanResult(plan: DatePlan)
    case giftFinder
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
        case .giftFinder: hasher.combine("giftFinder")
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
    
    // Sheet presentation states
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
        case giftFinder
        case playlist(planTitle: String)
        case reservation(venueName: String, venueType: String, address: String?, phone: String?)
        case partnerShare(plan: DatePlan)
        case routeMap(stops: [DatePlanStop])
        case memoryCapture
        
        var id: String {
            switch self {
            case .questionnaire: return "questionnaire"
            case .datePlanResult: return "datePlanResult"
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
        
        // Generate sample plan (in real app, this would call API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentDatePlan = DatePlan.sample
            self.generatedPlans = [DatePlan.sample]
            self.activeSheet = .datePlanResult
        }
    }
    
    func showGiftFinder() {
        activeSheet = .giftFinder
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
    
    // MARK: - Persistence
    
    private func loadSavedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    private func saveState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Root Navigation View
struct RootNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !coordinator.hasCompletedOnboarding {
                MobileOnboardingView()
                    .environmentObject(coordinator)
            } else {
                MainAppView()
                    .environmentObject(coordinator)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: coordinator.hasCompletedOnboarding)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.brandCream
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.brandGold)
                    .scaleEffect(scale)
                
                VStack(spacing: 8) {
                    Text("Your Date Genie")
                        .font(.custom("Cormorant-Bold", size: 32, relativeTo: .largeTitle))
                        .foregroundColor(.brandPrimary)
                    
                    Text("Date nights, planned for you.")
                        .font(.system(size: 16))
                        .foregroundColor(.brandMuted)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
}


// MARK: - Main App View (Tab-based)
struct MainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            HomeTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.home.rawValue, systemImage: NavigationCoordinator.Tab.home.icon)
                }
                .tag(NavigationCoordinator.Tab.home)
            
            ExploreTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.explore.rawValue, systemImage: NavigationCoordinator.Tab.explore.icon)
                }
                .tag(NavigationCoordinator.Tab.explore)
            
            MemoriesTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.memories.rawValue, systemImage: NavigationCoordinator.Tab.memories.icon)
                }
                .tag(NavigationCoordinator.Tab.memories)
            
            ProfileTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.profile.rawValue, systemImage: NavigationCoordinator.Tab.profile.icon)
                }
                .tag(NavigationCoordinator.Tab.profile)
        }
        .tint(.brandGold)
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: NavigationCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .questionnaire:
            QuestionnaireView { data in
                coordinator.completeQuestionnaire(with: data)
            }
        case .datePlanResult:
            if let plan = coordinator.currentDatePlan {
                DatePlanResultView(
                    plan: plan,
                    onSave: { coordinator.savePlan(plan) },
                    onRegenerate: { /* Regenerate logic */ }
                )
                .environmentObject(coordinator)
            }
        case .giftFinder:
            GiftFinderView()
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
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                        }
                    }
            }
        case .memoryCapture:
            MemoryGalleryView(showCloseButton: true)
        }
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent/Saved Plans
                    if !coordinator.savedPlans.isEmpty {
                        savedPlansSection
                    }
                    
                    // Features
                    featuresSection
                }
                .padding(.bottom, 100)
            }
            .background(Color.brandCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.brandGold)
                        Text("Your Date Genie")
                            .font(.custom("Cormorant-Bold", size: 20, relativeTo: .headline))
                            .foregroundColor(.brandPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Notifications
                    } label: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Greeting
            VStack(spacing: 4) {
                Text(greeting)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text("Ready for your next date?")
                    .font(.custom("Cormorant-Bold", size: 26, relativeTo: .title))
                    .foregroundColor(Color(UIColor.label))
            }
            
            // Main CTA Card
            Button {
                coordinator.startDatePlanning()
            } label: {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan a Date")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Create a personalized itinerary in minutes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 15, y: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionTile(icon: "gift.fill", title: "Gift Ideas", color: .pink) {
                        coordinator.showGiftFinder()
                    }
                    
                    QuickActionTile(icon: "photo.stack.fill", title: "Memories", color: .purple) {
                        coordinator.currentTab = .memories
                    }
                    
                    QuickActionTile(icon: "bookmark.fill", title: "Saved", color: .blue) {
                        // Show saved plans
                    }
                    
                    QuickActionTile(icon: "clock.fill", title: "History", color: .orange) {
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
                Text("Your Plans")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                Button("See All") {
                    // Show all saved plans
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.brandGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(coordinator.savedPlans) { plan in
                        SavedPlanCard(plan: plan) {
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
            Text("Explore Features")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureTile(icon: "wand.and.stars", title: "AI Planning", subtitle: "Smart recommendations", color: .brandGold)
                FeatureTile(icon: "map.fill", title: "Routes", subtitle: "Navigate easily", color: .blue)
                FeatureTile(icon: "music.note", title: "Playlists", subtitle: "Set the mood", color: .pink)
                FeatureTile(icon: "person.2.fill", title: "Share", subtitle: "With your partner", color: .purple)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Supporting Views
struct QuickActionTile: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.12))
                    .cornerRadius(14)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
            .frame(width: 80)
        }
    }
}

struct SavedPlanCard: View {
    let plan: DatePlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Emoji row
                HStack(spacing: 4) {
                    ForEach(plan.stops.prefix(3)) { stop in
                        Text(stop.emoji)
                            .font(.system(size: 20))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)
                    
                    Text("\(plan.stops.count) stops · \(plan.totalDuration)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .padding(16)
            .frame(width: 180)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        }
    }
}

struct FeatureTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Explore Tab View
struct ExploreTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Explore")
                            .font(.custom("Cormorant-Bold", size: 32, relativeTo: .largeTitle))
                            .foregroundColor(Color(UIColor.label))
                        
                        Text("Discover new date ideas")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .padding(.top, 20)
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Date Types")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                DateTypeTile(emoji: "🌹", title: "Romantic", color: .pink)
                                DateTypeTile(emoji: "🎉", title: "Fun & Active", color: .orange)
                                DateTypeTile(emoji: "🏠", title: "Cozy Night In", color: .purple)
                                DateTypeTile(emoji: "🚀", title: "Adventure", color: .blue)
                                DateTypeTile(emoji: "✨", title: "Special", color: .brandGold)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Inspiration Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get Inspired")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            InspirationCard(
                                title: "Wine & Dine",
                                description: "Elegant evening with wine tasting",
                                emoji: "🍷",
                                gradient: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]
                            )
                            
                            InspirationCard(
                                title: "Outdoor Adventure",
                                description: "Hiking, picnic, and sunset views",
                                emoji: "🌄",
                                gradient: [Color.green.opacity(0.8), Color.teal.opacity(0.6)]
                            )
                            
                            InspirationCard(
                                title: "Arts & Culture",
                                description: "Museums, galleries, and live shows",
                                emoji: "🎨",
                                gradient: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.brandCream)
        }
    }
}

struct DateTypeTile: View {
    let emoji: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 64, height: 64)
                .background(color.opacity(0.15))
                .cornerRadius(16)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(UIColor.label))
        }
    }
}

struct InspirationCard: View {
    let title: String
    let description: String
    let emoji: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 36))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(20)
        .background(
            LinearGradient(gradient: Gradient(colors: gradient), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
    }
}

// MARK: - Memories Tab View
struct MemoriesTabView: View {
    var body: some View {
        MemoryGalleryView()
    }
}

// MARK: - Profile Tab View
struct ProfileTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.brandGold.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.brandGold)
                            )
                        
                        VStack(spacing: 4) {
                            Text("Date Enthusiast")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(UIColor.label))
                            
                            Text("Member since 2024")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    HStack(spacing: 0) {
                        StatItem(value: "\(coordinator.savedPlans.count)", label: "Saved")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: "0", label: "Completed")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: "0", label: "Memories")
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Menu Items
                    VStack(spacing: 2) {
                        ProfileMenuItem(icon: "bookmark.fill", title: "Saved Plans", color: .brandGold)
                        ProfileMenuItem(icon: "clock.fill", title: "Date History", color: .blue)
                        ProfileMenuItem(icon: "heart.fill", title: "Preferences", color: .pink)
                        ProfileMenuItem(icon: "bell.fill", title: "Notifications", color: .orange)
                        ProfileMenuItem(icon: "gearshape.fill", title: "Settings", color: .gray)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Sign Out
                    Button {
                        // Sign out action
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100)
            }
            .background(Color.brandCream)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.brandPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button {
            // Action
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Preview
#Preview {
    RootNavigationView()
}
