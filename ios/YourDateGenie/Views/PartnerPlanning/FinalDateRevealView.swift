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
            Color.backgroundPrimary.ignoresSafeArea()

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
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
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
                .foregroundColor(Color.accentMaroon)

            Text("Your perfect date")
                .font(Font.displaySerif(38, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Text("Based on both your preferences and rankings")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
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
                .fill(Color.surfaceElevated)
                .shadow(color: Color.black.opacity(0.3), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentMaroon)
                .frame(width: 4)
                .padding(.vertical, 2)
        }
    }

    private func winnerCardHeader(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentMaroon)
                        Text("CHOSEN FOR YOU BOTH")
                            .font(Font.bodySans(10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color.textPrimary.opacity(0.7))
                    }
                    Text(plan.title)
                        .font(Font.displaySerif(28, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            if !plan.tagline.isEmpty {
                Text(plan.tagline)
                    .font(Font.bodySans(14, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
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
                    .foregroundColor(Color.textPrimary.opacity(0.5))
                ForEach(plan.stops.prefix(4), id: \.name) { stop in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.accentMaroon)
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.name)
                                .font(Font.bodySans(14, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            if !stop.description.isEmpty {
                                Text(stop.description)
                                    .font(Font.bodySans(12, weight: .regular))
                                    .foregroundColor(Color.textPrimary.opacity(0.6))
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.2))
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
                            .foregroundColor(Color.textPrimary.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
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
                        .foregroundColor(Color.accentMaroon)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why this plan")
                            .font(Font.bodySans(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color.textPrimary.opacity(0.6))
                            .textCase(.uppercase)
                        Text(reason)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.textPrimary.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color.surfaceElevated)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
        }
    }

    // MARK: - Actions

    private func actionsSection(plan: DatePlan) -> some View {
        VStack(spacing: 12) {
            // Single gold action for this screen.
            Button {
                confirmPlan(plan)
            } label: {
                HStack(spacing: 8) {
                    if isConfirming {
                        ProgressView().tint(Color.backgroundPrimary)
                    } else {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 18))
                        Text("Lock it in")
                            .font(Font.bodySans(16, weight: .semibold))
                    }
                }
                .foregroundColor(Color.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(isConfirming)

            // Secondary row (no gold — ghost / muted)
            HStack(spacing: 12) {
                Button {
                    savePlanForLater(plan)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14))
                        Text("Save for later")
                            .font(Font.bodySans(14, weight: .semibold))
                    }
                    .foregroundColor(Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.textPrimary.opacity(0.3), lineWidth: 1.5))
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
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.textPrimary.opacity(0.25), lineWidth: 1))
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
                        .foregroundColor(Color.textPrimary.opacity(0.6))
                    Spacer()
                    Image(systemName: showRunnerUp ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textPrimary.opacity(0.6))
                }
                .padding(14)
                .background(Color.surfaceElevated)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showRunnerUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    if !plan.tagline.isEmpty {
                        Text(plan.tagline)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.textPrimary.opacity(0.6))
                            .lineLimit(3)
                    }
                }
                .padding(14)
                .background(Color.surfaceElevated.opacity(0.6))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.textPrimary.opacity(0.7))
            Text("Loading your final plan…")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
        }
        .padding(.top, 60)
    }

    private var loadingErrorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(Color.textPrimary.opacity(0.5))
            Text("Couldn't load your date plan")
                .font(Font.displaySerif(26, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Check your connection and try again, or go back and retry.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
            Button {
                coordinator.dismissSheet()
            } label: {
                Text("Go back")
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentGold)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }

    // MARK: - Actions

    /// Confirm the winning plan: write it to the calendar with reminders (screen 11f),
    /// finalize the session, then route to the "locked in" confirmation (screen 15).
    private func confirmPlan(_ plan: DatePlan) {
        isConfirming = true
        PartnerSessionManager.shared.transitionPhase(to: .finalized, triggeredBy: "user")
        let chosenDate = chosenDate(for: plan)
        // Persist the matched night server-side so the partner's device schedules the SAME evening.
        if let sessionId = PartnerSessionManager.shared.sessionId {
            let label = PartnerSessionManager.shared.inviteInfo?.proposedDateTimes?
                .first(where: { Calendar.current.isDate($0.date, inSameDayAs: chosenDate) })?.timeLabel
            Task {
                try? await SupabaseService.shared.updatePartnerSessionMatchedNight(
                    sessionId: sessionId, date: chosenDate, label: label
                )
            }
        }
        Task {
            let result = await CalendarSyncManager.shared.addDatePlan(plan, on: chosenDate, withReminders: true)
            let synced: Bool
            if case .success = result { synced = true } else { synced = false }
            var finalized = plan
            finalized.scheduledDate = chosenDate
            await MainActor.run {
                isConfirming = false
                NotificationManager.shared.addNotification(AppNotification(
                    type: .planConfirmed,
                    title: "Your date plan is confirmed.",
                    message: synced
                        ? "It's on your calendar — reminders set for you both."
                        : "Make it magical — it's all planned out.",
                    timestamp: Date()
                ))
                // Route to the locked-in confirmation (screen 15) with the synced state.
                coordinator.presentLockedIn(plan: finalized, calendarSynced: synced)
            }
        }
    }

    /// Resolve the evening the couple matched on, falling back to the first proposed slot.
    private func chosenDate(for plan: DatePlan) -> Date {
        if let scheduled = plan.scheduledDate { return scheduled }
        if let proposed = PartnerSessionManager.shared.inviteInfo?.proposedDateTimes?.first?.date {
            return proposed
        }
        let cal = Calendar.current
        let nextSat = cal.nextDate(after: Date(), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? Date()
        return cal.date(bySettingHour: 19, minute: 0, second: 0, of: nextSat) ?? nextSat
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
