import SwiftUI

// MARK: - G1 · Your rose (spec §8)
//
// Rose progress toward the monthly 2–4 night goal + research line + shared streak.
// Single gold element = the "open the next bud" CTA. Progress is cream-on-maroon;
// the rose uses its own rose palette; the streak pill is maroon-outlined.

struct YourRoseView: View {
    @ObservedObject var rose: RoseManager
    /// Parent wires this to the plan flow during integration. Default = demo complete.
    var onOpenNextBud: () -> Void
    /// Navigate to G3.
    var onShowJourney: () -> Void
    /// Navigate to G5.
    var onShowRecap: () -> Void

    @State private var showScienceInfo = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    RosePlantView(mode: rose.plantDisplayMode)
                        .padding(.top, 8)

                    Text(roseHeadline)
                        .font(Font.displaySerif(22, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.top, 4)

                    Text(progressLine)
                        .font(Font.inter(13))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)

                    RoseProgressBar(progress: rose.monthProgress)
                        .padding(.top, 14)
                        .padding(.horizontal, 4)

                    Button {
                        showScienceInfo = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                            Text("Why \(rose.monthlyGoal) nights a month?")
                                .font(Font.inter(12, weight: .medium))
                        }
                        .foregroundColor(Color.luxuryMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    streakCard
                        .padding(.top, 18)

                    Button(action: onShowJourney) {
                        journeyRow
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    Button(action: onShowRecap) {
                        recapRow
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    Spacer(minLength: 28)

                    RosePrimaryButton(title: ctaTitle, action: onOpenNextBud)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Your rose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showScienceInfo) {
            RoseScienceInfoSheet(monthlyGoal: rose.monthlyGoal)
        }
    }

    private var roseHeadline: String {
        if rose.datesThisMonth >= rose.monthlyGoal {
            return "Your rose is in full bloom"
        }
        if !rose.hasEverCompletedDate {
            return "Your rose is ready"
        }
        if rose.datesThisMonth == 0 {
            return "Open your first bud this month"
        }
        return "Your rose is blooming"
    }

    private var progressLine: String {
        if !rose.hasEverCompletedDate {
            return "0 of \(rose.monthlyGoal) nights · \(rose.monthlyGoal) buds waiting to open"
        }
        let buds = rose.budsRemaining
        let budText = buds == 1 ? "1 bud left to open" : "\(buds) buds left to open"
        return "\(rose.datesThisMonth) of \(rose.monthlyGoal) nights this month · \(budText)"
    }

    private var ctaTitle: String {
        if !rose.hasEverCompletedDate {
            return "Plan your first date → open bud 1"
        }
        return rose.budsRemaining == 0
            ? "Full bloom — plan a bonus night"
            : "Open the next bud → plan night \(rose.datesThisMonth + 1)"
    }

    private var streakCard: some View {
        RoseCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(streakText)
                        .font(Font.inter(13, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text(rose.partnerName == nil ? "tend your rose nightly" : "you both tend this rose")
                        .font(Font.inter(11))
                        .foregroundColor(Color.luxuryMuted)
                }
                Spacer()
                RosePill(text: "🏅 ×\(rose.earnedBadgeCount)")
            }
        }
    }

    private var streakText: String {
        if let partner = rose.partnerName {
            return "🔥 \(rose.streakWeeks)-week streak · with \(partner)"
        }
        return "🔥 \(rose.streakWeeks)-week streak"
    }

    private var journeyRow: some View {
        RoseCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("⭐ Your journey")
                        .font(Font.inter(13, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text("Lvl \(rose.level) · 🔥 \(rose.streakWeeks)-week streak")
                        .font(Font.inter(11))
                        .foregroundColor(Color.luxuryMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
    }

    private var recapRow: some View {
        RoseCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("📅 Your month together")
                        .font(Font.inter(13, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text("A little proof you showed up")
                        .font(Font.inter(11))
                        .foregroundColor(Color.luxuryMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.luxuryMuted)
            }
        }
    }
}

#if DEBUG
struct YourRoseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            YourRoseView(rose: .shared, onOpenNextBud: {}, onShowJourney: {}, onShowRecap: {})
        }
        .preferredColorScheme(.dark)
    }
}
#endif
