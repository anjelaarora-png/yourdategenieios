import SwiftUI

// MARK: - Shared Rose UI components (Charcoal Maroon)
//
// Discipline (spec §1 + design rules): accentGold appears EXACTLY ONCE per
// screen — always as `RosePrimaryButton` (the single gold action). Everything
// else here is cream / muted / maroon-outline so the hierarchy stays clean.

// MARK: Primary CTA — the one gold element per screen

struct RosePrimaryButton: View {
    let title: String
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.inter(16, weight: .semibold))
                .foregroundColor(Color.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(RosePressStyle(reduceMotion: reduceMotion))
    }
}

/// Subtle press feedback; flattens scale animation under Reduce Motion.
struct RosePressStyle: ButtonStyle {
    var reduceMotion: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: Demoted underlined link (secondary action)

struct RoseGhostLink: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.inter(14, weight: .medium))
                .foregroundColor(Color.luxuryCreamMuted)
                .underline()
        }
        .buttonStyle(.plain)
    }
}

// MARK: Progress bar — cream fill on a dark maroon track (never gold)

struct RoseProgressBar: View {
    /// 0…1
    let progress: Double
    var height: CGFloat = 7
    var fill: Color = .textPrimary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animated: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.roseTrack)
                Capsule()
                    .fill(fill)
                    .frame(width: max(0, geo.size.width * animated))
            }
        }
        .frame(height: height)
        .onAppear {
            if reduceMotion { animated = clamped }
            else { withAnimation(.easeOut(duration: 0.7)) { animated = clamped } }
        }
        .onChange(of: progress) { _ in
            if reduceMotion { animated = clamped }
            else { withAnimation(.easeOut(duration: 0.5)) { animated = clamped } }
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }

    private var clamped: Double { min(1, max(0, progress)) }
}

// MARK: Maroon-outlined info pill

struct RosePill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Font.inter(11, weight: .semibold))
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentMaroon.opacity(0.25))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.accentMaroon.opacity(0.55), lineWidth: 1))
    }
}

// MARK: Elevated surface card

struct RoseCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.maroonBorderTint, lineWidth: 1)
            )
    }
}

// MARK: Cream stat card (recap numerals)

struct RoseStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Font.displaySerif(24, weight: .bold))
                .foregroundColor(Color.textOnCard)
            Text(label)
                .font(Font.inter(11, weight: .regular))
                .foregroundColor(Color.textMutedOnCard)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: Section label (uppercase, tracked)

struct RoseLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Font.inter(11, weight: .semibold))
            .tracking(1.5)
            .foregroundColor(Color.luxuryCreamMuted)
    }
}

// MARK: Home pill — subtle rose progress (spec §8: one small pill on Home)

struct RoseHomePill: View {
    @ObservedObject var rose: RoseManager
    var onTap: () -> Void

    @State private var showScienceInfo = false

    private var progressText: String {
        if rose.needsRevive {
            return "Tap for a gentle 15-min revive"
        }
        if !rose.hasEverCompletedDate {
            return "0 of \(rose.monthlyGoal) · plant your first bud"
        }
        if rose.datesThisMonth >= rose.monthlyGoal {
            return "In full bloom · \(rose.datesThisMonth) of \(rose.monthlyGoal) this month"
        }
        return "\(rose.datesThisMonth) of \(rose.monthlyGoal) dates this month"
    }

    private var titleText: String {
        if rose.needsRevive { return "Your rose misses you" }
        if !rose.hasEverCompletedDate { return "Your rose" }
        return "Your rose"
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    RosePlantView(mode: rose.plantDisplayMode, size: 52)
                        .frame(width: 52, height: 52)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(titleText)
                            .font(Font.bodySans(13, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Text(progressText)
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.luxuryCreamMuted.opacity(0.8))
                }
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Button {
                showScienceInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted.opacity(0.65))
                    .frame(width: 36, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Why four dates a month")
            .padding(.trailing, 8)
        }
        .background(Color.luxuryMaroonLight.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accentMaroon.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showScienceInfo) {
            RoseScienceInfoSheet(monthlyGoal: rose.monthlyGoal)
        }
    }
}

// MARK: Why 4? — research-backed explainer (discrete info sheet)

struct RoseScienceInfoSheet: View {
    let monthlyGoal: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Why \(monthlyGoal) dates a month?")
                        .font(Font.bodySerif(22, weight: .regular))
                        .foregroundColor(Color.textPrimary)

                    Text("Your rose blooms as you complete intentional date nights together — one bud for each night, \(monthlyGoal) for full bloom.")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    scienceBlock(
                        title: "The research floor: 2+ nights/month",
                        body: "In a 2023 survey of 2,000 married couples, those who went on date nights at least once or twice a month reported higher marital happiness, communication satisfaction, and sexual satisfaction than couples who dated less often (National Marriage Project & Wheatley Institute, The Date Night Opportunity)."
                    )

                    scienceBlock(
                        title: "The stretch goal: ~1 night/week",
                        body: "Relationship researcher John Gottman recommends about six hours per week nurturing your relationship — including roughly two hours for a dedicated date night with open-ended conversation and no distractions."
                    )

                    scienceBlock(
                        title: "Why we chose \(monthlyGoal)",
                        body: "\(monthlyGoal) nights per month is about one intentional date a week — ambitious but achievable. Two nights still keeps your rose healthy; \(monthlyGoal) is full bloom."
                    )

                    Text("These studies show association, not a guarantee. Quality of attention matters as much as frequency.")
                        .font(Font.bodySans(12, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sources")
                            .font(Font.bodySans(11, weight: .semibold))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .tracking(0.8)
                        Text("• Wilcox & Dew, The Date Night Opportunity (2023)")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                        Text("• Gottman Institute, 6 Hours a Week to a Better Relationship")
                            .font(Font.bodySans(11, weight: .regular))
                            .foregroundColor(Color.luxuryMuted)
                    }
                }
                .padding(24)
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.luxuryGold)
                }
            }
            .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func scienceBlock(title: String, body: String) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(body)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
