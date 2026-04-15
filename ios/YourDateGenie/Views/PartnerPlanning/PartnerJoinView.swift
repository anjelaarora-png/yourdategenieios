import SwiftUI

// MARK: - Partner Join View (opened via deep link when partner taps invite link)

struct PartnerJoinView: View {
    let sessionId: String
    var inviterName: String?

    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var userProfileManager = UserProfileManager.shared

    @State private var partnerNote = ""

    private var displayTitle: String {
        let name = (inviterName ?? "").trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            return "Join date plan"
        }
        return "Join \(name)'s date plan"
    }

    private var hasSavedPreferences: Bool {
        userProfileManager.hasCompletedPreferences && userProfileManager.isLoggedIn
    }

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()

            FloatingParticlesView()
                .ignoresSafeArea()
                .opacity(0.6)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    contentSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    coordinator.pendingPartnerJoinSessionId = nil
                    coordinator.pendingPartnerJoinInviterName = nil
                    coordinator.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
        .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.luxuryGold)
            Text(displayTitle)
                .font(Font.tangerine(24, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var contentSection: some View {
        if hasSavedPreferences {
            oneTapSection
        } else {
            addPreferencesSection
        }
    }

    private var oneTapSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("We've used your saved preferences.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)

            VStack(alignment: .leading, spacing: 8) {
                Text("Anything to add? (optional)")
                    .font(Font.bodySans(12, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.9))
                TextField("", text: $partnerNote, prompt: Text("e.g. Rooftop preferred").foregroundColor(Color.luxuryMuted.opacity(0.6)))
                    .font(Font.bodySans(15, weight: .regular))
                    .foregroundColor(Color.luxuryCream)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.luxuryMaroonLight)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                    )
            }

            Button {
                submitWithSavedPreferences()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("I'm in")
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
        }
        .padding(.vertical, 8)
    }

    private var addPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add your preferences so we can plan something you'll both love.")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)

            Button {
                access.require(.datePlan) {
                    coordinator.partnerJoinSessionId = sessionId
                    coordinator.dismissSheet()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        coordinator.planIntent = .fresh
                        coordinator.activeSheet = .questionnaire
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                    Text("Add my preferences")
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
        }
        .padding(.vertical, 8)
    }

    private func submitWithSavedPreferences() {
        var data = QuestionnaireData()
        UserProfileManager.shared.prePopulateQuestionnaireData(&data)
        if !partnerNote.trimmingCharacters(in: .whitespaces).isEmpty {
            let existing = data.additionalNotes.trimmingCharacters(in: .whitespaces)
            data.additionalNotes = [existing, partnerNote.trimmingCharacters(in: .whitespaces)].filter { !$0.isEmpty }.joined(separator: " ")
        }
        PartnerSessionManager.shared.submitPartnerData(sessionId: sessionId, data: data)
        coordinator.pendingPartnerJoinSessionId = nil
        coordinator.pendingPartnerJoinInviterName = nil
        // Route partner to the generating/waiting screen instead of just dismissing
        coordinator.activeSheet = .planGenerating(sessionId: sessionId, role: .partner)
    }
}

// MARK: - Previews

#Preview("Partner Join (with name)") {
    PartnerJoinView(sessionId: "preview-session", inviterName: "Alex")
        .environmentObject(NavigationCoordinator.shared)
}

#Preview("Partner Join (no name)") {
    PartnerJoinView(sessionId: "preview-session", inviterName: nil)
        .environmentObject(NavigationCoordinator.shared)
}
