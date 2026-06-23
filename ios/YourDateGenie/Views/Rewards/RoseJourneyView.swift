import SwiftUI

// MARK: - G3 · Your journey (spec §8) — level · streak (with freeze) · badges
//
// Opt-in detail page. Single gold element = "Plan a night → +XP".
// Level progress is cream-on-maroon; the streak-freeze pill and locked badge
// tiles use maroon / dim — gold stays reserved for the CTA.

struct RoseJourneyView: View {
    @ObservedObject var rose: RoseManager
    var onPlanNight: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    levelCard
                    streakCard

                    RoseLabel(text: "Badges")
                        .padding(.top, 4)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(rose.badges) { badge in
                            badgeTile(badge)
                        }
                    }

                    Spacer(minLength: 24)

                    RosePrimaryButton(title: "Plan a night → +\(RoseManager.xpPerNight) XP", action: onPlanNight)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Your journey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var levelCard: some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Level \(rose.level) · \(rose.levelName)")
                        .font(Font.displaySerif(15, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Text("\(rose.xpIntoLevel) / \(rose.xpForLevel)")
                        .font(Font.inter(11))
                        .foregroundColor(Color.luxuryMuted)
                }
                RoseProgressBar(progress: rose.levelProgress)
                Text(nextLevelLine)
                    .font(Font.inter(11))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
    }

    private var nextLevelLine: String {
        let nights = rose.nightsToNextLevel
        let nightText = nights == 1 ? "1 more night" : "\(nights) more nights"
        return "\(nightText) → Level \(rose.level + 1) · \(rose.nextLevelName) 💛"
    }

    private var streakCard: some View {
        RoseCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🔥 \(rose.streakWeeks)-week connection streak")
                        .font(Font.inter(13, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text("your longest yet")
                        .font(Font.inter(11))
                        .foregroundColor(Color.luxuryMuted)
                }
                Spacer()
                if rose.streakFreezeAvailable {
                    RosePill(text: "freeze 🧊")
                }
            }
        }
    }

    private func badgeTile(_ badge: RoseBadge) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(badge.isEarned ? Color.surfaceElevated : Color.roseTrack)
                Text(badge.isEarned ? badge.emoji : "🔒")
                    .font(.system(size: 18))
                    .opacity(badge.isEarned ? 1 : 0.5)
            }
            .frame(height: 42)
            Text(badge.title)
                .font(Font.inter(10))
                .foregroundColor(badge.isEarned ? Color.luxuryCreamMuted : Color.luxuryMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#if DEBUG
struct RoseJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RoseJourneyView(rose: .shared, onPlanNight: {})
        }
        .preferredColorScheme(.dark)
    }
}
#endif
