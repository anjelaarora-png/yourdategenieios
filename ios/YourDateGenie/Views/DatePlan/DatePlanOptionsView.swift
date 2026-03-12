import SwiftUI

struct DatePlanOptionsView: View {
    let plans: [DatePlan]
    var initialSelectedIndex: Int = 0
    var onSave: ((DatePlan) -> Void)?
    var onRegenerate: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var selectedPlanIndex = 0
    @State private var showPartnerShare = false
    @State private var showExport = false
    @State private var savedPlanIds: Set<UUID> = []
    @State private var showAddToCalendar = false
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    
    var selectedPlan: DatePlan {
        guard selectedPlanIndex < plans.count else { return plans.first ?? DatePlan.sample }
        return plans[selectedPlanIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    optionSelector
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            selectedPlanHeader
                            
                            planItinerary
                            
                            genieSecretTouch
                            
                            giftSuggestions
                            
                            packingAndWeather
                            
                            routeSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Your Date Plans")
                        .font(Font.header(17, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showAddToCalendar = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 13))
                                Text("Add to Calendar")
                                    .font(Font.bodySans(12, weight: .medium))
                            }
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button {
                            showPartnerShare = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 13))
                                Text("Invite Partner")
                                    .font(Font.bodySans(12, weight: .medium))
                            }
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button {
                            showExport = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 13))
                                Text("Export")
                                    .font(Font.bodySans(12, weight: .medium))
                            }
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.luxuryMaroonLight)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                savePlanBar
            }
            .onAppear {
                selectedPlanIndex = min(initialSelectedIndex, max(0, plans.count - 1))
            }
        }
        .sheet(isPresented: $showPartnerShare) {
            PartnerShareView(plan: selectedPlan)
        }
        .sheet(isPresented: $showAddToCalendar) {
            addToCalendarSheet(plan: selectedPlan)
        }
        .alert("Calendar", isPresented: $showCalendarAlert) {
            Button("OK") { calendarMessage = nil }
        } message: {
            if let msg = calendarMessage { Text(msg) }
        }
    }
    
    // MARK: - Add to Calendar Sheet
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
                        showAddToCalendar = false
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        }
    }
    
    // MARK: - Option Selector
    private var optionSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your date style:")
                .font(Font.bodySans(14, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                        PlanOptionCard(
                            plan: plan,
                            optionLabel: plan.optionLabel ?? "Option \(["A", "B", "C"][min(index, 2)])",
                            isSelected: selectedPlanIndex == index
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlanIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color.luxuryMaroon)
    }
    
    // MARK: - Save Plan Bar
    private var savePlanBar: some View {
        VStack(spacing: 12) {
            if let onSave = onSave {
                let isCurrentSaved = savedPlanIds.contains(selectedPlan.id)
                Button {
                    onSave(selectedPlan)
                    _ = withAnimation(.spring(response: 0.3)) {
                        savedPlanIds.insert(selectedPlan.id)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isCurrentSaved ? "checkmark.circle.fill" : "bookmark.fill")
                            .font(.system(size: 16))
                        Text(isCurrentSaved ? "Saved" : "Save Date Plan")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(isCurrentSaved ? Color.luxuryCream : Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(isCurrentSaved ? AnyShapeStyle(Color.luxuryGold.opacity(0.4)) : AnyShapeStyle(LinearGradient.goldShimmer))
                    )
                }
                .disabled(isCurrentSaved)
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
    
    // MARK: - Selected Plan Header
    private var selectedPlanHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(selectedPlan.title)
                    .font(Font.tangerine(42, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryCream)
                    .multilineTextAlignment(.center)
                
                Text(selectedPlan.tagline)
                    .font(Font.playfairItalic(16))
                    .foregroundColor(Color.luxuryMuted)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                    Text(selectedPlan.totalDuration)
                        .font(Font.bodySans(13, weight: .medium))
                }
                .foregroundColor(Color.luxuryCream)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(20)
                
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 13))
                    Text(selectedPlan.estimatedCost)
                        .font(Font.bodySans(13, weight: .medium))
                }
                .foregroundColor(Color.luxuryGold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.luxuryGold.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Plan Itinerary
    private var planItinerary: some View {
        VStack(spacing: 0) {
            if let startingPoint = coordinator.generatedPlans.first?.stops.first {
                StartingPointCard(address: startingPoint.address ?? "Your Location")
            }
            
            ForEach(Array(selectedPlan.stops.enumerated()), id: \.element.id) { index, stop in
                ItineraryStopCard(
                    stop: stop,
                    stopNumber: index + 1,
                    isLast: index == selectedPlan.stops.count - 1
                )
            }
        }
    }
    
    // MARK: - Genie Secret Touch
    private var genieSecretTouch: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.goldShimmer)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(Color.luxuryMaroon)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(selectedPlan.genieSecretTouch.emoji)
                        Text("Genie's Secret Touch")
                            .font(Font.header(16, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                    }
                    
                    Text(selectedPlan.genieSecretTouch.title)
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.9))
                }
            }
            
            Text(selectedPlan.genieSecretTouch.description)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 24)
    }
    
    // MARK: - Gift Suggestions
    @ViewBuilder
    private var giftSuggestions: some View {
        if let gifts = selectedPlan.giftSuggestions, !gifts.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Text("🎁")
                        Text("Gift Suggestions")
                            .font(Font.header(16, weight: .bold))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    Spacer()
                    
                    Button {
                        coordinator.showGiftFinder(datePlan: selectedPlan, dateLocation: selectedPlan.stops.first?.address)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("Get More Ideas")
                                .font(Font.bodySans(12, weight: .medium))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.luxuryCream)
                        .cornerRadius(20)
                    }
                }
                
                Text("Found \(gifts.count) suggestions for your \(selectedPlan.title) date")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                
                ForEach(gifts) { gift in
                    GiftSuggestionCard(gift: gift)
                }
            }
            .padding(20)
            .background(Color.luxuryMaroonLight.opacity(0.6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
            .padding(.top, 24)
        }
    }
    
    // MARK: - Packing and Weather
    private var packingAndWeather: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("What to Bring")
                        .font(Font.header(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(selectedPlan.packingList, id: \.self) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.luxuryGold)
                                .frame(width: 6, height: 6)
                            Text(item)
                                .font(Font.bodySans(13, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("Weather Note")
                        .font(Font.header(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text(selectedPlan.weatherNote)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Route Section
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundColor(Color.luxuryGold)
                Text("Your Route")
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
            }
            
            Button {
                coordinator.showRouteMap(stops: selectedPlan.stops)
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .foregroundColor(Color.luxuryGold)
                        Text("Your Date Route")
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryCream)
                    }
                    
                    Spacer()
                    
                    Text("\(selectedPlan.stops.count) stops")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                        Text("Open in Maps")
                            .font(Font.bodySans(12, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.luxuryGold.opacity(0.15))
                    .cornerRadius(20)
                }
                .padding(16)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
                )
            }
            
            RouteSummaryBar(stops: selectedPlan.stops)
        }
        .padding(.top, 24)
    }
}

