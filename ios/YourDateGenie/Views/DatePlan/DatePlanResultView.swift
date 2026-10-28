import SwiftUI

struct DatePlanResultView: View {
    let plan: DatePlan
    var onSave: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var onDelete: (() -> Void)?
    var isViewingMode: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @State private var showPlaylist = false
    @State private var showMap = false
    @State private var showPartnerShare = false
    @State private var showGiftFinder = false
    @State private var isSaved = false
    @State private var showAddToCalendar = false
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var mainPlanCardAppeared = false
    @State private var showNoReservableAlert = false
    @State private var showReserveVenuePicker = false
    @State private var reservableStopsForPicker: [DatePlanStop] = []
    @State private var platformPickerPayload: ReservationPlatformPickerPayload?
    @State private var showSaveDatePicker = false
    // Screen 23 · paywall appears AFTER the user has seen their first result (spec §10), once, dismissible.
    @State private var showPostResultPaywall = false
    @AppStorage("hasSeenPostResultPaywall") private var hasSeenPostResultPaywall = false
    @State private var swapContext: SwapStopContext?

    /// Live plan from coordinator after edits (e.g. stop swap); falls back to the passed-in plan.
    private var displayPlan: DatePlan {
        if let match = coordinator.generatedPlans.first(where: { $0.id == plan.id }) { return match }
        if let match = coordinator.savedPlans.first(where: { $0.id == plan.id }) { return match }
        if let match = coordinator.experiencesWaiting.first(where: { $0.id == plan.id }) { return match }
        if coordinator.currentDatePlan?.id == plan.id, let current = coordinator.currentDatePlan { return current }
        return plan
    }

