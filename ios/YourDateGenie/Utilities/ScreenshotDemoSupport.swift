#if DEBUG
import Foundation

/// Launch with `-AppStoreScreenshots -scene=<name>` to land on a fixed UI for simulator captures.
enum AppScreenshotScene: String {
    case home
    case homePlan
    case questionnaire
    case planOptions
    case planOptionsB
    case planDetail
    case partnerShare
    case dates
    case convo
    case generating
    case memories
    case playlist
    case giftFinder
    case planTogether
    case partnerRanking
    case partnerReveal
    case lockedIn
    // Pre-login root screens (handled by `rootOverrides`).
    case splash
    case ageGate
    case onboarding
    case signIn
    case hero
    case tutorial
    case lowKey
    case sparks
    case rose
    case settings
}

enum ScreenshotDemo {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-AppStoreScreenshots")
    }

    static var scene: AppScreenshotScene {
        let args = ProcessInfo.processInfo.arguments
        if let raw = args.first(where: { $0.hasPrefix("-scene=") })?
            .replacingOccurrences(of: "-scene=", with: "") {
            return AppScreenshotScene(rawValue: raw) ?? .home
        }
        return .home
    }

    static let sampleGiftSuggestions: [GiftSuggestion] = [
        GiftSuggestion(
            name: "Artisan Pasta Date Night Kit",
            description: "Fresh pasta, truffle oil, and a recipe card for recreating your Italian evening at home.",
            priceRange: "$45–$65",
            whereToBuy: "Eataly · Williams Sonoma",
            whyItFits: "Ties back to your pasta-and-wine date — thoughtful without being generic.",
            emoji: "🍝",
            storeSearchQuery: "artisan pasta gift kit"
        ),
        GiftSuggestion(
            name: "Wine Tasting Journal",
            description: "Leather-bound journal with guided tasting pages for the wines you discover together.",
            priceRange: "$35–$50",
            whereToBuy: "Uncommon Goods · Etsy",
            whyItFits: "Perfect for couples who love trying new bottles on date night.",
            emoji: "🍷",
            storeSearchQuery: "wine tasting journal gift"
        ),
        GiftSuggestion(
            name: "Hand-Poured Candle Duo",
            description: "Two complementary scents — one warm, one fresh — for cozy nights in.",
            priceRange: "$40–$55",
            whereToBuy: "Anthropologie · Local makers",
            whyItFits: "Sets the mood for the intimate vibe of your plan.",
            emoji: "🕯️",
            storeSearchQuery: "luxury candle gift set"
        ),
    ]

    @MainActor
    static func apply(to coordinator: NavigationCoordinator) {
        guard isActive else { return }

        UserDefaults.standard.set(true, forKey: "hasSeenHomeTutorial")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(true, forKey: "hasSkippedLogin")
        UserDefaults.standard.set(true, forKey: "hasCompletedPreferences")

        coordinator.hasCompletedOnboarding = true
        coordinator.hasSkippedLogin = true
        coordinator.hasCompletedPreferences = true
        coordinator.hasDeferredInitialPreferences = true
        coordinator.isLoggedIn = false
        coordinator.activeSheet = nil
        coordinator.currentTab = .home
        coordinator.isRegeneratingFromOptions = false
        coordinator.showMemoryGallery = false

        let access = AccessManager.shared
        access.isSubscribed = true
        access.isPaywallPresented = false

        let sample = showcasePlan()
        let generator = DatePlanGeneratorService.shared
        generator.isGenerating = false
        generator.loadingPlanIndices = []

        switch scene {
        case .home:
            coordinator.savedPlans = []
            coordinator.generatedPlans = []
            coordinator.experiencesWaiting = []
        case .homePlan:
            coordinator.savedPlans = [sample]
            coordinator.generatedPlans = []
            coordinator.experiencesWaiting = []
        case .questionnaire:
            coordinator.activeSheet = .questionnaire
        case .planOptions:
            coordinator.generatedPlans = [.sample, .sampleOptionB, .sampleOptionC]
            coordinator.generatedPlansSelectedIndex = 0
            coordinator.activeSheet = .datePlanOptions
        case .planOptionsB:
            coordinator.generatedPlans = [.sample, .sampleOptionB, .sampleOptionC]
            coordinator.generatedPlansSelectedIndex = 1
            coordinator.activeSheet = .datePlanOptions
        case .planDetail:
            coordinator.currentDatePlan = sample
            coordinator.activeSheet = .datePlanResult
        case .partnerShare:
            coordinator.activeSheet = .partnerShare(plan: sample)
        case .dates:
            coordinator.savedPlans = [sample, .sampleOptionB]
            coordinator.currentTab = .dates
        case .convo:
            coordinator.currentTab = .convo
        case .generating:
            coordinator.isRegeneratingFromOptions = true
            generator.isGenerating = true
        case .memories:
            seedShowcaseMemories()
            coordinator.activeSheet = .memoryGallery
        case .playlist:
            coordinator.activeSheet = .playlist(planTitle: sample.title, planId: sample.id)
        case .giftFinder:
            coordinator.activeSheet = .giftFinder(datePlan: sample, dateLocation: "New York, NY")
        case .planTogether:
            coordinator.activeSheet = .partnerPlanning
        case .partnerRanking:
            coordinator.generatedPlans = [.sample, .sampleOptionB, .sampleOptionC]
            coordinator.activeSheet = .partnerRanking
        case .partnerReveal:
            coordinator.generatedPlans = [.sample, .sampleOptionB, .sampleOptionC]
            coordinator.activeSheet = .finalDateReveal
        case .lockedIn:
            coordinator.activeSheet = .lockedIn(plan: sample, calendarSynced: true)
        case .tutorial:
            coordinator.savedPlans = []
            coordinator.generatedPlans = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                coordinator.homeTutorialReplayToken &+= 1
            }
        case .lowKey:
            coordinator.activeSheet = .lowKey
        case .sparks:
            coordinator.activeSheet = .conversationStarters
        case .rose:
            coordinator.activeSheet = .roseRewards
        case .settings:
            coordinator.activeSheet = .settings
        case .splash, .ageGate, .onboarding, .signIn, .hero:
            break
        }
    }

    /// Root-gate flags for pre-login scenes. Returns (showSplash, ageConfirmed).
    @MainActor
    static func rootOverrides(for coordinator: NavigationCoordinator) -> (showSplash: Bool, ageConfirmed: Bool) {
        switch scene {
        case .splash:
            return (true, true)
        case .ageGate:
            return (false, false)
        case .onboarding:
            coordinator.hasCompletedOnboarding = false
        case .signIn:
            coordinator.hasSkippedLogin = false
        case .hero:
            // Launch-time profile sync re-sets these, so apply after it settles.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UserDefaults.standard.set(false, forKey: "hasCompletedPreferences")
                UserProfileManager.shared.hasCompletedPreferences = false
                coordinator.hasCompletedPreferences = false
                coordinator.hasDeferredInitialPreferences = false
                coordinator.presentHeroBeforeInitialPreferences = true
            }
        default:
            break
        }
        return (false, true)
    }

    @MainActor
    static func seedShowcaseMemories() {
        let manager = MemoryManager.shared
        manager.memories = [
            DateMemory(
                title: "Italian Night",
                date: demoDate(month: 5, day: 18),
                location: "West Village, NYC",
                photoData: bundleJPEG(named: "memory_dinner"),
                caption: "The pasta was perfect. So was the company."
            ),
            DateMemory(
                title: "Cocktails & Conversation",
                date: demoDate(month: 4, day: 12),
                location: "SoHo, NYC",
                photoData: bundleJPEG(named: "memory_cocktail"),
                caption: "Best speakeasy find yet."
            ),
            DateMemory(
                title: "Sunday Slow Morning",
                date: demoDate(month: 3, day: 8),
                location: "Brooklyn, NYC",
                photoData: bundleJPEG(named: "memory_window"),
                caption: "Coffee, sunlight, nowhere to be."
            ),
        ]
    }

    private static func showcasePlan() -> DatePlan {
        var plan = DatePlan.sample
        plan.scheduledDate = Date()
        return plan
    }

    private static func demoDate(month: Int, day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.year = 2026
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func bundleJPEG(named: String) -> Data? {
        let url = Bundle.main.url(forResource: named, withExtension: "jpg", subdirectory: "ScreenshotDemo")
            ?? Bundle.main.url(forResource: named, withExtension: "jpg")
        guard let url else { return nil }
        return try? Data(contentsOf: url)
    }
}
#endif
