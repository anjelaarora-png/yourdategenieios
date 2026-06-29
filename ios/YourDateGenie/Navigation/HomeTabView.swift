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
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var memoryManager: MemoryManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var planForCalendar: DatePlan?
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var trendingPlaces: [GooglePlacesService.PlaceSearchResult] = []
    @State private var trendingPlacesLoading = false
    @State private var trendingFetchFailed = false
    @State private var lastLoadedLocationKey: String = ""
    @AppStorage("hasChosenMapsApp") private var hasChosenMapsApp = false
    @State private var showMapsAppPicker = false
    @State private var pendingPlaceForMaps: GooglePlacesService.PlaceSearchResult?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var tutorialStep: Int
    var isTutorialActive: Bool
    // Section collapse states — Shortcuts expanded by default; others collapsed
    @AppStorage("home_shortcuts_expanded") private var shortcutsExpanded = true
    @AppStorage("home_upcoming_expanded") private var upcomingExpanded = false
    @AppStorage("home_experiences_expanded") private var dateExperiencesExpanded = false
    @AppStorage("home_explore_expanded") private var exploreExpanded = true
    @AppStorage("home_story_expanded") private var storyExpanded = false
    // Upcoming Dates: show first 3, tap to expand
    // Sheet for reviewing > 3 unsaved plans
    @State private var showUnsavedPlansSheet = false
    @State private var heroPlanOverride: DatePlan?
    @State private var swapContext: SwapStopContext?

    private var heroPlan: DatePlan? {
        if let tonight = planForTonight { return tonight }
        let sortedSaved = coordinator.savedPlans.sorted {
            ($0.scheduledDate ?? $0.createdAt) < ($1.scheduledDate ?? $1.createdAt)
        }
        if let first = sortedSaved.first { return first }
        return allUnsavedPlans.first
    }

    private var heroPlanIsUnsaved: Bool {
        guard let plan = heroPlan else { return false }
        return allUnsavedPlans.contains(where: { $0.id == plan.id })
    }

    private var partnerDisplayName: String? {
        let name = PartnerSessionManager.shared.inviteInfo?.partnerName
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }

    private var displayHeroPlan: DatePlan? {
        heroPlanOverride ?? heroPlan
    }

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

    init(tutorialStep: Binding<Int> = .constant(0), isTutorialActive: Bool = false) {
        _tutorialStep = tutorialStep
        self.isTutorialActive = isTutorialActive
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                CharcoalMaroonBackground()
                    .ignoresSafeArea()
                
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 28) {
                            HomeAppHeaderBar(notificationManager: notificationManager)
                            headerSection
                            proactiveNudgeSection
                            heroSection
                                .id(HomeTutorialAnchor.heroPlan.rawValue)
                            lowKeyLink
                            shortcutsCollapsibleSection
                            yourUpcomingDatesSection
                            dateExperiencesCollapsibleSection
                            exploreCollapsibleSection
                            relationshipStorySection
                        }
                    }
                    .mainTabBarScrollInset()
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollContentBackground(.hidden)
                    .onChange(of: tutorialStep) { _, step in
                        guard isTutorialActive else { return }
                        scrollTutorial(to: step, proxy: scrollProxy)
                    }
                    .onChange(of: isTutorialActive) { _, active in
                        if active {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                scrollTutorial(to: tutorialStep, proxy: scrollProxy)
                            }
                        }
                    }
                }
            }
            .onAppear {
                coordinator.refreshPreferencesState()
                Task { await loadTrendingPlaces() }
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
                coordinator.refreshPreferencesState()
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
            .sheet(item: $swapContext) { context in
                SwapStopSheet(plan: context.plan, stopIndex: context.stopIndex) { alternative in
                    applySwap(alternative, to: context.plan, stopIndex: context.stopIndex)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: heroPlan?.id) { _, _ in
                heroPlanOverride = nil
            }
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK") { calendarMessage = nil }
            } message: {
                if let msg = calendarMessage { Text(msg) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $notificationManager.showNotificationsSheet) {
                NotificationsSheetView(notificationManager: notificationManager)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(greetingLine1)
                .font(Font.bodySerif(22, weight: .regular))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(greetingLine2)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 4)
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
        if heroPlan != nil {
            return "Tonight's plan is ready for review."
        }
        return "One tap to a finished plan your partner will love."
    }
    
    private var heroSection: some View {
        Group {
            if let plan = displayHeroPlan {
                ItineraryHeroCard(
                    plan: plan,
                    partnerName: partnerDisplayName,
                    onApprove: { approveHeroPlan(plan) },
                    onSwap: { presentSwapSheet(for: plan) },
                    onView: { openHeroPlan(plan) }
                )
                .homeTutorialAnchor(.planButton)
                .id(HomeTutorialAnchor.planButton.rawValue)
            } else {
                emptyHeroPlanCTA
            }
        }
        .homeTutorialAnchor(.heroPlan)
    }

    private func scrollTutorial(to step: Int, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.45)) {
            switch step {
            case 0:
                proxy.scrollTo(HomeTutorialAnchor.planButton.rawValue, anchor: .center)
            case 1:
                proxy.scrollTo(HomeTutorialAnchor.heroPlan.rawValue, anchor: .center)
            default:
                break
            }
        }
    }

    // MARK: - Screen 10 entry · Low-key tonight link (subtle, non-gold to keep one gold action on Home)
    private var lowKeyLink: some View {
        Button {
            coordinator.activeSheet = .lowKey
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .medium))
                Text("Not up for going out? Keep it low-key tonight")
                    .font(Font.bodySans(13, weight: .semibold))
            }
            .foregroundColor(Color.luxuryCreamMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.luxuryGold.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Screen 18 · Proactive nudge (uses important dates; dormant when none are near)
    @ViewBuilder
    private var proactiveNudgeSection: some View {
        if let nudge = upcomingImportantDate {
            Button {
                coordinator.startDatePlanning(mode: .fresh)
            } label: {
                HStack(spacing: 12) {
                    Text(nudge.emoji)
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(nudge.title)
                            .font(Font.bodySans(14, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(nudge.subtitle)
                            .font(Font.bodySans(12, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .goldHighlightMaroonAccent(cornerRadius: 16)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }

    private struct ImportantDateNudge {
        let emoji: String
        let title: String
        let subtitle: String
    }

    /// Soonest important date within the next 45 days (today's captured set: the user's birthday).
    /// Extend here as onboarding captures anniversary + partner birthday.
    private var upcomingImportantDate: ImportantDateNudge? {
        guard let dob = userProfileManager.currentUser?.dateOfBirth else { return nil }
        guard let days = daysUntilNextAnnual(of: dob), days <= 45 else { return nil }
        let whenText = days == 0 ? "today" : (days == 1 ? "tomorrow" : "in \(days) days")
        return ImportantDateNudge(
            emoji: "🎂",
            title: "Your birthday is \(whenText)",
            subtitle: "Plan something memorable — or send your partner a hint."
        )
    }

    /// Days until the next anniversary of a date (ignoring year). Nil if it can't be computed.
    private func daysUntilNextAnnual(of date: Date) -> Int? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let comps = cal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        var next = DateComponents(); next.month = month; next.day = day
        guard let thisYear = cal.nextDate(after: today.addingTimeInterval(-1), matching: next, matchingPolicy: .nextTimePreservingSmallerComponents) else { return nil }
        return cal.dateComponents([.day], from: today, to: cal.startOfDay(for: thisYear)).day
    }

    private func presentSwapSheet(for plan: DatePlan) {
        guard let stopIndex = SwapStopLogic.dinnerStopIndex(in: plan) else { return }
        swapContext = SwapStopContext(plan: plan, stopIndex: stopIndex)
    }

    private func applySwap(_ alternative: SwapStopAlternative, to plan: DatePlan, stopIndex: Int) {
        guard !alternative.isCurrent else { return }
        let updated = plan.replacingStop(at: stopIndex, with: alternative)
        heroPlanOverride = updated
        // Persist locally + to Supabase so the swapped stop survives reload.
        coordinator.persistEditedPlan(updated)
    }

    private var emptyHeroPlanCTA: some View {
        let showUseLast = LastQuestionnaireStore.hasLastData || coordinator.hasCompletedPreferences
        let showResume = QuestionnaireProgressStore.hasValidProgress

        return VStack(spacing: 16) {
            Button {
                coordinator.startDatePlanning(mode: .fresh)
            } label: {
                Text("Plan My Next Date")
                    .font(Font.bodySans(16, weight: .semibold))
                    .foregroundColor(Color.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentGold)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .homeTutorialAnchor(.planButton)
            .id(HomeTutorialAnchor.planButton.rawValue)

            if !coordinator.isLoggedIn {
                Text("Sign in to generate your date plan")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.55))
                    .multilineTextAlignment(.center)
            } else if !access.isSubscribed && access.freePlansRemaining > 0 {
                Text(access.freePlansRemaining == AccessManager.freePlanLimit
                     ? "\(access.freePlansRemaining) free date plans included — no card needed"
                     : "\(access.freePlansRemaining) free plan remaining · subscribe for unlimited")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.accentGold.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            if showUseLast || showResume {
                Button {
                    coordinator.startDatePlanning(mode: showResume ? .resume : .useLast)
                } label: {
                    Text("or reuse your last plan")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.accentGold)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private func openHeroPlan(_ plan: DatePlan) {
        coordinator.currentDatePlan = plan
        if heroPlanIsUnsaved,
           coordinator.generatedPlans.contains(where: { $0.id == plan.id }),
           let idx = coordinator.generatedPlans.firstIndex(where: { $0.id == plan.id }) {
            coordinator.generatedPlansSelectedIndex = idx
            coordinator.activeSheet = .datePlanOptions
        } else {
            coordinator.activeSheet = .datePlanResult
        }
    }

    private func approveHeroPlan(_ plan: DatePlan) {
        if heroPlanIsUnsaved {
            coordinator.savePlan(plan)
        } else {
            planForCalendar = plan
            calendarDate = plan.scheduledDate ?? Date()
        }
    }
    
    /// Key used to refetch trending when location (starting point or city) becomes available or changes.
    private var trendingLocationKey: String {
        UserProfileManager.resolvedLocationForDiscovery(from: userProfileManager)
    }

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
            let places = try await GooglePlacesService.shared.fetchRecommendedInCity(city: location, limit: 6, radiusMeters: 16_090)
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

    private func openPlaceInPreferredMaps(place: GooglePlacesService.PlaceSearchResult) {
        guard hasChosenMapsApp else {
            pendingPlaceForMaps = place
            showMapsAppPicker = true
            return
        }
        ExplorePlaceOpener.open(place)
    }

    // MARK: - Explore (Google Places carousel → full Explore sheet)

    private var exploreCollapsibleSection: some View {
        CollapsibleHomeSection(
            title: "Explore",
            subtitle: exploreSectionSubtitle,
            isExpanded: $exploreExpanded,
            headerTrailing: {
                Button { coordinator.showExplore() } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(Color.accentGold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open full Explore list")
            }
        ) {
            exploreCarouselContent
                .padding(.top, 14)
        }
    }

    private var exploreSectionSubtitle: String {
        let city = trendingLocationKey
        if city.isEmpty {
            return "Top-rated spots · tap a card or sparkles for the full list"
        }
        return "Near \(city) · tap for restaurants, bars & date-night spots"
    }

    @ViewBuilder
    private var exploreCarouselContent: some View {
        if trendingPlacesLoading {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.luxuryMaroonLight.opacity(0.5))
                            .frame(width: 200, height: 200)
                            .overlay(ProgressView().tint(Color.luxuryGold))
                    }
                    ExploreContinueCircleButton(action: { coordinator.showExplore() })
                }
                .padding(.horizontal, 20)
            }
        } else if !trendingPlaces.isEmpty {
            let preferredCity = trendingLocationKey
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
                    ExploreContinueCircleButton(action: { coordinator.showExplore() })
                }
                .padding(.horizontal, 20)
            }

            Button { coordinator.showExplore() } label: {
                HStack(spacing: 6) {
                    Text("See all spots in Explore")
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
        } else {
            exploreEmptyState
        }
    }

    private var exploreEmptyState: some View {
        VStack(spacing: 12) {
            if trendingLocationKey.isEmpty {
                Text("Set your starting address or city in Settings to see recommended spots.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { coordinator.activeSheet = .settings } label: {
                    HStack(spacing: 6) {
                        Text("Open Settings")
                            .font(Font.bodySans(13, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else if trendingFetchFailed {
                Text("Couldn't load nearby spots. Pull down to refresh.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { Task { await loadTrendingPlaces(force: true) } } label: {
                    HStack(spacing: 6) {
                        Text("Try again")
                            .font(Font.bodySans(13, weight: .semibold))
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Text("Browse categories and hot spots in your area.")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button { coordinator.showExplore() } label: {
                HStack(spacing: 6) {
                    Text("Open Explore")
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
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Date Experiences collapsible wrapper (events only)
    private var dateExperiencesCollapsibleSection: some View {
        CollapsibleHomeSection(
            title: "Happening Near You",
            subtitle: "Live events within 60 miles",
            isExpanded: $dateExperiencesExpanded
        ) {
            DateExperiencesSection(showHeader: false, compactEmptyState: true)
                .padding(.top, 4)
        }
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
                // Gold left accent bar → maroon on cream-card rows stays gold for now in list rows
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
            .background(Color.backgroundPrimary)
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
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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
                            Text("UPCOMING")
                                .font(Font.bodySans(13, weight: .semibold))
                                .tracking(1.2)
                                .foregroundColor(Color.accentGold)
                            if badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(Font.bodySans(11, weight: .bold))
                                    .foregroundColor(Color.backgroundPrimary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.accentGold)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(isMultiCity
                             ? "\(cityGroups.count) cities · tap a plan to view"
                             : "Saved plans · tap to view or add to calendar")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.textPrimary.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: upcomingExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.accentGold.opacity(0.7))
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
                                .foregroundColor(Color.accentGold)
                            Text("\(unsaved.count) date plans waiting to be saved")
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(Color.accentGold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.accentGold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.accentMaroon)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.accentGold.opacity(0.3), lineWidth: 1)
                        )
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
            .background(Color.backgroundPrimary)
            .navigationTitle("Plans Waiting to be Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { showUnsavedPlansSheet = false }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var shortcutsCollapsibleSection: some View {
        CollapsibleHomeSection(
            title: "Shortcuts",
            subtitle: "Quick tools for your date",
            isExpanded: $shortcutsExpanded
        ) {
            shortcutsGridContent
                .padding(.top, 14)
        }
    }

    private var shortcutsGridContent: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 16
        ) {
            LuxuryQuickTile(icon: "gift", title: "Gift Finder", color: Color.accentGold, isLocked: !access.canAccess(.gifting)) {
                    access.require(.gifting) {
                        coordinator.showGiftFinder(
                            datePlan: coordinator.currentDatePlan,
                            dateLocation: coordinator.currentDatePlan?.stops.first?.address
                        )
                    }
                }
                LuxuryQuickTile(icon: "music.note.list", title: "Smart Playlists", color: Color.luxuryGoldLight, isLocked: !access.canAccess(.playlist)) {
                    access.require(.playlist) {
                        coordinator.showPlaylist(for: coordinator.currentDatePlan?.title ?? "Date Night", planId: coordinator.currentDatePlan?.id)
                    }
                }
                LuxuryQuickTile(icon: "bubble.left.and.bubble.right", title: "Conversation Starters", color: Color.accentGold, isLocked: !access.canAccess(.conversation)) {
                    access.require(.conversation) {
                        coordinator.showConversationStarters()
                    }
                }
                LuxuryQuickTile(icon: "person.2.fill", title: "Plan Together", color: Color.accentGold, isLocked: !access.canAccess(.datePlan)) {
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
                LuxuryQuickTile(icon: "heart", title: "Send to partner", color: Color.luxuryGoldLight, isLocked: !access.canAccess(.datePlan)) {
                    access.require(.datePlan) {
                        if let plan = heroPlan ?? coordinator.currentDatePlan {
                            coordinator.activeSheet = .partnerShare(plan: plan)
                        }
                    }
                }
                LuxuryQuickTile(icon: "book.closed", title: "Date Tips", color: Color.accentGold, isLocked: !access.canAccess(.datingTips)) {
                    access.require(.datingTips) {
                        coordinator.showPlaybook()
                    }
                }
        }
        .padding(.horizontal, 20)
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
                        Text("YOUR STORY")
                            .font(Font.bodySans(13, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(Color.accentGold)
                        Text("Your journey together at a glance")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.textPrimary.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: storyExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.accentGold.opacity(0.7))
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
                        coordinator.showMemoryGallery = true
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

// MARK: - Luxury Unified Date Card (Explore carousel on Home)
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
                        image.resizable().aspectRatio(contentMode: .fill)
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
                        if !time.isEmpty {
                            Label(time, systemImage: "clock")
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                        if !price.isEmpty {
                            Text(price)
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                    }
                    Text(actionTitle)
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(12)
                }
                .padding(14)
            }
            .frame(width: 200)
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
