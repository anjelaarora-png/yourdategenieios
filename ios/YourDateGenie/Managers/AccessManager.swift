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

/// Central subscription gate. Mirrors `PurchaseManager.shared.isSubscribed` and coordinates a single app-wide paywall + deferred navigation.
@MainActor
final class AccessManager: ObservableObject {
    static let shared = AccessManager()

    @Published var isSubscribed: Bool = false
    @Published var isPaywallPresented: Bool = false

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
