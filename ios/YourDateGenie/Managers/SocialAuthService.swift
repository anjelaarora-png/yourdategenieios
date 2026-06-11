import AuthenticationServices
import CryptoKit
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

    /// Raw nonce generated per-attempt; stored so `SignInWithAppleButton.onRequest` and
    /// `handleAppleAuthorization` share the same value without a race.
    private(set) var currentRawNonce: String?

    private override init() {}

    // MARK: - Nonce helpers

    /// Generates a cryptographically random nonce and caches it for the current attempt.
    /// Call from `SignInWithAppleButton.onRequest`.
    func generateAndCacheNonce() -> String {
        let raw = UUID().uuidString + UUID().uuidString
        currentRawNonce = raw
        return sha256(raw)
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Sign in with Apple

    /// Called from `SignInWithAppleButton.onCompletion` with the authorization Apple already
    /// collected. Extracts the identity token, passes the cached raw nonce, exchanges for a
    /// Supabase session, and captures full name on first sign-in (Apple only sends it once).
    func handleAppleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData  = credential.identityToken,
              let idToken    = String(data: tokenData, encoding: .utf8) else {
            AppLogger.error("Sign in with Apple: missing or unreadable identity token", category: .auth)
            return
        }
        guard !isLoading else { return }
        isLoading = true
        let rawNonce = currentRawNonce
        currentRawNonce = nil

        // Apple only sends fullName on the very first authorization. Capture it now before the
        // async boundary so it's available for profile hydration after the token exchange.
        let displayName: String? = {
            guard let fn = credential.fullName else { return nil }
            let parts = [fn.givenName, fn.familyName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }()

        Task { @MainActor in
            defer { self.isLoading = false }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: rawNonce)
                if let name = displayName, !name.isEmpty {
                    await SupabaseService.shared.updateAppleUserDisplayName(name)
                }
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
        let hashedNonce = generateAndCacheNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

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
            let rawNonce = self.currentRawNonce
            self.currentRawNonce = nil
            let displayName: String? = {
                guard let fn = credential.fullName else { return nil }
                let parts = [fn.givenName, fn.familyName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }()
            defer { self.isLoading = false }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: rawNonce)
                if let name = displayName, !name.isEmpty {
                    await SupabaseService.shared.updateAppleUserDisplayName(name)
                }
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
