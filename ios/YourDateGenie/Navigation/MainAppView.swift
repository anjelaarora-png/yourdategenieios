import SwiftUI

// MARK: - Luxury Main App View (Tab-based)
struct LuxuryMainAppView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            LuxuryHomeTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.home.rawValue, systemImage: NavigationCoordinator.Tab.home.icon)
                }
                .tag(NavigationCoordinator.Tab.home)
            
            LuxuryExploreTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.explore.rawValue, systemImage: NavigationCoordinator.Tab.explore.icon)
                }
                .tag(NavigationCoordinator.Tab.explore)
            
            MemoriesTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.memories.rawValue, systemImage: NavigationCoordinator.Tab.memories.icon)
                }
                .tag(NavigationCoordinator.Tab.memories)
            
            LuxuryProfileTabView()
                .tabItem {
                    Label(NavigationCoordinator.Tab.profile.rawValue, systemImage: NavigationCoordinator.Tab.profile.icon)
                }
                .tag(NavigationCoordinator.Tab.profile)
        }
        .tint(Color.luxuryGold)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.luxuryMaroon)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.luxuryMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.luxuryMuted)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.luxuryGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.luxuryGold)]
            
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
                initialSelectedIndex: coordinator.generatedPlansSelectedIndex,
                onSave: { plan in coordinator.savePlan(plan) },
                onRegenerate: { }
            )
            .environmentObject(coordinator)
        case .datePlanResult:
            if let plan = coordinator.currentDatePlan {
                DatePlanResultView(
                    plan: plan,
                    onSave: { coordinator.savePlan(plan) },
                    onRegenerate: { }
                )
                .environmentObject(coordinator)
            }
        case .giftFinder(let datePlan, let dateLocation):
            GiftFinderView(datePlan: datePlan, dateLocation: dateLocation)
        case .playlist(let title):
            PlaylistWidgetView(planTitle: title)
        case .reservation(let name, let type, let address, let phone):
            ReservationWidgetView(
                venueName: name,
                venueType: type,
                address: address,
                phoneNumber: phone
            )
        case .partnerShare(let plan):
            PartnerShareView(plan: plan)
        case .routeMap(let stops):
            NavigationStack {
                RouteMapView(stops: stops)
                    .navigationTitle("Your Route")
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
        }
    }
}

// MARK: - Memories Tab View
struct MemoriesTabView: View {
    var body: some View {
        MemoryGalleryView()
    }
}
