import SwiftUI
import MapKit

// Wrapper so we can use sheet(item:) with DatePlan.
private struct IdentifiablePlan: Identifiable {
    let plan: DatePlan
    var id: UUID { plan.id }
}

// MARK: - Luxury Home Tab View
struct LuxuryHomeTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject private var access: AccessManager
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var memoryManager: MemoryManager
    @State private var planForCalendar: DatePlan?
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var trendingPlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var trendingPlacesLoading = false
    @State private var trendingFetchFailed = false
    @State private var lastLoadedLocationKey: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasSeenHomeTutorial") private var hasSeenHomeTutorial = false
    @State private var showHomeTutorial = false
    @AppStorage("hasChosenMapsApp") private var hasChosenMapsApp = false
    @State private var showMapsAppPicker = false
    @State private var pendingPlaceForMaps: GooglePlacesService.PlaceSearchResult?

    // Section collapse states — persisted across launches
    @AppStorage("home_upcoming_expanded") private var upcomingExpanded = true
    @AppStorage("home_experiences_expanded") private var dateExperiencesExpanded = true
    @AppStorage("home_trending_expanded") private var trendingExpanded = true
    @AppStorage("home_story_expanded") private var storyExpanded = true
    // Upcoming Dates: show first 3, tap to expand
    // Sheet for reviewing > 3 unsaved plans
    @State private var showUnsavedPlansSheet = false

    private var planForTonight: DatePlan? {
        let calendar = Calendar.current
        return coordinator.savedPlans.first { plan in
            guard let d = plan.scheduledDate else { return false }
            return calendar.isDateInToday(d)
        }
    }

    /// All unsaved plans: prefers experiencesWaiting; falls back to generatedPlans.
    private var allUnsavedPlans: [DatePlan] {
        let waiting = coordinator.experiencesWaiting
        return waiting.isEmpty ? coordinator.generatedPlans : waiting
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    FloatingParticlesView()
                        .ignoresSafeArea()
                        .opacity(0.6)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        heroSection
                        quickActionsSection
                        yourUpcomingDatesSection
                        dateExperiencesCollapsibleSection
                        trendingInYourAreaSection
                        relationshipStorySection
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .onAppear {
                coordinator.refreshPreferencesState()
                Task { await loadTrendingPlaces() }
                if !hasSeenHomeTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showHomeTutorial = true
                        hasSeenHomeTutorial = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showHomeTutorial) {
                HomeTutorialOverlayView(isPresented: $showHomeTutorial)
            }
            .confirmationDialog("Open route in which app?", isPresented: $showMapsAppPicker, titleVisibility: .visible) {
                Button("Apple Maps") {
                    UserDefaults.standard.set("apple", forKey: "dateGenie_preferredMapsApp")
                    hasChosenMapsApp = true
                    if let place = pendingPlaceForMaps { openPlaceInPreferredMaps(place: place) }
                    pendingPlaceForMaps = nil
                }
                Button("Google Maps") {
                    UserDefaults.standard.set("google", forKey: "dateGenie_preferredMapsApp")
                    hasChosenMapsApp = true
                    if let place = pendingPlaceForMaps { openPlaceInPreferredMaps(place: place) }
                    pendingPlaceForMaps = nil
                }
                Button("Cancel", role: .cancel) { pendingPlaceForMaps = nil }
            } message: {
                Text("Your choice will be remembered. Change it later in Profile > Settings.")
            }
            .onChange(of: trendingLocationKey) { _, _ in
                Task { await loadTrendingPlaces(force: true) }
            }
            .refreshable {
                await loadTrendingPlaces(force: true)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { Task { await loadTrendingPlacesIfNeeded() } }
            }
            .sheet(item: Binding(
                get: { planForCalendar.map { IdentifiablePlan(plan: $0) } },
                set: { planForCalendar = $0?.plan }
            )) { wrapper in
                addToCalendarSheet(plan: wrapper.plan)
            }
            .sheet(isPresented: $showUnsavedPlansSheet) {
                unsavedPlansSheet
            }
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK") { calendarMessage = nil }
            } message: {
                if let msg = calendarMessage { Text(msg) }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Match UIBarButtonItem host width (~80pt) to avoid Auto Layout conflict with SwiftUI’s width <= ~68.
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .frame(minWidth: 80, minHeight: 44, alignment: .leading)
                        .accessibilityLabel("Your Date Genie")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellButton(notificationManager: notificationManager)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(greetingLine1)
                .font(Font.tangerine(46, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Text(greetingLine2)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var greetingLine1: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeWord: String
        switch hour {
        case 0..<12: timeWord = "Good morning"
        case 12..<17: timeWord = "Good afternoon"
        default: timeWord = "Good evening"
        }
        let name = userProfileManager.currentUser?.firstName
        let nameDisplay = (name?.isEmpty == false) ? name! : "there"
        return "\(timeWord) \(nameDisplay)"
    }
    
    private var greetingLine2: String {
        if planForTonight != nil {
            let d = planForTonight!.scheduledDate ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let day = formatter.string(from: d)
            return "Your \(day) night plan is ready."
        }
        return "Ready to surprise your partner tonight?"
    }
    
    private var heroSection: some View {
        let showUseLast = LastQuestionnaireStore.hasLastData || coordinator.hasCompletedPreferences
        let showResume = QuestionnaireProgressStore.hasValidProgress
        let hasPlanTonight = planForTonight != nil
        
        return VStack(spacing: 16) {
            Button {
                if hasPlanTonight, let plan = planForTonight {
                    coordinator.currentDatePlan = plan
                    coordinator.activeSheet = .datePlanResult
                } else {
                    coordinator.startDatePlanning(mode: .fresh)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                    Text(hasPlanTonight ? "View Date Plan" : "Plan My Next Date")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(16)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            
            if !access.isSubscribed && access.freePlansRemaining > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text(access.freePlansRemaining == AccessManager.freePlanLimit
                         ? "\(access.freePlansRemaining) free date plans included — no card needed"
                         : "\(access.freePlansRemaining) free plan remaining · subscribe for unlimited")
                        .font(Font.bodySans(12, weight: .regular))
                }
                .foregroundColor(Color.luxuryGold.opacity(0.8))
                .multilineTextAlignment(.center)
            }

            if (showUseLast || showResume) && !hasPlanTonight {
                Button {
                    coordinator.startDatePlanning(mode: showResume ? .resume : .useLast)
                } label: {
                    Text("or reuse your last plan")
                        .font(Font.bodySans(13, weight: .semibold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    /// Key used to refetch trending when location (starting point or city) becomes available or changes.
    private var trendingLocationKey: String {
        guard let prefs = userProfileManager.currentUser?.preferences else { return "" }
        let start = prefs.defaultStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = prefs.defaultCity.trimmingCharacters(in: .whitespacesAndNewlines)
        return start.isEmpty ? city : start
    }
    
    // MARK: - Recommended in your area (Google Places; refetches when location loads, on pull-to-refresh, and when app becomes active)

    /// Fetch only when not already loading for this location key. Used by onAppear and scene-active.
    private func loadTrendingPlacesIfNeeded() async {
        let key = trendingLocationKey
        guard !key.isEmpty else { return }
        let skip = await MainActor.run { () -> Bool in
            if trendingPlacesLoading || key == lastLoadedLocationKey { return true }
            trendingPlacesLoading = true
            return false
        }
        if skip { return }
        await performTrendingFetch(location: key)
    }

    /// Force a fresh fetch regardless of loading state. Used by pull-to-refresh and location changes.
    private func loadTrendingPlaces(force: Bool = false) async {
        let key = trendingLocationKey
        guard !key.isEmpty else { return }
        if !force {
            await loadTrendingPlacesIfNeeded()
            return
        }
        await MainActor.run {
            trendingPlaces = []
            trendingPlacesLoading = true
            lastLoadedLocationKey = ""
        }
        await performTrendingFetch(location: key)
    }

    private func performTrendingFetch(location: String) async {
        do {
            let places = try await GooglePlacesService.shared.fetchRecommendedInCity(city: location, limit: 6)
            await MainActor.run {
                trendingPlaces = places
                trendingPlacesLoading = false
                trendingFetchFailed = false
                lastLoadedLocationKey = location
            }
        } catch {
            await MainActor.run {
                trendingPlaces = []
                trendingPlacesLoading = false
                trendingFetchFailed = true
            }
        }
    }
    
    /// Opens the business profile in Google Maps or Apple Maps (reviews, hours, photos).
    /// On first use, prompts the user to choose their preferred app.
    private func openPlaceInPreferredMaps(place: GooglePlacesService.PlaceSearchResult) {
        guard hasChosenMapsApp else {
            pendingPlaceForMaps = place
            showMapsAppPicker = true
            return
        }
        let app = UserDefaults.standard.string(forKey: "dateGenie_preferredMapsApp") ?? "apple"
        if app == "google" {
            // Google Maps: api=1 + query (lat,lon) + query_place_id opens the business profile in the app
            let query = "\(place.latitude),\(place.longitude)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let placeIdEncoded = place.placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.placeId
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)&query_place_id=\(placeIdEncoded)") {
                UIApplication.shared.open(url)
                return
            }
        }
        // Apple Maps: place URL shows business-style card with name, address, coordinate
        var comp = URLComponents(string: "https://maps.apple.com/place")!
        comp.queryItems = [
            URLQueryItem(name: "address", value: place.address),
            URLQueryItem(name: "coordinate", value: "\(place.latitude),\(place.longitude)"),
            URLQueryItem(name: "name", value: place.name),
            URLQueryItem(name: "q", value: place.name),
            URLQueryItem(name: "map", value: "explore"),
        ]
        if let url = comp.url {
            UIApplication.shared.open(url)
        } else {
            let coord = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let placemark = MKPlacemark(coordinate: coord)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = place.name
            mapItem.openInMaps(launchOptions: nil)
        }
    }
    
    private var trendingInYourAreaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gold section divider
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            // Collapsible header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    trendingExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundColor(Color.luxuryGold)
                            Text("Local")
                                .font(Font.tangerine(32, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            Text("Gems")
                                .font(Font.tangerine(32, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                        Text("Top-rated spots handpicked for your next date")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    Spacer(minLength: 8)
                    Button { coordinator.showExplore() } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(Color.luxuryGold)
                    }
                    .buttonStyle(.plain)
                    Image(systemName: trendingExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            // Keep views in the hierarchy when collapsed so AsyncImage requests are never cancelled.
            VStack(alignment: .leading, spacing: 12) {
                // Only show actual places from Google — no vague or fake cards
                if trendingPlacesLoading {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.luxuryMaroonLight.opacity(0.5))
                                    .frame(width: 200, height: 200)
                                    .overlay(ProgressView().tint(Color.luxuryGold))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else if !trendingPlaces.isEmpty {
                    let preferredCity = userProfileManager.currentUser?.preferences.defaultCity.trimmingCharacters(in: .whitespaces) ?? userProfileManager.currentUser?.preferences.defaultStartingPoint.trimmingCharacters(in: .whitespaces) ?? ""
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(trendingPlaces.prefix(6), id: \.placeId) { place in
                                let price = CurrencyHelper.formattedPriceLevel(place.priceLevel)
                                let cityState = MapURLHelper.cityStateOrRegionFromAddress(place.address)
                                let location = cityState.isEmpty ? preferredCity : cityState
                                let tagline: String = {
                                    if let r = place.rating {
                                        let stars = "★ \(String(format: "%.1f", r))"
                                        if let n = place.userRatingsTotal, n > 0 { return "\(stars) · \(n) reviews" }
                                        return stars
                                    }
                                    return "On Google Maps"
                                }()
                                LuxuryUnifiedDateCard(
                                    imageUrl: place.photoUrl ?? "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop",
                                    title: place.name,
                                    tagline: tagline,
                                    location: location,
                                    time: place.openNow == true ? "Open now" : "",
                                    price: price,
                                    actionTitle: "View in Maps",
                                    action: { openPlaceInPreferredMaps(place: place) }
                                )
                            }
                            TrendingExploreCircleButton(action: { coordinator.showExplore() })
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    trendingEmptyState
                }
            }
            .opacity(trendingExpanded ? 1 : 0)
            .frame(height: trendingExpanded ? nil : 0)
            .clipped()
        }
    }
    
    /// Shown when we have no actual places (no location set or fetch failed). No vague placeholder cards.
    private var trendingEmptyState: some View {
        VStack(spacing: 14) {
            if trendingLocationKey.isEmpty {
                Text("Set your starting address (or city) in Settings to see recommended spots near you.")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button {
                    coordinator.activeSheet = .settings
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13))
                        Text("Open Settings")
                            .font(Font.bodySans(13, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else if trendingFetchFailed {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 22))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                    Text("Couldn't load nearby spots. Check your connection and pull down to refresh.")
                        .font(Font.bodySans(13, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button {
                        Task { await loadTrendingPlaces(force: true) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Try Again")
                                .font(Font.bodySans(13, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Highly rated restaurants and things to do will appear here. Pull down to refresh or tap below for more.")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            TrendingExploreCircleButton(action: { coordinator.showExplore() })
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Upcoming Date Row
    /// Elegant list row: gold left-accent bar, capsule chips for meta, clean gold action icon.
    /// `isUnsaved`: dashed border + "UNSAVED" chip + bookmark icon.
    private func upcomingDateRow(plan: DatePlan, isUnsaved: Bool = false) -> some View {
        let location = MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address)
        let time = plan.stops.first?.timeSlot ?? ""
        let price = plan.estimatedCost

        let tapAction: () -> Void = {
            if isUnsaved {
                if coordinator.experiencesWaiting.contains(where: { $0.id == plan.id }) {
                    coordinator.currentDatePlan = plan
                    coordinator.activeSheet = .datePlanResult
                } else if let idx = coordinator.generatedPlans.firstIndex(where: { $0.id == plan.id }) {
                    coordinator.generatedPlansSelectedIndex = idx
                    coordinator.currentDatePlan = plan
                    coordinator.activeSheet = .datePlanOptions
                } else {
                    coordinator.currentDatePlan = plan
                    coordinator.activeSheet = .datePlanResult
                }
            } else {
                coordinator.currentDatePlan = plan
                coordinator.activeSheet = .datePlanResult
            }
        }

        return Button(action: tapAction) {
            HStack(spacing: 0) {
                // Gold left accent bar
                LinearGradient.goldShimmer
                    .frame(width: 3)
                    .cornerRadius(1.5)
                    .padding(.vertical, 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Gold capsule chips for location / time / price / UNSAVED badge
                    HStack(spacing: 6) {
                        if !location.isEmpty {
                            upcomingMetaChip(icon: "mappin", text: location)
                        }
                        if !time.isEmpty {
                            upcomingMetaChip(icon: "clock", text: time)
                        }
                        if !price.isEmpty {
                            upcomingMetaChip(icon: nil, text: price)
                        }
                        if isUnsaved {
                            Text("UNSAVED")
                                .font(Font.bodySans(9, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color.luxuryMaroon)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.luxuryGold)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.leading, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right action icon
                Group {
                    if isUnsaved {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    } else {
                        Button {
                            planForCalendar = plan
                            calendarDate = plan.scheduledDate ?? Date()
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.luxuryGold)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.luxuryMaroonLight.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isUnsaved
                                    ? Color.luxuryGold.opacity(0.45)
                                    : Color.luxuryGold.opacity(0.18),
                                style: isUnsaved
                                    ? StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    : StrokeStyle(lineWidth: 1)
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isUnsaved {
                Button(role: .destructive) {
                    coordinator.removeFromExperiencesWaiting(planId: plan.id)
                } label: {
                    Label("Remove from list", systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    coordinator.deletePlan(plan)
                } label: {
                    Label("Delete plan", systemImage: "trash")
                }
            }
        }
    }

    /// Small gold capsule chip used in upcoming date rows for location, time and price metadata.
    @ViewBuilder
    private func upcomingMetaChip(icon: String?, text: String) -> some View {
        HStack(spacing: 4) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 9, weight: .medium))
            }
            Text(text)
                .font(Font.bodySans(11, weight: .medium))
        }
        .foregroundColor(Color.luxuryGold)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.luxuryGold.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.luxuryGold.opacity(0.35), lineWidth: 0.5))
    }

    // MARK: - Add to Calendar Sheet (from Upcoming Magic cards)
    private func addToCalendarSheet(plan: DatePlan) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose the date for your plan")
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                
                DatePicker("Date", selection: $calendarDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color.luxuryGold)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        let result = await CalendarService.addDatePlan(plan, on: calendarDate)
                        await MainActor.run {
                            switch result {
                            case .success:
                                coordinator.updateScheduledDate(for: plan.id, date: calendarDate)
                                calendarMessage = "Added to your calendar."
                                showCalendarAlert = true
                                planForCalendar = nil
                            case .denied:
                                calendarMessage = "Calendar access was denied. Enable it in Settings to add date plans."
                                showCalendarAlert = true
                            case .failed(let msg):
                                calendarMessage = "Could not add: \(msg)"
                                showCalendarAlert = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text("Add to Calendar")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.luxuryMaroon)
            .navigationTitle("Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        planForCalendar = nil
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
    
    // MARK: - Your Upcoming Dates (saved + merged unsaved)
    private var yourUpcomingDatesSection: some View {
        let unsaved = allUnsavedPlans
        let unsavedToMerge = unsaved.count <= 3 ? unsaved : []
        let savedCount = coordinator.savedPlans.count
        let badgeCount = savedCount + unsavedToMerge.count

        // Group saved plans by city, sorted soonest first
        let cityGroups: [(city: String, plans: [DatePlan])] = {
            let grouped = Dictionary(grouping: coordinator.savedPlans) { plan -> String in
                let c = MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address)
                return c.isEmpty ? "No Location" : c
            }
            return grouped
                .map { key, plans -> (city: String, plans: [DatePlan]) in
                    let sorted = plans.sorted {
                        let a = $0.scheduledDate ?? $0.createdAt
                        let b = $1.scheduledDate ?? $1.createdAt
                        return a < b
                    }
                    return (city: key, plans: sorted)
                }
                .sorted { a, b in
                    let aDate = a.plans.first.map { $0.scheduledDate ?? $0.createdAt } ?? .distantFuture
                    let bDate = b.plans.first.map { $0.scheduledDate ?? $0.createdAt } ?? .distantFuture
                    return aDate < bDate
                }
        }()
        let isMultiCity = cityGroups.count > 1

        return VStack(alignment: .leading, spacing: 0) {
            // Gold section divider
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            // Collapsible header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    upcomingExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Your Upcoming Dates")
                                .font(Font.tangerine(32, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            if badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(Font.bodySans(11, weight: .bold))
                                    .foregroundColor(Color.luxuryMaroon)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.luxuryGold)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(isMultiCity
                             ? "\(cityGroups.count) cities · tap a plan to view"
                             : "Tap a plan to view or add to your calendar")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    Spacer()
                    Image(systemName: upcomingExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                // Banner: > 3 unsaved plans waiting
                if unsaved.count > 3 {
                    Button { showUnsavedPlansSheet = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(Color.luxuryMaroon)
                            Text("\(unsaved.count) date plans waiting to be saved")
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(Color.luxuryMaroon)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.luxuryMaroon)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }

                // Saved plans — city-grouped when multi-city, flat list for single city
                if !coordinator.savedPlans.isEmpty {
                    if isMultiCity {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(cityGroups, id: \.city) { group in
                                upcomingCityGroupView(city: group.city, plans: Array(group.plans.prefix(2)))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, unsaved.count > 3 ? 8 : 14)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(coordinator.savedPlans.prefix(3))) { plan in
                                upcomingDateRow(plan: plan, isUnsaved: false)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, unsaved.count > 3 ? 8 : 14)
                    }
                }

                // Unsaved plans merged in (≤ 3) with dashed-border styling
                if !unsavedToMerge.isEmpty {
                    HStack(spacing: 8) {
                        Rectangle().fill(Color.luxuryGold.opacity(0.2)).frame(height: 1)
                        Text("UNSAVED")
                            .font(Font.bodySans(10, weight: .bold))
                            .foregroundColor(Color.luxuryGold.opacity(0.6))
                            .tracking(1.5)
                        Rectangle().fill(Color.luxuryGold.opacity(0.2)).frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, coordinator.savedPlans.isEmpty ? 14 : 6)

                    VStack(spacing: 10) {
                        ForEach(unsavedToMerge) { plan in
                            upcomingDateRow(plan: plan, isUnsaved: true)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if coordinator.savedPlans.isEmpty && unsaved.isEmpty {
                    Text("Save a plan and it will appear here.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                }

                // "View all" footer — shown when preview doesn't cover all saved plans
                let previewCount = isMultiCity
                    ? cityGroups.reduce(0) { $0 + min($1.plans.count, 2) }
                    : min(coordinator.savedPlans.count, 3)
                if !coordinator.savedPlans.isEmpty && coordinator.savedPlans.count > previewCount {
                    Button { coordinator.activeSheet = .savedPlansList } label: {
                        HStack(spacing: 6) {
                            Text("View all \(coordinator.savedPlans.count) saved plans")
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
            .opacity(upcomingExpanded ? 1 : 0)
            .frame(height: upcomingExpanded ? nil : 0)
            .clipped()
        }
    }

    // MARK: - City group header + plan rows for multi-city upcoming view
    @ViewBuilder
    private func upcomingCityGroupView(city: String, plans: [DatePlan]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // City pill header
            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.luxuryGold)
                Text(city)
                    .font(Font.bodySans(12, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .tracking(0.3)
                Spacer()
                let total = coordinator.savedPlans.filter {
                    let c = MapURLHelper.cityStateOrRegionFromAddress($0.stops.first?.address)
                    return (c.isEmpty ? "No Location" : c) == city
                }.count
                if total > 2 {
                    Button { coordinator.activeSheet = .savedPlansList } label: {
                        Text("+\(total - 2) more")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.luxuryGold.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.luxuryGold.opacity(0.2), lineWidth: 0.5))

            VStack(spacing: 8) {
                ForEach(plans) { plan in
                    upcomingDateRow(plan: plan, isUnsaved: false)
                }
            }
        }
    }
    
    // MARK: - Unsaved Plans Sheet (shown when > 3 unsaved plans)
    private var unsavedPlansSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Tap a plan to view and save it before it's gone.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    ForEach(allUnsavedPlans) { plan in
                        upcomingDateRow(plan: plan, isUnsaved: true)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.luxuryMaroon)
            .navigationTitle("Plans Waiting to be Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { showUnsavedPlansSheet = false }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Date Experiences collapsible wrapper
    private var dateExperiencesCollapsibleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gold section divider
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            // Collapsible header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dateExperiencesExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Happening")
                                .font(Font.tangerine(32, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                            Text("Near You")
                                .font(Font.tangerine(32, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                        Text("Live events & experiences within 60 miles")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    Spacer()
                    Image(systemName: dateExperiencesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            DateExperiencesSection(showHeader: false)
                .opacity(dateExperiencesExpanded ? 1 : 0)
                .frame(height: dateExperiencesExpanded ? nil : 0)
                .clipped()
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Quick")
                    .font(Font.tangerine(34, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Magic")
                    .font(Font.tangerine(34, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    LuxuryQuickTile(icon: "gift", title: "Gift Finder", color: Color.luxuryGold, isLocked: !access.canAccess(.gifting)) {
                        access.require(.gifting) {
                            coordinator.showGiftFinder(
                                datePlan: coordinator.currentDatePlan,
                                dateLocation: coordinator.currentDatePlan?.stops.first?.address
                            )
                        }
                    }
                    LuxuryQuickTile(icon: "music.note.list", title: "Date Playlist", color: Color.luxuryGoldLight, isLocked: !access.canAccess(.playlist)) {
                        access.require(.playlist) {
                            coordinator.showPlaylist(for: coordinator.currentDatePlan?.title ?? "Date Night", planId: coordinator.currentDatePlan?.id)
                        }
                    }
                    LuxuryQuickTile(icon: "bubble.left.and.bubble.right", title: "Convo Starters", color: Color.luxuryGold, isLocked: !access.canAccess(.conversation)) {
                        access.require(.conversation) {
                            coordinator.showConversationStarters()
                        }
                    }
                    LuxuryQuickTile(icon: "person.2.fill", title: "Plan Together", color: Color.luxuryGold, isLocked: !access.canAccess(.datePlan)) {
                        access.require(.datePlan) {
                            coordinator.showPartnerPlanning()
                        }
                    }
                    LuxuryQuickTile(icon: "clock", title: "Past Dates", color: Color.luxuryGoldLight, isLocked: false) {
                        coordinator.showPastMagic()
                    }
                    LuxuryQuickTile(icon: "map", title: "Journey Map", color: Color.luxuryGoldLight, isLocked: !access.canAccess(.datePlan)) {
                        access.require(.datePlan) {
                            let allPastStops = coordinator.pastPlans.flatMap { $0.stops }
                            if !allPastStops.isEmpty {
                                coordinator.activeSheet = .routeMap(stops: allPastStops, startingPoint: nil, showRouteLine: false)
                            } else if let plan = coordinator.currentDatePlan, !plan.stops.isEmpty {
                                coordinator.activeSheet = .routeMap(stops: plan.stops, startingPoint: plan.startingPoint)
                            } else {
                                coordinator.activeSheet = .routeMap(stops: [], startingPoint: nil, showRouteLine: false)
                            }
                        }
                    }
                    LuxuryQuickTile(icon: "heart", title: "Share Joy", color: Color.luxuryGoldLight, isLocked: !access.canAccess(.datePlan)) {
                        access.require(.datePlan) {
                            if let plan = coordinator.currentDatePlan {
                                coordinator.activeSheet = .partnerShare(plan: plan)
                            }
                        }
                    }
                    LuxuryQuickTile(icon: "book.closed", title: "Date Tips", color: Color.luxuryGold, isLocked: !access.canAccess(.datingTips)) {
                        access.require(.datingTips) {
                            coordinator.showPlaybook()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    
    // MARK: - Your Relationship Story
    private var relationshipStorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gold section divider
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            // Collapsible header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    storyExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Relationship Story")
                            .font(Font.tangerine(32, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("Your journey together at a glance")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    Spacer()
                    Image(systemName: storyExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            HStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("\(coordinator.savedPlans.count)")
                        .font(Font.header(28, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    Text("dates planned together")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.luxuryMaroonLight.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
                )
                
                Button {
                    access.require(.memory) {
                        coordinator.currentTab = .memories
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text("\(memoryManager.totalMemoriesCount)")
                            .font(Font.header(28, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                        Text("memories saved")
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.luxuryMaroonLight.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
                    )
                    .opacity(access.canAccess(.memory) ? 1 : 0.5)
                    .overlay(alignment: .topTrailing) {
                        if !access.canAccess(.memory) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.luxuryGold.opacity(0.9))
                                .padding(8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .opacity(storyExpanded ? 1 : 0)
            .frame(height: storyExpanded ? nil : 0)
            .clipped()
        }
    }
}

// MARK: - Trending Explore Circle (large circle with golden sparkles + "Continue exploring" at end of trending scroll)
private struct TrendingExploreCircleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.luxuryMaroonLight.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(LinearGradient.goldShimmer, lineWidth: 2)
                    )
                    .shadow(color: Color.luxuryGold.opacity(0.3), radius: 16, y: 4)
                    .frame(width: 160, height: 160)
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(LinearGradient.goldShimmer)
                    Text("Continue exploring")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundStyle(LinearGradient.goldShimmer)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 160, height: 160)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Luxury Unified Date Card (IMAGE / TITLE / TAG LINE / DETAILS / ACTION, 24pt radius, glass-style, gold shadow)
private struct LuxuryUnifiedDateCard: View {
    let imageUrl: String
    let title: String
    let tagline: String
    let location: String
    let time: String
    let price: String
    let actionTitle: String
    var isPremiumLocked: Bool = false
    let action: () -> Void
    var onAddToCalendar: (() -> Void)? = nil
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
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
                .frame(width: 200, height: 120)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, Color.luxuryMaroon.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(alignment: .topTrailing) {
                    if isPremiumLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                            .padding(8)
                            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                    
                    Text(tagline)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                    
                    HStack(spacing: 10) {
                        if !location.isEmpty {
                            Label(location, systemImage: "location")
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        Label(time, systemImage: "clock")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                        if !price.isEmpty {
                            Text(price)
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(actionTitle)
                            .font(Font.bodySans(12, weight: .semibold))
                            .foregroundColor(Color.luxuryMaroon)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(LinearGradient.goldShimmer)
                            .cornerRadius(12)
                        
                        if let onAddToCalendar = onAddToCalendar {
                            Button {
                                onAddToCalendar()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 10))
                                    Text("Calendar")
                                        .font(Font.bodySans(10, weight: .semibold))
                                }
                                .foregroundColor(Color.luxuryGold)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
            }
            .frame(width: 200)
            .opacity(isPremiumLocked ? 0.5 : 1)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.luxuryMaroonLight.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Particles View
struct FloatingParticlesView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [Particle] = []
    @State private var particleTimer: Timer?

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    var body: some View {
        if reduceMotion {
            Color.clear
                .accessibilityHidden(true)
        } else {
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
                .accessibilityHidden(true)
                .onAppear {
                    if particles.isEmpty {
                        createParticles(in: geometry.size)
                    }
                    if particleTimer == nil {
                        startAnimating(in: geometry.size)
                    }
                }
                .onDisappear {
                    particleTimer?.invalidate()
                    particleTimer = nil
                }
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
    
    private func startAnimating(in size: CGSize) {
        particleTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
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
                    .font(Font.bodySans(14, weight: .semibold))
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

// MARK: - Booked Date Card (Upcoming Magic — saved plans, same visuals as ExperienceCard)
struct BookedDateCard: View {
    let plan: DatePlan
    let onTap: () -> Void
    var onAddToCalendar: (() -> Void)?
    
    private var dateTimeText: String {
        let timeSlot = plan.stops.first?.timeSlot ?? "—"
        if let d = plan.scheduledDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "\(formatter.string(from: d)) at \(timeSlot)"
        }
        return "\(timeSlot) · No date set"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: plan.displayImageUrl)) { phase in
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
                    
                    Text(plan.stops.first?.emoji ?? "✨")
                        .font(.system(size: 28))
                        .padding(10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(dateTimeText)
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(1)
                    
                    if onAddToCalendar != nil {
                        Button {
                            onAddToCalendar?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 10))
                                Text("Save to Calendar")
                                    .font(Font.bodySans(10, weight: .semibold))
                            }
                            .foregroundColor(Color.luxuryMaroon)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
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
        .buttonStyle(.plain)
    }
}
