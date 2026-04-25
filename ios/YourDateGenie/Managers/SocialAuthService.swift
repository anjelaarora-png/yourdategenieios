import AuthenticationServices
import SwiftUI

// MARK: - SocialAuthService

/// Handles Sign in with Apple (native) and Sign in with Google (Supabase PKCE OAuth).
///
/// All token exchanges go through `SupabaseService.shared` so the cached session, PKCE verifier,
/// and `isAuthenticated` flag all live on a single Supabase client. Using a different client for
/// OAuth made the PKCE code verifier unreachable during `exchangeCodeForSession`, which silently
/// bounced users back to the login screen after Google completed.
///
/// Observe `SocialAuthService.shared.error` in an alert to surface failures to the user.
@MainActor
final class SocialAuthService: NSObject, ObservableObject {
    static let shared = SocialAuthService()

    @Published var isLoading = false
    @Published var error: Error?

    private override init() {}

    // MARK: - Sign in with Apple

    /// Called from `SignInWithAppleButton.onCompletion` with the authorization Apple already
    /// collected. Extracts the identity token and exchanges it for a Supabase session without
    /// opening a second system sheet.
    ///
    /// This is the correct entry point when using SwiftUI's `SignInWithAppleButton` — the button
    /// handles showing the native sheet; we only need to process the result it hands back.
    func handleAppleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData  = credential.identityToken,
              let idToken    = String(data: tokenData, encoding: .utf8) else {
            AppLogger.error("Sign in with Apple: missing or unreadable identity token", category: .auth)
            return
        }
        guard !isLoading else { return }
        isLoading = true
        Task { @MainActor in
            defer { self.isLoading = false }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken)
                await UserProfileManager.shared.refreshAfterSocialSignIn()
            } catch {
                self.error = error
                AppLogger.error("Sign in with Apple failed: \(error)", category: .auth)
            }
        }
    }

    /// Initiates a Sign in with Apple flow via a manually created `ASAuthorizationController`.
    /// Use this only when presenting from a context that does NOT already use `SignInWithAppleButton`
    /// (e.g. a custom button outside the auth screen). For `SignInWithAppleButton` use
    /// `handleAppleAuthorization(_:)` in its `onCompletion` instead.
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Sign in with Google

    /// Launches Google OAuth via Supabase's PKCE helper. The SDK opens its own
    /// `ASWebAuthenticationSession`, exchanges the returned `?code=…` for a session, and updates
    /// the shared client before this call returns.
    func signInWithGoogle() {
        guard !isLoading else { return }
        isLoading = true
        Task { @MainActor in
            defer { self.isLoading = false }
            do {
                _ = try await SupabaseService.shared.signInWithGoogle()
                await UserProfileManager.shared.refreshAfterSocialSignIn()
            } catch {
                let nsError = error as NSError
                // User cancelled the web sheet — don't show an error alert for that.
                let cancelled = nsError.domain == ASWebAuthenticationSessionErrorDomain
                    && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                if !cancelled {
                    self.error = error
                    AppLogger.error("Sign in with Google failed: \(error)", category: .auth)
                }
            }
        }
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
            self.isLoading = true
            defer { self.isLoading = false }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken)
                await UserProfileManager.shared.refreshAfterSocialSignIn()
            } catch {
                self.error = error
                AppLogger.error("Sign in with Apple failed: \(error)", category: .auth)
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
        Task { @MainActor in
            self.error = error
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding (Sign in with Apple)

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
