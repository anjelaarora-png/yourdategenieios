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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.ydgBase.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    RosePlantView(mode: rose.plantDisplayMode)
                        .padding(.top, YDGSpace.xs)

                    Text(roseHeadline)
                        .ydgText(.title2)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, YDGSpace.xxs)

                    Text(progressLine)
                        .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, YDGSpace.xxs)

                    budSegments
                        .padding(.top, YDGSpace.sm)

                    rowsCard
                        .padding(.top, YDGSpace.lg)
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.bottom, YDGSpace.lg)
            }
        }
        .safeAreaInset(edge: .bottom) {
            RosePrimaryButton(title: ctaTitle, action: onOpenNextBud)
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.sm)
                .padding(.bottom, YDGSpace.xs)
                .background(Color.ydgBase)
        }
        .navigationTitle("Your rose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ydgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showScienceInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17))
                        .foregroundColor(Color.ydgTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Why \(rose.monthlyGoal) nights a month?")
            }
        }
        .sheet(isPresented: $showScienceInfo) {
            RoseScienceInfoSheet(monthlyGoal: rose.monthlyGoal)
        }
    }

    /// One segment per bud in the monthly goal; opened buds fill rose.
    private var budSegments: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(rose.monthlyGoal, 1), id: \.self) { i in
                Capsule()
                    .fill(i < rose.datesThisMonth ? Color.ydgHighlight : Color.ydgOverlay)
                    .frame(width: 40, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(rose.datesThisMonth) of \(rose.monthlyGoal) buds open")
    }

    private var rowsCard: some View {
        VStack(spacing: 0) {
            roseRow(title: streakText, subtitle: rose.partnerName == nil ? "Tend your rose with a night out each week" : "You both tend this rose", trailing: rose.earnedBadgeCount > 0 ? "\(rose.earnedBadgeCount) badges" : nil, action: onShowJourney)
            YDGListDivider(leadingInset: YDGSpace.md)
            roseRow(title: "Your journey", subtitle: "Level \(rose.level) · \(rose.levelName)", trailing: nil, action: onShowJourney)
            YDGListDivider(leadingInset: YDGSpace.md)
            roseRow(title: "Your month together", subtitle: "A little proof you showed up", trailing: nil, action: onShowRecap)
        }
        .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                .stroke(Color.ydgBorder, lineWidth: 1)
        )
    }

    private func roseRow(title: String, subtitle: String, trailing: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: YDGSpace.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .ydgText(.subhead, weight: .semibold)
                    Text(subtitle)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                Spacer(minLength: 0)
                if let trailing {
                    Text(trailing)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.ydgTextTertiary)
            }
            .padding(.horizontal, YDGSpace.md)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            return "0 of \(rose.monthlyGoal) nights · \(rose.monthlyGoal) buds waiting"
        }
        let buds = rose.budsRemaining
        let budText = buds == 1 ? "1 bud to go" : "\(buds) buds to go"
        return "\(rose.datesThisMonth) of \(rose.monthlyGoal) nights this month · \(budText)"
    }

    private var ctaTitle: String {
        if !rose.hasEverCompletedDate {
            return "Plan your first night"
        }
        return rose.budsRemaining == 0
            ? "Plan a bonus night"
            : "Plan night \(rose.datesThisMonth + 1)"
    }

    private var streakText: String {
        if let partner = rose.partnerName {
            return rose.streakWeeks == 0 ? "Start a streak with \(partner)" : "\(rose.streakWeeks)-week streak with \(partner)"
        }
        return rose.streakWeeks == 0 ? "Start your streak" : "\(rose.streakWeeks)-week streak"
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
