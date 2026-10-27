import SwiftUI

// MARK: - Partner Ranking View
// Private ranking screen for both users. Rankings are hidden from each other
// until both submit. Supports tap-to-rank (1st → 2nd → 3rd).

struct PartnerRankingView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var partnerManager = PartnerSessionManager.shared

    @State private var rankAssignments: [Int: Int] = [:]  // planIndex → rankPosition
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var rankSubmitted = false
    @State private var showSubmitConfirm = false

    private var plans: [DatePlan] { coordinator.generatedPlans }

    private var allRanked: Bool {
        rankAssignments.count == plans.count
    }

    private var rankingsAsEntries: [RankEntry] {
        rankAssignments.map { RankEntry(planIndex: $0.key, rankPosition: $0.value) }
            .sorted { $0.rankPosition < $1.rankPosition }
    }

    var body: some View {
        ZStack {
            Color.ydgBase.ignoresSafeArea()

            if rankSubmitted {
                rankSubmittedView
            } else {
                rankingContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !rankSubmitted {
                    Button {
                        coordinator.dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.ydgTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .toolbarBackground(Color.ydgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: partnerManager.currentPhase) { phase in
            if phase == .finalOptionSelected {
                // Coordinator's phase observer will route to final reveal
            }
        }
    }

    // MARK: - Ranking content

    private var rankingContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: YDGSpace.lg) {
                    headerSection
                    rankingCards
                    Text("Tap a plan to give it the next rank. Tap the x to undo.")
                        .ydgText(.footnote, color: .ydgTextTertiary)
                    if let err = submitError {
                        Text(err)
                            .ydgText(.footnote, color: .ydgDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.md)
                .padding(.bottom, YDGSpace.xl)
            }
            submitBar
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text("Rank your favorites")
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)
            Label("Private until you've both submitted.", systemImage: "lock")
                .font(.ydg(.subhead))
                .foregroundColor(Color.ydgTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rankingCards: some View {
        VStack(spacing: YDGSpace.sm) {
            ForEach(Array(plans.enumerated()), id: \.offset) { index, plan in
                RankingOptionCard(
                    plan: plan,
                    planIndex: index + 1,
                    optionLabel: plan.optionLabel ?? "Option \(["A","B","C","D","E"][min(index, 4)])",
                    assignedRank: rankAssignments[index + 1],
                    isDisabled: isSubmitting
                ) {
                    assignRank(to: index + 1)
                } onClear: {
                    clearRank(for: index + 1)
                }
            }
        }
    }

    private var submitBar: some View {
        VStack(spacing: YDGSpace.xs) {
            Button {
                guard allRanked else { return }
                showSubmitConfirm = true
            } label: {
                Text(allRanked ? "Submit my rankings" : "Rank all \(plans.count) to submit")
            }
            .buttonStyle(YDGButtonStyle(kind: .primary, isLoading: isSubmitting))
            .disabled(!allRanked || isSubmitting)
            .animation(.easeInOut(duration: 0.2), value: allRanked)
            .confirmationDialog("Submit your rankings?", isPresented: $showSubmitConfirm, titleVisibility: .visible) {
                Button("Submit rankings") { submitRankings() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Once submitted, you won't be able to change your picks.")
            }
        }
        .padding(.horizontal, YDGSpace.margin)
        .padding(.top, YDGSpace.sm)
        .padding(.bottom, YDGSpace.md)
        .background(
            Color.ydgBase
                .overlay(alignment: .top) { Rectangle().fill(Color.ydgBorder).frame(height: 1) }
        )
    }

    // MARK: - Submitted / waiting state

    private var rankSubmittedView: some View {
        VStack(alignment: .leading, spacing: YDGSpace.md) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Color.ydgSuccess)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.ydgSuccess.opacity(0.15)))
                .accessibilityHidden(true)

            Text("Your rankings are in.")
                .ydgText(.title1)
                .accessibilityAddTraits(.isHeader)
            Text(partnerManager.currentPhase == .finalOptionSelected
                 ? "The final plan has been chosen. Reveal it now."
                 : "Waiting for your partner to rank their options.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if partnerManager.currentPhase == .waitingForPartnerRanking {
                waitingPulse
            }

            Spacer()

            if partnerManager.currentPhase == .finalOptionSelected {
                Button("Reveal your date plan") {
                    coordinator.loadFinalOptionAndShowReveal()
                }
                .buttonStyle(.ydgPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.margin)
        .padding(.bottom, YDGSpace.lg)
    }

    private var waitingPulse: some View {
        HStack(spacing: 6) {
            WaitingRingView()
                .frame(width: 28, height: 28)
            Text("Waiting for your partner…")
                .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
        }
    }

    // MARK: - Rank assignment logic

    private func assignRank(to planIndex: Int) {
        guard !isSubmitting else { return }
        let nextRank = (rankAssignments.values.max() ?? 0) + 1
        guard nextRank <= plans.count else {
            // All ranks full — clear this plan's rank and reassign
            clearRank(for: planIndex)
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rankAssignments[planIndex] = nextRank
        }
    }

    private func clearRank(for planIndex: Int) {
        guard !isSubmitting else { return }
        guard let removedRank = rankAssignments[planIndex] else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rankAssignments.removeValue(forKey: planIndex)
            // Shift down ranks above the removed one
            for key in rankAssignments.keys {
                if let r = rankAssignments[key], r > removedRank {
                    rankAssignments[key] = r - 1
                }
            }
        }
    }

    private func submitRankings() {
        guard allRanked else { return }
        isSubmitting = true
        submitError = nil
        partnerManager.submitRankings(rankingsAsEntries, plans: plans) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    withAnimation(.spring(response: 0.4)) { rankSubmitted = true }
                case .failure(let err):
                    submitError = "Couldn't save your rankings. Please try again. (\(err.localizedDescription))"
                }
            }
        }
    }

    // MARK: - Rank badge

    func rankBadgeView(rank: Int, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(rankColor(rank))
                .frame(width: size, height: size)
            Text("\(rank)")
                .font(Font.ydgSans(size * 0.4, weight: .bold))
                .foregroundColor(rank == 1 ? Color.ydgTextOnAccent : Color.ydgAccent)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.ydgAccent
        default: return Color.ydgAccentSubtle
        }
    }
}

