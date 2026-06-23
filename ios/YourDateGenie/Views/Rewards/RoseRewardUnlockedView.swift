import SwiftUI

// MARK: - G4 · Reward unlocked (spec §8) — the variable reward / dopamine hit
//
// Presented occasionally after a completed night (see RoseManager.maybeUnlockReward).
// Single gold element = "Plan this for <partner>". The gift medallion + rarity
// pill use surface / maroon so gold stays reserved for the one action.

struct RoseRewardUnlockedView: View {
    let reward: HiddenDateReward
    var partnerName: String?
    /// Parent wires this to start planning the unlocked hidden date.
    var onPlan: (HiddenDateReward) -> Void
    var onSaveForLater: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.surfaceElevated)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(Color.accentMaroon.opacity(0.5), lineWidth: 1))
                    Text(reward.emoji)
                        .font(.system(size: 34))
                }
                .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.6))
                .opacity(appeared ? 1 : 0)

                Text("Surprise — you earned it")
                    .font(Font.inter(12))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.top, 18)

                Text(reward.title)
                    .font(Font.displaySerif(22, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                Text(reward.blurb)
                    .font(Font.inter(14))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                RosePill(text: "✨ \(reward.rarityLabel)")
                    .padding(.top, 18)

                Spacer()

                RosePrimaryButton(title: planTitle) { onPlan(reward) }

                RoseGhostLink(title: "Save for later", action: onSaveForLater)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true } }
        }
    }

    private var planTitle: String {
        if let partner = partnerName, !partner.isEmpty { return "Plan this for \(partner)" }
        return "Plan this date"
    }
}

#if DEBUG
struct RoseRewardUnlockedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RoseRewardUnlockedView(
                reward: HiddenDateReward(
                    id: "rooftop", emoji: "🌃", title: "Hidden date unlocked",
                    blurb: "Rooftop stargazing + cocoa — only for couples on a 6-week streak.",
                    rarityLabel: "Rare · 1 of 8 secret dates"),
                partnerName: "Maya",
                onPlan: { _ in }, onSaveForLater: {})
        }
        .preferredColorScheme(.dark)
    }
}
#endif