    private var hasMultipleGeneratedOptions: Bool {
        coordinator.generatedPlans.count > 1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.ydgBase
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: YDGSpace.sm) {
                            if let names = coordinator.currentPlanPartnerNames {
                                partnerBadgeView(names: names)
                            }
                            mainPlanCard
                            planSecondaryActions
                        }
                        .padding(.horizontal, YDGSpace.xxs)
                        .padding(.top, YDGSpace.xs)
                        .padding(.bottom, YDGSpace.lg)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        coordinator.dismissSheet()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.ydgTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 0) {
                        Button {
                            access.require(.datePlan) {
                                showPartnerShare = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.ydgTextPrimary)
                                .opacity(access.canAccess(.datePlan) ? 1 : 0.45)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Share this plan")

                        Menu {
                            planToolsMenu
                            if onDelete != nil {
                                Divider()
                                Button(role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete plan", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.ydgTextPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("More options")
                    }
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
        .tint(Color.luxuryGold)
        .sheet(isPresented: $showPlaylist) {
            PlaylistWidgetView(
                planTitle: plan.title,
                planId: plan.id,
                stops: plan.stops.map { PlaylistStop(name: $0.name, venueType: $0.venueType) }
            )
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                RouteMapView(
                    stops: ItineraryPlanFormatting.itineraryStops(for: plan),
                    startingPoint: plan.startingPoint
                )
                    .navigationTitle("Your route")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showMap = false }
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showPartnerShare) {
            PartnerShareView(plan: plan)
        }
        .sheet(isPresented: $showGiftFinder) {
            GiftFinderView(datePlan: plan, dateLocation: plan.stops.first?.address)
        }
        .sheet(isPresented: $showAddToCalendar) {
            AddToCalendarSheet(
                plan: plan,
                onDismiss: { showAddToCalendar = false }
            ) { result, date in
                switch result {
                case .success:
                    calendarMessage = "Added to your calendar."
                    showCalendarAlert = true
                    showAddToCalendar = false
                    if coordinator.savedPlans.contains(where: { $0.id == plan.id }) {
                        coordinator.updateScheduledDate(for: plan.id, date: date)
                    }
                case .denied:
                    calendarMessage = "Calendar access was denied. Enable it in Settings to add date plans."
                    showCalendarAlert = true
                case .failed(let msg):
                    calendarMessage = "Could not add: \(msg)"
                    showCalendarAlert = true
                }
            }
        }
        .sheet(isPresented: $showReserveVenuePicker) {
            NavigationStack {
                ZStack {
                    Color.backgroundPrimary.ignoresSafeArea()
                    List {
                        ForEach(reservableStopsForPicker) { stop in
                            ReservationPlatformActionRow(
                                venueName: stop.name,
                                phoneNumber: stop.phoneNumber,
                                address: stop.address,
                                reservationPlatforms: stop.reservationPlatforms,
                                bookingUrl: stop.bookingUrl,
                                onAction: { showReserveVenuePicker = false }
                            )
                            .padding(.vertical, 4)
                            .listRowBackground(Color.luxeSurfaceTintStrong)
                            .listRowSeparatorTint(Color.luxuryGold.opacity(0.28))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Reserve")
                            .font(Font.bodySerif(18, weight: .regular))
                            .foregroundColor(Color.accentGold)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { showReserveVenuePicker = false }
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .sheet(isPresented: $showSaveDatePicker) {
            DatePickerSheet(planTitle: plan.title) { date in
                showSaveDatePicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.savePlan(plan, plannedDate: date)
                    withAnimation(.spring(response: 0.3)) { isSaved = true }
                }
            } onCancel: {
                showSaveDatePicker = false
            }
        }
        .alert("Calendar", isPresented: $showCalendarAlert) {
            Button("OK") { calendarMessage = nil }
        } message: {
            if let msg = calendarMessage { Text(msg) }
        }
        .alert("Reservations", isPresented: $showNoReservableAlert) {
            Button("OK") { showNoReservableAlert = false }
        } message: {
            Text("This plan doesn't include any reservable venues (e.g. restaurant or bar).")
        }
        .alert("Delete plan?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { showDeleteConfirmation = false }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This plan will be permanently removed. This cannot be undone.")
        }
        .onAppear {
            if coordinator.savedPlans.contains(where: { $0.id == plan.id }) {
                isSaved = true
            }
            mainPlanCardAppeared = true
            maybePresentPostResultPaywall()
        }
        .sheet(item: $platformPickerPayload) { payload in
            ReservationPlatformPickerSheet(payload: payload) {
                platformPickerPayload = nil
            }
        }
        .sheet(isPresented: $showPostResultPaywall) {
            PremiumDatePlanPaywallView {
                showPostResultPaywall = false
            }
        }
        .sheet(item: $swapContext) { context in
            SwapStopSheet(plan: context.plan, stopIndex: context.stopIndex) { alternative in
                applySwap(alternative, to: context.plan, stopIndex: context.stopIndex)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    /// Show the paywall once, shortly after the first result renders, for non-subscribers.
    /// The first full plan stays free; this is a soft, dismissible upsell after the payoff.
    private func maybePresentPostResultPaywall() {
        guard !isViewingMode, !access.isSubscribed, !hasSeenPostResultPaywall else { return }
        hasSeenPostResultPaywall = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showPostResultPaywall = true
        }
    }
    
    // MARK: - Main Plan Card (matches Home hero cream card)
    private var mainPlanCard: some View {
        ItineraryCreamCardChrome(edgePadding: YDGSpace.md, surface: .plain) {
            ItineraryCreamPlanDetailContent(
                plan: displayPlan,
                partnerName: partnerDisplayName,
                onReserveStop: { stop in
                    platformPickerPayload = ReservationPlatformPickerPayload(
                        venueName: stop.name,
                        phoneNumber: stop.phoneNumber,
                        address: stop.address,
                        reservationPlatforms: stop.reservationPlatforms,
                        bookingUrl: stop.bookingUrl
                    )
                },
                onOpenRoute: {
                    coordinator.showRouteMap(
                        stops: ItineraryPlanFormatting.itineraryStops(for: displayPlan),
                        startingPoint: displayPlan.startingPoint
                    )
                },
                onGetMoreGiftIdeas: {
                    access.require(.gifting) {
                        showGiftFinder = true
                    }
                },
                canAccessGiftIdeas: access.canAccess(.gifting)
            )
        }
        .opacity(mainPlanCardAppeared ? 1 : 0)
        .offset(y: mainPlanCardAppeared ? 0 : 8)
        .animation(.easeOut(duration: 0.4), value: mainPlanCardAppeared)
    }

    private var planSecondaryActions: some View {
        HStack(spacing: YDGSpace.xs) {
            if SwapStopLogic.dinnerStopIndex(in: displayPlan) != nil {
                Button("Swap a stop") {
                    presentSwapSheet(for: displayPlan)
                }
                .buttonStyle(YDGButtonStyle(kind: .secondary))
            }

            if hasMultipleGeneratedOptions {
                Button("Compare options") {
                    if let idx = coordinator.generatedPlans.firstIndex(where: { $0.id == displayPlan.id }) {
                        coordinator.generatedPlansSelectedIndex = idx
                    }
                    coordinator.activeSheet = .datePlanOptions
                }
                .buttonStyle(YDGButtonStyle(kind: .secondary))
            }
        }
    }

    private func presentSwapSheet(for plan: DatePlan) {
        guard let stopIndex = SwapStopLogic.dinnerStopIndex(in: plan) else { return }
        swapContext = SwapStopContext(plan: plan, stopIndex: stopIndex)
    }

    private func applySwap(_ alternative: SwapStopAlternative, to plan: DatePlan, stopIndex: Int) {
        guard !alternative.isCurrent else { return }
        let updated = plan.replacingStop(at: stopIndex, with: alternative)
        coordinator.persistEditedPlan(updated)
    }

    private var partnerDisplayName: String? {
        if let names = coordinator.currentPlanPartnerNames {
            return names.1
        }
        let name = PartnerSessionManager.shared.inviteInfo?.partnerName
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }

    // MARK: - Partner badge ("Made for A & B")
    private func partnerBadgeView(names: (String, String)) -> some View {
        Text("Made for \(names.0) & \(names.1)")
            .ydgText(.caption, color: .ydgHighlight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Plan tools (in the "…" menu; the design keeps the bottom bar to Share + Save)
    @ViewBuilder
    private var planToolsMenu: some View {
        Button {
            access.require(.datePlan) { showMap = true }
        } label: { Label("Route", systemImage: "map") }

        Button {
            access.require(.datePlan) { showAddToCalendar = true }
        } label: { Label("Add to calendar", systemImage: "calendar.badge.plus") }

        Button {
            access.require(.datePlan) { reserveTapped() }
        } label: { Label("Reserve a table", systemImage: "fork.knife") }

        Button {
            access.require(.playlist) { showPlaylist = true }
        } label: { Label("Playlist", systemImage: "music.note") }

        Button {
            access.require(.gifting) { showGiftFinder = true }
        } label: { Label("Gift ideas", systemImage: "gift") }

        Button {
            access.require(.memory) { coordinator.isShowingMemoryCapture = true }
        } label: { Label("Add a photo", systemImage: "camera") }
    }

    private func reserveTapped() {
        let reservable = plan.stops.filter { ItineraryPlanFormatting.isReservable($0) }
        if reservable.isEmpty {
            showNoReservableAlert = true
        } else if reservable.count == 1 {
            let stop = reservable[0]
            platformPickerPayload = ReservationPlatformPickerPayload(
                venueName: stop.name,
                phoneNumber: stop.phoneNumber,
                address: stop.address,
                reservationPlatforms: stop.reservationPlatforms,
                bookingUrl: stop.bookingUrl
            )
        } else {
            reservableStopsForPicker = reservable
            showReserveVenuePicker = true
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: YDGSpace.xxs) {
            HStack(spacing: YDGSpace.sm) {
                Button("Share") {
                    access.require(.datePlan) { showPartnerShare = true }
                }
                .buttonStyle(YDGButtonStyle(kind: .secondary, fullWidth: onSave == nil))

                // Save — only when onSave provided
                if onSave != nil {
                    Button {
                        guard !isSaved else { return }
                        if plan.scheduledDate != nil || coordinator.lastQuestionnaireScheduledDate != nil {
                            withAnimation(.spring(response: 0.3)) { isSaved = true }
                            onSave?()
                        } else {
                            showSaveDatePicker = true
                        }
                    } label: {
                        Text(isSaved ? "Saved" : "Save this plan")
                    }
                    .buttonStyle(.ydgPrimary)
                    .disabled(isSaved)
                }
            }

            // Move to Past Dates — when plan is saved, user can mark date as done
            if isSaved && coordinator.savedPlans.contains(where: { $0.id == plan.id }) {
                Button("We went on this date") {
                    coordinator.markPlanAsPast(plan)
                    coordinator.dismissSheet()
                }
                .buttonStyle(.ydgTertiary)
            }
        }
        .padding(.horizontal, YDGSpace.margin)
        .padding(.top, YDGSpace.sm)
        .padding(.bottom, YDGSpace.xs)
        .background(Color.ydgBase.ignoresSafeArea())
    }
}

// MARK: - Travel Leg Row (between stops: mode icon + time + distance)
struct TravelLegRow: View {
    let travelMode: String?
    let timeText: String
    let distanceText: String?
    var useDarkStyle: Bool = false
    
    private var accentColor: Color { useDarkStyle ? Color.luxuryGoldDark : Color.luxuryGold }
    private var secondaryText: Color { useDarkStyle ? Color(hex: "5C4A3D") : Color.luxuryMuted }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: TravelModeIcon.sfSymbol(for: travelMode, inferFromTimeText: timeText))
                .font(.system(size: 12))
                .foregroundColor(accentColor)
            Text(timeText)
                .font(Font.bodySans(11, weight: .medium))
                .foregroundColor(secondaryText)
            if let dist = distanceText, !dist.isEmpty {
                Text("·")
                    .foregroundColor(secondaryText)
                Text(dist)
                    .font(Font.bodySans(11, weight: .regular))
                    .foregroundColor(secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(accentColor.opacity(0.12))
        .cornerRadius(8)
        .padding(.leading, 56)
        .padding(.bottom, 6)
    }
}

// MARK: - Compact Stop Row
struct CompactStopRow: View {
    let stop: DatePlanStop
    let isLast: Bool
    var useDarkStyle: Bool = false
    var onTap: (() -> Void)?
    
    @State private var hoursExpanded = false
    
    private var primaryText: Color { useDarkStyle ? Color(hex: "3D2C2C") : Color.luxuryCream }
    private var secondaryText: Color { useDarkStyle ? Color(hex: "5C4A3D") : Color.luxuryMuted }
    private var accentColor: Color { useDarkStyle ? Color.luxuryGoldDark : Color.luxuryGold }
    private var linkColor: Color { useDarkStyle ? Color.luxuryGoldDark : Color.luxuryGoldLight }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: venueIcon)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(accentColor.opacity(0.25))
                        .frame(width: 1.5, height: 50)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(stop.name)
                        .font(Font.playfair(16, weight: .semibold))
                        .foregroundColor(primaryText)
                    
                    if stop.isVerified {
                        VerifiedBadge()
                    }
                }
                
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(stop.timeSlot)
                            .font(Font.bodySans(12, weight: .regular))
                    }
                    .foregroundColor(secondaryText)
                    
                    Text("·")
                        .foregroundColor(secondaryText)
                    
                    Text(stop.formattedAddress)
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let hours = stop.openingHours, !hours.isEmpty {
                    Button {
                        hoursExpanded.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("Hours")
                                .font(Font.bodySans(10, weight: .medium))
                            Image(systemName: hoursExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(secondaryText)
                    }
                    .buttonStyle(.plain)
                    if hoursExpanded {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(hours, id: \.self) { line in
                                Text(line)
                                    .font(Font.bodySans(10, weight: .regular))
                                    .foregroundColor(secondaryText)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                if stop.phoneNumber != nil || (stop.websiteUrl != nil && !(stop.websiteUrl?.isEmpty ?? true)) {
                    HStack(spacing: 10) {
                        if let phone = stop.phoneNumber {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 9))
                                Text(phone)
                                    .font(Font.bodySans(10, weight: .regular))
                            }
                            .foregroundColor(linkColor)
                        }
                        if let webUrl = stop.websiteUrl, let url = URL(string: webUrl) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 9))
                                    Text("Website")
                                        .font(Font.bodySans(10, weight: .regular))
                                }
                                .foregroundColor(linkColor)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: noteIcon)
                        .font(.system(size: 10))
                        .padding(.top, 1)
                    Text(stop.romanticTip)
                        .font(Font.bodySans(11, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(accentColor)
                .padding(.top, 2)
            }
            .padding(.bottom, isLast ? 8 : 16)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
        }
    }
    
    private var venueIcon: String {
        let type = stop.venueType.lowercased()
        if type.contains("restaurant") || type.contains("dining") || type.contains("cafe") { return "fork.knife" }
        if type.contains("bar") || type.contains("cocktail") || type.contains("lounge") { return "wineglass.fill" }
        if type.contains("walk") || type.contains("park") || type.contains("garden") { return "figure.walk" }
        if type.contains("museum") || type.contains("gallery") || type.contains("art") { return "building.columns.fill" }
        if type.contains("rooftop") || type.contains("view") { return "building.2.fill" }
        if type.contains("spa") || type.contains("wellness") { return "leaf.fill" }
        if type.contains("movie") || type.contains("cinema") || type.contains("theater") { return "film.fill" }
        if type.contains("music") || type.contains("concert") { return "music.note" }
        return "mappin"
    }
    
    private var noteIcon: String {
        let tip = stop.romanticTip.lowercased()
        if tip.contains("reserv") { return "checkmark.circle.fill" }
        if tip.contains("access") || tip.contains("wheelchair") { return "figure.roll" }
        if tip.contains("vegan") || tip.contains("menu") { return "leaf.fill" }
        return "sparkle"
    }
}

// MARK: - Verified Badge
struct VerifiedBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "4CAF50"))
            
            Text("Verified")
                .font(Font.bodySans(9, weight: .semibold))
                .foregroundColor(Color(hex: "4CAF50"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(hex: "4CAF50").opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color(hex: "4CAF50").opacity(0.3), lineWidth: 0.5)
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    var isLocked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                YDGIconTile(systemName: icon, size: 44)
                    .overlay(alignment: .topTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color.ydgTextOnAccent)
                                .frame(width: 16, height: 16)
                                .background(Circle().fill(Color.ydgIconCream))
                                .offset(x: 3, y: -3)
                        }
                    }
                Text(label)
                    .font(Font.ydgSans(12, weight: .medium))
                    .foregroundColor(Color.ydgTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(isLocked ? "\(label), Premium" : label)
    }
}

