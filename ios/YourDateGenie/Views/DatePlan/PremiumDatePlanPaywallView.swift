import SwiftUI

/// Thin wrapper so existing call sites keep the same type name; content is the shared `PaywallView`.
struct PremiumDatePlanPaywallView: View {
    let onSubscribed: () -> Void

    var body: some View {
        PaywallView(onSubscribed: onSubscribed, showsNotNowButton: true)
    }
}

#Preview {
    PremiumDatePlanPaywallView(onSubscribed: {})
}
