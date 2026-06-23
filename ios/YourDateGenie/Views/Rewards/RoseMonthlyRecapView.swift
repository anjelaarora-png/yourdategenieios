import SwiftUI

// MARK: - G5 · Your month together (spec §8) — shareable recap
//
// Warm, intimate proof-of-effort (not a vanity leaderboard). Single gold element
// = "Share our month". Stat tiles are cream cards; everything else cream/muted.

struct RoseMonthlyRecapView: View {
    let recap: RoseMonthlyRecap
    /// Parent wires this to a share sheet / image export.
    var onShare: (RoseMonthlyRecap) -> Void

    private let columns = [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your \(recap.monthName)\ntogether 💛")
                        .font(Font.displaySerif(24, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    Text("A little proof you showed up for each other.")
                        .font(Font.inter(14))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .padding(.top, 6)

                    LazyVGrid(columns: columns, spacing: 9) {
                        RoseStatCard(value: "\(recap.nightsOut)", label: "nights out")
                        RoseStatCard(value: "\(recap.newPlaces)", label: "new places")
                        RoseStatCard(value: "\(recap.streakWeeks)", label: "week streak")
                        RoseStatCard(value: "\(recap.badgesEarned)", label: "badges earned")
                    }
                    .padding(.top, 18)

                    RoseCard {
                        HStack(spacing: 0) {
                            Text("Most-loved night: ")
                                .font(Font.inter(13))
                                .foregroundColor(Color.luxuryCreamMuted)
                            Text(recap.mostLovedNight)
                                .font(Font.inter(13, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                        }
                    }
                    .padding(.top, 12)

                    Spacer(minLength: 28)

                    RosePrimaryButton(title: "Share our month ↗") { onShare(recap) }
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Your month")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#if DEBUG
struct RoseMonthlyRecapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RoseMonthlyRecapView(
                recap: RoseMonthlyRecap(
                    monthName: "May", nightsOut: 4, newPlaces: 2,
                    streakWeeks: 6, badgesEarned: 3, mostLovedNight: "the gallery walk 🎨"),
                onShare: { _ in })
        }
        .preferredColorScheme(.dark)
    }
}
#endif
