import Foundation
import Combine

/// Persists saved and bought gifts to UserDefaults. Used by Gift Finder and Gifts tab.
final class GiftStorageManager: ObservableObject {
    static let shared = GiftStorageManager()
    
    private let key = "date_genie_saved_gifts"
    
    @Published private(set) var savedGifts: [StoredGift] = []
    
    private init() {
        load()
    }
    
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
    }
    
    private func normalizeKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
}
