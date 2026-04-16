import SwiftUI

// MARK: - Final Date Reveal View
// The premium winner-reveal screen shown to both users once rankings are complete.

struct FinalDateRevealView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var partnerManager = PartnerSessionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hasRevealed = false
    @State private var revealScale: CGFloat = 0.85
    @State private var revealOpacity: Double = 0
    @State private var confettiPieces: [RevealConfettiPiece] = []
    @State private var showRunnerUp = false
    @State private var isConfirming = false
    @State private var loadingTimedOut = false
    @State private var loadingTimeoutTask: Task<Void, Never>?

    private var winningPlan: DatePlan? {
        guard let sel = coordinator.finalOptionSelection,
              sel.winningPlanIndex >= 1,
              sel.winningPlanIndex - 1 < coordinator.generatedPlans.count else {
            return coordinator.generatedPlans.first
        }
        return coordinator.generatedPlans[sel.winningPlanIndex - 1]
    }

    private var runnerUpPlan: DatePlan? {
        guard let sel = coordinator.finalOptionSelection,
              let idx = sel.runnerUpPlanIndex,
              idx >= 1,
              idx - 1 < coordinator.generatedPlans.count else { return nil }
        return coordinator.generatedPlans[idx - 1]
    }

    var body: some View {
        ZStack {
            Color.luxuryMaroon.ignoresSafeArea()
            FloatingParticlesView().ignoresSafeArea().opacity(0.5)

            // Confetti layer (decorative, skipped when Reduce Motion is on)
            if !reduceMotion {
                GeometryReader { geo in
                    ForEach(confettiPieces) { piece in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(piece.color)
                            .frame(width: piece.w, height: piece.h)
                            .rotationEffect(.degrees(piece.rotation))
                            .position(x: piece.x, y: piece.y)
                            .opacity(piece.opacity)
                    }
                    Color.clear.onAppear { spawnConfetti(in: geo.size) }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    if let plan = winningPlan {
                        winnerCard(plan: plan)
                            .scaleEffect(revealScale)
                            .opacity(revealOpacity)
                        selectionReasonCard
                        actionsSection(plan: plan)
                        if let runner = runnerUpPlan {
                            runnerUpSection(plan: runner)
                        }
                    } else if loadingTimedOut {
                        loadingErrorState
                    } else {
                        loadingState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    coordinator.dismissSheet()
                    PartnerSessionManager.shared.clearSession()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
        .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if reduceMotion {
                    revealScale = 1.0
                    revealOpacity = 1.0
                } else {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                        revealScale = 1.0
                        revealOpacity = 1.0
                    }
                    animateConfetti()
                }
            }
            if winningPlan == nil {
                loadingTimeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 15_000_000_000)
                    await MainActor.run {
                        if winningPlan == nil { loadingTimedOut = true }
                    }
                }
            }
        }
        .onDisappear {
            loadingTimeoutTask?.cancel()
        }
        .onChange(of: winningPlan == nil) { _, isNil in
            if !isNil { loadingTimeoutTask?.cancel() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(Color.luxuryGold)
                .shadow(color: Color.luxuryGold.opacity(0.5), radius: 12)

            Text("Your Perfect Date")
                .font(Font.tangerine(48, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)

            Text("Based on both your preferences and rankings")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Winner card

    private func winnerCard(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            winnerCardHeader(plan: plan)
            winnerCardStops(plan: plan)
            winnerCardHints(plan: plan)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.luxuryMaroonLight)
                .shadow(color: Color.luxuryGold.opacity(0.2), radius: 20, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.luxuryGold.opacity(0.5), lineWidth: 1.5)
        )
    }

    private func winnerCardHeader(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.luxuryGold)
                        Text("CHOSEN FOR YOU BOTH")
                            .font(Font.bodySans(10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color.luxuryGold.opacity(0.8))
                    }
                    Text(plan.title)
                        .font(Font.tangerine(32, weight: .bold))
                        .italic()
                        .foregroundColor(Color.luxuryCream)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            if !plan.tagline.isEmpty {
                Text(plan.tagline)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func winnerCardStops(plan: DatePlan) -> some View {
        if !plan.stops.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR EVENING")
                    .font(Font.bodySans(10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color.luxuryGold.opacity(0.7))
                ForEach(plan.stops.prefix(4), id: \.name) { stop in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.luxuryGold)
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.name)
                                .font(Font.bodySans(14, weight: .semibold))
                                .foregroundColor(Color.luxuryCream)
                            if !stop.description.isEmpty {
                                Text(stop.description)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.luxuryCreamMuted)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.luxuryMaroon.opacity(0.5))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func winnerCardHints(plan: DatePlan) -> some View {
        let hints = Array(plan.packingList.prefix(4))
        if !hints.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hints, id: \.self) { hint in
                        Text(hint)
                            .font(Font.bodySans(11, weight: .semibold))
                            .foregroundColor(Color.luxuryGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.luxuryGold.opacity(0.12))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Selection reason

    private var selectionReasonCard: some View {
        Group {
            if let reason = coordinator.finalOptionSelection?.selectionReason {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(Color.luxuryGold)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why this plan")
                            .font(Font.bodySans(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color.luxuryGold.opacity(0.8))
                            .textCase(.uppercase)
                        Text(reason)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color.luxuryMaroonLight.opacity(0.6))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: - Actions

    private func actionsSection(plan: DatePlan) -> some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button {
                confirmPlan(plan)
            } label: {
                HStack(spacing: 8) {
                    if isConfirming {
                        ProgressView().tint(Color.luxuryMaroon)
                    } else {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 18))
                        Text("Confirm This Plan")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                }
                .foregroundColor(Color.luxuryMaroon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.goldShimmer)
                .cornerRadius(16)
                .shadow(color: Color.luxuryGold.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isConfirming)

            // Secondary row
            HStack(spacing: 12) {
                Button {
                    savePlanForLater(plan)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14))
                        Text("Save for Later")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold, lineWidth: 1.5))
                }
                .buttonStyle(.plain)

                Button {
                    regenerate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text("Regenerate")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .foregroundColor(Color.luxuryCreamMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryCreamMuted.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Runner-up

    private func runnerUpSection(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showRunnerUp.toggle() }
            } label: {
                HStack {
                    Text("Backup option")
                        .font(Font.bodySans(13, weight: .semibold))
                        .foregroundColor(Color.luxuryCreamMuted)
                    Spacer()
                    Image(systemName: showRunnerUp ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.luxuryCreamMuted)
                }
                .padding(14)
                .background(Color.luxuryMaroonLight.opacity(0.4))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showRunnerUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    if !plan.tagline.isEmpty {
                        Text(plan.tagline)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.luxuryCreamMuted)
                            .lineLimit(3)
                    }
                }
                .padding(14)
                .background(Color.luxuryMaroonLight.opacity(0.3))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxuryGold.opacity(0.15), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.luxuryGold)
            Text("Loading your final plan…")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .padding(.top, 60)
    }

    private var loadingErrorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(Color.luxuryGold.opacity(0.7))
            Text("Couldn't load your date plan")
                .font(Font.tangerine(28, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)
            Text("Check your connection and try again, or go back and retry.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .multilineTextAlignment(.center)
            Button {
                coordinator.dismissSheet()
            } label: {
                Text("Go Back")
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.goldShimmer)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }

    // MARK: - Actions

    private func confirmPlan(_ plan: DatePlan) {
        isConfirming = true
        PartnerSessionManager.shared.transitionPhase(to: .finalized, triggeredBy: "user")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isConfirming = false
            coordinator.dismissSheet()
            coordinator.currentDatePlan = plan
            coordinator.generatedPlans = [plan]
            coordinator.activeSheet = .datePlanOptions
            NotificationManager.shared.addNotification(AppNotification(
                type: .planConfirmed,
                title: "Your date plan is confirmed.",
                message: "Make it magical — it's all planned out.",
                timestamp: Date()
            ))
        }
    }

    private func savePlanForLater(_ plan: DatePlan) {
        coordinator.savedPlans.append(plan)
        coordinator.dismissSheet()
    }

    private func regenerate() {
        // Clear session ranking state and restart from preferences_complete
        PartnerSessionManager.shared.transitionPhase(to: .preferencesComplete, triggeredBy: "user")
        coordinator.finalOptionSelection = nil
        coordinator.dismissSheet()
        coordinator.partnerDataReceivedMergeAndGenerate()
    }

    // MARK: - Confetti

    private func spawnConfetti(in size: CGSize) {
        let colors: [Color] = [.luxuryGold, .luxuryGoldLight, .luxuryCream, .luxuryMaroonLight, Color(hex: "FFD700")]
        confettiPieces = (0..<50).map { i in
            RevealConfettiPiece(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                y: -CGFloat.random(in: 10...60),
                w: CGFloat.random(in: 5...12),
                h: CGFloat.random(in: 3...8),
                color: colors.randomElement() ?? .luxuryGold,
                rotation: 0,
                opacity: 0.9
            )
        }
    }

    private func animateConfetti() {
        guard !confettiPieces.isEmpty else { return }
        withAnimation(.easeIn(duration: 2.5)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y += UIScreen.main.bounds.height + 100
                confettiPieces[i].x += CGFloat.random(in: -80...80)
                confettiPieces[i].rotation = Double.random(in: 180...540)
            }
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
            for i in confettiPieces.indices {
                confettiPieces[i].opacity = 0
            }
        }
    }
}

private struct RevealConfettiPiece: Identifiable {
    let id: Int
    var x, y, w, h: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
}

#Preview("Final Reveal") {
    NavigationStack {
        FinalDateRevealView()
            .environmentObject(NavigationCoordinator.shared)
    }
}
