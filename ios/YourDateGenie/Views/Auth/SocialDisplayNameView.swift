import SwiftUI

/// Collects first + last name after Apple/Google sign-in when Apple didn't provide a name
/// (or the DB fell back to the email local-part).
struct SocialDisplayNameView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Your Date Genie")
                        .font(Font.bodySerif(28, weight: .regular))
                        .foregroundColor(Color.accentGold)

                    Text("What should we call you?")
                        .font(Font.bodySans(20, weight: .semibold))
                        .foregroundColor(Color.textPrimary)

                    Text("We don’t use your email as your name. Enter your first and last name to finish setting up your account.")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 48)
                .padding(.bottom, 28)

                VStack(spacing: 16) {
                    LuxuryTextField(
                        title: "First Name",
                        placeholder: "First name",
                        text: $firstName,
                        icon: nil
                    )
                    LuxuryTextField(
                        title: "Last Name",
                        placeholder: "Last name",
                        text: $lastName,
                        icon: nil
                    )

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(Font.bodySans(13, weight: .regular))
                            .foregroundColor(Color.orange.opacity(0.95))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(Color.luxuryMaroon) }
                            Text(isSaving ? "Saving…" : "Continue")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    .disabled(!isValid || isSaving)
                    .padding(.top, 8)
                }
                .padding(20)
                .luxuryCard()

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }

    @MainActor
    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await profileManager.completeSocialDisplayName(
                firstName: firstName,
                lastName: lastName
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SocialDisplayNameView()
}
