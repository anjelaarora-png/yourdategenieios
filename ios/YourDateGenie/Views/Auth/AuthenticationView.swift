import SwiftUI
import Combine

struct AuthenticationView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = AuthViewModelState()
    @StateObject private var profileManager = UserProfileManager.shared
    @FocusState private var focusedField: AuthInputField?
    @State private var showResetPasswordSheet = false
    
    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    authHeader
                    
                    authModeToggle
                        .padding(.top, 24)
                    
                    if viewModel.isSignUp {
                        signUpForm
                    } else {
                        signInForm
                    }
                    
                    authButton
                        .padding(.top, 24)
                    
                    if !viewModel.isSignUp {
                        forgotPasswordButton
                            .padding(.top, 12)
                    }
                    
                    if viewModel.isSignUp {
                        signUpBenefits
                            .padding(.top, 32)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
            .sheet(isPresented: $showResetPasswordSheet) {
                ResetPasswordSheet(
                    email: $viewModel.email,
                    onSend: { email in
                        performPasswordReset(email: email)
                        showResetPasswordSheet = false
                    },
                    onDismiss: { showResetPasswordSheet = false }
                )
            }
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundColor(Color.luxuryGold)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Password Reset", isPresented: $viewModel.showPasswordResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If an account exists with that email, you will receive a password reset link.")
        }
        .onChange(of: profileManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                if profileManager.hasCompletedPreferences {
                    coordinator.completeSignIn()
                } else {
                    coordinator.completeSignUp()
                }
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color.luxuryGold)
                
                Text(viewModel.isSignUp ? "Creating your account..." : "Signing in...")
                    .font(Font.bodySans(14, weight: .medium))
                    .foregroundColor(Color.luxuryCream)
            }
            .padding(32)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(16)
        }
    }
    
    private var forgotPasswordButton: some View {
        Button {
            showResetPasswordSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 12))
                Text("Forgot Password?")
                    .font(Font.bodySans(14, weight: .medium))
            }
            .foregroundColor(Color.luxuryGold)
        }
    }
    
    private var authHeader: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color.luxuryGold.opacity(0.3), radius: 20)
            
            Text(viewModel.isSignUp ? "Create your account" : "Welcome back")
                .font(Font.header(22, weight: .regular))
                .foregroundColor(Color.luxuryCream)
            
            Text(viewModel.isSignUp ? "Start planning unforgettable dates" : "Sign in to continue your journey")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
        .padding(.top, 60)
    }
    
    private var authModeToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSignUp = false
                }
            } label: {
                Text("Sign In")
                    .font(Font.bodySans(15, weight: viewModel.isSignUp ? .regular : .semibold))
                    .foregroundColor(viewModel.isSignUp ? Color.luxuryMuted : Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.isSignUp ? AnyShapeStyle(Color.clear) : AnyShapeStyle(LinearGradient.goldShimmer)
                    )
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSignUp = true
                }
            } label: {
                Text("Sign Up")
                    .font(Font.bodySans(15, weight: viewModel.isSignUp ? .semibold : .regular))
                    .foregroundColor(viewModel.isSignUp ? Color.luxuryMaroon : Color.luxuryMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.isSignUp ? AnyShapeStyle(LinearGradient.goldShimmer) : AnyShapeStyle(Color.clear)
                    )
            }
        }
        .background(Color.luxuryMaroonLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var signInForm: some View {
        VStack(spacing: 20) {
            LuxuryTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            
            AuthSecureField(
                title: "Password",
                placeholder: "Enter your password",
                text: $viewModel.password,
                icon: "lock.fill"
            )
            .focused($focusedField, equals: .password)
        }
        .padding(.top, 32)
    }
    
    private var signUpForm: some View {
        VStack(spacing: 20) {
            if viewModel.isSignUp {
                signUpBenefitsInline
            }
            
            HStack(spacing: 16) {
                LuxuryTextField(
                    title: "First Name",
                    placeholder: "John",
                    text: $viewModel.firstName,
                    icon: nil
                )
                .focused($focusedField, equals: .firstName)
                
                LuxuryTextField(
                    title: "Last Name",
                    placeholder: "Doe",
                    text: $viewModel.lastName,
                    icon: nil
                )
                .focused($focusedField, equals: .lastName)
            }
            
            LuxuryTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            
            AuthSecureField(
                title: "Password",
                placeholder: "••••••••",
                text: $viewModel.password,
                icon: "lock.fill"
            )
            .focused($focusedField, equals: .password)
            
            AuthSecureField(
                title: "Confirm Password",
                placeholder: "••••••••",
                text: $viewModel.confirmPassword,
                icon: "lock.fill"
            )
            .focused($focusedField, equals: .confirmPassword)
        }
        .padding(.top, 24)
    }
    
    private var signUpBenefitsInline: some View {
        VStack(alignment: .leading, spacing: 10) {
            AuthBenefitRow(text: "Personalized multi-stop date plans")
            AuthBenefitRow(text: "Real venues with verified details")
            AuthBenefitRow(text: "Dietary restrictions always respected")
        }
        .padding(.vertical, 16)
    }
    
    private var authButton: some View {
        VStack(spacing: 16) {
            Button {
                if viewModel.isSignUp {
                    performSignUp()
                } else {
                    performSignIn()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(viewModel.isSignUp ? "Start Planning Dates" : "Sign In")
                        .font(Font.bodySans(16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuxuryGoldButtonStyle())
            .disabled(!viewModel.isFormValid)
            .opacity(viewModel.isFormValid ? 1 : 0.5)
            
            Button {
                withAnimation {
                    viewModel.isSignUp.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(Font.bodySans(14, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                    Text(viewModel.isSignUp ? "Sign in" : "Sign up")
                        .font(Font.bodySans(14, weight: .semibold))
                        .foregroundColor(Color.luxuryGold)
                }
            }
        }
    }
    
    private var signUpBenefits: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Color.luxuryGold.opacity(0.7))
                Text("Your data is private")
                    .font(Font.bodySans(13, weight: .medium))
                    .foregroundColor(Color.luxuryGold.opacity(0.9))
            }
            
            Text("We never share your personal information. Your preferences are used only to create personalized date plans.")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.luxuryMaroonLight.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.luxuryGold.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func performSignIn() {
        focusedField = nil
        viewModel.isLoading = true
        
        Task {
            do {
                try await UserProfileManager.shared.signIn(
                    email: viewModel.email,
                    password: viewModel.password
                )
            } catch let error as SupabaseError {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            } catch let error as AuthenticationError {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            }
            
            await MainActor.run {
                viewModel.isLoading = false
            }
        }
    }
    
    private func performSignUp() {
        focusedField = nil
        
        guard viewModel.password == viewModel.confirmPassword else {
            viewModel.errorMessage = "Passwords do not match"
            viewModel.showError = true
            return
        }
        
        viewModel.isLoading = true
        
        Task {
            do {
                try await UserProfileManager.shared.signUp(
                    firstName: viewModel.firstName,
                    lastName: viewModel.lastName,
                    email: viewModel.email,
                    password: viewModel.password
                )
            } catch let error as SupabaseError {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            } catch let error as AuthenticationError {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            }
            
            await MainActor.run {
                viewModel.isLoading = false
            }
        }
    }
    
    private func performPasswordReset(email: String) {
        guard !email.isEmpty && email.contains("@") else {
            viewModel.errorMessage = "Please enter a valid email address"
            viewModel.showError = true
            return
        }
        
        viewModel.isLoading = true
        
        Task {
            do {
                try await UserProfileManager.shared.sendPasswordReset(to: email)
                await MainActor.run {
                    viewModel.showPasswordResetSuccess = true
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = "Failed to send reset email. Please check your connection and try again."
                    viewModel.showError = true
                }
            }
            
            await MainActor.run {
                viewModel.isLoading = false
            }
        }
    }
}

// MARK: - Reset Password Sheet
private struct ResetPasswordSheet: View {
    @Binding var email: String
    let onSend: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var resetEmail = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundStyle(LinearGradient.goldShimmer)
                    
                    Text("Reset your password")
                        .font(Font.header(22, weight: .semibold))
                        .foregroundColor(Color.luxuryCream)
                    
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(Font.bodySans(15, weight: .regular))
                        .foregroundColor(Color.luxuryCreamMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    LuxuryTextField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $resetEmail,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    .padding(.top, 8)
                    
                    Button {
                        onSend(resetEmail.isEmpty ? email : resetEmail)
                    } label: {
                        HStack(spacing: 8) {
                            Text("Send Reset Link")
                                .font(Font.bodySans(16, weight: .semibold))
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuxuryGoldButtonStyle())
                    .disabled(resetEmail.isEmpty && email.isEmpty)
                    .opacity((resetEmail.isEmpty && email.isEmpty) ? 0.5 : 1)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Color.luxuryGold)
                }
            }
            .onAppear {
                resetEmail = email
            }
        }
    }
}

