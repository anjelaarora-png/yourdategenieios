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
    @State private var accountMode: AccountMode = .individual
    @State private var showBusinessPortal = false
    @State private var showResetPasswordSheet = false
    /// Required before register or login (Apple §1.2 EULA). Restored from disk so remounts
    /// (social hydrate / auth-required sheet) don't clear a checkbox the user already checked.
    @State private var agreedToTerms = AgeEligibility.hasAcceptedTerms
    @State private var showTermsRequiredAlert = false

    enum AccountMode { case individual, business }
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
            Color.ydgBase
                .ignoresSafeArea()
            
            Group {
                if profileManager.pendingEmailConfirmation {
                    emailConfirmationWaitScreen
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            authHeader

                            if accountMode == .business {
                                businessPanel
                                    .padding(.top, YDGSpace.lg)
                            } else {
                                // Terms agreement gates every login method (§1.2 EULA).
                                termsAgreementRow
                                    .padding(.top, YDGSpace.lg)

                                // Sign in with Apple first (§4.8 prominence when Google is also offered).
                                socialAuthButtons
                                    .padding(.top, YDGSpace.lg)

                                socialDivider
                                    .padding(.top, YDGSpace.lg)

                                authModeToggle
                                    .padding(.top, YDGSpace.md)

                                if viewModel.isSignUp {
                                    signUpForm
                                } else {
                                    signInForm
                                }

                                authButton
                                    .padding(.top, YDGSpace.lg)

                                if !viewModel.isSignUp {
                                    forgotPasswordButton
                                }

                                if viewModel.isSignUp {
                                    signUpBenefits
                                        .padding(.top, YDGSpace.lg)
                                }

                                if allowSkipToExplore {
                                    exploreWithoutAccountButton
                                        .padding(.top, YDGSpace.md)
                                }
                            }

                            accountModeFooter
                                .padding(.top, YDGSpace.xl)

                            Spacer(minLength: YDGSpace.xxl)
                        }
                        .padding(.horizontal, YDGSpace.margin)
                    }
                    // Keep scrolled content out from under the status bar (there's no nav bar here).
                    .clipped()
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
            .fullScreenCover(isPresented: $showBusinessPortal) {
                BusinessPortalView(
                    defaultEmail: viewModel.email,
                    onClose: { showBusinessPortal = false }
                )
            }
            
            if viewModel.isLoading || socialAuth.isLoading {
                loadingOverlay
            }
            
            if let onDismiss = onDismiss,
               !profileManager.pendingEmailConfirmation {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.ydgTextPrimary)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.ydgOverlay))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Close")
                        .padding(.top, YDGSpace.xs)
                        .padding(.trailing, YDGSpace.sm)
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
                .foregroundColor(Color.ydgAccent)
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
        .alert("Terms Required", isPresented: $showTermsRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please agree to the Terms of Use and Privacy Policy to continue.")
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
                finishAuthRoutingIfReady()
            }
        }
        .onChange(of: socialAuth.isCompletingSocialSignIn) { _, inProgress in
            if !inProgress && profileManager.isLoggedIn {
                finishAuthRoutingIfReady()
            }
        }
    }

    // MARK: - Social Auth

    private var termsAgreementRow: some View {
        HStack(alignment: .top, spacing: YDGSpace.xs) {
            Button {
                agreedToTerms.toggle()
                AgeEligibility.markAcceptedTerms(agreedToTerms)
            } label: {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(agreedToTerms ? Color.ydgAccent : Color.ydgTextTertiary)
                    .frame(width: 30, height: 44, alignment: .topLeading)
            }
            .accessibilityLabel(agreedToTerms ? "Agreed to Terms and Privacy Policy" : "Agree to Terms and Privacy Policy")

            VStack(alignment: .leading, spacing: 4) {
                // Age is already verified on AgeGateView; keep this row to Terms / UGC (§1.2 EULA).
                Text("I agree to the Terms of Use and Privacy Policy. There is no tolerance for objectionable content or abusive users.")
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: YDGSpace.md) {
                    Link("Terms", destination: URL(string: "https://yourdategenie.com/terms")!)
                    Link("Privacy Policy", destination: URL(string: "https://yourdategenie.com/privacy-policy")!)
                }
                .font(.ydg(.footnote, weight: .semibold))
                .foregroundColor(Color.ydgAccent)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var socialDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.ydgBorder)
                .frame(height: 1)
            Text("or use email")
                .ydgText(.footnote, color: .ydgTextTertiary)
                .fixedSize()
            Rectangle()
                .fill(Color.ydgBorder)
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
                        // Generate a per-attempt nonce; hash goes to Apple, raw value goes to
                        // Supabase during token exchange for replay protection.
                        request.nonce = socialAuth.generateAndCacheNonce()
                    },
                    onCompletion: { result in
                        guard agreedToTerms else {
                            showTermsRequiredAlert = true
                            return
                        }
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
                .frame(height: 52)
                .clipShape(Capsule())
                .disabled(socialAuth.isLoading || !agreedToTerms)
                .opacity(agreedToTerms ? 1 : 0.45)
            }

            // Sign in with Google (Supabase OAuth via ASWebAuthenticationSession)
            Button {
                guard agreedToTerms else {
                    showTermsRequiredAlert = true
                    return
                }
                socialAuth.signInWithGoogle()
            } label: {
                Label("Continue with Google", systemImage: "globe")
            }
            .buttonStyle(.ydgSecondary)
            .disabled(socialAuth.isLoading || !agreedToTerms)
            .opacity(agreedToTerms ? 1 : 0.45)

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
                .font(.ydg(.subhead, weight: .medium))
                .foregroundColor(Color.ydgTextSecondary)
                .frame(minHeight: 44)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color.ydgTextPrimary)
                
                Text(loadingOverlayMessage)
                    .ydgText(.subhead, weight: .medium)
            }
            .padding(YDGSpace.xl)
            .background(Color.ydgOverlay, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
        }
    }

    private var loadingOverlayMessage: String {
        if socialAuth.isLoading {
            return "Signing in…"
        }
        return viewModel.isSignUp ? "Creating your account..." : "Signing in..."
    }

    /// Routes past auth once social hydrate finishes. Never waits on display-name collection
    /// (Apple Guideline 4 — SIWA must not require name/email after Authentication Services).
    private func finishAuthRoutingIfReady() {
        guard profileManager.isLoggedIn else { return }
        guard !socialAuth.isCompletingSocialSignIn else { return }

        // `hasEverLoggedIn` is written to keychain on first successful auth and survives
        // sign-out. Use it to distinguish a returning user (→ main app) from a brand-new
        // user who has never set preferences (→ onboarding gate).
        let isReturningUser = KeychainManager.shared.getHasEverLoggedIn()
        if isReturningUser || profileManager.hasCompletedPreferences {
            coordinator.completeSignIn()
        } else {
            coordinator.completeSignUp()
        }
    }
    
    private var forgotPasswordButton: some View {
        Button {
            showResetPasswordSheet = true
        } label: {
            Text("Forgot password?")
        }
        .buttonStyle(.ydgTertiary)
    }
    
    /// Full-screen wait after sign-up: no actions that bypass verification; updates automatically when the confirm link opens in-app.
    private var emailConfirmationWaitScreen: some View {
        let pendingEmail = profileManager.pendingConfirmationEmail ?? viewModel.email

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                EmailConfirmationMagicalWaitView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, YDGSpace.xl)

                Text("Check your email")
                    .ydgText(.title1)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, YDGSpace.lg)

                (Text("We sent a confirmation link to ").foregroundColor(Color.ydgTextSecondary)
                 + Text(pendingEmail).foregroundColor(Color.ydgTextPrimary).fontWeight(.semibold))
                    .font(.ydg(.body))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, YDGSpace.xs)

                VStack(alignment: .leading, spacing: YDGSpace.sm) {
                    EmailConfirmationStep(number: "1", text: "Open the email we just sent")
                    EmailConfirmationStep(number: "2", text: "Tap the confirmation link inside it")
                    EmailConfirmationStep(number: "3", text: "Come back here. The app opens automatically.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ydgCard()
                .padding(.top, YDGSpace.lg)

                Text("If the app doesn't open after you tap the link, use \"Already verified? Sign in\" below.")
                    .ydgText(.footnote, color: .ydgTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, YDGSpace.sm)

                VStack(spacing: YDGSpace.sm) {
                    Button("Already verified? Sign in") {
                        transitionToSignInAfterVerification()
                    }
                    .buttonStyle(.ydgPrimary)

                    HStack(spacing: YDGSpace.sm) {
                        mailAppQuickActions
                        Button(resendCooldownRemaining > 0 ? "Resend in \(resendCooldownRemaining)s" : "Resend email") {
                            performResendConfirmationEmail()
                        }
                        .buttonStyle(YDGButtonStyle(kind: .secondary, isLoading: viewModel.isLoading))
                        .disabled(viewModel.isLoading || resendCooldownRemaining > 0 || pendingEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Button("Use a different email") {
                        useDifferentEmail()
                    }
                    .buttonStyle(.ydgTertiary)
                }
                .padding(.top, YDGSpace.lg)

                Text("Didn't get it? Check spam or promotions, or use a different email.")
                    .ydgText(.footnote, color: .ydgTextTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)

                if let resendFeedbackMessage {
                    Text(resendFeedbackMessage)
                        .ydgText(.footnote, color: .ydgTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, YDGSpace.xs)
                }
            }
            .padding(.horizontal, YDGSpace.margin)
            .padding(.bottom, YDGSpace.xxl)
        }
    }

    private var mailAppQuickActions: some View {
        HStack(spacing: 10) {
            MailQuickActionButton(title: "Open Mail") {
                openURLIfPossible(URL(string: "message://") ?? URL(string: "mailto:")!)
            }
        }
    }
    
    private var authHeader: some View {
        VStack(spacing: YDGSpace.sm) {
            DateNightMarkView(side: 96)
            
            Text(authHeaderTitle)
                .ydgText(.title1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, YDGSpace.xs)
            
            Text(authHeaderSubtitle)
                .ydgText(.body, color: .ydgTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, YDGSpace.xxl)
    }

    private var authHeaderTitle: String {
        if coordinator.authRequiredForIntent != nil {
            return "Sign in to plan a date"
        }
        if accountMode == .business {
            return "Partner with us"
        }
        return viewModel.isSignUp ? "Create your account" : "Welcome back"
    }

    private var authHeaderSubtitle: String {
        if coordinator.authRequiredForIntent != nil {
            return "A free account keeps your plans and lets you share them with your partner."
        }
        if accountMode == .business {
            return "Reach couples planning date nights near you. Restaurants, bars, experiences, retail and events all welcome."
        }
        return viewModel.isSignUp
            ? "Save plans, share them with your partner and keep your memories in one place."
            : "Pick up where you left off."
    }
    
    /// Business partners are a side door, so the switch lives at the bottom of the screen.
    private var accountModeFooter: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                accountMode = accountMode == .business ? .individual : .business
            }
        } label: {
            HStack(spacing: 4) {
                Text(accountMode == .business ? "Planning a date?" : "Own a venue?")
                    .foregroundColor(Color.ydgTextSecondary)
                Text(accountMode == .business ? "Sign in" : "Partner with us")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.ydgAccent)
            }
            .font(.ydg(.subhead))
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private var businessPanel: some View {
        VStack(alignment: .leading, spacing: YDGSpace.lg) {
            VStack(alignment: .leading, spacing: YDGSpace.sm) {
                AuthBenefitRow(text: "Featured inside AI date itineraries")
                AuthBenefitRow(text: "Reach couples mid-plan, not mid-scroll")
                AuthBenefitRow(text: "Launch partner placement rates")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ydgCard()

            Button("Continue to partner portal") {
                showBusinessPortal = true
            }
            .buttonStyle(.ydgPrimary)
        }
    }

    private var authModeToggle: some View {
        YDGSegmentedControl(
            options: [false, true],
            selection: $viewModel.isSignUp,
            title: { $0 ? "Create account" : "Sign in" }
        )
    }
    
    private var signInForm: some View {
        VStack(spacing: YDGSpace.md) {
            LuxuryTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            
            AuthSecureField(
                title: "Password",
                placeholder: "Enter your password",
                text: $viewModel.password
            )
            .focused($focusedField, equals: .password)
        }
        .padding(.top, YDGSpace.lg)
    }
    
    private var signUpForm: some View {
        VStack(spacing: YDGSpace.md) {
            if viewModel.isSignUp {
                signUpBenefitsInline
            }
            
            HStack(spacing: YDGSpace.sm) {
                LuxuryTextField(
                    title: "First name",
                    placeholder: "Maya",
                    text: $viewModel.firstName,
                    icon: nil
                )
                .focused($focusedField, equals: .firstName)
                
                LuxuryTextField(
                    title: "Last name",
                    placeholder: "Optional",
                    text: $viewModel.lastName,
                    icon: nil
                )
                .focused($focusedField, equals: .lastName)
            }
            
            LuxuryTextField(
                title: "Email",
                placeholder: "you@example.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            
            VStack(alignment: .leading, spacing: 0) {
                AuthSecureField(
                    title: "Password",
                    placeholder: "At least 8 characters",
                    text: $viewModel.password
                )
                .focused($focusedField, equals: .password)
            }
            
            AuthSecureField(
                title: "Confirm password",
                placeholder: "Type it again",
                text: $viewModel.confirmPassword
            )
            .focused($focusedField, equals: .confirmPassword)
        }
        .padding(.top, YDGSpace.lg)
    }
    
    private var signUpBenefitsInline: some View {
        VStack(alignment: .leading, spacing: 10) {
            AuthBenefitRow(text: "Personalized multi-stop date plans")
            AuthBenefitRow(text: "Real venues with verified details")
            AuthBenefitRow(text: "Dietary restrictions always respected")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var authButton: some View {
        VStack(spacing: YDGSpace.xs) {
            Button {
                guard agreedToTerms else {
                    showTermsRequiredAlert = true
                    return
                }
                if viewModel.isSignUp {
                    performSignUp()
                } else {
                    performSignIn()
                }
            } label: {
                Text(viewModel.isSignUp ? "Create account" : "Sign in")
            }
            .buttonStyle(.ydgPrimary)
            .disabled(!viewModel.isFormValid || !agreedToTerms)
            
            Button {
                withAnimation {
                    viewModel.isSignUp.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.isSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(Color.ydgTextSecondary)
                    Text(viewModel.isSignUp ? "Sign in" : "Sign up")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ydgAccent)
                }
                .font(.ydg(.subhead))
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var signUpBenefits: some View {
        HStack(alignment: .top, spacing: YDGSpace.sm) {
            Image(systemName: "lock.shield")
                .font(.system(size: 17))
                .foregroundColor(Color.ydgTextSecondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your data is private")
                    .ydgText(.subhead, weight: .semibold)
                Text("We never share your personal information. Your preferences are only used to plan your dates.")
                    .ydgText(.footnote, color: .ydgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .ydgCard()
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
        Button(title, action: action)
            .buttonStyle(.ydgSecondary)
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
                Color.ydgBase
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: YDGSpace.md) {
                    VStack(alignment: .leading, spacing: YDGSpace.xs) {
                        Text("Reset your password")
                            .ydgText(.title1)
                            .accessibilityAddTraits(.isHeader)
                        Text("Enter your email and we'll send you a link to reset your password.")
                            .ydgText(.body, color: .ydgTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    LuxuryTextField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $resetEmail,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )
                    .padding(.top, YDGSpace.xs)
                    
                    Spacer()

                    Button("Send reset link") {
                        onSend(resetEmail.isEmpty ? email : resetEmail)
                    }
                    .buttonStyle(.ydgPrimary)
                    .disabled(resetEmail.isEmpty && email.isEmpty)
                }
                .padding(.horizontal, YDGSpace.margin)
                .padding(.top, YDGSpace.md)
                .padding(.bottom, YDGSpace.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Color.ydgAccent)
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
                .foregroundColor(Color.ydgSuccess)
                .accessibilityHidden(true)
            
            Text(text)
                .ydgText(.subhead, weight: .regular, color: .ydgTextPrimary)
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
        VStack(alignment: .leading, spacing: YDGSpace.xs) {
            Text(title)
                .ydgText(.subhead, weight: .medium)
            
            HStack(spacing: YDGSpace.sm) {
                Group {
                    if isSecure {
                        SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.ydgTextTertiary))
                    } else {
                        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.ydgTextTertiary))
                    }
                }
                .font(.ydg(.body))
                .foregroundColor(Color.ydgTextPrimary)
                .accessibilityLabel(title)
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(Color.ydgTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(isSecure ? "Show password" : "Hide password")
            }
            .padding(.leading, YDGSpace.md)
            .padding(.trailing, 4)
            .frame(minHeight: 52)
            .background(Color.ydgRaised, in: RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: YDGRadius.card, style: .continuous)
                    .stroke(text.isEmpty ? Color.ydgBorder : Color.ydgBorderStrong, lineWidth: 1)
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
                        .foregroundStyle(Color.ydgIconCream.opacity(0.8))
                        .offset(y: -52)
                        .rotationEffect(.degrees(Double(i) * 36 + spin))
                }

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.ydgIconCream.opacity(0.15),
                                Color.ydgIconCream,
                                Color.ydgIconCream.opacity(0.5),
                                Color.ydgIconCream.opacity(0.15)
                            ],
                            center: .center
                        ),
                        lineWidth: 3.5
                    )
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-spin * 1.25))

                Image(systemName: "envelope.open")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.ydgIconCream)
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
                    .fill(Color.ydgHighlightSubtle)
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(Font.ydgSans(13, weight: .bold))
                    .foregroundColor(Color.ydgHighlight)
            }
            .accessibilityHidden(true)
            Text(text)
                .ydgText(.subhead, weight: .regular, color: .ydgTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(NavigationCoordinator.shared)
}
