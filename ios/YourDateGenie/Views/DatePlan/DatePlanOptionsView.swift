import SwiftUI

struct DatePlanOptionsView: View {
    let plans: [DatePlan]
    var loadingPlanIndices: Set<Int> = []
    var initialSelectedIndex: Int = 0
    var onSave: ((DatePlan) -> Void)?
    var onRegenerate: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @State private var selectedPlanIndex = 0
    @State private var showPartnerShare = false
    @State private var showExport = false
    @State private var savedPlanIds: Set<UUID> = []
    @State private var showAddToCalendar = false
    @State private var calendarDate = Date()
    @State private var calendarMessage: String?
    @State private var showCalendarAlert = false
    @State private var itineraryAppeared = false
    @State private var loadingSpinnerRotation: Double = 0
    @State private var showSavedBanner = false
    @State private var showCloseConfirmation = false

    @State private var inviterFirstChoiceIndex: Int?
    @State private var inviterSecondChoiceIndex: Int?
    @State private var inviterRankSubmitted = false

    private var isPartnerPlanMode: Bool { coordinator.currentPlanPartnerNames != nil }

    var selectedPlan: DatePlan {
        guard selectedPlanIndex < plans.count else { return plans.first ?? DatePlan.sample }
        return plans[selectedPlanIndex]
    }
    
