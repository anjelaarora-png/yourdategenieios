import SwiftUI

/// Self-contained venue-partner flow: onboarding → advertising application → confirmation.
/// Independent of the couple Supabase account; writes to Firebase `business_listings`.
struct BusinessPortalView: View {
    var defaultEmail: String = ""
    var source: String = "ios-business"
    let onClose: () -> Void

    @State private var step: Step = .onboarding

    enum Step { case onboarding, apply, done }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                switch step {
                case .onboarding:
                    BusinessOnboardingView(
                        onComplete: { withAnimation { step = .apply } },
                        onSkip: { withAnimation { step = .apply } }
                    )
                case .apply:
                    BusinessApplicationFormView(
                        source: source,
                        defaultEmail: defaultEmail,
                        onSuccess: { withAnimation { step = .done } }
                    )
                case .done:
                    doneView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(titleForStep)
                        .font(Font.bodySans(16, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close", action: onClose)
                        .font(Font.bodySans(15, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var titleForStep: String {
        switch step {
        case .onboarding: return "Venue partners"
        case .apply: return "Advertising application"
        case .done: return "You’re on the list"
        }
    }

    private var doneView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.luxuryGold.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color.luxuryGold)
            }
            Text("You’re on the list")
                .font(Font.displaySerif(40, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            Text("We’ll review your application and send placement options. Thanks for partnering with Your Date Genie.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
            Spacer()
            Button(action: onClose) {
                Text("Done")
                    .font(Font.bodySans(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
