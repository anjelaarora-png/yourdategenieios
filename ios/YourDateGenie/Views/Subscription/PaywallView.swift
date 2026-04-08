import SwiftUI

/// Reusable subscription paywall (StoreKit 2 via `PurchaseManager`).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchases = PurchaseManager.shared

    /// Invoked on the main actor when the user becomes subscribed (purchase or restore).
    var onSubscribed: () -> Void
    /// When false, hides the navigation bar close control (e.g. embedded in another container).
    var showsNotNowButton: Bool = true

    @State private var actionError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(LinearGradient.goldShimmer)
                            .padding(.top, 8)

                        Text("Your Date Genie")
                            .font(Font.tangerine(32, weight: .bold))
                            .italic()
                            .foregroundColor(Color.luxuryGold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Unlock Your Dating Assistant")
                            .font(Font.bodySans(17, weight: .medium))
                            .foregroundColor(Color.luxuryCream)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow("Unlimited date plans")
                            benefitRow("Love notes & conversation help")
                            benefitRow("Gift ideas & playlists")
                            benefitRow("Memory & smart recommendations")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)

                        priceBlock
                            .padding(.vertical, 8)

                        if let actionError, !actionError.isEmpty {
                            Text(actionError)
                                .font(Font.bodySans(13, weight: .regular))
                                .foregroundColor(Color.orange.opacity(0.95))
                                .multilineTextAlignment(.center)
                        }
                        if let msg = purchases.lastErrorMessage, !msg.isEmpty, actionError == nil {
                            Text(msg)
                                .font(Font.bodySans(13, weight: .regular))
                                .foregroundColor(Color.orange.opacity(0.95))
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task {
                                actionError = nil
                                do {
                                    try await purchases.purchasePremiumMonthly()
                                    if purchases.isSubscribed {
                                        onSubscribed()
                                    }
                                } catch {
                                    actionError = error.localizedDescription
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if purchases.isPurchasing {
                                    ProgressView()
                                        .tint(Color.luxuryMaroon)
                                }
                                Text(purchases.isPurchasing ? "Processing…" : "Start 7-Day Free Trial")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryGoldButtonStyle())
                        .disabled(purchases.isPurchasing)

                        Button {
                            Task {
                                actionError = nil
                                await purchases.restorePurchases()
                                if purchases.isSubscribed {
                                    onSubscribed()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if purchases.isRestoring {
                                    ProgressView()
                                        .tint(Color.luxuryGold)
                                }
                                Text("Restore Purchases")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LuxuryOutlineButtonStyle())
                        .disabled(purchases.isRestoring)

                        Text("Subscription renews after the trial unless canceled. Manage anytime in Settings → Subscriptions.")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryMuted.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if showsNotNowButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Not now") {
                            dismiss()
                        }
                        .font(Font.bodySans(15, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .task {
                await purchases.loadProducts()
            }
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.luxuryGold)
            Text(text)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var priceBlock: some View {
        Group {
            if purchases.isLoadingProducts {
                ProgressView()
                    .tint(Color.luxuryGold)
                    .padding(.vertical, 12)
            } else if let product = purchases.premiumMonthlyProduct {
                VStack(spacing: 6) {
                    Text(product.displayPrice)
                        .font(Font.header(28, weight: .bold))
                        .foregroundColor(Color.luxuryGold)
                    Text("per month after trial")
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .luxuryCard()
            } else {
                Text("Price unavailable")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .luxuryCard()
            }
        }
    }
}

#Preview {
    PaywallView(onSubscribed: {})
}
