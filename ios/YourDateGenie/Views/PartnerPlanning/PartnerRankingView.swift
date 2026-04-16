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
            Color.luxuryMaroon.ignoresSafeArea()
            FloatingParticlesView().ignoresSafeArea().opacity(0.4)

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
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.luxuryGold)
                    }
                }
            }
        }
        .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
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
                VStack(spacing: 28) {
                    headerSection
                    privacyBadge
                    rankingInstructions
                    rankingCards
                    if let err = submitError {
                        Text(err)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color(hex: "FF6B6B"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            submitBar
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Rank Your Options")
                .font(Font.tangerine(40, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            Text("Your picks are private until you both submit")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var privacyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(Color.luxuryGold)
            Text("Rankings revealed only after both submit")
                .font(Font.bodySans(11, weight: .semibold))
                .foregroundColor(Color.luxuryGold.opacity(0.85))
                .tracking(0.5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.luxuryGold.opacity(0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
    }

    private var rankingInstructions: some View {
        HStack(spacing: 16) {
            ForEach(1...min(3, plans.count), id: \.self) { rank in
                VStack(spacing: 4) {
                    rankBadgeView(rank: rank, size: 32)
                    Text(rank == 1 ? "Top pick" : rank == 2 ? "2nd" : "3rd")
                        .font(Font.bodySans(11, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
            }
            Spacer()
            Text("Tap a card to assign rank")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 4)
    }

    private var rankingCards: some View {
        VStack(spacing: 14) {
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
        VStack(spacing: 12) {
            if !allRanked && !plans.isEmpty {
                Text("Rank all \(plans.count) options to continue")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
            }
            Button {
                guard allRanked else { return }
                showSubmitConfirm = true
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color.luxuryMaroon)
                            .accessibilityLabel("Submitting rankings")
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(allRanked ? "Submit My Rankings" : "Rank all options first")
                                .font(Font.bodySans(16, weight: .semibold))
                        }
                    }
                }
                .foregroundColor(allRanked ? Color.luxuryMaroon : Color.luxuryCreamMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(allRanked ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.luxuryMaroonLight], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: allRanked ? Color.luxuryGold.opacity(0.35) : Color.clear, radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!allRanked || isSubmitting)
            .animation(.easeInOut(duration: 0.2), value: allRanked)
            .confirmationDialog("Submit your rankings?", isPresented: $showSubmitConfirm, titleVisibility: .visible) {
                Button("Submit Rankings") { submitRankings() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Once submitted, you won't be able to change your picks.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.luxuryMaroon.shadow(color: Color.black.opacity(0.3), radius: 10, y: -5))
    }

    // MARK: - Submitted / waiting state

    private var rankSubmittedView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.luxuryGold)
            }

            VStack(spacing: 12) {
                Text("Your rankings are in.")
                    .font(Font.tangerine(38, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
                Text(partnerManager.currentPhase == .finalOptionSelected
                     ? "The final plan has been chosen — reveal it now."
                     : "Waiting for your partner to rank their options.")
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if partnerManager.currentPhase == .waitingForPartnerRanking {
                waitingPulse
            }

            if partnerManager.currentPhase == .finalOptionSelected {
                Button {
                    coordinator.loadFinalOptionAndShowReveal()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 18))
                        Text("Reveal Your Date Plan")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(16)
                    .shadow(color: Color.luxuryGold.opacity(0.35), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private var waitingPulse: some View {
        HStack(spacing: 6) {
            WaitingRingView()
                .frame(width: 28, height: 28)
            Text("Waiting for partner…")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
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
                .font(Font.bodySans(size * 0.4, weight: .bold))
                .foregroundColor(rank == 1 ? Color.luxuryMaroon : Color.luxuryCream)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.luxuryGold
        case 2: return Color.luxuryGoldLight.opacity(0.7)
        default: return Color.luxuryMaroonLight
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

    var body: some View {
        Button(action: isDisabled ? {} : onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Rank badge or empty circle
                ZStack {
                    Circle()
                        .stroke(isRanked ? rankBorderColor : Color.luxuryGold.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                    if let rank = assignedRank {
                        Circle()
                            .fill(rankFillColor(rank))
                            .frame(width: 40, height: 40)
                        Text("\(rank)")
                            .font(Font.bodySans(16, weight: .bold))
                            .foregroundColor(rank == 1 ? Color.luxuryMaroon : Color.luxuryCream)
                    } else {
                        Text(optionLabel)
                            .font(Font.bodySans(13, weight: .semibold))
                            .foregroundColor(Color.luxuryGold.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(isRanked ? Color.luxuryCream : Color.luxuryCream.opacity(0.9))
                        .lineLimit(2)

                    if !plan.tagline.isEmpty {
                        Text(plan.tagline)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineLimit(2)
                    }

                    if !plan.packingList.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(plan.packingList.prefix(3), id: \.self) { hint in
                                    Text(hint)
                                        .font(Font.bodySans(10, weight: .semibold))
                                        .foregroundColor(Color.luxuryGold.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.luxuryGold.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Spacer()

                if isRanked {
                    Button(action: isDisabled ? {} : onClear) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(Color.luxuryCreamMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isRanked ? Color.luxuryMaroonLight : Color.luxuryMaroonLight.opacity(0.5))
                    .shadow(color: isRanked ? Color.luxuryGold.opacity(0.15) : Color.clear, radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isRanked ? rankBorderColor : Color.luxuryGold.opacity(0.2), lineWidth: isRanked ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: assignedRank)
    }

    private var rankBorderColor: Color {
        guard let rank = assignedRank else { return Color.luxuryGold.opacity(0.2) }
        switch rank {
        case 1: return Color.luxuryGold
        case 2: return Color.luxuryGoldLight.opacity(0.7)
        default: return Color.luxuryGold.opacity(0.4)
        }
    }

    private func rankFillColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.luxuryGold
        case 2: return Color.luxuryGoldLight.opacity(0.6)
        default: return Color.luxuryMaroonLight
        }
    }
}


#Preview("Partner Ranking") {
    NavigationStack {
        PartnerRankingView()
            .environmentObject(NavigationCoordinator.shared)
    }
}
