import AuthenticationServices
import SwiftUI

// MARK: - SocialAuthService

/// Handles Sign in with Apple (native) and Sign in with Google (Supabase OAuth via ASWebAuthenticationSession).
/// Add SocialAuthService.shared.error to an alert in the calling view to surface failures.
@MainActor
final class SocialAuthService: NSObject, ObservableObject {
    static let shared = SocialAuthService()

    @Published var isLoading = false
    @Published var error: Error?

    private override init() {}

    // MARK: - Sign in with Apple

    /// Initiates the native Sign in with Apple flow and exchanges the identity token with Supabase.
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Sign in with Google

    /// Opens a Supabase-hosted Google OAuth page inside ASWebAuthenticationSession.
    /// The existing `handleAuthCallback(url:)` in YourDateGenieApp catches the redirect.
    func signInWithGoogle() {
        isLoading = true

        // Supabase Google OAuth URL — the app's URL scheme is `yourdategenie://`
        let supabaseURL   = AppConfig.supabaseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        let redirectURL   = "yourdategenie://auth-callback"
        guard let encoded = redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let oauthURL = URL(string: "\(supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(encoded)") else {
            isLoading = false
            return
        }

        let session = ASWebAuthenticationSession(
            url: oauthURL,
            callbackURLScheme: "yourdategenie"
        ) { [weak self] _, sessionError in
            Task { @MainActor [weak self] in
                self?.isLoading = false
                if let sessionError, (sessionError as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    self?.error = sessionError
                }
                // On success the system will call scene(_:openURLContexts:) / onOpenURL which
                // routes the callback URL through NavigationCoordinator.handleAuthCallback(url:)
            }
        }
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SocialAuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData   = credential.identityToken,
              let idToken     = String(data: tokenData, encoding: .utf8) else {
            return
        }

        Task { @MainActor in
            isLoading = true
            do {
                // Exchange the Apple identity token for a Supabase session
                try await SupabaseManager.shared.client.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: idToken)
                )
            } catch {
                self.error = error
                AppLogger.error("Sign in with Apple failed: \(error)", category: .auth)
            }
            isLoading = false
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Ignore cancellations
        guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
        Task { @MainActor in
            self.error = error
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
