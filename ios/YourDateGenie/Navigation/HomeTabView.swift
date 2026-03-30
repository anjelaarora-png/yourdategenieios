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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var pulseAnimation = false
    @State private var planForCalendar: DatePlan?
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var trendingPlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var trendingPlacesLoading = false
    
    private var planForTonight: DatePlan? {
        let calendar = Calendar.current
        return coordinator.savedPlans.first { plan in
            guard let d = plan.scheduledDate else { return false }
            return calendar.isDateInToday(d)
        }
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                FloatingParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        heroSection
                        quickActionsSection
                        yourUpcomingDatesSection
                        experiencesWaitingSection
                        trendingInYourAreaSection
                        featuresSection
                        relationshipStorySection
                    }
                    .padding(.bottom, 120)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .onAppear {
                coordinator.refreshPreferencesState()
                Task { await loadTrendingPlacesIfNeeded() }
            }
            .onChange(of: trendingLocationKey) { _, _ in
                Task { await loadTrendingPlacesIfNeeded() }
            }
            .refreshable {
                await loadTrendingPlacesIfNeeded()
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
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK") { calendarMessage = nil }
            } message: {
                if let msg = calendarMessage { Text(msg) }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    }
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
            
            if showUseLast && !hasPlanTonight {
                Button {
                    coordinator.startDatePlanning(mode: .useLast)
                } label: {
                    Text("Reuse Last Plan")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.luxuryGold, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            
            if showResume && !hasPlanTonight {
                Button {
                    coordinator.startDatePlanning(mode: .resume)
                } label: {
                    Text("Pick up where you left off")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.luxuryGold, lineWidth: 1.5)
                        )
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
    
    // MARK: - Trending in your area (Google Places; refetches when location loads, on pull-to-refresh, and when app becomes active)
    private func loadTrendingPlacesIfNeeded() async {
        let prefs = userProfileManager.currentUser?.preferences
        let location = prefs.map { $0.defaultStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
            ?? prefs.map { $0.defaultCity.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
            ?? ""
        guard !location.isEmpty else { return }
        await MainActor.run { if trendingPlacesLoading { return }; trendingPlacesLoading = true }
        do {
            let places = try await GooglePlacesService.shared.fetchRecommendedInCity(city: location, limit: 6)
            await MainActor.run {
                trendingPlaces = places
                trendingPlacesLoading = false
            }
        } catch {
            await MainActor.run {
                trendingPlaces = []
                trendingPlacesLoading = false
            }
        }
    }
    
    /// Opens the business profile in Google Maps or Apple Maps (reviews, hours, photos).
    private func openPlaceInPreferredMaps(place: GooglePlacesService.PlaceSearchResult) {
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
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.system(size: 22))
                        .foregroundColor(Color.luxuryGold)
                    Text("Recommended in your area")
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryGold)
                    Spacer(minLength: 8)
                    Button {
                        coordinator.showExplore()
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(Color.luxuryGold)
                    }
                    .buttonStyle(.plain)
                }
                Text("Highly rated restaurants & things to do")
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            .padding(.horizontal, 20)
            
            // Only show actual places from Google — no vague or fake cards
            if trendingPlacesLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.luxuryMaroonLight.opacity(0.5))
                                .frame(width: 200, height: 180)
                                .overlay(ProgressView().tint(Color.luxuryGold))
                        }
                        TrendingExploreCircleButton(action: { coordinator.showExplore() })
                    }
                    .padding(.horizontal, 20)
                }
            } else if !trendingPlaces.isEmpty {
                // Real places from Google Places (rating/reviews, View in Maps)
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
                // No fake cards — clear empty state so users set location or try Continue exploring
                trendingEmptyState
            }
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
    
    // MARK: - Your Upcoming Dates (saved plans with unified cards)
    
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
    
    // MARK: - Your Upcoming Dates (saved plans)
    private var yourUpcomingDatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Your")
                    .font(Font.tangerine(32, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Upcoming Dates")
                    .font(Font.tangerine(32, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            if !coordinator.savedPlans.isEmpty {
                Text("Saved plans — tap to view or add to calendar.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(coordinator.savedPlans) { plan in
                            LuxuryUnifiedDateCard(
                                imageUrl: plan.displayImageUrl,
                                title: plan.title,
                                tagline: plan.tagline,
                                location: MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address),
                                time: plan.stops.first?.timeSlot ?? "—",
                                price: plan.estimatedCost,
                                actionTitle: "View Plan",
                                action: {
                                    coordinator.currentDatePlan = plan
                                    coordinator.activeSheet = .datePlanResult
                                },
                                onAddToCalendar: {
                                    planForCalendar = plan
                                    calendarDate = plan.scheduledDate ?? Date()
                                }
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    coordinator.deletePlan(plan)
                                } label: {
                                    Label("Delete plan", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                Text("Save a plan and it will appear here.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Experiences Waiting (unsaved generated plans — same links as before)
    private var experiencesWaitingSection: some View {
        let hasWaiting = !coordinator.experiencesWaiting.isEmpty
        let hasGenerated = !coordinator.generatedPlans.isEmpty
        
        return Group {
            if hasWaiting || hasGenerated {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 22))
                            .foregroundColor(Color.luxuryGold)
                        Text("Experiences")
                            .font(Font.tangerine(32, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                        Text("Waiting")
                            .font(Font.tangerine(32, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                    }
                    .padding(.horizontal, 20)
                    
                    Text(hasWaiting ? "Unsaved plans — tap to view and save." : "Tap to choose one and save to Your Upcoming Dates.")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            if hasWaiting {
                                ForEach(coordinator.experiencesWaiting) { plan in
                                    LuxuryUnifiedDateCard(
                                        imageUrl: plan.displayImageUrl,
                                        title: plan.title,
                                        tagline: plan.tagline,
                                        location: MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address),
                                        time: plan.stops.first?.timeSlot ?? "—",
                                        price: plan.estimatedCost,
                                        actionTitle: "View Plan",
                                        action: {
                                            coordinator.currentDatePlan = plan
                                            coordinator.activeSheet = .datePlanResult
                                        }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            coordinator.removeFromExperiencesWaiting(planId: plan.id)
                                        } label: {
                                            Label("Remove from list", systemImage: "trash")
                                        }
                                    }
                                }
                            } else {
                                ForEach(Array(coordinator.generatedPlans.enumerated()), id: \.element.id) { index, plan in
                                    LuxuryUnifiedDateCard(
                                        imageUrl: plan.displayImageUrl,
                                        title: plan.title,
                                        tagline: plan.tagline,
                                        location: MapURLHelper.cityStateOrRegionFromAddress(plan.stops.first?.address),
                                        time: plan.stops.first?.timeSlot ?? "—",
                                        price: plan.estimatedCost,
                                        actionTitle: "Choose",
                                        action: {
                                            coordinator.generatedPlansSelectedIndex = index
                                            coordinator.currentDatePlan = plan
                                            coordinator.activeSheet = .datePlanOptions
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            } else {
                EmptyView()
            }
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
            
            HStack(spacing: 8) {
                LuxuryQuickTile(icon: "gift", title: "Gift Finder", color: Color.luxuryGold) {
                    coordinator.showGiftFinder(
                        datePlan: coordinator.currentDatePlan,
                        dateLocation: coordinator.currentDatePlan?.stops.first?.address
                    )
                }
                .frame(maxWidth: .infinity)
                LuxuryQuickTile(icon: "music.note.list", title: "Date Playlist", color: Color.luxuryGoldLight) {
                    coordinator.showPlaylist(for: coordinator.currentDatePlan?.title ?? "Date Night", planId: coordinator.currentDatePlan?.id)
                }
                .frame(maxWidth: .infinity)
                LuxuryQuickTile(icon: "bubble.left.and.bubble.right", title: "Conversation Starters", color: Color.luxuryGold) {
                    coordinator.showConversationStarters()
                }
                .frame(maxWidth: .infinity)
                LuxuryQuickTile(icon: "person.2.fill", title: "Plan Together", color: Color.luxuryGold) {
                    coordinator.showPartnerPlanning()
                }
                .frame(maxWidth: .infinity)
                LuxuryQuickTile(icon: "clock", title: "Past Dates", color: Color.luxuryGoldLight) {
                    coordinator.showPastMagic()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Magical")
                    .font(Font.tangerine(34, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Tools")
                    .font(Font.tangerine(34, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    LuxuryQuickTile(icon: "map", title: "Journey Map", color: Color.luxuryGoldLight) {
                        let allPastStops = coordinator.pastPlans.flatMap { $0.stops }
                        if !allPastStops.isEmpty {
                            coordinator.activeSheet = .routeMap(stops: allPastStops, startingPoint: nil, showRouteLine: false)
                        } else if let plan = coordinator.currentDatePlan, !plan.stops.isEmpty {
                            coordinator.activeSheet = .routeMap(stops: plan.stops, startingPoint: plan.startingPoint)
                        } else {
                            coordinator.activeSheet = .routeMap(stops: [], startingPoint: nil, showRouteLine: false)
                        }
                    }
                    LuxuryQuickTile(icon: "music.note", title: "Mood Music", color: Color.luxuryGold) {
                        coordinator.showPlaylist(for: coordinator.currentDatePlan?.title ?? "Date Night", planId: coordinator.currentDatePlan?.id)
                    }
                    LuxuryQuickTile(icon: "heart", title: "Share Joy", color: Color.luxuryGoldLight) {
                        if let plan = coordinator.currentDatePlan {
                            coordinator.activeSheet = .partnerShare(plan: plan)
                        }
                    }
                    LuxuryQuickTile(icon: "book.closed", title: "Date Tips", color: Color.luxuryGold) {
                        coordinator.showPlaybook()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Your Relationship Story
    private var relationshipStorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("Your")
                    .font(Font.tangerine(32, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Relationship Story")
                    .font(Font.tangerine(32, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
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
                    coordinator.currentTab = .memories
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
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
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
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
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
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.luxuryMaroonLight.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
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
