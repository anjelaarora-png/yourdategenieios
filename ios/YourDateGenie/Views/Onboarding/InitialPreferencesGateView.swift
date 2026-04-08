import SwiftUI

/// First-time preferences after login: optional hero (post–email confirm), then full-screen preferences questionnaire.
struct InitialPreferencesGateView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var didConfigureQuestionnaire = false

    var body: some View {
        Group {
            if coordinator.presentHeroBeforeInitialPreferences {
                HeroView(onBeginJourney: {
                    coordinator.transitionFromHeroToInitialPreferences()
                })
                .environmentObject(coordinator)
                .environmentObject(AccessManager.shared)
            } else {
                QuestionnaireView(onComplete: { _ in })
                    .environmentObject(coordinator)
                    .environmentObject(AccessManager.shared)
                    .onAppear {
                        if !didConfigureQuestionnaire {
                            didConfigureQuestionnaire = true
                            if !coordinator.isPresentingInitialPreferencesFlow {
                                coordinator.startInitialPreferencesQuestionnaireAtRoot()
                            }
                        }
                    }
            }
        }
    }
}
