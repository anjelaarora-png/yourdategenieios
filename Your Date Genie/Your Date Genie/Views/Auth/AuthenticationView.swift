import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = AuthenticationViewModel()
    @FocusState private var focusedField: AuthField?
    
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
                    
                    if viewModel.isSignUp {
                        signUpBenefits
                            .padding(.top, 32)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
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
    }
    
    private var authHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(LinearGradient.goldShimmer)
                .shadow(color: Color.luxuryGold.opacity(0.5), radius: 20)
            
            HStack(spacing: 6) {
                Text("Your Date")
                    .font(Font.header(24, weight: .regular))
                    .foregroundColor(Color.luxuryGold)
                Text("Genie")
                    .font(Font.tangerine(48, weight: .bold))
                    .italic()
                    .foregroundColor(Color.luxuryGold)
            }
            
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
                        viewModel.isSignUp ? Color.clear : LinearGradient.goldShimmer
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
                        viewModel.isSignUp ? LinearGradient.goldShimmer : Color.clear
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
            
            LuxurySecureField(
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
            
            LuxurySecureField(
                title: "Password",
                placeholder: "••••••••",
                text: $viewModel.password,
                icon: "lock.fill"
            )
            .focused($focusedField, equals: .password)
            
            LuxurySecureField(
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
            BenefitRow(text: "Personalized multi-stop date plans")
            BenefitRow(text: "Real venues with verified details")
            BenefitRow(text: "Dietary restrictions always respected")
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
        do {
            try UserProfileManager.shared.signIn(email: viewModel.email, password: viewModel.password)
            coordinator.completeSignIn()
        } catch let error as AuthenticationError {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        } catch {
            viewModel.errorMessage = "An unexpected error occurred"
            viewModel.showError = true
        }
    }
    
    private func performSignUp() {
        focusedField = nil
        
        guard viewModel.password == viewModel.confirmPassword else {
            viewModel.errorMessage = "Passwords do not match"
            viewModel.showError = true
            return
        }
        
        do {
            try UserProfileManager.shared.signUp(
                firstName: viewModel.firstName,
                lastName: viewModel.lastName,
                email: viewModel.email,
                password: viewModel.password
            )
            coordinator.completeSignUp()
        } catch let error as AuthenticationError {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        } catch {
            viewModel.errorMessage = "An unexpected error occurred"
            viewModel.showError = true
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
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

// MARK: - Secure Field
struct LuxurySecureField: View {
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

// MARK: - Auth Field
enum AuthField {
    case firstName, lastName, email, password, confirmPassword
}

// MARK: - ViewModel
class AuthenticationViewModel: ObservableObject {
    @Published var isSignUp = true
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
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
