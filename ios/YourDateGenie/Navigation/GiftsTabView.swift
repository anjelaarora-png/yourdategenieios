import SwiftUI

// MARK: - Gifts Tab View (Find Gifts, Saved, Bought)
struct GiftsTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ObservedObject private var giftStore = GiftStorageManager.shared
    @State private var listTab: ListTab = .saved

    enum ListTab: Hashable { case saved, bought }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ydgBase
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        Text("Find, save and track gifts for your person.")
                            .ydgText(.body, color: .ydgTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        findGiftsCard
                        giftListSection
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xs)
                    .padding(.bottom, YDGSpace.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gifts")
                        .ydgText(.headline)
                }
            }
            .toolbarBackground(Color.ydgBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var findGiftsCard: some View {
        VStack(alignment: .leading, spacing: YDGSpace.md) {
            HStack(alignment: .top, spacing: YDGSpace.sm) {
                YDGIconTile(systemName: "gift", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gift finder")
                        .ydgText(.headline)
                    Text("Occasion, budget, interests. We suggest ideas with links.")
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Button("Find a gift") {
                coordinator.showGiftFinder(datePlan: nil, dateLocation: nil)
            }
            .buttonStyle(.ydgPrimary)
        }
        .ydgCard(padding: YDGSpace.margin)
    }
    
    private var giftListSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.md) {
            Text("Your gift list")
                .ydgText(.title2)
                .accessibilityAddTraits(.isHeader)

            YDGSegmentedControl(options: [ListTab.saved, .bought], selection: $listTab) { tab in
                tab == .saved ? "Saved · \(giftStore.savedOnly.count)" : "Bought · \(giftStore.boughtOnly.count)"
            }

            let items = listTab == .saved ? giftStore.savedOnly : giftStore.boughtOnly
            if items.isEmpty {
                GiftListEmptyState(
                    icon: listTab == .saved ? "heart" : "checkmark.circle",
                    title: listTab == .saved ? "Nothing saved yet" : "Nothing bought yet",
                    subtitle: listTab == .saved
                        ? "Tap the heart on any idea in the gift finder to keep it here. Bought gifts won't be suggested again."
                        : "Mark a gift as bought and we won't suggest it again."
                )
            } else {
                VStack(spacing: YDGSpace.sm) {
                    ForEach(items) { stored in
                        StoredGiftRowView(
                            stored: stored,
                            onShop: { openShop(stored: stored) },
                            onNewLink: { openSearchLink(name: stored.name) },
                            onMarkBought: listTab == .saved ? { giftStore.markAsBought(toGiftSuggestion(stored)) } : nil
                        )
                    }
                }
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
