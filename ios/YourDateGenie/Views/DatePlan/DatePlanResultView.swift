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
    @State private var showPlaylist = false
    @State private var showMap = false
    @State private var showPartnerShare = false
    @State private var showGiftFinder = false
    @State private var selectedVenue: DatePlanStop?
    @State private var isSaved = false
    @State private var showAddToCalendar = false
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var mainPlanCardAppeared = false
    @State private var showNoReservableAlert = false
    @State private var showReserveVenuePicker = false
    @State private var reservableStopsForPicker: [DatePlanStop] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            if let names = coordinator.currentPlanPartnerNames {
                                partnerBadgeView(names: names)
                            }
                            mainPlanCard
                            if coordinator.currentPlanPartnerNames != nil {
                                bothLoveSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
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
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Close")
                                .font(Font.inter(14, weight: .medium))
                        }
                        .foregroundColor(Color.luxuryGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.luxuryMaroonLight.opacity(0.8))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.luxuryGold.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if onDelete != nil {
                            Menu {
                                Button(role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete plan", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.luxuryGold)
                            }
                        }
                        
                        Button {
                            showPartnerShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15))
                                .foregroundColor(Color.luxuryGold)
                        }
                        
                        if isSaved {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
        .sheet(isPresented: $showPlaylist) {
            PlaylistWidgetView(
                planTitle: plan.title,
                stops: plan.stops.map { PlaylistStop(name: $0.name, venueType: $0.venueType) }
            )
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                RouteMapView(stops: itineraryStops, startingPoint: plan.startingPoint)
                    .navigationTitle("Route")
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
        .sheet(item: $selectedVenue) { venue in
            ReservationWidgetView(
                venueName: venue.name,
                venueType: venue.venueType,
                address: venue.address,
                phoneNumber: venue.phoneNumber,
                bookingUrl: venue.bookingUrl,
                websiteUrl: venue.websiteUrl,
                openingHours: venue.openingHours
            )
        }
        .sheet(isPresented: $showAddToCalendar) {
            addToCalendarSheet
        }
        .sheet(isPresented: $showReserveVenuePicker) {
            NavigationStack {
                List {
                    ForEach(Array(reservableStopsForPicker.enumerated()), id: \.offset) { _, stop in
                        Button {
                            selectedVenue = stop
                            showReserveVenuePicker = false
                        } label: {
                            HStack {
                                Text(stop.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if let url = stop.bookingUrl?.lowercased() {
                                    if url.contains("opentable") {
                                        Text("OpenTable")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if url.contains("resy") {
                                        Text("Resy")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Choose a venue to reserve")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { showReserveVenuePicker = false }
                            .foregroundColor(Color.luxuryGold)
                    }
                }
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
        }
    }
    
    // MARK: - Add to Calendar Sheet
    private var addToCalendarSheet: some View {
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
                                calendarMessage = "Added to your calendar."
                                showCalendarAlert = true
                                showAddToCalendar = false
                                if coordinator.savedPlans.contains(where: { $0.id == plan.id }) {
                                    coordinator.updateScheduledDate(for: plan.id, date: calendarDate)
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
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text("Add to Calendar")
                            .font(Font.inter(16, weight: .semibold))
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
                        showAddToCalendar = false
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
    
    // MARK: - Main Plan Card (love letter paper style)
    private var mainPlanCard: some View {
        LoveLetterItineraryBackground(cornerRadius: 24) {
            VStack(spacing: 0) {
                cardHeader
                Divider()
                    .background(Color.luxuryGold.opacity(0.4))
                    .padding(.horizontal, 20)
                titleSection
                if let start = plan.startingPoint {
                    startingPointSection(firstStop: itineraryStops.first, start: start)
                }
                stopsTimeline
                Divider()
                    .background(Color.luxuryGold.opacity(0.4))
                    .padding(.horizontal, 20)
                statsRow
                weatherNote
                conversationStartersSection
                giftSuggestionsSection
                packingChips
                pageDots
            }
        }
        .opacity(mainPlanCardAppeared ? 1 : 0)
        .offset(y: mainPlanCardAppeared ? 0 : 8)
        .animation(.easeOut(duration: 0.4), value: mainPlanCardAppeared)
    }
    
    // MARK: - Partner badge ("Made for A & B")
    private func partnerBadgeView(names: (String, String)) -> some View {
        Text("Made for \(names.0) & \(names.1)")
            .font(Font.bodySans(14, weight: .semibold))
            .foregroundColor(Color.luxuryGold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.luxuryMaroonLight.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.luxuryGold, lineWidth: 1.5)
            )
    }
    
    // MARK: - Both of you will love this because...
    private var bothLoveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Both of you will love this because...")
                .font(Font.bodySans(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text(plan.tagline)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            Text(plan.genieSecretTouch.description)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.luxuryGold.opacity(0.15), radius: 12, y: 4)
        )
    }
    
    // MARK: - Card Header (on paper: dark text)
    private var cardHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(Color.luxuryGoldDark)
                
                Text("Your Date Plan")
                    .font(Font.inter(14, weight: .semibold))
                    .foregroundColor(Color(hex: "4A0E0E"))
            }
            
            Spacer()
            
            if isSaved {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.title)
                .font(Font.header(28, weight: .semibold))
                .foregroundColor(Color(hex: "3D2C2C"))
            
            Text(plan.tagline)
                .font(Font.playfair(15, weight: .regular))
                .foregroundColor(Color.luxuryGoldDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    /// Itinerary = venues only (step 1, 2, 3...). Starting point is not a step.
    private var itineraryStops: [DatePlanStop] {
        plan.stops.filter { $0.venueType != "Starting point" && $0.name != "Your location" }
    }
    
    // MARK: - Starting Point (before timeline)
    private func startingPointSection(firstStop: DatePlanStop?, start: StartingPoint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.luxuryGoldDark)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starting point")
                        .font(Font.inter(14, weight: .semibold))
                        .foregroundColor(Color(hex: "3D2C2C"))
                    Text(start.address)
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(Color.luxuryGoldDark)
                }
                Spacer(minLength: 0)
            }
            if let first = firstStop, let url = MapURLHelper.directionsURL(origin: start, destination: first) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 12))
                        Text("Get to stop 1: \(first.name)")
                            .font(Font.inter(13, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Stops Timeline (on paper: dark style)
    private var stopsTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(itineraryStops.enumerated()), id: \.element.id) { index, stop in
                if index > 0, let time = stop.travelTimeFromPrevious, !time.isEmpty {
                    TravelLegRow(
                        travelMode: stop.travelMode,
                        timeText: time,
                        distanceText: stop.travelDistanceFromPrevious,
                        useDarkStyle: true
                    )
                }
                CompactStopRow(
                    stop: stop,
                    isLast: index == itineraryStops.count - 1,
                    useDarkStyle: true,
                    onTap: {
                        if isReservable(stop) {
                            selectedVenue = stop
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats Row (on paper: dark text)
    private var statsRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(Color.luxuryGoldDark)
                Text(plan.totalDuration)
                    .font(Font.inter(13, weight: .medium))
                    .foregroundColor(Color(hex: "3D2C2C"))
            }
            Text("·")
                .foregroundColor(Color(hex: "6B5344"))
                .padding(.horizontal, 12)
            Text(plan.estimatedCost)
                .font(Font.inter(13, weight: .medium))
                .foregroundColor(Color(hex: "3D2C2C"))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "figure.roll")
                    .font(.system(size: 11))
                Text("Accessible")
                    .font(Font.inter(11, weight: .medium))
            }
            .foregroundColor(Color.luxuryGoldDark)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Weather Note (on paper: dark text)
    private var weatherNote: some View {
        Group {
            if !plan.weatherNote.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.luxuryGoldDark)
                    
                    Text(plan.weatherNote)
                        .font(Font.inter(13, weight: .regular))
                        .foregroundColor(Color(hex: "5C4A3D"))
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.luxuryGold.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Conversation Starters Section (on paper: all starters when selected)
    private var conversationStartersSection: some View {
        Group {
            if let starters = plan.conversationStarters, !starters.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 12))
                        Text("Conversation Starters")
                            .font(Font.inter(12, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGoldDark)
                    
                    ForEach(starters) { starter in
                        Text("\"\(starter.question)\"")
                            .font(Font.playfairItalic(14))
                            .foregroundColor(Color(hex: "5C4A3D"))
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.luxuryGold.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Gift Suggestions Section (on paper: when selected)
    private var giftSuggestionsSection: some View {
        Group {
            if let gifts = plan.giftSuggestions, !gifts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                        Text("Gift Suggestions")
                            .font(Font.inter(12, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGoldDark)
                    
                    ForEach(gifts) { gift in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text(gift.emoji)
                                    .font(.system(size: 16))
                                Text(gift.name)
                                    .font(Font.inter(13, weight: .semibold))
                                    .foregroundColor(Color(hex: "3D2C2C"))
                                Spacer(minLength: 8)
                                Text(gift.priceRange)
                                    .font(Font.inter(11, weight: .medium))
                                    .foregroundColor(Color.luxuryGoldDark)
                            }
                            Text(gift.description)
                                .font(Font.inter(12, weight: .regular))
                                .foregroundColor(Color(hex: "5C4A3D"))
                                .lineLimit(2)
                            if !gift.whereToBuy.isEmpty {
                                Text("Where: \(gift.whereToBuy)")
                                    .font(Font.inter(11, weight: .regular))
                                    .foregroundColor(Color.luxuryGoldDark)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.luxuryGold.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.luxuryGold.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Packing Chips (on paper: dark text)
    private var packingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(plan.packingList.prefix(4), id: \.self) { item in
                    HStack(spacing: 6) {
                        Image(systemName: packingIcon(for: item))
                            .font(.system(size: 11))
                        Text(item)
                            .font(Font.inter(12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "5C4A3D"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Page Dots
    private var pageDots: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.luxuryGold.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Capsule()
                .fill(Color.luxuryGoldDark)
                .frame(width: 20, height: 6)
            
            Circle()
                .fill(Color.luxuryGold.opacity(0.3))
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            // Quick Actions
            HStack(spacing: 12) {
                QuickActionButton(icon: "map.fill", label: "Route") {
                    showMap = true
                }
                
                QuickActionButton(icon: "calendar.badge.plus", label: "Calendar") {
                    showAddToCalendar = true
                }
                
                QuickActionButton(icon: "music.note", label: "Playlist") {
                    showPlaylist = true
                }
                
                QuickActionButton(icon: "gift.fill", label: "Gifts") {
                    showGiftFinder = true
                }
                
                QuickActionButton(icon: "fork.knife.circle", label: "Reserve") {
                    let reservable = plan.stops.filter { isReservable($0) }
                    if reservable.isEmpty {
                        showNoReservableAlert = true
                    } else if reservable.count == 1 {
                        selectedVenue = reservable[0]
                    } else {
                        reservableStopsForPicker = reservable
                        showReserveVenuePicker = true
                    }
                }
                
                QuickActionButton(icon: "camera.fill", label: "Photo") {
                    coordinator.currentTab = .memories
                }
            }
            
            // Main Action Button (Save) - only when onSave provided and not yet saved
            if onSave != nil {
                Button {
                    if let onSave = onSave, !isSaved {
                        withAnimation(.spring(response: 0.3)) {
                            isSaved = true
                        }
                        onSave()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isSaved ? "checkmark.circle.fill" : "bookmark.fill")
                            .font(.system(size: 14))
                        Text(isSaved ? "Saved" : "Save Date Plan")
                            .font(Font.inter(14, weight: .semibold))
                    }
                    .foregroundColor(isSaved ? Color.luxuryCream : Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                            .background(Capsule().fill(isSaved ? Color.luxuryGold.opacity(0.4) : Color.luxuryMaroonLight))
                    )
                }
                .disabled(isSaved)
            }

            // Move to Past Dates — when plan is saved, user can mark date as done
            if isSaved && coordinator.savedPlans.contains(where: { $0.id == plan.id }) {
                Button {
                    coordinator.markPlanAsPast(plan)
                    coordinator.dismissSheet()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                        Text("We did this date — move to Past Dates")
                            .font(Font.inter(13, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.luxuryMaroon
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    private func isReservable(_ stop: DatePlanStop) -> Bool {
        let types = ["restaurant", "bar", "cafe", "lounge", "bistro", "dining"]
        return types.contains { stop.venueType.lowercased().contains($0) }
    }
    
    private func packingIcon(for item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("shoe") || lower.contains("walking") { return "shoeprints.fill" }
        if lower.contains("jacket") || lower.contains("coat") { return "cloud.fill" }
        if lower.contains("phone") { return "iphone" }
        if lower.contains("camera") { return "camera.fill" }
        if lower.contains("book") || lower.contains("art") { return "book.fill" }
        if lower.contains("umbrella") { return "umbrella.fill" }
        if lower.contains("mint") || lower.contains("breath") { return "leaf.fill" }
        return "bag.fill"
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
                .font(Font.inter(11, weight: .medium))
                .foregroundColor(secondaryText)
            if let dist = distanceText, !dist.isEmpty {
                Text("·")
                    .foregroundColor(secondaryText)
                Text(dist)
                    .font(Font.inter(11, weight: .regular))
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
                            .font(Font.inter(12, weight: .regular))
                    }
                    .foregroundColor(secondaryText)
                    
                    Text("·")
                        .foregroundColor(secondaryText)
                    
                    Text(stop.formattedAddress)
                        .font(Font.inter(12, weight: .regular))
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                }
                
                if let hours = stop.openingHours, !hours.isEmpty {
                    Button {
                        hoursExpanded.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("Hours")
                                .font(Font.inter(10, weight: .medium))
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
                                    .font(Font.inter(10, weight: .regular))
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
                                    .font(Font.inter(10, weight: .regular))
                            }
                            .foregroundColor(linkColor)
                        }
                        if let webUrl = stop.websiteUrl, let url = URL(string: webUrl) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 9))
                                    Text("Website")
                                        .font(Font.inter(10, weight: .regular))
                                }
                                .foregroundColor(linkColor)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: noteIcon)
                        .font(.system(size: 10))
                    Text(stop.romanticTip)
                        .font(Font.inter(11, weight: .medium))
                        .lineLimit(1)
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
                .font(Font.inter(9, weight: .semibold))
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.luxuryGold)
                    .frame(width: 44, height: 44)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                    )
                
                Text(label)
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .frame(maxWidth: .infinity)
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
                .font(Font.inter(13, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
            Text(label)
                .font(Font.inter(9, weight: .medium))
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
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Text(title)
                    .font(Font.inter(10, weight: .medium))
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
                    .font(Font.inter(10, weight: .semibold))
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
                .font(Font.inter(11, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 160)
        .background(Color.luxuryMaroonLight)
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
                    .font(Font.inter(10, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryMaroonLight)
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
}
