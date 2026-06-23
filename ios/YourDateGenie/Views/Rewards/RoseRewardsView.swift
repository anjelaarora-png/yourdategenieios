import SwiftUI

// MARK: - Rose Rewards — self-contained entry point (Phase 3 · G1–G5)
//
// Presentable container that owns its own NavigationStack and routes between the
// five rose screens. It deliberately does NOT touch shared navigation
// (NavigationCoordinator / MainAppView) so it can be merged without conflicts —
// the parent wires it in during integration (see CHARCOAL_MAROON_ROLLOUT note).
//
// Flow:
//   root = needsRevive ? G2 (revive) : G1 (your rose)
//   G1 → push G3 (journey) / G5 (recap)
//   completing a night may unlock G4 (variable reward) as a full-screen cover.
//
// Integration hooks (all optional — sensible self-contained demo defaults):
//   • onPlanDate     — open the real plan/questionnaire flow for a new night
//   • onPlanReward   — plan a specific unlocked hidden date
//   • onReviveTonight — start the low-key at-home flow
//   • partnerName    — name shown on the shared rose ("with Maya")

struct RoseRewardsView: View {
    @StateObject private var rose = RoseManager.shared

    var partnerName: String?
    var onPlanDate: (() -> Void)?
    var onPlanReward: ((HiddenDateReward) -> Void)?
    var onReviveTonight: ((ReviveIdea) -> Void)?

    @State private var path: [RoseRoute] = []
    @State private var shareText: ShareItem?

    enum RoseRoute: Hashable { case journey, recap }

    var body: some View {
        NavigationStack(path: $path) {
            rootScreen
                .navigationDestination(for: RoseRoute.self) { route in
                    switch route {
                    case .journey:
                        RoseJourneyView(rose: rose, onPlanNight: planNight)
                    case .recap:
                        RoseMonthlyRecapView(recap: rose.monthlyRecap) { recap in
                            shareText = ShareItem(text: shareCopy(recap))
                        }
                    }
                }
        }
        .tint(Color.accentGold)
        .fullScreenCover(item: $rose.pendingReward) { reward in
            NavigationStack {
                RoseRewardUnlockedView(
                    reward: reward,
                    partnerName: rose.partnerName,
                    onPlan: { reward in
                        rose.clearPendingReward()
                        if let onPlanReward { onPlanReward(reward) } else { planNight() }
                    },
                    onSaveForLater: { rose.clearPendingReward() }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { rose.clearPendingReward() }
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(item: $shareText) { item in
            RoseShareSheet(activityItems: [item.text])
        }
        .onAppear { if let partnerName { rose.partnerName = partnerName } }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var rootScreen: some View {
        if rose.needsRevive {
            RoseReviveView(
                rose: rose,
                onRevive: { idea in onReviveTonight?(idea) },
                onRemindLater: {}
            )
        } else {
            YourRoseView(
                rose: rose,
                onOpenNextBud: planNight,
                onShowJourney: { path.append(.journey) },
                onShowRecap: { path.append(.recap) }
            )
        }
    }

    /// Either hand off to the real plan flow, or (standalone) advance the rose locally.
    private func planNight() {
        if let onPlanDate {
            onPlanDate()
        } else {
            rose.completeDate()
        }
    }

    private func shareCopy(_ recap: RoseMonthlyRecap) -> String {
        "Our \(recap.monthName) together 💛 — \(recap.nightsOut) nights out, \(recap.newPlaces) new places, a \(recap.streakWeeks)-week streak. Planned with Your Date Genie 🌹"
    }
}

// MARK: - Share plumbing (self-contained)

private struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

private struct RoseShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#if DEBUG
struct RoseRewardsView_Previews: PreviewProvider {
    static var previews: some View {
        RoseRewardsView(partnerName: "Maya")
    }
}
#endif
