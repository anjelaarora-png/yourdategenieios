import SwiftUI

// MARK: - Plan selector

enum SubscriptionPlan: CaseIterable {
    case annual, monthly
}

// MARK: - Paywall

/// Reusable subscription paywall (StoreKit 2 via `PurchaseManager`).
/// Shows annual plan selected by default with a 7-day free trial on both plans.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchases = PurchaseManager.shared

    /// Invoked on the main actor when the user becomes subscribed (purchase or restore).
    var onSubscribed: () -> Void
    /// When false, hides the navigation bar close control (e.g. embedded in another container).
    var showsNotNowButton: Bool = true

    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var actionError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        planToggle
                        priceBlock.padding(.vertical, 4)
                        benefitsSection
                        errorSection
                        ctaSection
                        legalText
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
                        Button("Not now") { dismiss() }
                            .font(Font.bodySans(15, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
            .task { await purchases.loadProducts() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
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

            Text("Plan perfect dates — automatically")
                .font(Font.bodySans(17, weight: .medium))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)

            Text("7-day free trial · Cancel anytime")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryGold.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    // MARK: - Plan toggle

    private var planToggle: some View {
        HStack(spacing: 0) {
            planTab(.annual, label: "Annual", badge: savingsBadge)
            planTab(.monthly, label: "Monthly", badge: nil)
        }
        .background(Color.luxuryMaroonLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
    }

    private func planTab(_ plan: SubscriptionPlan, label: String, badge: String?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(Font.bodySans(14, weight: selectedPlan == plan ? .semibold : .regular))
                    .foregroundColor(selectedPlan == plan ? Color.luxuryMaroon : Color.luxuryCream)
                if let badge {
                    Text(badge)
                        .font(Font.bodySans(11, weight: .semibold))
                        .foregroundColor(selectedPlan == plan ? Color.luxuryMaroon : Color.luxuryGold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(selectedPlan == plan ? Color.luxuryMaroon.opacity(0.15) : Color.luxuryGold.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                Group {
                    if selectedPlan == plan {
                        AnyView(LinearGradient.goldShimmer)
                    } else {
                        AnyView(Color.clear)
                    }
                }
            )
            .cornerRadius(11)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selectedPlan)
    }

    private var savingsBadge: String {
        guard let annual = purchases.premiumAnnualProduct,
              let monthly = purchases.premiumMonthlyProduct else { return "Save 17%" }
        let annualDouble = NSDecimalNumber(decimal: annual.price).doubleValue
        let monthlyDouble = NSDecimalNumber(decimal: monthly.price).doubleValue
        guard monthlyDouble > 0 else { return "Best Value" }
        let savings = (1.0 - (annualDouble / 12.0) / monthlyDouble) * 100.0
        let rounded = Int(savings.rounded())
        return rounded > 0 ? "Save \(rounded)%" : "Best Value"
    }

    // MARK: - Price card

    private var priceBlock: some View {
        Group {
            if purchases.isLoadingProducts {
                ProgressView()
                    .tint(Color.luxuryGold)
                    .padding(.vertical, 16)
            } else {
                switch selectedPlan {
                case .annual:
                    priceCard(
                        price: purchases.premiumAnnualProduct?.displayPrice ?? "$49.99",
                        period: "per year",
                        note: annualPerMonthNote
                    )
                case .monthly:
                    priceCard(
                        price: purchases.premiumMonthlyProduct?.displayPrice ?? "$4.99",
                        period: "per month after free trial",
                        note: nil
                    )
                }
            }
        }
    }

    private var annualPerMonthNote: String {
        if let annual = purchases.premiumAnnualProduct {
            let perMonth = NSDecimalNumber(decimal: annual.price).doubleValue / 12.0
            return String(format: "~$%.2f/mo · 7 days free", perMonth)
        }
        return "~$4.17/mo · 7 days free"
    }

    private func priceCard(price: String, period: String, note: String?) -> some View {
        VStack(spacing: 6) {
            Text(price)
                .font(Font.header(32, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            Text(period)
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
            if let note {
                Text(note)
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.85))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .luxuryCard()
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow("Plan the perfect date in 60 seconds",
                       detail: "AI-powered, fully personalised to you")
            benefitRow("Unlimited date plans",
                       detail: "Generate as many as you want, any time")
            benefitRow("Plan together with your partner",
                       detail: "Invite, rank options and reveal your match")
            benefitRow("Love Notes, Gift Finder & Memories",
                       detail: "Every romantic detail, beautifully organised")
            benefitRow("Smart playlists & conversation starters", detail: nil)
            benefitRow("Route maps & calendar integration", detail: nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private func benefitRow(_ text: String, detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.luxuryGold)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.luxuryCream)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Errors

    private var errorSection: some View {
        Group {
            if let actionError, !actionError.isEmpty {
                Text(actionError)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.orange.opacity(0.95))
                    .multilineTextAlignment(.center)
            } else if let msg = purchases.lastErrorMessage, !msg.isEmpty {
                Text(msg)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.orange.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - CTAs

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    actionError = nil
                    do {
                        switch selectedPlan {
                        case .annual:  try await purchases.purchasePremiumAnnual()
                        case .monthly: try await purchases.purchasePremiumMonthly()
                        }
                        if purchases.isSubscribed { onSubscribed() }
                    } catch {
                        actionError = error.localizedDescription
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if purchases.isPurchasing { ProgressView().tint(Color.luxuryMaroon) }
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
                    if purchases.isSubscribed { onSubscribed() }
                }
            } label: {
                HStack(spacing: 8) {
                    if purchases.isRestoring { ProgressView().tint(Color.luxuryGold) }
                    Text("Restore Purchases")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryOutlineButtonStyle())
            .disabled(purchases.isRestoring)
        }
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("7-day free trial, then \(selectedPlanPriceDescription). Renews automatically unless cancelled at least 24 hours before the end of the trial. Manage in Settings → Subscriptions.")
            .font(Font.bodySans(11, weight: .regular))
            .foregroundColor(Color.luxuryMuted.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private var selectedPlanPriceDescription: String {
        switch selectedPlan {
        case .annual:
            return "\(purchases.premiumAnnualProduct?.displayPrice ?? "$49.99")/year"
        case .monthly:
            return "\(purchases.premiumMonthlyProduct?.displayPrice ?? "$4.99")/month"
        }
    }
}

#Preview {
    PaywallView(onSubscribed: {})
}
