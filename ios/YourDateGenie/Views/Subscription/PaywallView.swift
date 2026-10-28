import SwiftUI

// MARK: - Plan selector

enum SubscriptionPlan: CaseIterable {
    case annual, monthly
}

// MARK: - Legal URLs

private enum LegalURLs {
    static let privacy = URL(string: "https://yourdategenie.com/privacy-policy")!
    static let terms   = URL(string: "https://yourdategenie.com/terms")!
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
    /// When false, omit the inner `NavigationStack` so a parent stack can own the toolbar
    /// (avoids double nav bars on iPad sheets).
    var embedsNavigationStack: Bool = true

    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var actionError: String?

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { paywallChrome }
            } else {
                paywallChrome
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var paywallChrome: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: YDGSpace.lg) {
                        headerSection
                        benefitsSection
                        planOptions
                        errorSection
                    }
                    .padding(.horizontal, YDGSpace.margin)
                    .padding(.top, YDGSpace.xs)
                    .padding(.bottom, YDGSpace.lg)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                VStack(spacing: YDGSpace.sm) {
                    ctaSection
                    legalText
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.bottom, YDGSpace.xs)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ydgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if showsNotNowButton {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Not now") { dismiss() }
                        .font(.ydg(.body, weight: .medium))
                        .foregroundColor(Color.ydgTextSecondary)
                }
            }
        }
        .task { await purchases.loadProducts() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text("Your Date Genie Premium")
                .ydgText(.caption, color: .ydgHighlight)
            Text("Wake up to a finished plan, not a blank page")
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Plan rows (design 3.9: two selectable rows, annual first)

    private var planOptions: some View {
        VStack(spacing: YDGSpace.sm) {
            if purchases.isLoadingProducts {
                ProgressView()
                    .tint(Color.ydgTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, YDGSpace.md)
            } else {
                planRow(
                    .annual,
                    title: "Annual",
                    badge: savingsBadge,
                    detail: "7 days free, then \(purchases.premiumAnnualProduct?.displayPrice ?? "$119.99")/year",
                    price: annualPerMonthPrice,
                    priceUnit: "per month"
                )
                planRow(
                    .monthly,
                    title: "Monthly",
                    badge: nil,
                    detail: "7 days free, then \(purchases.premiumMonthlyProduct?.displayPrice ?? "$14.99")/month",
                    price: purchases.premiumMonthlyProduct?.displayPrice ?? "$14.99",
                    priceUnit: "per month"
                )
            }
        }
    }

    private func planRow(_ plan: SubscriptionPlan, title: String, badge: String?, detail: String, price: String, priceUnit: String) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack(spacing: YDGSpace.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ydgAccent : Color.ydgBorderStrong, lineWidth: isSelected ? 6 : 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected { Circle().fill(Color.ydgAccentSubtle).frame(width: 10, height: 10) }
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: YDGSpace.xs) {
                        Text(title)
                            .ydgText(.headline)
                        if let badge {
                            Text(badge)
                                .font(.ydg(.footnote, weight: .semibold))
                                .foregroundColor(Color.ydgTextOnAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.ydgAccent))
                        }
                    }
                    Text(detail)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .ydgText(.headline)
                    Text(priceUnit)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
            }
            .padding(YDGSpace.md)
            .background(isSelected ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isSelected ? Color.ydgAccent : Color.ydgBorder, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var savingsBadge: String {
        guard let annual = purchases.premiumAnnualProduct,
              let monthly = purchases.premiumMonthlyProduct else { return "Save 33%" }
        let annualDouble = NSDecimalNumber(decimal: annual.price).doubleValue
        let monthlyDouble = NSDecimalNumber(decimal: monthly.price).doubleValue
        guard monthlyDouble > 0 else { return "Best value" }
        let savings = (1.0 - (annualDouble / 12.0) / monthlyDouble) * 100.0
        let rounded = Int(savings.rounded())
        return rounded > 0 ? "Save \(rounded)%" : "Best value"
    }

    private var annualPerMonthPrice: String {
        if let annual = purchases.premiumAnnualProduct {
            let perMonth = NSDecimalNumber(decimal: annual.price).doubleValue / 12.0
            return annual.priceFormatStyle.format(Decimal(perMonth))
        }
        return "$10.00"
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            benefitRow("Unlimited date plans, with backups")
            benefitRow("Plan together: invite, rank, lock it in")
            benefitRow("Love Notes, Gift Finder and Memories")
            benefitRow("Route maps, calendar and playlists")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: YDGSpace.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.ydgAccent)
                .accessibilityHidden(true)
            Text(text)
                .ydgText(.body, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Errors

    private var errorSection: some View {
        Group {
            if let actionError, !actionError.isEmpty {
                Text(actionError)
                    .font(.ydg(.footnote))
                    .foregroundColor(Color.ydgWarning)
                    .multilineTextAlignment(.center)
            } else if let msg = purchases.lastErrorMessage, !msg.isEmpty {
                Text(msg)
                    .font(.ydg(.footnote))
                    .foregroundColor(Color.ydgWarning)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - CTAs

    private var productsReady: Bool {
        switch selectedPlan {
        case .annual:  return purchases.premiumAnnualProduct != nil
        case .monthly: return purchases.premiumMonthlyProduct != nil
        }
    }

    private var ctaSection: some View {
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
            Text(purchases.isPurchasing ? "Processing…" : "Start 7-day free trial")
        }
        .buttonStyle(YDGButtonStyle(kind: .primary, isLoading: purchases.isPurchasing))
        .disabled(purchases.isPurchasing || purchases.isLoadingProducts || !productsReady)
    }

    private func restoreTapped() {
        Task {
            actionError = nil
            await purchases.restorePurchases()
            if purchases.isSubscribed {
                onSubscribed()
            } else if let msg = purchases.lastErrorMessage, !msg.isEmpty {
                actionError = msg
            }
        }
    }

    // MARK: - Legal

    private var legalText: some View {
        VStack(spacing: YDGSpace.xs) {
            Text("Renews at \(selectedPlanPriceDescription) unless cancelled 24 hours before the trial ends. Cancel anytime in Settings.")
                .ydgText(.footnote, color: .ydgTextTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: YDGSpace.lg) {
                Button(purchases.isRestoring ? "Restoring…" : "Restore purchases") { restoreTapped() }
                    .disabled(purchases.isRestoring)
                Button("Terms") { OpenTableReservationSafari.openInSafari(LegalURLs.terms) }
                Button("Privacy") { OpenTableReservationSafari.openInSafari(LegalURLs.privacy) }
            }
            .font(.ydg(.footnote, weight: .medium))
            .foregroundColor(Color.ydgTextSecondary)
            .frame(minHeight: 44)
        }
    }

    private var selectedPlanPriceDescription: String {
        switch selectedPlan {
        case .annual:
            return "\(purchases.premiumAnnualProduct?.displayPrice ?? "$119.99")/year"
        case .monthly:
            return "\(purchases.premiumMonthlyProduct?.displayPrice ?? "$14.99")/month"
        }
    }
}

#Preview {
    PaywallView(onSubscribed: {})
}