// MARK: - Plan Option Card
struct PlanOptionCard: View {
    let plan: DatePlan
    let optionLabel: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(optionLabel)
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(isSelected ? Color.luxuryMaroon : Color.luxuryMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.luxuryGold : Color.luxuryMaroonLight)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.luxuryGold)
                    }
                }
                
                Text(plan.title)
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(plan.tagline)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Divider()
                    .background(Color.luxuryGold.opacity(0.2))
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(plan.totalDuration)
                            .font(Font.bodySans(11, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryMuted)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 11))
                        Text(plan.estimatedCost)
                            .font(Font.bodySans(11, weight: .medium))
                    }
                    .foregroundColor(Color.luxuryMuted)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "4CAF50"))
                    Text("\(plan.stops.filter { $0.validated == true }.count)/\(plan.stops.count) venues verified")
                        .font(Font.bodySans(11, weight: .medium))
                        .foregroundColor(Color(hex: "4CAF50"))
                }
            }
            .padding(16)
            .frame(width: 220)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.luxuryGold : Color.luxuryGold.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Starting Point Card
struct StartingPointCard: View {
    let address: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.luxuryMaroonLight)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "location.fill")
                    .foregroundColor(Color.luxuryGold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("🏠")
                    Text("Starting Point")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text(address)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.luxuryMaroonLight.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Itinerary Stop Card
struct ItineraryStopCard: View {
    let stop: DatePlanStop
    let stopNumber: Int
    let isLast: Bool
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let travelTime = stop.travelTimeFromPrevious {
                TravelIndicator(
                    time: travelTime,
                    distance: stop.travelDistanceFromPrevious
                )
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Color.luxuryGold)
                            .frame(width: 28, height: 28)
                        
                        Text("\(stopNumber)")
                            .font(Font.bodySans(13, weight: .bold))
                            .foregroundColor(Color.luxuryMaroon)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 8) {
                                Text(stop.emoji)
                                Text(stop.name)
                                    .font(Font.header(16, weight: .bold))
                                    .foregroundColor(Color.luxuryCream)
                                
                                if stop.validated == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "4CAF50"))
                                }
                            }
                            
                            Spacer()
                            
                            Text(stop.timeSlot)
                                .font(Font.bodySans(13, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.luxuryGold.opacity(0.15))
                                .cornerRadius(16)
                        }
                        
                        Text(stop.venueType)
                            .font(Font.bodySans(13, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                        
                        if let address = stop.address {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text(address)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Color.luxuryMuted)
                        }
                        
                        HStack(spacing: 16) {
                            if let website = stop.websiteUrl {
                                Link(destination: URL(string: website) ?? URL(string: "https://google.com")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 11))
                                        Text("Website")
                                            .font(Font.bodySans(11, weight: .medium))
                                    }
                                    .foregroundColor(Color.luxuryGold)
                                }
                            }
                            
                            Button {
                                if let placeId = stop.placeId,
                                   let url = URL(string: "https://www.google.com/maps/place/?q=place_id:\(placeId)") {
                                    UIApplication.shared.open(url)
                                } else if let address = stop.address,
                                          let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                          let url = URL(string: "maps://?q=\(encoded)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                        .font(.system(size: 11))
                                    Text("View on Maps")
                                        .font(Font.bodySans(11, weight: .medium))
                                }
                                .foregroundColor(Color.luxuryGold)
                            }
                            
                            if let phone = stop.phoneNumber {
                                Link(destination: URL(string: "tel:\(phone)")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 11))
                                        Text(phone)
                                            .font(Font.bodySans(11, weight: .medium))
                                    }
                                    .foregroundColor(Color.luxuryGold)
                                }
                            }
                            
                            if let hours = stop.openingHours, !hours.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 11))
                                        Text("Hours (from Google)")
                                            .font(Font.bodySans(11, weight: .medium))
                                    }
                                    .foregroundColor(Color.luxuryGold)
                                    ForEach(hours.indices, id: \.self) { i in
                                        Text(hours[i])
                                            .font(Font.bodySans(11, weight: .regular))
                                            .foregroundColor(Color.luxuryCreamMuted)
                                    }
                                }
                            }
                        }
                        
                        Text(stop.description)
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineSpacing(4)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("Why this fits:")
                                    .font(Font.bodySans(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                                Text(stop.whyItFits)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("😍")
                                Text("Romantic tip:")
                                    .font(Font.bodySans(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                                Text(stop.romanticTip)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                        .padding(12)
                        .background(Color.luxuryMaroon.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.top, 8)
                        
                        HStack(spacing: 24) {
                            HStack(spacing: 6) {
                                Text("Duration:")
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                                Text(stop.duration)
                                    .font(Font.bodySans(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryCream)
                            }
                            
                            if let cost = stop.estimatedCostPerPerson {
                                HStack(spacing: 6) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.luxuryGold)
                                    Text(cost)
                                        .font(Font.bodySans(12, weight: .semibold))
                                        .foregroundColor(Color.luxuryCream)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.leading, 12)
                }
            }
            .padding(20)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Travel Indicator
struct TravelIndicator: View {
    let time: String
    let distance: String?
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.3))
                .frame(width: 2, height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                    .foregroundColor(Color.luxuryGold)
                
                Text(time)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                
                if let distance = distance {
                    Text("·")
                        .foregroundColor(Color.luxuryMuted)
                    Text(distance)
                        .font(Font.bodySans(12, weight: .medium))
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.luxuryMaroonLight.opacity(0.5))
            .cornerRadius(16)
        }
        .padding(.leading, 14)
        .padding(.vertical, 4)
    }
}

