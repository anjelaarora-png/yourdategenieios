import Combine
import Foundation
import SwiftUI

enum AppFeature {
    case datePlan
    case gifting
    case playlist
    case loveNotes
    case conversation
    case memory
    case datingTips
    case nearby
}

/// Central subscription gate. Mirrors `PurchaseManager.shared.isSubscribed` and coordinates a
/// single app-wide paywall + deferred navigation.
///
/// Free tier: users may generate up to `freePlanLimit` date plans before subscribing.
/// Viewing previously generated plans is always allowed so users are never locked out of content
/// they already created.
@MainActor
final class AccessManager: ObservableObject {
    static let shared = AccessManager()

    // MARK: - Free tier constants

    private static let freePlansUsedKey = "com.yourdategenie.freePlansUsed"
    /// Number of free date-plan generations allowed before the paywall appears.
    static let freePlanLimit = 2

    // MARK: - Published state

    @Published var isSubscribed: Bool = false
    @Published var isPaywallPresented: Bool = false

    // MARK: - Free usage tracking

    /// How many free date plans this device has generated (ignored once subscribed).
    var freePlansUsed: Int {
        UserDefaults.standard.integer(forKey: Self.freePlansUsedKey)
    }

    /// Remaining free generations before the paywall. Always 0 when subscribed.
    var freePlansRemaining: Int {
        guard !isSubscribed else { return 0 }
        return max(0, Self.freePlanLimit - freePlansUsed)
    }

    /// `true` when the user can start a new date-plan generation (either subscribed or still
    /// within the free tier allowance).
    func canGenerateDatePlan() -> Bool {
        return isSubscribed || freePlansUsed < Self.freePlanLimit
    }

    /// Call this once after each successful date-plan generation to consume one free credit.
    /// No-ops when already subscribed — subscribers have unlimited generations.
    func recordDatePlanGenerated() {
        guard !isSubscribed else { return }
        UserDefaults.standard.set(freePlansUsed + 1, forKey: Self.freePlansUsedKey)
    }

    // MARK: - Private

    private var pendingUnlock: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        isSubscribed = PurchaseManager.shared.isSubscribed
        PurchaseManager.shared.$isSubscribed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isSubscribed = value
            }
            .store(in: &cancellables)
    }

    // MARK: - Feature access

    func canAccess(_ feature: AppFeature) -> Bool {
        switch feature {
        case .nearby:
            return true
        default:
            return isSubscribed
        }
    }

    /// Runs `perform` immediately if allowed; otherwise stores it and presents the paywall.
    func require(_ feature: AppFeature, perform: @escaping () -> Void) {
        if canAccess(feature) {
            perform()
        } else {
            pendingUnlock = perform
            isPaywallPresented = true
        }
    }

    func cancelPaywallIntent() {
        pendingUnlock = nil
        isPaywallPresented = false
    }

    /// When the paywall sheet closes without subscribing (e.g. "Not now", swipe), drop any deferred navigation.
    func paywallSheetDismissed() {
        if !isSubscribed {
            pendingUnlock = nil
        }
    }

    /// Call after a successful purchase or restore from `PaywallView` (or when subscription is already active).
    func handleSubscriptionResolved() {
        isPaywallPresented = false
        let action = pendingUnlock
        pendingUnlock = nil
        action?()
    }
}
