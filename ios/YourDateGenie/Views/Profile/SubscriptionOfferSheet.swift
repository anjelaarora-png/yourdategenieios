import SwiftUI

/// Settings-entry paywall sheet — embeds the shared PaywallView so both plans
/// (annual default, monthly toggle) are always available from Settings too.
struct SubscriptionOfferSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PaywallView(
                onSubscribed: { dismiss() },
                showsNotNowButton: false,
                embedsNavigationStack: false
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
    }
}

#Preview {
    SubscriptionOfferSheet()
}
