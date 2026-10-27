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
            // The app's one signature gradient (Final design): a warm rose glow behind the reveal.
            RadialGradient(
                colors: [Color(hex: "4A2328"), Color(hex: "2A1A1C"), Color.ydgBase],
                center: UnitPoint(x: 0.5, y: 0.18),
                startRadius: 0,
                endRadius: 520
            )
            .ignoresSafeArea()

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
                VStack(spacing: YDGSpace.lg) {
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
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.md)
                .padding(.bottom, YDGSpace.xxl)
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
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
        VStack(spacing: YDGSpace.sm) {
            Label("Chosen for you both", systemImage: "heart.fill")
                .font(Font.ydgSans(13, weight: .semibold))
                .foregroundColor(Color.ydgTextPrimary)
                .labelStyle(RoseIconLabelStyle())
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(Capsule().fill(Color.ydgHighlight.opacity(0.15)))
                .overlay(Capsule().stroke(Color.ydgHighlight.opacity(0.4), lineWidth: 1))

            if let plan = winningPlan {
                Text(plan.title)
                    .ydgText(.display)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(ItineraryPlanFormatting.metaLine(for: plan))
                    .ydgText(.body, color: Color(hex: "E0C9C2"))
                    .multilineTextAlignment(.center)
            } else {
                Text("Your perfect date")
                    .ydgText(.display)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, YDGSpace.xxl)
    }

    // MARK: - Winner card

    private func winnerCard(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ItineraryCompactStopList(stops: Array(ItineraryPlanFormatting.itineraryStops(for: plan).prefix(4)))
                .padding(.bottom, 4)
            winnerCardHints(plan: plan)
        }
        .background(Color.ydgBase.opacity(0.7), in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                .stroke(Color(hex: "4A3436"), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func winnerCardHints(plan: DatePlan) -> some View {
        let hints = Array(plan.packingList.prefix(4))
        if !hints.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bring")
                    .ydgText(.caption, color: .ydgTextTertiary)
                Text(hints.joined(separator: " · "))
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(YDGSpace.md)
            .overlay(alignment: .top) { Rectangle().fill(Color(hex: "4A3436")).frame(height: 1) }
        }
    }

    // MARK: - Selection reason

    private var selectionReasonCard: some View {
        Group {
            if let reason = coordinator.finalOptionSelection?.selectionReason {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why this one")
                        .ydgText(.caption, color: .ydgHighlight)
                    Text(reason)
                        .ydgText(.subhead, weight: .regular, color: Color(hex: "E0C9C2"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Actions

    private func actionsSection(plan: DatePlan) -> some View {
        VStack(spacing: YDGSpace.xxs) {
            Button {
                confirmPlan(plan)
            } label: {
                Text("Lock it in")
            }
            .buttonStyle(YDGButtonStyle(kind: .primary, isLoading: isConfirming))
            .disabled(isConfirming)

            HStack(spacing: YDGSpace.lg) {
                Button("Save for later") { savePlanForLater(plan) }
                    .buttonStyle(.ydgTertiary)
                Button("New options") { regenerate() }
                    .buttonStyle(.ydgTertiary)
            }
        }
        .padding(.top, YDGSpace.xs)
    }

    // MARK: - Runner-up

    private func runnerUpSection(plan: DatePlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showRunnerUp.toggle() }
            } label: {
                HStack {
                    Text("See the backup option")
                        .ydgText(.subhead, weight: .semibold, color: .ydgTextSecondary)
                    Spacer()
                    Image(systemName: showRunnerUp ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textPrimary.opacity(0.6))
                }
                .padding(14)
                .background(Color.ydgBase.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.luxeSurfaceTint, lineWidth: 1))
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
                .font(Font.ydgDisplay(26))
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
                    .background(Capsule().fill(Color.ydgAccent))
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

/// Rose icon + cream title (reveal badge).
private struct RoseIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
                .font(.system(size: 12))
                .foregroundColor(Color.ydgHighlight)
            configuration.title
        }
    }
}
