import SwiftUI

// MARK: - G2 · Behind pace → revive (spec §8 guardrail)
//
// The rose droops (loss aversion) but NEVER dies and NEVER shames. We drop the
// bar to a 15-minute at-home idea and frame the gap warmly. Copy here is
// deliberately guilt-free: "no guilt", "misses you", "welcome back" energy.
// Single gold element = "Revive it tonight".

struct RoseReviveView: View {
    @ObservedObject var rose: RoseManager
    /// Parent wires this to start the low-key at-home flow. Default = demo revive.
    var onRevive: (ReviveIdea) -> Void
    /// "Remind me tomorrow" — gentle defer, never a penalty.
    var onRemindLater: () -> Void

    @State private var idea: ReviveIdea = .placeholder

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                RosePlantView(mode: .drooping)

                Text("Your rose misses you")
                    .font(Font.displaySerif(22, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .padding(.top, 6)

                Text(missCopy)
                    .font(Font.inter(14))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 8)
                    .padding(.horizontal, 8)

                RoseCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(idea.title) \(idea.emoji)")
                            .font(Font.inter(13, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                        Text("\(idea.detail) 🌹")
                            .font(Font.inter(11))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }
                .padding(.top, 20)

                Text("1 of dozens · shuffle anytime")
                    .font(Font.inter(11))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.top, 10)

                Spacer(minLength: 24)

                RosePrimaryButton(title: "Revive it tonight") {
                    rose.revive()
                    onRevive(idea)
                }

                RoseGhostLink(title: "Remind me tomorrow", action: onRemindLater)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .navigationTitle("Your rose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { idea = rose.nextReviveIdea() }
    }

    private var missCopy: String {
        let weeks = max(2, rose.weeksSinceLastDate)
        return "It's been \(weeks) weeks — no guilt. Revive it in 15 minutes, tonight, from the couch."
    }
}

#if DEBUG
struct RoseReviveView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RoseReviveView(rose: .shared, onRevive: { _ in }, onRemindLater: {})
        }
        .preferredColorScheme(.dark)
    }
}
#endif
