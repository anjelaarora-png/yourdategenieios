import SwiftUI

// MARK: - Edit Account Sheet (Settings → Edit name, email, phone)
struct EditAccountSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileManager = UserProfileManager.shared

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var userProfile: UserProfile? {
        profileManager.currentUser
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update your account details")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryCreamMuted)

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
                            LuxuryTextField(
                                title: "Email",
                                placeholder: "you@example.com",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )
                            LuxuryTextField(
                                title: "Phone",
                                placeholder: "+1 (555) 000-0000",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad
                            )
                        }
                        .padding(18)
                        .luxuryCard()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(Font.bodySans(15, weight: .medium))
                    .foregroundColor(Color.luxuryCreamMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .font(Font.bodySans(15, weight: .semibold))
                    .foregroundColor(Color.luxuryGold)
                    .disabled(isSaving || !isValid)
                }
            }
            .onAppear {
                firstName = userProfile?.firstName ?? ""
                lastName = userProfile?.lastName ?? ""
                email = userProfile?.email ?? ""
                phoneNumber = userProfile?.phoneNumber ?? ""
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        return !trimmedFirst.isEmpty && !trimmedEmail.isEmpty && isValidEmail(trimmedEmail)
    }

    private func isValidEmail(_ string: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    private func saveAndDismiss() {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespaces)

        guard !trimmedFirst.isEmpty, isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid name and email."
            showError = true
            return
        }

        isSaving = true
        profileManager.updateAccountInfo(
            firstName: trimmedFirst,
            lastName: trimmedLast,
            email: trimmedEmail,
            phoneNumber: trimmedPhone
        )
        isSaving = false
        dismiss()
    }
}

#Preview {
    EditAccountSheetView()
}
