import SwiftUI

/// Shown in place of a premium tab when the user is not subscribed.
struct LockedPremiumTabPlaceholder: View {
    let feature: AppFeature
    let title: String
    let subtitle: String

    @EnvironmentObject private var access: AccessManager

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.luxuryGold)

                Text(title)
                    .font(Font.tangerine(28, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    access.require(feature) {}
                } label: {
                    Text("Unlock with Premium")
                        .font(Font.bodySans(16, weight: .semibold))
                        .foregroundColor(Color.luxuryMaroon)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.goldShimmer)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
    }
}
