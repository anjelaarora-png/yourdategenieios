import SwiftUI

// MARK: - Luxury Main App View (Tab-based)
struct LuxuryMainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @ObservedObject private var planGenerator = DatePlanGeneratorService.shared
    @StateObject private var network = NetworkMonitor.shared
    @State private var undoDeletedPlan: DatePlan?
    @State private var undoTimer: Timer?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary
                .ignoresSafeArea()

            Group {
                switch coordinator.currentTab {
                case .home:
                    LuxuryHomeTabView()
                case .dates:
                    DatesTabView()
                case .convo:
                    ConvoTabView()
                case .you:
                    LuxuryProfileTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tint(Color.luxuryGold)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LuxuryTabBar(selectedTab: $coordinator.currentTab) {
                coordinator.startDatePlanning()
            }
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .sheet(isPresented: $coordinator.showMemoryGallery) {
            MemoryGalleryView(showCloseButton: true)
        }
        .sheet(isPresented: $coordinator.isShowingMemoryCapture) {
            AddMemorySheet()
        }
        .overlay {
            if coordinator.isRegeneratingFromOptions && planGenerator.isGenerating {
                MagicalLoadingView(generator: planGenerator)
                    .ignoresSafeArea()
            }
        }
        .sheet(item: $coordinator.reservationPlatformPickerPayload) { payload in
            ReservationPlatformPickerSheet(payload: payload) {
                coordinator.reservationPlatformPickerPayload = nil
            }
        }
        .onChange(of: coordinator.showMemoryGallery) { _, show in
            if show && !access.canAccess(.memory) {
                coordinator.showMemoryGallery = false
                access.require(.memory) {
                    coordinator.showMemoryGallery = true
                }
            }
        }
        .onChange(of: coordinator.isShowingMemoryCapture) { _, show in
            if show && !access.canAccess(.memory) {
                coordinator.isShowingMemoryCapture = false
                access.require(.memory) {
                    coordinator.isShowingMemoryCapture = true
                }
            }
        }
        // Offline banner at the top
        .safeAreaInset(edge: .top, spacing: 0) {
            if !network.isConnected {
                OfflineBannerView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.35), value: network.isConnected)
            }
        }
        // Undo snackbar at the bottom
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let plan = undoDeletedPlan {
                UndoSnackbarView(message: "Plan deleted") {
                    // Undo: restore the plan
                    coordinator.savedPlans.insert(plan, at: 0)
                    undoDeletedPlan = nil
                    undoTimer?.invalidate()
                } onDismiss: {
                    undoDeletedPlan = nil
                }
                .animation(.spring(response: 0.4), value: undoDeletedPlan != nil)
            }
        }
    }

    /// Call this from any delete-plan action to trigger the undo snackbar.
    func planWasDeleted(_ plan: DatePlan) {
        undoDeletedPlan = plan
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation { undoDeletedPlan = nil }
            }
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: NavigationCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .questionnaire:
            QuestionnaireView { data in
                coordinator.completeQuestionnaire(with: data)
            }
            .environmentObject(coordinator)
            .environmentObject(access)
        case .datePlanOptions:
            DatePlanOptionsView(
                plans: coordinator.generatedPlans,
                loadingPlanIndices: planGenerator.loadingPlanIndices,
                initialSelectedIndex: coordinator.generatedPlansSelectedIndex,
                onSave: { plan in coordinator.savePlan(plan) },
                onRegenerate: { coordinator.requestRegenerateFromOptions() }
            )
            .environmentObject(coordinator)
            .environmentObject(access)
        case .datePlanResult:
            if let plan = coordinator.currentDatePlan {
                DatePlanResultView(
                    plan: plan,
                    onSave: { coordinator.savePlan(plan) },
                    onRegenerate: { },
                    onDelete: {
                        coordinator.deletePlan(plan)
                        coordinator.dismissSheet()
                    }
                )
                .environmentObject(coordinator)
                .environmentObject(access)
            }
        case .gifts:
            NavigationStack {
                Group {
                    if access.canAccess(.gifting) {
                        GiftsTabView()
                    } else {
                        LockedPremiumTabPlaceholder(
                            feature: .gifting,
                            title: "Gifts",
                            subtitle: "Discover thoughtful gift ideas tailored to your dates."
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { coordinator.dismissSheet() }
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .environmentObject(coordinator)
            .environmentObject(access)
        case .giftFinder(let datePlan, let dateLocation):
            GiftFinderView(datePlan: datePlan, dateLocation: dateLocation)
        case .playlist(let title, let planId):
            PlaylistWidgetView(planTitle: title, planId: planId)
        case .reservation(let name, _, let addr, let phone, let bookingUrl, _, _):
            // Redirect: set the platform picker payload directly and dismiss so the
            // dedicated reservationPlatformPickerPayload sheet handles presentation
            // without a flicker-prone relay.
            EmptyView()
                .onAppear {
                    coordinator.reservationPlatformPickerPayload = ReservationPlatformPickerPayload(
                        venueName: name,
                        phoneNumber: phone,
                        address: addr,
                        bookingUrl: bookingUrl
                    )
                    coordinator.dismissSheet()
                }
        case .partnerShare(let plan):
            PartnerShareView(plan: plan)
        case .routeMap(let stops, let startingPoint, let showRouteLine):
            NavigationStack {
                RouteMapView(stops: stops, startingPoint: startingPoint, showRouteLine: showRouteLine)
                    .navigationTitle(showRouteLine ? "Your Route" : "Journey Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                            .foregroundColor(Color.luxuryGold)
                        }
                    }
            }
        case .memoryGallery:
            MemoryGalleryView(showCloseButton: true)
        case .conversationStarters:
            ConversationStartersView()
                .environmentObject(coordinator)
                .environmentObject(access)
        case .pastMagic:
            PastMagicView()
                .environmentObject(coordinator)
                .environmentObject(access)
        case .savedPlansList:
            SavedPlansListSheetView()
                .environmentObject(coordinator)
                .environmentObject(access)
        case .settings:
            SettingsSheetView()
                .environmentObject(coordinator)
                .environmentObject(access)
        case .playbook:
            PlaybookView()
                .environmentObject(coordinator)
                .environmentObject(access)
        case .roseRewards:
            RoseRewardsView(
                partnerName: nil,
                onPlanDate: { coordinator.startDatePlanning(mode: .fresh) },
                onReviveTonight: { _ in coordinator.startDatePlanning(mode: .fresh) }
            )
        case .lowKey:
            LowKeyDateView(
                onChoose: { _ in coordinator.activeSheet = nil },
                onClose: { coordinator.activeSheet = nil }
            )
        case .explore:
            NavigationStack {
                LuxuryExploreTabView()
                    .environmentObject(coordinator)
                    .navigationTitle("Explore")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                            .foregroundColor(Color.luxuryGold)
                        }
                    }
            }
        case .partnerPlanning:
            NavigationStack {
                PartnerPlanningSheetView()
                    .environmentObject(coordinator)
                    .environmentObject(access)
            }
        case .partnerJoin(let sessionId, let inviterName):
            PartnerJoinView(sessionId: sessionId, inviterName: inviterName)
                .environmentObject(coordinator)
                .environmentObject(access)
        case .planGenerating(let sessionId, let role):
            PlanGeneratingView(sessionId: sessionId, role: role)
                .environmentObject(coordinator)
                .environmentObject(access)
        case .partnerRanking:
            NavigationStack {
                PartnerRankingView()
                    .environmentObject(coordinator)
                    .environmentObject(access)
            }
        case .finalDateReveal:
            NavigationStack {
                FinalDateRevealView()
                    .environmentObject(coordinator)
                    .environmentObject(access)
            }
        case .lockedIn(let plan, let calendarSynced):
            NavigationStack {
                LockedInView(plan: plan, calendarSynced: calendarSynced)
                    .environmentObject(coordinator)
                    .environmentObject(access)
            }
        case .partnerReceivesPlan(let plan, let inviterName):
            NavigationStack {
                PartnerReceivesPlanView(plan: plan, inviterName: inviterName)
                    .environmentObject(coordinator)
                    .environmentObject(access)
            }
        case .authRequired:
            AuthenticationView(onDismiss: { coordinator.dismissAuthRequiredSheet() }, allowSkipToExplore: false)
                .environmentObject(coordinator)
        }
    }
}

// MARK: - Memories Tab View
struct MemoriesTabView: View {
    var body: some View {
        MemoryGalleryView()
    }
}