    var isOnRegeneratePage: Bool { selectedPlanIndex >= plans.count }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isPartnerPlanMode, !inviterRankSubmitted {
                        partnerRankPromptView
                            .zIndex(3)
                    }
                    optionChipsSection
                        .zIndex(2)
                    mainContentArea
                }
                .overlay(alignment: .top) {
                    if showSavedBanner {
                        savedBannerView
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(10)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showSavedBanner)
            }
            .interactiveDismissDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCloseConfirmation = true
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
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
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
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
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
                if !isOnRegeneratePage {
                    savePlanBar
                }
            }
            .onAppear {
                selectedPlanIndex = min(initialSelectedIndex, max(0, plans.count - 1))
                let savedIds = Set(coordinator.savedPlans.map(\.id))
                savedPlanIds = Set(plans.filter { savedIds.contains($0.id) }.map(\.id))
            }
            .onDisappear {
                coordinator.moveUnsavedPlansToExperiencesWaiting()
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
        .alert("Close date plans?", isPresented: $showCloseConfirmation) {
            Button("Cancel", role: .cancel) {
                showCloseConfirmation = false
            }
            Button("Close") {
                showCloseConfirmation = false
                coordinator.currentPlanPartnerNames = nil
                coordinator.partnerSessionPlanRowIds = nil
                coordinator.dismissSheet()
            }
        } message: {
            Text("Your options will be moved to Experiences Waiting. You can save a date from there when you're ready.")
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
    
    // MARK: - Main content (swipeable TabView: one page per plan + Regenerate page)
    private var mainContentArea: some View {
        TabView(selection: $selectedPlanIndex) {
            ForEach(0..<plans.count, id: \.self) { index in
                planPageContent(index: index)
                    .tag(index)
            }
            regeneratePageContent
                .tag(plans.count)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedPlanIndex)
        .onChange(of: selectedPlanIndex) { _, _ in
            if selectedPlanIndex < plans.count {
                itineraryAppeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { itineraryAppeared = true }
            }
        }
    }
    
    @ViewBuilder
    private func planPageContent(index: Int) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if loadingPlanIndices.contains(index) {
                    loadingOptionView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    let plan = plans[index]
                    LoveLetterItineraryBackground(cornerRadius: 20) {
                        VStack(spacing: 0) {
                            planHeaderView(plan: plan)
                            planItineraryView(plan: plan)
                            genieSecretTouchView(plan: plan)
                            giftSuggestionsView(plan: plan)
                            packingAndWeatherView(plan: plan)
                            routeSectionView(plan: plan)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 16)
                    .id(index)
                    .transition(.bookFlip)
                    .opacity(itineraryAppeared ? 1 : 0)
                    .offset(y: itineraryAppeared ? 0 : 10)
                    .scaleEffect(itineraryAppeared ? 1 : 0.98)
                    .animation(.easeOut(duration: 0.45), value: itineraryAppeared)
                }
            }
            .padding(.bottom, 120)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: loadingPlanIndices.contains(index))
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            if index == selectedPlanIndex { itineraryAppeared = true }
        }
    }
    
    private var regeneratePageContent: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.luxuryGold, Color.luxuryGoldLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("Want different options?")
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                    .multilineTextAlignment(.center)
                Text("Get three new date plans with the same preferences.")
                    .font(Font.bodySans(16, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            
            if let onRegenerate = onRegenerate {
                Button(action: onRegenerate) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                        Text("Regenerate plans")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Save confirmation banner
    private var savedBannerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4CAF50"))
            Text("Date plan saved")
                .font(Font.bodySans(15, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.luxuryMaroonLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }
    
    @ViewBuilder
    private var partnerRankPromptView: some View {
        if inviterFirstChoiceIndex == nil {
            Text("Tap your favorite")
                .font(Font.bodySans(14, weight: .medium))
                .foregroundColor(Color.luxuryCreamMuted)
                .padding(.top, 12)
                .padding(.bottom, 4)
        } else if inviterSecondChoiceIndex == nil {
            Text("Tap your second choice")
                .font(Font.bodySans(14, weight: .medium))
                .foregroundColor(Color.luxuryCreamMuted)
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
    }

    // MARK: - Option chips (ExperienceCard-style: image, emoji, title — like navigation pane)
    private var optionChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                    let rankBadge: Int? = {
                        if inviterFirstChoiceIndex == index { return 1 }
                        if inviterSecondChoiceIndex == index { return 2 }
                        if inviterRankSubmitted, inviterFirstChoiceIndex != index, inviterSecondChoiceIndex != index { return 3 }
                        return nil
                    }()
                    OptionChipCard(
                        plan: plan,
                        optionLabel: plan.optionLabel ?? "Option \(["A", "B", "C"][min(index, 2)])",
                        isSelected: selectedPlanIndex == index,
                        isSaved: savedPlanIds.contains(plan.id),
                        isVerifying: loadingPlanIndices.contains(index),
                        rankBadge: rankBadge
                    ) {
                        if isPartnerPlanMode, !inviterRankSubmitted {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if inviterFirstChoiceIndex == nil {
                                    inviterFirstChoiceIndex = index
                                } else if inviterSecondChoiceIndex == nil, index != inviterFirstChoiceIndex {
                                    inviterSecondChoiceIndex = index
                                    submitInviterRanks()
                                }
                                selectedPlanIndex = index
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedPlanIndex = index
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 120)
        .background(Color.luxuryMaroon)
        .contentShape(Rectangle())
    }

    private func submitInviterRanks() {
        guard let ids = coordinator.partnerSessionPlanRowIds, ids.count >= 3,
              let first = inviterFirstChoiceIndex, let second = inviterSecondChoiceIndex else { return }
        let third = [0, 1, 2].first(where: { $0 != first && $0 != second }) ?? 0
        Task {
            try? await SupabaseService.shared.updatePartnerSessionPlanRank(planId: ids[first], inviterRank: 1, partnerRank: nil)
            try? await SupabaseService.shared.updatePartnerSessionPlanRank(planId: ids[second], inviterRank: 2, partnerRank: nil)
            try? await SupabaseService.shared.updatePartnerSessionPlanRank(planId: ids[third], inviterRank: 3, partnerRank: nil)
            await MainActor.run { inviterRankSubmitted = true }
        }
    }
    
    // MARK: - Save Plan Bar
    private var savePlanBar: some View {
        VStack(spacing: 12) {
            if let onSave = onSave {
                let isCurrentSaved = savedPlanIds.contains(selectedPlan.id)
                Button {
                    onSave(selectedPlan)
                    withAnimation(.spring(response: 0.3)) {
                        savedPlanIds.insert(selectedPlan.id)
                    }
                    showSavedBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSavedBanner = false
                        }
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
    
    // MARK: - Loading Option (preparing in background — luxe animation)
    private var loadingOptionView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 3)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.luxuryGold, Color.luxuryGoldLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(loadingSpinnerRotation))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: loadingSpinnerRotation)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.luxuryGold, Color.luxuryGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            VStack(spacing: 8) {
                Text("Adding the finishing touches")
                    .font(Font.tangerine(24, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text("Your date is almost ready")
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                loadingSpinnerRotation = 360
            }
        }
    }
    
    // MARK: - Plan Header (parameterized for TabView pages)
    private func planHeaderView(plan: DatePlan) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(plan.title)
                    .font(Font.tangerine(42, weight: .bold))
                    .italic()
                    .foregroundColor(Color(hex: "3D2C2C"))
                    .multilineTextAlignment(.center)
                
                Text(plan.tagline)
                    .font(Font.playfairItalic(17))
                    .foregroundColor(Color(hex: "4A3D2C"))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text(plan.totalDuration)
                        .font(Font.bodySans(14, weight: .medium))
                }
                .foregroundColor(Color(hex: "3D2C2C"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.luxuryGold.opacity(0.15))
                .cornerRadius(20)
                
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 14))
                    Text(plan.estimatedCost)
                        .font(Font.bodySans(14, weight: .medium))
                }
                .foregroundColor(Color(hex: "4A0E0E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.luxuryGold.opacity(0.2))
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Selected Plan Header (on paper: dark text) — used by sheets
    private var selectedPlanHeader: some View {
        planHeaderView(plan: selectedPlan)
    }
    
    // MARK: - Plan Itinerary (parameterized for TabView pages)
    private func planItineraryView(plan: DatePlan) -> some View {
        VStack(spacing: 0) {
            if let start = plan.startingPoint {
                StartingPointCard(address: start.address)
            }
            
            ForEach(Array(plan.stops.enumerated()), id: \.element.id) { index, stop in
                ItineraryStopCard(
                    stop: stop,
                    stopNumber: index + 1,
                    isLast: index == plan.stops.count - 1
                )
            }
        }
    }
    
    // MARK: - Plan Itinerary (selectedPlan)
    private var planItinerary: some View {
        planItineraryView(plan: selectedPlan)
    }
    
    // MARK: - Genie Secret Touch (parameterized)
    private func genieSecretTouchView(plan: DatePlan) -> some View {
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
                        Text(plan.genieSecretTouch.emoji)
                        Text("Genie's Secret Touch")
                            .font(Font.header(17, weight: .bold))
                            .foregroundColor(Color.luxuryGold)
                    }
                    
                    Text(plan.genieSecretTouch.title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryGold.opacity(0.95))
                }
            }
            
            Text(plan.genieSecretTouch.description)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .lineSpacing(5)
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
    
    // MARK: - Genie Secret Touch (selectedPlan)
    private var genieSecretTouch: some View {
        genieSecretTouchView(plan: selectedPlan)
    }
    
    // MARK: - Gift Suggestions (parameterized)
    @ViewBuilder
    private func giftSuggestionsView(plan: DatePlan) -> some View {
        if let gifts = plan.giftSuggestions, !gifts.isEmpty {
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
                        access.require(.gifting) {
                            coordinator.showGiftFinder(datePlan: plan, dateLocation: plan.stops.first?.address)
                        }
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
                        .opacity(access.canAccess(.gifting) ? 1 : 0.5)
                    }
                }
                
                Text("Found \(gifts.count) suggestions for your \(plan.title) date")
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                
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
    
    // MARK: - Gift Suggestions (selectedPlan)
    @ViewBuilder
    private var giftSuggestions: some View {
        giftSuggestionsView(plan: selectedPlan)
    }
    
    // MARK: - Packing and Weather (parameterized)
    private func packingAndWeatherView(plan: DatePlan) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .foregroundColor(Color.luxuryGold)
                    Text("What to Bring")
                        .font(Font.header(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.packingList, id: \.self) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.luxuryGold)
                                .frame(width: 6, height: 6)
                            Text(item)
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryCream)
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
                        .font(Font.header(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text(plan.weatherNote)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Packing and Weather (selectedPlan)
    private var packingAndWeather: some View {
        packingAndWeatherView(plan: selectedPlan)
    }
    
    /// Itinerary = venues only (same as DatePlanResultView). Starting point is not a step.
    private func itineraryStops(for plan: DatePlan) -> [DatePlanStop] {
        plan.stops.filter { $0.venueType != "Starting point" && $0.name != "Your location" }
    }
    
    private var selectedPlanItineraryStops: [DatePlanStop] {
        itineraryStops(for: selectedPlan)
    }
    
    // MARK: - Route Section (parameterized)
    private func routeSectionView(plan: DatePlan) -> some View {
        let stops = itineraryStops(for: plan)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundColor(Color.luxuryGold)
                Text("Your Route")
                    .font(Font.header(16, weight: .bold))
                    .foregroundColor(Color.luxuryCream)
            }
            
            Button {
                coordinator.showRouteMap(stops: stops, startingPoint: plan.startingPoint)
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
                    
                    Text("\(stops.count) stops")
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
            
            RouteSummaryBar(stops: stops)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Route Section (selectedPlan)
    private var routeSection: some View {
        routeSectionView(plan: selectedPlan)
    }
}

// MARK: - Option Chip Card (mini ExperienceCard-style for options strip)
private struct OptionChipCard: View {
    let plan: DatePlan
    let optionLabel: String
    let isSelected: Bool
    let isSaved: Bool
    let isVerifying: Bool
    var rankBadge: Int? = nil
    let onTap: () -> Void
    
    private let cardWidth: CGFloat = 110
    private let imageHeight: CGFloat = 52
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    if isVerifying {
                        Color.luxuryMaroonLight
                            .frame(width: cardWidth, height: imageHeight)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.luxuryGold))
                            .scaleEffect(0.9)
                    } else {
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
                        .frame(width: cardWidth, height: imageHeight)
                        .clipped()
                        LinearGradient(
                            colors: [.clear, Color.luxuryMaroon.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Text(plan.stops.first?.emoji ?? "✨")
                            .font(.system(size: 18))
                            .padding(6)
                    }
                    if isSaved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "4CAF50"))
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                    if let rank = rankBadge {
                        Text("\(rank)")
                            .font(Font.bodySans(12, weight: .bold))
                            .foregroundColor(Color.luxuryMaroon)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.luxuryGold))
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }
                .frame(width: cardWidth, height: imageHeight)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(Font.bodySans(11, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                        .lineLimit(2)
                }
                .padding(8)
            }
            .frame(width: cardWidth)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.luxuryGold : Color.luxuryGold.opacity(0.25), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plan Option Card
