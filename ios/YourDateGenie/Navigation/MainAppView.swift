import SwiftUI

// MARK: - Luxury Main App View (Tab-based)
struct LuxuryMainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @ObservedObject private var planGenerator = DatePlanGeneratorService.shared
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            LuxuryHomeTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.home.tabBarTitle, systemImage: NavigationCoordinator.Tab.home.icon)
                }
                .tag(NavigationCoordinator.Tab.home)
            
            Group {
                if access.canAccess(.loveNotes) {
                    LoveNoteGeneratorView()
                } else {
                    LockedPremiumTabPlaceholder(
                        feature: .loveNotes,
                        title: "Love Notes",
                        subtitle: "Write heartfelt notes and AI-enhanced messages for your partner."
                    )
                }
            }
            .tabItem {
                Label(NavigationCoordinator.Tab.loveNote.tabBarTitle, systemImage: NavigationCoordinator.Tab.loveNote.icon)
            }
            .tag(NavigationCoordinator.Tab.loveNote)
            
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
            .tabItem {
                Label(NavigationCoordinator.Tab.gifts.tabBarTitle, systemImage: NavigationCoordinator.Tab.gifts.icon)
            }
            .tag(NavigationCoordinator.Tab.gifts)
            
            Group {
                if access.canAccess(.memory) {
                    MemoriesTabView()
                } else {
                    LockedPremiumTabPlaceholder(
                        feature: .memory,
                        title: "Memories",
                        subtitle: "Save photos and moments from your dates in one place."
                    )
                }
            }
            .tabItem {
                Label(NavigationCoordinator.Tab.memories.tabBarTitle, systemImage: NavigationCoordinator.Tab.memories.icon)
            }
            .tag(NavigationCoordinator.Tab.memories)
            
            LuxuryProfileTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.profile.tabBarTitle, systemImage: NavigationCoordinator.Tab.profile.icon)
                }
                .tag(NavigationCoordinator.Tab.profile)
        }
        .tint(Color.luxuryGold)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.luxuryMaroon)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = .center
            let font = UIFont.systemFont(ofSize: 10, weight: .medium)
            let normalAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(Color.luxuryMuted),
                .paragraphStyle: paragraphStyle,
                .font: font
            ]
            let selectedAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(Color.luxuryGold),
                .paragraphStyle: paragraphStyle,
                .font: font
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.luxuryMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.luxuryGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
            appearance.inlineLayoutAppearance.normal.titleTextAttributes = normalAttrs
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedAttrs
            appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttrs
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttrs
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
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
        case .giftFinder(let datePlan, let dateLocation):
            GiftFinderView(datePlan: datePlan, dateLocation: dateLocation)
        case .playlist(let title, let planId):
            PlaylistWidgetView(planTitle: title, planId: planId)
        case .reservation(let name, _, _, let phone, _, _, _):
            // Redirect: set the platform picker payload directly and dismiss so the
            // dedicated reservationPlatformPickerPayload sheet handles presentation
            // without a flicker-prone relay.
            EmptyView()
                .onAppear {
                    coordinator.reservationPlatformPickerPayload = ReservationPlatformPickerPayload(venueName: name, phoneNumber: phone)
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
