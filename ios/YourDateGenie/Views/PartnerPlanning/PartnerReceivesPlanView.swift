import SwiftUI

// MARK: - Partner Receives Plan View (screen 16)
// The delight moment on the *partner's* device: their partner planned the date,
// and here it is. They add it to their own calendar (reminders for both sides).
// Charcoal Maroon: one gold highlight (add to my calendar / done).

struct PartnerReceivesPlanView: View {
    let plan: DatePlan
    let inviterName: String?

    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cardScale: CGFloat = 0.85
    @State private var cardOpacity: Double = 0
    @State private var confettiPieces: [PartnerReceivesConfettiPiece] = []
    @State private var calendarState: CalendarState = .idle

    private enum CalendarState: Equatable {
        case idle
        case adding
        case added
        case failed
    }

    private var inviterDisplayName: String {
        let name = (inviterName ?? "").trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your partner" : name
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

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
                    Color.clear.onAppear { spawnConfetti(in: geo.size); animateConfetti(in: geo.size) }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    planCard
                        .scaleEffect(cardScale)
                        .opacity(cardOpacity)
                    calendarStatusRow
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    coordinator.dismissToHome()
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
            if reduceMotion {
                cardScale = 1.0
                cardOpacity = 1.0
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1)) {
                    cardScale = 1.0
                    cardOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.accentMaroon, lineWidth: 2)
                    .frame(width: 80, height: 80)
                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.accentMaroon)
            }

            Text("\(inviterDisplayName) planned a date for you")
                .font(Font.displaySerif(32, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("You both ranked your favorites — here's the night you matched on.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Plan card (cream itinerary card, maroon left border)

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                if let scheduledLabel = scheduledLabel {
                    Text(scheduledLabel.uppercased())
                        .font(Font.bodySans(11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color.textMutedOnCard)
                }
                Text(plan.title)
                    .font(Font.displaySerif(26, weight: .bold))
                    .foregroundColor(Color.textOnCard)
                    .fixedSize(horizontal: false, vertical: true)
                if !plan.tagline.isEmpty {
                    Text(plan.tagline)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.textMutedOnCard)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !plan.stops.isEmpty {
                Divider().background(Color.textOnCard.opacity(0.12))
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(plan.stops.prefix(4), id: \.name) { stop in
                        HStack(alignment: .top, spacing: 10) {
                            Text(stop.timeSlot)
                                .font(Font.bodySans(11, weight: .semibold))
                                .foregroundColor(Color.accentMaroon)
                                .frame(width: 56, alignment: .leading)
                            Text(stop.name)
                                .font(Font.bodySans(13, weight: .medium))
                                .foregroundColor(Color.textOnCard)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.creamCard)
        .cornerRadius(18)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentMaroon)
                .frame(width: 4)
                .padding(.vertical, 6)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 14, y: 6)
    }

    private var scheduledLabel: String? {
        guard let date = plan.scheduledDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Calendar status

    @ViewBuilder
    private var calendarStatusRow: some View {
        switch calendarState {
        case .idle, .adding:
            EmptyView()
        case .added:
            statusCard(
                icon: "calendar.badge.checkmark",
                tint: Color.luxurySuccess,
                title: "Added to your calendar",
                subtitle: "Reminders set the night before and a few hours ahead."
            )
        case .failed:
            statusCard(
                icon: "calendar.badge.exclamationmark",
                tint: Color.textPrimary.opacity(0.6),
                title: "Couldn't reach your calendar",
                subtitle: "Turn on Calendar access in Settings to add reminders."
            )
        }
    }

    private func statusCard(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(subtitle)
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceElevated)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Actions (single gold highlight)

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if calendarState == .added {
                Button {
                    coordinator.dismissToHome()
                } label: {
                    Text("Can't wait")
                        .font(Font.bodySans(16, weight: .semibold))
                        .foregroundColor(Color.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentGold)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    addToCalendar()
                } label: {
                    HStack(spacing: 8) {
                        if calendarState == .adding {
                            ProgressView().tint(Color.backgroundPrimary)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))
                            Text("Add to my calendar")
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
                .disabled(calendarState == .adding)

                Button {
                    coordinator.dismissToHome()
                } label: {
                    Text("Maybe later")
                        .font(Font.bodySans(15, weight: .semibold))
                        .foregroundColor(Color.textPrimary.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.textPrimary.opacity(0.3), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Logic

    private func addToCalendar() {
        calendarState = .adding
        let date = plan.scheduledDate ?? fallbackDate()
        Task {
            let result = await CalendarService.addDatePlan(plan, on: date, withReminders: true)
            await MainActor.run {
                switch result {
                case .success:
                    calendarState = .added
                case .denied, .failed:
                    calendarState = .failed
                }
            }
        }
    }

    private func fallbackDate() -> Date {
        let cal = Calendar.current
        let nextSat = cal.nextDate(after: Date(), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) ?? Date()
        return cal.date(bySettingHour: 19, minute: 0, second: 0, of: nextSat) ?? nextSat
    }

    // MARK: - Confetti

    private func spawnConfetti(in size: CGSize) {
        let colors: [Color] = [.luxuryGold, .luxuryGoldLight, .luxuryCream, .luxuryMaroonLight, .luxuryGoldDark]
        confettiPieces = (0..<45).map { i in
            PartnerReceivesConfettiPiece(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                y: -CGFloat.random(in: 10...50),
                w: CGFloat.random(in: 4...10),
                h: CGFloat.random(in: 3...7),
                color: colors.randomElement() ?? .luxuryGold,
                rotation: 0,
                opacity: 0.95
            )
        }
    }

    private func animateConfetti(in size: CGSize) {
        guard !confettiPieces.isEmpty else { return }
        withAnimation(.easeIn(duration: 2.4)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y = size.height + CGFloat.random(in: 20...80)
                confettiPieces[i].x += CGFloat.random(in: -70...70)
                confettiPieces[i].rotation = Double.random(in: 180...720)
            }
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
            for i in confettiPieces.indices {
                confettiPieces[i].opacity = 0
            }
        }
    }
}

private struct PartnerReceivesConfettiPiece: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
}

#Preview("Partner Receives") {
    NavigationStack {
        PartnerReceivesPlanView(plan: DatePlan.sample, inviterName: "Anjela")
            .environmentObject(NavigationCoordinator.shared)
    }
}