struct PlanOptionCard: View {
    let plan: DatePlan
    let optionLabel: String
    let isSelected: Bool
    var isVerifying: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
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
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(10)
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
                    .font(Font.bodySans(14, weight: .semibold))
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
                
                if isVerifying {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.luxuryGold))
                            .scaleEffect(0.7)
                        Text("Just a moment…")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "4CAF50"))
                        Text("\(plan.stops.filter { $0.validated == true }.count)/\(plan.stops.count) venues verified")
                            .font(Font.bodySans(11, weight: .medium))
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
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
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.luxuryGold.opacity(0.25) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
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
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🏠")
                    Text("Starting Point")
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Text(address)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .lineLimit(2)
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
                    distance: stop.travelDistanceFromPrevious,
                    travelMode: stop.travelMode
                )
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Color.luxuryGold)
                            .frame(width: 28, height: 28)
                        
                        Text("\(stopNumber)")
                            .font(Font.bodySans(14, weight: .bold))
                            .foregroundColor(Color.luxuryMaroon)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            HStack(spacing: 6) {
                                Text(stop.emoji)
                                Text(stop.name)
                                    .font(Font.header(17, weight: .bold))
                                    .foregroundColor(Color.luxuryCream)
                                
                                if stop.validated == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "4CAF50"))
                                }
                            }
                            
                            Spacer()
                            
                            Text(stop.timeSlot)
                                .font(Font.bodySans(14, weight: .semibold))
                                .foregroundColor(Color.luxuryGold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.luxuryGold.opacity(0.15))
                                .cornerRadius(16)
                        }
                        
                        Text(stop.venueType)
                            .font(Font.bodySans(14, weight: .medium))
                            .foregroundColor(Color.luxuryCreamMuted)
                        
                        if let address = stop.address {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 13))
                                Text(address)
                                    .font(Font.bodySans(13, weight: .regular))
                                    .lineLimit(2)
                            }
                            .foregroundColor(Color.luxuryCreamMuted)
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
                                if let url = MapURLHelper.urlForStop(stop) {
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
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(hours.indices, id: \.self) { i in
                                            Text(hours[i])
                                                .font(Font.bodySans(11, weight: .regular))
                                                .foregroundColor(Color.luxuryCreamMuted)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 11))
                                        Text("Hours (from Google)")
                                            .font(Font.bodySans(11, weight: .medium))
                                    }
                                    .foregroundColor(Color.luxuryGold)
                                }
                                .disclosureGroupStyle(.automatic)
                            }
                        }
                        
                        Text(stop.description)
                            .font(Font.bodySans(14, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineSpacing(4)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("Why this fits:")
                                    .font(Font.bodySans(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                                Text(stop.whyItFits)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                            
                            HStack(alignment: .top, spacing: 6) {
                                Text("😍")
                                Text("Romantic tip:")
                                    .font(Font.bodySans(12, weight: .semibold))
                                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                                Text(stop.romanticTip)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryMuted)
                            }
                        }
                        .padding(10)
                        .background(Color.luxuryMaroon.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.top, 6)
                        
                        HStack(spacing: 20) {
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
                        .padding(.top, 6)
                    }
                    .padding(.leading, 10)
                }
            }
            .padding(16)
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
    /// Transportation mode for this leg (e.g. "driving", "walking"). When nil, inferred from time text (e.g. "Drive 15 mins").
    var travelMode: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.luxuryGold.opacity(0.3))
                .frame(width: 2, height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: TravelModeIcon.sfSymbol(for: travelMode, inferFromTimeText: time))
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
