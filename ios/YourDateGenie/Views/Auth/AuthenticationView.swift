import SwiftUI
import Combine
import UIKit
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = AuthViewModelState()
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var socialAuth = SocialAuthService.shared
    @FocusState private var focusedField: AuthInputField?
    @State private var showResetPasswordSheet = false
    @State private var resendCooldownRemaining = 0
    @State private var resendFeedbackMessage: String?
    @State private var showResendSuccess = false
    @State private var verificationPollingElapsed = 0
    @State private var isAutoCheckingVerification = false
    private let verificationPollingDurationSeconds = 180
    /// Spaced to limit silent sign-in attempts while email confirmation is pending.
    private let verificationPollingIntervalSeconds = 15
    /// When true, returning user after reinstall; default to Sign In and show welcome-back messaging.
    var isReinstallFlow: Bool = false
    /// When set, show an X to dismiss (e.g. close auth sheet or skip login).
    var onDismiss: (() -> Void)? = nil
    /// When true, show "Explore without an account" link (root flow only; not when auth is required for Plan my date).
    var allowSkipToExplore: Bool = false

    var body: some View {
        ZStack {
            Color.luxuryMaroon
                .ignoresSafeArea()
            
            RadialGradient.goldGlow
                .opacity(0.15)
                .ignoresSafeArea()
            
            Group {
                if profileManager.pendingEmailConfirmation {
                    emailConfirmationWaitScreen
                } else {
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

                            socialDivider
                                .padding(.top, 28)

                            socialAuthButtons
                                .padding(.top, 16)

                            if viewModel.isSignUp {
                                signUpBenefits
                                    .padding(.top, 32)
                            }

                            if allowSkipToExplore {
                                exploreWithoutAccountButton
                                    .padding(.top, 28)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 24)
                    }
                }
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
            
            if let onDismiss = onDismiss, !profileManager.pendingEmailConfirmation {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.luxuryGold.opacity(0.9))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .padding(.top, 56)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
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
        .alert("Confirmation Email Sent", isPresented: $showResendSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We sent another confirmation email. Please check your inbox and spam folder.")
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendCooldownRemaining > 0 {
                resendCooldownRemaining -= 1
            }
            if profileManager.pendingEmailConfirmation {
                if verificationPollingElapsed < verificationPollingDurationSeconds {
                    verificationPollingElapsed += 1
                    if verificationPollingElapsed % verificationPollingIntervalSeconds == 0 {
                        performAutoVerificationCheck()
                    }
                }
            } else {
                verificationPollingElapsed = 0
            }
        }
        .onAppear {
            if profileManager.pendingEmailConfirmation, SupabaseService.shared.isAuthenticated {
                profileManager.clearPendingEmailConfirmation()
            }
            if isReinstallFlow {
                viewModel.isSignUp = false
            } else if coordinator.preferSignUpTabOnNextAuth {
                viewModel.isSignUp = true
                coordinator.consumePreferSignUpTab()
            }
            if profileManager.pendingEmailConfirmation {
                verificationPollingElapsed = 0
            }
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

    // MARK: - Social Auth

    private var socialDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.luxuryMuted.opacity(0.3))
                .frame(height: 1)
            Text("or continue with")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .fixedSize()
            Rectangle()
                .fill(Color.luxuryMuted.opacity(0.3))
                .frame(height: 1)
        }
    }

    private var socialAuthButtons: some View {
        VStack(spacing: 12) {
            // Sign in with Apple (required by Apple when Google is offered)
            VStack(spacing: 4) {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        // Pass the authorization Apple already collected straight to the service.
                        // Do NOT call signInWithApple() here — that creates a second
                        // ASAuthorizationController and shows the Apple sheet a second time.
                        switch result {
                        case .success(let authorization):
                            socialAuth.handleAppleAuthorization(authorization)
                        case .failure(let error):
                            let nsErr = error as NSError
                            if nsErr.code != ASAuthorizationError.canceled.rawValue {
                                socialAuth.error = error
                            }
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(12)
                .disabled(socialAuth.isLoading)

                Text("Use your Apple ID \u{2014} no new password needed")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
            }

            // Sign in with Google (Supabase OAuth via ASWebAuthenticationSession)
            Button {
                socialAuth.signInWithGoogle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                    Text("Continue with Google")
                        .font(Font.bodySans(15, weight: .medium))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(12)
            }
            .disabled(socialAuth.isLoading)

        }
        .alert("Sign In Error", isPresented: Binding(
            get: { socialAuth.error != nil },
            set: { if !$0 { socialAuth.error = nil } }
        )) {
            Button("OK", role: .cancel) { socialAuth.error = nil }
        } message: {
            Text(socialAuth.error?.localizedDescription ?? "")
        }
    }

    /// "Explore without an account" / "Maybe later" — closes auth and goes to main nav.
    private var exploreWithoutAccountButton: some View {
        Button {
            onDismiss?()
        } label: {
            Text("Explore without an account")
                .font(Font.bodySans(15, weight: .medium))
                .foregroundColor(Color.luxuryMuted)
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
    
    /// Full-screen wait after sign-up: no actions that bypass verification; updates automatically when the confirm link opens in-app.
    private var emailConfirmationWaitScreen: some View {
        let pendingEmail = profileManager.pendingConfirmationEmail ?? viewModel.email

        return VStack(spacing: 0) {
            Spacer(minLength: 32)

            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .shadow(color: Color.luxuryGold.opacity(0.35), radius: 18)

            EmailConfirmationMagicalWaitView()
                .padding(.top, 40)
                .padding(.bottom, 28)

            Text("Check your email")
                .font(Font.tangerine(30, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
                .multilineTextAlignment(.center)

            Text("We sent a confirmation link to")
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCreamMuted)
                .padding(.top, 16)

            Text(pendingEmail)
                .font(Font.bodySans(16, weight: .semibold))
                .foregroundColor(Color.luxuryCream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 14) {
                EmailConfirmationStep(number: "1", text: "Open the email we just sent to \(pendingEmail)")
                EmailConfirmationStep(number: "2", text: "Tap the confirmation link inside it")
                EmailConfirmationStep(number: "3", text: "Come back here — the app will open automatically")
            }
            .padding(.top, 20)
            .padding(.horizontal, 8)

            Text("If the app doesn't open after clicking the link, tap 'Already verified? Sign in' below.")
                .font(Font.bodySans(13, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 8)

            VStack(spacing: 12) {
                mailAppQuickActions

                Button {
                    performResendConfirmationEmail()
                } label: {
                    Text(resendCooldownRemaining > 0 ? "Resend available in \(resendCooldownRemaining)s" : "Resend confirmation email")
                        .font(Font.bodySans(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryGoldButtonStyle())
                .disabled(viewModel.isLoading || resendCooldownRemaining > 0 || pendingEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity((viewModel.isLoading || resendCooldownRemaining > 0) ? 0.6 : 1)

                Button {
                    useDifferentEmail()
                } label: {
                    Text("Use a different email")
                        .font(Font.bodySans(14, weight: .medium))
                        .foregroundColor(Color.luxuryGold)
                }

                Button {
                    transitionToSignInAfterVerification()
                } label: {
                    Text("Already verified? Sign in")
                        .font(Font.bodySans(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuxuryMaroonButtonStyle())
            }
            .padding(.top, 24)
            .padding(.horizontal, 8)

            Text("Did not receive it yet? Check spam/promotions or use a different email.")
                .font(Font.bodySans(12, weight: .regular))
                .foregroundColor(Color.luxuryMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 8)

            if let resendFeedbackMessage {
                Text(resendFeedbackMessage)
                    .font(Font.bodySans(13, weight: .regular))
                    .foregroundColor(Color.luxuryCreamMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 8)
            }

            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
    }

    private var mailAppQuickActions: some View {
        HStack(spacing: 10) {
            MailQuickActionButton(title: "Open Mail") {
                openURLIfPossible(URL(string: "message://") ?? URL(string: "mailto:")!)
            }
        }
    }
    
    private var authHeader: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color.luxuryGold.opacity(0.3), radius: 20)
            
            Text(viewModel.isSignUp ? "Create Your Account" : "Welcome Back")
                .font(Font.tangerine(36, weight: .bold))
                .italic()
                .foregroundColor(Color.luxuryGold)
            
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
                    .font(Font.bodySans(16, weight: viewModel.isSignUp ? .regular : .semibold))
                    .foregroundColor(viewModel.isSignUp ? Color.luxuryMuted : Color.luxuryMaroon)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.isSignUp ? AnyShapeStyle(Color.clear) : AnyShapeStyle(LinearGradient.goldShimmer)
                    )
            }
            .accessibilityLabel("Sign In")
            .accessibilityAddTraits(viewModel.isSignUp ? [] : .isSelected)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSignUp = true
                }
            } label: {
                Text("Create Account")
                    .font(Font.bodySans(16, weight: viewModel.isSignUp ? .semibold : .regular))
                    .foregroundColor(viewModel.isSignUp ? Color.luxuryMaroon : Color.luxuryMuted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.isSignUp ? AnyShapeStyle(LinearGradient.goldShimmer) : AnyShapeStyle(Color.clear)
                    )
            }
            .accessibilityLabel("Create Account")
            .accessibilityAddTraits(viewModel.isSignUp ? .isSelected : [])
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
            
            VStack(alignment: .leading, spacing: 6) {
                AuthSecureField(
                    title: "Password",
                    placeholder: "••••••••",
                    text: $viewModel.password,
                    icon: "lock.fill"
                )
                .focused($focusedField, equals: .password)
                
                Text("Must be at least 8 characters")
                    .font(Font.bodySans(12, weight: .regular))
                    .foregroundColor(Color.luxuryMuted)
                    .padding(.leading, 4)
            }
            
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

    private func performResendConfirmationEmail() {
        let email = (profileManager.pendingConfirmationEmail ?? viewModel.email)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !email.isEmpty, email.contains("@") else {
            viewModel.errorMessage = "We couldn't find a valid email to resend to."
            viewModel.showError = true
            return
        }

        viewModel.isLoading = true
        resendFeedbackMessage = nil

        Task {
            do {
                try await UserProfileManager.shared.resendEmailConfirmation(to: email)
                await MainActor.run {
                    resendCooldownRemaining = 30
                    showResendSuccess = true
                    resendFeedbackMessage = "Sent to \(email)."
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                    resendFeedbackMessage = "Unable to resend right now. Please try again shortly."
                }
            }

            await MainActor.run {
                viewModel.isLoading = false
            }
        }
    }

    private func useDifferentEmail() {
        let previousEmail = profileManager.pendingConfirmationEmail ?? viewModel.email
        profileManager.clearPendingEmailConfirmation()
        viewModel.isSignUp = true
        viewModel.email = previousEmail
        viewModel.password = ""
        viewModel.confirmPassword = ""
        resendFeedbackMessage = nil
        resendCooldownRemaining = 0
    }

    /// Leaves the wait screen and shows Sign in with the pending email (password must be entered if not still in memory).
    private func transitionToSignInAfterVerification() {
        let email = profileManager.pendingConfirmationEmail ?? viewModel.email
        profileManager.clearPendingEmailConfirmation()
        viewModel.email = email
        viewModel.isSignUp = false
        resendFeedbackMessage = nil
        resendCooldownRemaining = 0
        verificationPollingElapsed = 0
    }

    private func performAutoVerificationCheck() {
        guard profileManager.pendingEmailConfirmation else { return }
        guard !isAutoCheckingVerification else { return }
        isAutoCheckingVerification = true
        Task {
            defer {
                Task { @MainActor in
                    isAutoCheckingVerification = false
                }
            }
            let email = await MainActor.run {
                (profileManager.pendingConfirmationEmail ?? viewModel.email)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            let password = await MainActor.run { viewModel.password }

            // Confirming in Mail/Safari often never opens the app with tokens; sign-in still works once the address is verified.
            if password.count >= 6, !email.isEmpty {
                do {
                    try await UserProfileManager.shared.signIn(email: email, password: password)
                    return
                } catch {
                    // Unconfirmed, wrong password, or offline — fall through to refreshSession.
                }
            }

            try? await SupabaseService.shared.refreshSession()
        }
    }

    private func openURLIfPossible(_ url: URL?) {
        guard let url else { return }
        let app = UIApplication.shared
        if app.canOpenURL(url) {
            app.open(url)
        } else if let fallback = URL(string: "mailto:"), app.canOpenURL(fallback) {
            app.open(fallback)
        }
    }
}

private struct MailQuickActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.bodySans(12, weight: .semibold))
                .foregroundColor(Color.luxuryGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Color.luxuryMaroonLight.opacity(0.7))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.luxuryGold.opacity(0.25), lineWidth: 1)
                )
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

// MARK: - Email confirmation wait (magical ring + sparkles)

private struct EmailConfirmationMagicalWaitView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let spin = (t.truncatingRemainder(dividingBy: 10) / 10) * 360
            let pulse = 0.9 + 0.1 * sin(t * 2.8)

            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.luxuryGold.opacity(0.88))
                        .offset(y: -52)
                        .rotationEffect(.degrees(Double(i) * 36 + spin))
                }

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.luxuryGold.opacity(0.2),
                                Color.luxuryGold,
                                Color.luxuryGold.opacity(0.55),
                                Color.luxuryGold.opacity(0.2)
                            ],
                            center: .center
                        ),
                        lineWidth: 3.5
                    )
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-spin * 1.25))

                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(LinearGradient.goldShimmer)
                    .scaleEffect(pulse)
            }
            .frame(width: 128, height: 128)
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

// MARK: - Email Confirmation Step Row

private struct EmailConfirmationStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient.goldShimmer)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(Font.bodySans(14, weight: .bold))
                    .foregroundColor(Color.luxuryMaroon)
            }
            Text(text)
                .font(Font.bodySans(15, weight: .regular))
                .foregroundColor(Color.luxuryCream)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(NavigationCoordinator.shared)
}
