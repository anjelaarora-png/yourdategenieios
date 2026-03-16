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
                emptyStateCard(
                    icon: "heart.circle.fill",
                    title: "No saved gifts yet",
                    subtitle: "Save ideas from the Gift Finder to see them here"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.savedOnly) { stored in
                        StoredGiftRow(
                            stored: stored,
                            location: "",
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
                emptyStateCard(
                    icon: "checkmark.circle.fill",
                    title: "No bought gifts yet",
                    subtitle: "Mark gifts as bought in the finder so we don't suggest them again"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(giftStore.boughtOnly) { stored in
                        StoredGiftRow(
                            stored: stored,
                            location: "",
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
    
    private func emptyStateCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(Color.luxuryGold)
            Text(title)
                .font(Font.tangerine(22, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            Text(subtitle)
                .font(Font.inter(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Color.luxuryMaroonLight.opacity(0.6))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Stored Gift Row (compact card for Saved/Bought lists)
private struct StoredGiftRow: View {
    let stored: StoredGift
    let location: String
    let onShop: () -> Void
    let onNewLink: () -> Void
    var onMarkBought: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(stored.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stored.name)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text(stored.priceRange)
                        .font(Font.inter(12, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button(action: onShop) {
                    HStack(spacing: 5) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 11))
                        Text("Shop")
                            .font(Font.inter(12, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(8)
                }
                Button(action: onNewLink) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundColor(Color.luxuryGold)
                        Text("New link")
                            .font(Font.inter(11, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1)
                    )
                }
                if let onMarkBought = onMarkBought {
                    Button(action: onMarkBought) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Bought")
                                .font(Font.inter(11, weight: .semibold))
                        }
                        .foregroundColor(Color.luxuryMaroon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.luxuryCream.opacity(0.9))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.luxuryMaroonLight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
        )
    }
}
