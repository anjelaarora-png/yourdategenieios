import SwiftUI

// MARK: - Luxury Main App View (Tab-based)
struct LuxuryMainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var planGenerator = DatePlanGeneratorService.shared
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            LuxuryHomeTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.home.tabBarTitle, systemImage: NavigationCoordinator.Tab.home.icon)
                }
                .tag(NavigationCoordinator.Tab.home)
            
            LoveNoteGeneratorView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.loveNote.tabBarTitle, systemImage: NavigationCoordinator.Tab.loveNote.icon)
                }
                .tag(NavigationCoordinator.Tab.loveNote)
            
            GiftsTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.gifts.tabBarTitle, systemImage: NavigationCoordinator.Tab.gifts.icon)
                }
                .tag(NavigationCoordinator.Tab.gifts)
            
            MemoriesTabView()
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
            let font = UIFont.systemFont(ofSize: 9, weight: .medium)
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
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: NavigationCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .questionnaire:
            QuestionnaireView { data in
                coordinator.completeQuestionnaire(with: data)
            }
            .environmentObject(coordinator)
        case .datePlanOptions:
            DatePlanOptionsView(
                plans: coordinator.generatedPlans,
                loadingPlanIndices: planGenerator.loadingPlanIndices,
                initialSelectedIndex: coordinator.generatedPlansSelectedIndex,
                onSave: { plan in coordinator.savePlan(plan) },
                onRegenerate: { coordinator.requestRegenerateFromOptions() }
            )
            .environmentObject(coordinator)
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
            }
        case .giftFinder(let datePlan, let dateLocation):
            GiftFinderView(datePlan: datePlan, dateLocation: dateLocation)
        case .playlist(let title):
            PlaylistWidgetView(planTitle: title)
        case .reservation(let name, let type, let address, let phone, let bookingUrl, let websiteUrl, let openingHours):
            ReservationWidgetView(
                venueName: name,
                venueType: type,
                address: address,
                phoneNumber: phone,
                bookingUrl: bookingUrl,
                websiteUrl: websiteUrl,
                openingHours: openingHours
            )
        case .partnerShare(let plan):
            PartnerShareView(plan: plan)
        case .routeMap(let stops, let startingPoint, let showRouteLine):
            NavigationStack {
                RouteMapView(stops: stops, startingPoint: startingPoint, showRouteLine: showRouteLine)
                    .navigationTitle(showRouteLine ? "Your Route" : "Journey Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                coordinator.dismissSheet()
                            } label: {
                                HStack(spacing: 8) {
                                    AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=40&h=40&fit=crop")) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Circle().fill(Color.luxuryGold.opacity(0.3))
                                        }
                                    }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    
                                    Text("Done")
                                }
                                .foregroundColor(Color.luxuryGold)
                            }
                        }
                    }
            }
        case .memoryGallery:
            MemoryGalleryView(showCloseButton: true)
        case .conversationStarters:
            ConversationStartersView()
                .environmentObject(coordinator)
        case .pastMagic:
            PastMagicView()
                .environmentObject(coordinator)
        case .savedPlansList:
            SavedPlansListSheetView()
                .environmentObject(coordinator)
        case .settings:
            SettingsSheetView()
                .environmentObject(coordinator)
        case .playbook:
            PlaybookView()
                .environmentObject(coordinator)
        case .explore:
            NavigationStack {
                LuxuryExploreTabView()
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
            }
        case .authRequired:
            AuthenticationView(onDismiss: { coordinator.dismissAuthRequiredSheet() })
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
