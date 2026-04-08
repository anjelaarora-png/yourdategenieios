import StoreKit
import SwiftUI

/// Presents the premium monthly subscription with StoreKit 2 purchase flow.
struct SubscriptionOfferSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchases = PurchaseManager.shared

    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Premium monthly")
                            .font(Font.header(22, weight: .semibold))
                            .foregroundColor(Color.luxuryCream)

                        Text("Subscriptions renew automatically until canceled. You can manage or cancel in App Store account settings.")
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        if purchases.isLoadingProducts {
                            ProgressView()
                                .tint(Color.luxuryGold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else if let product = purchases.premiumMonthlyProduct {
                            subscriptionRow(product)
                        } else {
                            Text("Products are unavailable. Check your product ID in App Store Connect or attach the StoreKit configuration in the Run scheme (Options).")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.orange.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let purchaseError {
                            Text(purchaseError)
                                .font(Font.bodySans(13, weight: .regular))
                                .foregroundColor(Color.orange.opacity(0.95))
                        }

                        if let msg = purchases.lastErrorMessage, !msg.isEmpty {
                            Text(msg)
                                .font(Font.bodySans(13, weight: .regular))
                                .foregroundColor(Color.orange.opacity(0.95))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Font.bodySans(15, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .task {
                await purchases.loadProducts()
            }
        }
    }

    @ViewBuilder
    private func subscriptionRow(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(Font.bodySans(17, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    Text(product.description)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(Font.bodySans(16, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
            }

            Button {
                Task {
                    purchaseError = nil
                    do {
                        try await purchases.purchasePremiumMonthly()
                        if purchases.isSubscribed {
                            dismiss()
                        }
                    } catch {
                        purchaseError = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    if purchases.isPurchasing {
                        ProgressView()
                            .tint(Color.luxuryMaroon)
                    }
                    Text(purchases.isPurchasing ? "Processing…" : "Subscribe")
                        .font(Font.bodySans(15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.luxuryGold)
                .foregroundColor(Color.luxuryMaroon)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(purchases.isPurchasing)
        }
        .padding(18)
        .luxuryCard()
    }
}

#Preview {
    SubscriptionOfferSheet()
}
