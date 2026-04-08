import SwiftUI

// MARK: - Gifts Tab View (Find Gifts, Saved, Bought)
struct GiftsTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var giftStore = GiftStorageManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        findGiftsSection
                        savedGiftsSection
                        boughtGiftsSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gifts")
                        .font(Font.tangerine(28, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Gifts")
                .font(Font.tangerine(52, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            
            Text("Find, save, and track gifts for your person")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .padding(.top, 16)
    }
    
    private var findGiftsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Find Gifts")
                .font(Font.tangerine(28, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .padding(.horizontal, 20)
            
            Button {
                coordinator.showGiftFinder(datePlan: nil, dateLocation: nil)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.luxuryGold.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.luxuryGold)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Gift Finder")
                            .font(Font.bodySans(17, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)
                        Text("Occasion, budget, interests — we’ll suggest ideas with links")
                            .font(Font.inter(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
                .padding(18)
                .background(Color.luxuryMaroonLight)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.luxuryGold.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }
    
    private var savedGiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Gifts")
                .font(Font.tangerine(28, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .padding(.horizontal, 20)
            
            if giftStore.savedOnly.isEmpty {
                GiftListEmptyState(
                    icon: "heart.circle.fill",
                    title: "No saved gifts yet",
                    subtitle: "Save ideas from the Gift Finder to see them here"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.savedOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openShop(stored: stored) },
                            onNewLink: { openSearchLink(name: stored.name) },
                            onMarkBought: { giftStore.markAsBought(toGiftSuggestion(stored)) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var boughtGiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bought Gifts")
                .font(Font.tangerine(28, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .padding(.horizontal, 20)
            
            if giftStore.boughtOnly.isEmpty {
                GiftListEmptyState(
                    icon: "checkmark.circle.fill",
                    title: "No bought gifts yet",
                    subtitle: "Mark gifts as bought in the finder so we don't suggest them again"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.boughtOnly) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openShop(stored: stored) },
                            onNewLink: { openSearchLink(name: stored.name) },
                            onMarkBought: nil
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func openShop(stored: StoredGift) {
        if let s = stored.purchaseUrl, !s.isEmpty,
           let url = URL(string: s),
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
        } else {
            openSearchLink(name: stored.name)
        }
    }
    
    private func openSearchLink(name: String) {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func toGiftSuggestion(_ stored: StoredGift) -> GiftSuggestion {
        GiftSuggestion(
            name: stored.name,
            description: stored.description,
            priceRange: stored.priceRange,
            whereToBuy: stored.whereToBuy,
            purchaseUrl: stored.purchaseUrl,
            whyItFits: stored.whyItFits,
            emoji: stored.emoji,
            storeSearchQuery: stored.storeSearchQuery,
            imageUrl: stored.imageUrl
        )
    }
}
