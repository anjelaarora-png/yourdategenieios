import Foundation
import Combine

/// Persists saved and bought gifts to UserDefaults and syncs them to `public.gift_suggestions`
/// (standalone rows: `plan_id = NULL`, scoped by `couple_id` / `user_id`).
final class GiftStorageManager: ObservableObject {
    static let shared = GiftStorageManager()

    private let key = "date_genie_saved_gifts"

    @Published private(set) var savedGifts: [StoredGift] = []

    private init() {
        load()
    }

    // MARK: - Persistence (UserDefaults)

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([StoredGift].self, from: data) else {
            savedGifts = []
            return
        }
        savedGifts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(savedGifts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Public API

    /// Saved-only list (not marked bought).
    var savedOnly: [StoredGift] {
        savedGifts.filter { !$0.purchased }
    }

    /// Bought-only list.
    var boughtOnly: [StoredGift] {
        savedGifts.filter { $0.purchased }
    }

    /// Names of purchased gifts (for excluding from "Get more ideas").
    var purchasedGiftNames: [String] {
        savedGifts.filter { $0.purchased }.map(\.name)
    }

    func addSaved(_ gift: GiftSuggestion) {
        if isSaved(gift) { return }
        let stored = StoredGift(
            id: UUID(),
            name: gift.name,
            description: gift.description,
            priceRange: gift.priceRange,
            whereToBuy: gift.whereToBuy,
            purchaseUrl: gift.purchaseUrl,
            whyItFits: gift.whyItFits,
            emoji: gift.emoji,
            storeSearchQuery: gift.storeSearchQuery,
            imageUrl: gift.imageUrl,
            purchased: false
        )
        savedGifts.insert(stored, at: 0)
        save()
        scheduleCloudSync()
    }

    func markAsBought(_ gift: GiftSuggestion) {
        guard let idx = savedGifts.firstIndex(where: { normalizeKey($0.name) == normalizeKey(gift.name) }) else {
            let stored = StoredGift(
                id: UUID(),
                name: gift.name,
                description: gift.description,
                priceRange: gift.priceRange,
                whereToBuy: gift.whereToBuy,
                purchaseUrl: gift.purchaseUrl,
                whyItFits: gift.whyItFits,
                emoji: gift.emoji,
                storeSearchQuery: gift.storeSearchQuery,
                imageUrl: gift.imageUrl,
                purchased: true
            )
            savedGifts.insert(stored, at: 0)
            save()
            scheduleCloudSync()
            return
        }
        savedGifts[idx] = StoredGift(
            id: savedGifts[idx].id,
            name: savedGifts[idx].name,
            description: savedGifts[idx].description,
            priceRange: savedGifts[idx].priceRange,
            whereToBuy: savedGifts[idx].whereToBuy,
            purchaseUrl: savedGifts[idx].purchaseUrl,
            whyItFits: savedGifts[idx].whyItFits,
            emoji: savedGifts[idx].emoji,
            storeSearchQuery: savedGifts[idx].storeSearchQuery,
            imageUrl: savedGifts[idx].imageUrl,
            purchased: true
        )
        save()
        scheduleCloudSync()
    }

    func isSaved(_ gift: GiftSuggestion) -> Bool {
        savedGifts.contains { normalizeKey($0.name) == normalizeKey(gift.name) }
    }

    func isBought(_ gift: GiftSuggestion) -> Bool {
        savedGifts.contains { normalizeKey($0.name) == normalizeKey(gift.name) && $0.purchased }
    }

    /// Move a bought gift back to saved (undo bought).
    func markAsNotBought(_ stored: StoredGift) {
        guard let idx = savedGifts.firstIndex(where: { $0.id == stored.id }) else { return }
        savedGifts[idx] = StoredGift(
            id: stored.id,
            name: stored.name,
            description: stored.description,
            priceRange: stored.priceRange,
            whereToBuy: stored.whereToBuy,
            purchaseUrl: stored.purchaseUrl,
            whyItFits: stored.whyItFits,
            emoji: stored.emoji,
            storeSearchQuery: stored.storeSearchQuery,
            imageUrl: stored.imageUrl,
            purchased: false
        )
        save()
        scheduleCloudSync()
    }

    func removeGift(_ stored: StoredGift) {
        savedGifts.removeAll { $0.id == stored.id }
        save()
        Task { await deleteFromCloud(giftId: stored.id) }
    }

    private func normalizeKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Cloud Sync

    private func scheduleCloudSync() {
        Task { await pushToCloud() }
    }

    /// Called on login to pull cloud state and merge with local.
    func syncFromSupabaseWhenLoggedIn(coupleId: UUID, userId: UUID) {
        Task { await syncFromCloud(coupleId: coupleId, userId: userId) }
    }

    private func pushToCloud() async {
        guard UserProfileManager.shared.isLoggedIn,
              let coupleId = UserProfileManager.shared.coupleId,
              let userId = UserProfileManager.shared.userId else { return }
        let snapshot = await MainActor.run { savedGifts }
        for gift in snapshot {
            let dbGift = gift.toDBGiftSuggestion(coupleId: coupleId, userId: userId)
            do {
                _ = try await SupabaseService.shared.upsertStandaloneGift(dbGift)
            } catch {
                print("[GiftStorageManager] pushToCloud error for \(gift.name): \(error)")
            }
        }
    }

    private func syncFromCloud(coupleId: UUID, userId: UUID) async {
        do {
            let remote = try await SupabaseService.shared.getStandaloneGifts(userId: userId)
            await MainActor.run {
                let remoteById = Dictionary(uniqueKeysWithValues: remote.map { ($0.giftId, $0) })
                var existing = savedGifts
                // Update any local gifts whose cloud row has changed
                for i in existing.indices {
                    if let cloudRow = remoteById[existing[i].id] {
                        existing[i] = existing[i].merging(from: cloudRow)
                    }
                }
                // Append any cloud gifts not yet local
                let localIds = Set(existing.map { $0.id })
                let newFromCloud = remote
                    .filter { !localIds.contains($0.giftId) }
                    .map { StoredGift(from: $0) }
                savedGifts = newFromCloud + existing
                save()
            }
            // Push any local gifts that didn't exist in cloud yet
            await pushToCloud()
        } catch {
            print("[GiftStorageManager] syncFromCloud error: \(error)")
        }
    }

    private func deleteFromCloud(giftId: UUID) async {
        guard UserProfileManager.shared.isLoggedIn else { return }
        do {
            try await SupabaseService.shared.deleteGiftSuggestion(giftId: giftId)
        } catch {
            print("[GiftStorageManager] deleteFromCloud error: \(error)")
        }
    }
}

// MARK: - Stored Gift Model

struct StoredGift: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let priceRange: String
    let whereToBuy: String
    let purchaseUrl: String?
    let whyItFits: String
    let emoji: String
    let storeSearchQuery: String?
    let imageUrl: String?
    let purchased: Bool