// MARK: - Ranking Option Card

private struct RankingOptionCard: View {
    let plan: DatePlan
    let planIndex: Int
    let optionLabel: String
    let assignedRank: Int?
    let isDisabled: Bool
    let onTap: () -> Void
    let onClear: () -> Void

    private var isRanked: Bool { assignedRank != nil }

    private var stopNames: String {
        ItineraryPlanFormatting.itineraryStops(for: plan).prefix(3).map(\.name).joined(separator: " · ")
    }

    var body: some View {
        Button(action: isDisabled ? {} : onTap) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    if let rank = assignedRank {
                        Circle()
                            .fill(rank == 1 ? Color.ydgAccent : Color.clear)
                        Circle()
                            .stroke(Color.ydgAccent, lineWidth: 1.5)
                        Text("\(rank)")
                            .font(Font.ydgSans(16, weight: .bold))
                            .foregroundColor(rank == 1 ? Color.ydgTextOnAccent : Color.ydgAccent)
                    } else {
                        Circle()
                            .strokeBorder(Color.ydgBorderStrong, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    }
                }
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .ydgText(.callout, weight: .semibold)
                        .lineLimit(2)
                    Text(stopNames.isEmpty ? optionLabel : stopNames)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if isRanked {
                    Button(action: isDisabled ? {} : onClear) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.ydgTextTertiary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear rank")
                }
            }
            .padding(.leading, YDGSpace.md)
            .padding(.trailing, isRanked ? 4 : YDGSpace.md)
            .padding(.vertical, YDGSpace.sm)
            .frame(minHeight: 72)
            .background(isRanked ? Color.ydgAccentSubtle : Color.ydgRaised,
                        in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(isRanked ? Color.ydgAccent : Color.ydgBorder, lineWidth: isRanked ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: assignedRank)
        .accessibilityLabel("\(optionLabel): \(plan.title)")
        .accessibilityValue(assignedRank.map { "Ranked \($0)" } ?? "Not ranked")
    }
}


#Preview("Partner Ranking") {
    NavigationStack {
        PartnerRankingView()
            .environmentObject(NavigationCoordinator.shared)
    }
}
