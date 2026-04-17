import Combine
import Foundation
import StoreKit

// MARK: - Purchase errors

enum PurchaseManagerError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "We couldn't load subscription options. Please check your connection and try again in a moment."
        case .purchaseFailed(let message):
            return message
        }
    }
}

/// StoreKit 2 purchase coordinator: loads the premium monthly product, purchases, verifies JWS-backed transactions,
/// keeps `isSubscribed` in sync with **verified** `Transaction.currentEntitlements`, and mirrors state to `UserDefaults` for fast cold start (always refreshed from the App Store).
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    /// Must match App Store Connect and `Products.storekit` for local testing.
    static let premiumMonthlyProductID = "com.yourdategenie.premium.monthly"
    static let premiumAnnualProductID = "com.yourdategenie.premium.annual"

    private static let subscribedUserDefaultsKey = "com.yourdategenie.purchase.isSubscribed"

    @Published private(set) var isSubscribed: Bool
    @Published private(set) var premiumMonthlyProduct: Product?
    @Published private(set) var premiumAnnualProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRestoring = false
    @Published private(set) var isPurchasing = false
    /// User-facing message for recoverable failures (empty when none).
    @Published var lastErrorMessage: String?

    private var transactionListener: Task<Void, Never>?
    private var launchCheckTask: Task<Void, Never>?

    private init() {
        isSubscribed = UserDefaults.standard.bool(forKey: Self.subscribedUserDefaultsKey)
        transactionListener = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    /// Runs once on cold start (from `YourDateGenieApp`). Fast local entitlement read first, then `AppStore.sync()` off the main thread, then refresh again. Persists `isSubscribed` to `UserDefaults`.
    func checkSubscriptionOnAppLaunch() {
        launchCheckTask?.cancel()
        launchCheckTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshEntitlements()
            await Task.detached(priority: .utility) {
                try? await AppStore.sync()
            }.value
            await self.refreshEntitlements()
        }
    }

    // MARK: - Products

    func loadProducts() async {
        isLoadingProducts = true
        lastErrorMessage = nil
        defer { isLoadingProducts = false }

        do {
            let productIDs = [Self.premiumMonthlyProductID, Self.premiumAnnualProductID]
            let products = try await Product.products(for: productIDs)
            premiumMonthlyProduct = products.first(where: { $0.id == Self.premiumMonthlyProductID })
            premiumAnnualProduct = products.first(where: { $0.id == Self.premiumAnnualProductID })
            if premiumMonthlyProduct == nil && premiumAnnualProduct == nil {
                lastErrorMessage = PurchaseManagerError.productNotFound.localizedDescription
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchasePremiumMonthly() async throws {
        if premiumMonthlyProduct == nil {
            await loadProducts()
        }
        guard let product = premiumMonthlyProduct else {
            throw PurchaseManagerError.productNotFound
        }
        try await purchase(product)
    }

    func purchasePremiumAnnual() async throws {
        if premiumAnnualProduct == nil {
            await loadProducts()
        }
        guard let product = premiumAnnualProduct else {
            throw PurchaseManagerError.productNotFound
        }
        try await purchase(product)
    }

    func purchase(_ product: Product) async throws {
        lastErrorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.verify(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        lastErrorMessage = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Entitlements & persistence

    /// Alias for `refreshEntitlements()` — matches common naming in subscription flows.
    func checkSubscriptionStatus() async {
        await refreshEntitlements()
    }

    /// Re-reads verified active entitlements from StoreKit and updates `isSubscribed` and UserDefaults.
    func refreshEntitlements() async {
        let subscribed = await computeIsSubscribedFromStore()
        let wasSubscribed = isSubscribed
        if isSubscribed != subscribed {
            isSubscribed = subscribed
        }
        persistSubscribed(subscribed)
        if subscribed && !wasSubscribed {
            NotificationManager.shared.addNotification(AppNotification(
                type: .subscriptionActivated,
                title: "Welcome to Premium! 👑",
                message: "Your full genie powers are unlocked — enjoy unlimited date magic.",
                timestamp: Date()
            ))
        }
    }

    private func computeIsSubscribedFromStore() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            let validIDs: Set<String> = [Self.premiumMonthlyProductID, Self.premiumAnnualProductID]
            guard validIDs.contains(transaction.productID) else { continue }
            return true
        }
        return false
    }

    private func persistSubscribed(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.subscribedUserDefaultsKey)
    }

    // MARK: - Transaction updates

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            await handle(transactionResult: result)
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try Self.verify(transactionResult)
            await transaction.finish()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Verification (production)

    /// Only **verified** JWS-backed transactions are accepted; unverified results are rejected.
    private static func verify(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            throw PurchaseManagerError.purchaseFailed(error.localizedDescription)
        case .verified(let transaction):
            return transaction
        }
    }
}