    /// Build from a cloud row fetched from `gift_suggestions`.
    init(from db: DBGiftSuggestion) {
        self.id = db.giftId
        self.name = db.name ?? ""
        self.description = db.description ?? ""
        self.priceRange = db.priceRange ?? ""
        self.whereToBuy = db.whereToBuy ?? ""
        self.purchaseUrl = db.purchaseUrl
        self.whyItFits = db.whyItFits ?? ""
        self.emoji = db.emoji ?? "🎁"
        self.storeSearchQuery = db.storeSearchQuery
        self.imageUrl = db.imageUrl
        self.purchased = db.purchased
    }

    init(id: UUID, name: String, description: String, priceRange: String, whereToBuy: String,
         purchaseUrl: String?, whyItFits: String, emoji: String, storeSearchQuery: String?,
         imageUrl: String?, purchased: Bool) {
        self.id = id; self.name = name; self.description = description
        self.priceRange = priceRange; self.whereToBuy = whereToBuy
        self.purchaseUrl = purchaseUrl; self.whyItFits = whyItFits
        self.emoji = emoji; self.storeSearchQuery = storeSearchQuery
        self.imageUrl = imageUrl; self.purchased = purchased
    }

    func toDBGiftSuggestion(coupleId: UUID, userId: UUID) -> DBGiftSuggestion {
        DBGiftSuggestion(
            giftId: id,
            planId: nil,
            coupleId: coupleId,
            userId: userId,
            name: name,
            priceRange: priceRange,
            description: description,
            whyItFits: whyItFits,
            whereToBuy: whereToBuy,
            purchaseUrl: purchaseUrl,
            emoji: emoji,
            storeSearchQuery: storeSearchQuery,
            imageUrl: imageUrl,
            liked: true,
            purchased: purchased,
            purchasedAt: purchased ? Date() : nil
        )
    }

    /// Keep local purchased state; update metadata from cloud row.
    func merging(from db: DBGiftSuggestion) -> StoredGift {
        StoredGift(
            id: id,
            name: db.name ?? name,
            description: db.description ?? description,
            priceRange: db.priceRange ?? priceRange,
            whereToBuy: db.whereToBuy ?? whereToBuy,
            purchaseUrl: db.purchaseUrl ?? purchaseUrl,
            whyItFits: db.whyItFits ?? whyItFits,
            emoji: db.emoji ?? emoji,
            storeSearchQuery: db.storeSearchQuery ?? storeSearchQuery,
            imageUrl: db.imageUrl ?? imageUrl,
            purchased: db.purchased || purchased
        )
    }
}