// MARK: - Auth Benefit Row
private struct AuthBenefitRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.luxuryGold)
            
            Text(text)
                .font(Font.bodySans(14, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
        }
    }
}

// MARK: - Auth Secure Field
private struct AuthSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.bodySans(13, weight: .medium))
                .foregroundColor(Color.luxuryGold)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                        .frame(width: 20)
                }
                
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.luxuryMuted.opacity(0.6)))
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.luxuryMuted.opacity(0.6)))
                        .font(Font.bodySans(16, weight: .regular))
                        .foregroundColor(Color.luxuryCream)
                }
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(Color.luxuryGold.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luxuryMaroonLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        text.isEmpty ? Color.luxuryGold.opacity(0.2) : Color.luxuryGold.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Auth Input Field
private enum AuthInputField: Hashable {
    case firstName, lastName, email, password, confirmPassword
}

// MARK: - Auth View Model
private class AuthViewModelState: ObservableObject {
    @Published var isSignUp = true
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var showPasswordResetSuccess = false
    
    var isFormValid: Bool {
        if isSignUp {
            return !firstName.isEmpty &&
                   !email.isEmpty &&
                   email.contains("@") &&
                   password.count >= 6 &&
                   password == confirmPassword
        } else {
            return !email.isEmpty &&
                   email.contains("@") &&
                   !password.isEmpty
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(NavigationCoordinator.shared)
}