// MARK: - Gift Suggestion Card
struct GiftSuggestionCard: View {
    let gift: GiftSuggestion
    @State private var isFavorited = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Text(gift.emoji)
                        .font(.system(size: 24))
                    
                    Text(gift.name)
                        .font(Font.header(15, weight: .bold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Spacer()
                
                Text(gift.priceRange)
                    .font(Font.bodySans(12, weight: .semibold))
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.luxuryCream)
                    .cornerRadius(16)
                
                Button {
                    isFavorited.toggle()
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? Color.red : Color.luxuryMuted)
                }
                
                Button {
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.luxuryMuted)
                }
            }
            
            Text(gift.description)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(Color.luxuryGold)
                    Text("Why this gift fits:")
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
                
                Text(gift.whyItFits)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
            .padding(12)
            .background(Color.luxuryMaroon.opacity(0.5))
            .cornerRadius(10)
            
            HStack(spacing: 6) {
                Text("Where to buy:")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                Text(gift.whereToBuy)
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
        }
        .padding(16)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Route Summary Bar
struct RouteSummaryBar: View {
    let stops: [DatePlanStop]
    
    var totalTime: String {
        var minutes = 0
        for stop in stops {
            if let travel = stop.travelTimeFromPrevious {
                let nums = travel.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                minutes += Int(nums) ?? 0
            }
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("Total:")
                        .font(Font.bodySans(12, weight: .regular))
                    Text(totalTime)
                        .font(Font.bodySans(12, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
                .foregroundColor(Color.luxuryCream)
                
                Divider()
                    .frame(height: 20)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "4CAF50"))
                        Text("Start")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryMuted)
                    }
                    
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        if let travel = stop.travelTimeFromPrevious {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                Text(travel)
                                    .font(Font.bodySans(10, weight: .regular))
                            }
                            .foregroundColor(Color.luxuryMuted)
                        }
                        
                        HStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.luxuryGold)
                                    .frame(width: 18, height: 18)
                                Text("\(index + 1)")
                                    .font(Font.bodySans(10, weight: .bold))
                                    .foregroundColor(Color.luxuryMaroon)
                            }
                            Text(stop.name.components(separatedBy: " ").first ?? "")
                                .font(Font.bodySans(11, weight: .medium))
                                .foregroundColor(Color.luxuryCream)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
        }
    }
}

#Preview {
    DatePlanOptionsView(plans: [DatePlan.sample, DatePlan.sample, DatePlan.sample])
        .environmentObject(NavigationCoordinator.shared)
}
