import SwiftUI

// MARK: - Partner Join View (opened via deep link when partner taps invite link)

struct PartnerJoinView: View {
    let sessionId: String
    var inviterName: String?

    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject private var access: AccessManager
    @StateObject private var userProfileManager = UserProfileManager.shared

    @State private var partnerNote = ""
    @State private var showContentFilterAlert = false

    private var hasSavedPreferences: Bool {
        userProfileManager.hasCompletedPreferences && userProfileManager.isLoggedIn
    }

    private var inviterFirstName: String? {
        let name = (inviterName ?? "").trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    var body: some View {
        ZStack {
            Color.ydgBase
                .ignoresSafeArea()

            if !userProfileManager.isLoggedIn {
                // Partner must be signed in before they can contribute preferences
                signInRequiredSection
            } else {
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: YDGSpace.lg) {
                            headerSection
                            contentSection
                        }
                        .padding(.horizontal, YDGSpace.margin)
                        .padding(.top, YDGSpace.md)
                        .padding(.bottom, YDGSpace.lg)
                    }
                    bottomAction
                        .padding(.horizontal, YDGSpace.margin)
                        .padding(.bottom, YDGSpace.xs)
                }
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.ydgTextPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
        }
        .toolbarBackground(Color.ydgBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Message not allowed", isPresented: $showContentFilterAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ObjectionableContentFilter.rejectionMessage)
        }
    }

    private var signInRequiredSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.md) {
            Spacer()
            Image(systemName: "lock")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color.ydgHighlight)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.ydgHighlightSubtle))
                .accessibilityHidden(true)
            Text(inviterFirstName.map { "Sign in to join \($0)" } ?? "Sign in to join")
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("You need an account to add your preferences to this date plan.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Sign in or create account") {
                coordinator.dismissSheet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordinator.activeSheet = .authRequired(.fresh)
                }
            }
            .buttonStyle(.ydgPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YDGSpace.margin)
        .padding(.bottom, YDGSpace.xs)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            HStack(spacing: YDGSpace.xs) {
                Text(String((inviterFirstName ?? "?").prefix(1)).uppercased())
                    .font(.ydgSans(13, weight: .semibold))
                    .foregroundColor(Color.ydgTextPrimary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.ydgIconTile))
                    .accessibilityHidden(true)
                Text(inviterFirstName.map { "\($0) invited you" } ?? "You're invited")
                    .ydgText(.caption, color: .ydgHighlight)
            }
            Text("Help plan your next date")
                .ydgText(.title1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, YDGSpace.xxs)
            Text("Answer on your own. \(inviterFirstName ?? "They") won't see your picks until you've both ranked.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentSection: some View {
        if hasSavedPreferences {
            oneTapSection
        } else {
            Text("Add your preferences so we can plan something you'll both love.")
                .ydgText(.body, color: .ydgTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Saved preferences summary (design 4.4)

    private func labels(_ values: [String], in options: [OptionItem]) -> String {
        let names = values.compactMap { v in options.first { $0.value == v }?.label }
        return names.isEmpty ? "None" : names.prefix(2).joined(separator: ", ")
    }

    private var preferenceRows: [(String, String)] {
        let p = userProfileManager.currentUser?.preferences ?? DatePreferences()
        return [
            ("Into", labels(p.favoriteActivities, in: QuestionnaireOptions.activities)),
            ("Food", labels(p.favoriteCuisines, in: QuestionnaireOptions.cuisines)),
            ("Drinks", labels(p.beveragePreferences, in: QuestionnaireOptions.drinkPreferences)),
            ("Hard no's", labels(p.hardNos, in: QuestionnaireOptions.hardNos)),
        ]
    }

    private var oneTapSection: some View {
        VStack(alignment: .leading, spacing: YDGSpace.lg) {
            VStack(spacing: 0) {
                HStack {
                    Text("Your saved preferences")
                        .ydgText(.subhead, weight: .semibold)
                    Spacer()
                    Button("Edit") { openPreferencesQuestionnaire() }
                        .buttonStyle(.ydgTertiary)
                }
                .padding(.leading, YDGSpace.md)
                .padding(.trailing, YDGSpace.xs)
                ForEach(preferenceRows, id: \.0) { row in
                    YDGListDivider(leadingInset: 0)
                    HStack {
                        Text(row.0)
                            .ydgText(.subhead, weight: .regular, color: .ydgTextSecondary)
                        Spacer()
                        Text(row.1)
                            .ydgText(.subhead, weight: .regular)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, YDGSpace.md)
                    .frame(minHeight: 44)
                }
            }
            .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(Color.ydgBorder, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: YDGSpace.xs) {
                HStack {
                    Text("Anything to add?")
                        .ydgText(.subhead, weight: .medium)
                    Spacer()
                    Text("Optional")
                        .ydgText(.footnote, color: .ydgTextTertiary)
                }
                TextField("", text: $partnerNote, prompt: Text("e.g. Rooftop if the weather holds").foregroundColor(Color.ydgTextTertiary))
                    .font(.ydg(.body))
                    .foregroundColor(Color.ydgTextPrimary)
                    .padding(.horizontal, YDGSpace.md)
                    .frame(minHeight: 52)
                    .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                            .stroke(Color.ydgBorder, lineWidth: 1)
                    )
            }
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        if hasSavedPreferences {
            Button("I'm in") { submitWithSavedPreferences() }
                .buttonStyle(.ydgPrimary)
        } else {
            Button("Add my preferences") { openPreferencesQuestionnaire() }
                .buttonStyle(.ydgPrimary)
        }
    }

    private func openPreferencesQuestionnaire() {
        access.require(.datePlan) {
            coordinator.partnerJoinSessionId = sessionId
            coordinator.dismissSheet()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                coordinator.planIntent = .fresh
                coordinator.activeSheet = .questionnaire
            }
        }
    }

    private func submitWithSavedPreferences() {
        if ObjectionableContentFilter.rejectionReason(for: partnerNote) != nil {
            showContentFilterAlert = true
            return
        }
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
