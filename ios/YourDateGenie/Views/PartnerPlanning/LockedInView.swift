import SwiftUI

// MARK: - Locked In View (screen 15)
// Payoff screen shown after the couple confirms their date. The plan is on the
// calendar with reminders set, and we hand the user a pre-drafted love note they
// can copy/share to their partner. Charcoal Maroon: one gold highlight (copy note).

struct LockedInView: View {
    let plan: DatePlan
    /// Whether the plan was successfully written to the system calendar.
    let calendarSynced: Bool

    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var partnerManager = PartnerSessionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sealScale: CGFloat = 0.7
    @State private var sealOpacity: Double = 0
    @State private var didCopyNote = false
    @State private var noteText: String = ""

    private var partnerDisplayName: String {
        let name = (partnerManager.inviteInfo?.partnerName ?? "").trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your partner" : name
    }

    var body: some View {
        ZStack {
            Color.ydgBase.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: YDGSpace.lg) {
                    sealSection
                    statusCard
                    draftedNoteSection
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.md)
                .padding(.bottom, YDGSpace.xl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionsSection
                .padding(.horizontal, YDGSpace.margin)
                .padding(.bottom, YDGSpace.xs)
                .background(Color.ydgBase)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    coordinator.dismissToHome()
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
        .toolbarBackground(Color.ydgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if noteText.isEmpty { noteText = Self.draftLoveNote(for: plan) }
            if reduceMotion {
                sealScale = 1.0
                sealOpacity = 1.0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    sealScale = 1.0
                    sealOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Seal / header

    private var sealSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Color.ydgSuccess)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.ydgSuccess.opacity(0.15)))
                .scaleEffect(sealScale)
                .opacity(sealOpacity)
                .accessibilityHidden(true)

            Text("Locked in.")
                .ydgText(.display)
                .accessibilityAddTraits(.isHeader)

            Text("It's settled. No more back-and-forth texts.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, YDGSpace.xl)
    }

    // MARK: - Status card (calendar + booking nudge, design 4.7)

    /// First stop that still needs a table — the one worth nudging about.
    private var unbookedStop: DatePlanStop? {
        plan.stops.first { ItineraryPlanFormatting.isReservable($0) }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            statusRow(
                systemImage: calendarSynced ? "calendar" : "calendar.badge.exclamationmark",
                title: calendarSynced ? "On both your calendars" : "Saved to your plans",
                detail: calendarSynced
                    ? "Reminders the night before and a few hours ahead."
                    : "Turn on Calendar access to get reminders for you both."
            )
            if let stop = unbookedStop {
                YDGListDivider(leadingInset: 52)
                HStack(spacing: 0) {
                    statusRow(
                        systemImage: "bookmark",
                        title: "\(stop.name) isn't booked yet",
                        detail: "Tables go fast. Grab one now."
                    )
                    Button("Book") {
                        coordinator.reservationPlatformPickerPayload = ReservationPlatformPickerPayload(
                            venueName: stop.name,
                            phoneNumber: stop.phoneNumber,
                            address: stop.address,
                            reservationPlatforms: stop.reservationPlatforms,
                            bookingUrl: stop.bookingUrl
                        )
                    }
                    .buttonStyle(.ydgTertiary)
                    .padding(.trailing, YDGSpace.sm)
                }
            }
        }
        .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                .stroke(Color.ydgBorder, lineWidth: 1)
        )
    }

    private func statusRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: YDGSpace.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundColor(calendarSynced || systemImage == "bookmark" ? Color.ydgTextPrimary : Color.ydgTextSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .ydgText(.subhead, weight: .semibold)
                Text(detail)
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(YDGSpace.md)
    }

    // MARK: - Drafted note

    private var draftedNoteSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.sm) {
            Text("A note for \(partnerDisplayName), ready to send")
                .ydgText(.caption, color: .ydgHighlight)

            Text(noteText)
                .font(.ydgDisplay(19, weight: .regular).italic())
                .foregroundColor(Color.ydgTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ydgHighlightSubtle, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        }
    }

    // MARK: - Actions (single gold highlight = copy note)

    private var actionsSection: some View {
        VStack(spacing: YDGSpace.sm) {
            Button {
                copyNote()
            } label: {
                Label(didCopyNote ? "Copied. Paste it to \(partnerDisplayName)" : "Copy note for \(partnerDisplayName)",
                      systemImage: didCopyNote ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(YDGButtonStyle(kind: .secondary))

            Button("Done") {
                coordinator.dismissToHome()
                PartnerSessionManager.shared.clearSession()
            }
            .buttonStyle(.ydgPrimary)
        }
        .padding(.top, YDGSpace.xs)
    }

    // MARK: - Logic

    private func copyNote() {
        UIPasteboard.general.string = noteText
        if reduceMotion {
            didCopyNote = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { didCopyNote = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.2)) { didCopyNote = false }
        }
    }

    /// Build a warm, send-ready note from the locked-in plan (no network call).
    static func draftLoveNote(for plan: DatePlan) -> String {
        let whenLine: String
        if let date = plan.scheduledDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            whenLine = "\(formatter.string(from: date)) is ours."
        } else {
            whenLine = "I've got our next one planned."
        }
        let tagline = plan.tagline.trimmingCharacters(in: .whitespacesAndNewlines)
        let middle = tagline.isEmpty
            ? "I planned \(plan.title) for us."
            : "I planned \(plan.title) for us — \(tagline.prefix(1).lowercased() + tagline.dropFirst())."
        return "\(whenLine) \(middle) Can't wait to share it with you. ❤️"
    }
}

#Preview("Locked In") {
    NavigationStack {
        LockedInView(plan: DatePlan.sample, calendarSynced: true)
            .environmentObject(NavigationCoordinator.shared)
    }
}
