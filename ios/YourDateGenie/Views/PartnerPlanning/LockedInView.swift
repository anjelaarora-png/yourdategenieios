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
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    sealSection
                    planCard
                    calendarStatusRow
                    draftedNoteSection
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.accentMaroon, lineWidth: 2)
                    .frame(width: 84, height: 84)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.accentMaroon)
            }
            .scaleEffect(sealScale)
            .opacity(sealOpacity)

            Text("Locked in")
                .font(Font.displaySerif(38, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Text("It's settled — no more back-and-forth texts.")
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Plan card (cream itinerary card, maroon left border)

    private var planCard: some View {
        ItineraryCreamPlanPreviewCard(
            plan: plan,
            partnerName: partnerDisplayName == "your partner" ? nil : partnerDisplayName
        )
    }

    // MARK: - Calendar status

    private var calendarStatusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: calendarSynced ? "calendar.badge.checkmark" : "calendar.badge.exclamationmark")
                .font(.system(size: 18))
                .foregroundColor(calendarSynced ? Color.luxurySuccess : Color.textPrimary.opacity(0.6))
            VStack(alignment: .leading, spacing: 2) {
                Text(calendarSynced ? "On both your calendars" : "Saved to your plans")
                    .font(Font.bodySans(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(calendarSynced
                     ? "Reminders set the night before and a few hours ahead."
                     : "Turn on Calendar access to get reminders for you both.")
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
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.luxeSurfaceBorder, lineWidth: 1))
    }

    // MARK: - Drafted note

    private var draftedNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.accentMaroon)
                Text("Your Love Note, ready to send")
                    .font(Font.bodySans(11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Color.textPrimary.opacity(0.6))
                    .textCase(.uppercase)
            }

            LoveNoteCreamCard(bannerSubtitle: "Ready to send") {
                Text(noteText)
                    .font(Font.bodySerif(15, weight: .regular))
                    .foregroundColor(Color.textOnCard)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Actions (single gold highlight = copy note)

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                copyNote()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: didCopyNote ? "checkmark" : "doc.on.doc.fill")
                        .font(.system(size: 16))
                    Text(didCopyNote ? "Copied — paste your Love Note to \(partnerDisplayName)" : "Copy Love Note for \(partnerDisplayName)")
                        .font(Font.bodySans(16, weight: .semibold))
                }
                .foregroundColor(Color.backgroundPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            Button {
                coordinator.dismissToHome()
                PartnerSessionManager.shared.clearSession()
            } label: {
                Text("Done")
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.textPrimary.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.textPrimary.opacity(0.3), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
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