// MARK: - Supporting Views (kept for compatibility)
struct LuxuryStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.luxuryGold)
            Text(value)
                .font(Font.bodySans(13, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text(label)
                .font(Font.bodySans(9, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
        }
    }
}

struct LuxuryQuickAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(Color.luxeSurfaceTintStrong)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Text(title)
                    .font(Font.bodySans(10, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
        }
    }
}

struct LuxurySectionTitle: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color.luxuryGold)
            Text(title)
                .font(Font.playfair(16, weight: .semibold))
                .foregroundColor(Color.luxuryGold)
        }
    }
}

struct LuxuryStopCard: View {
    let stop: DatePlanStop
    let isLast: Bool
    var onReserve: (() -> Void)?
    
    var body: some View {
        CompactStopRow(stop: stop, isLast: isLast, onTap: onReserve)
    }
}

struct LuxuryGiftCard: View {
    let gift: GiftSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(gift.emoji)
                    .font(.system(size: 28))
                Spacer()
                Text(gift.priceRange)
                    .font(Font.bodySans(10, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(6)
            }
            
            Text(gift.name)
                .font(Font.playfair(14, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .lineLimit(1)
            
            Text(gift.description)
                .font(Font.bodySans(11, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 160)
        .background(Color.luxeSurfaceTintStrong)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

struct LuxuryConversationCard: View {
    let starter: ConversationStarter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(starter.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(starter.question)
                    .font(Font.playfair(14, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                
                Text(starter.category)
                    .font(Font.bodySans(10, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxeSurfaceTintStrong)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    DatePlanResultView(
        plan: DatePlan.sample,
        onSave: { },
        onRegenerate: { }
    )
    .environmentObject(NavigationCoordinator.shared)
    .environmentObject(AccessManager.shared)
}
