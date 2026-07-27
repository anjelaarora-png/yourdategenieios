import AuthenticationServices
import CryptoKit
import GoogleSignIn
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
    /// True while Apple/Google token exchange + profile hydrate is in flight — auth UI must not route away early.
    @Published var isCompletingSocialSignIn = false

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
            self.error = Self.userFacingError(
                message: "Sign in with Apple didn’t return a valid token. Try again, or use email login."
            )
            return
        }
        guard !isLoading else { return }
        isLoading = true
        isCompletingSocialSignIn = true
        let rawNonce = currentRawNonce
        currentRawNonce = nil

        guard let rawNonce, !rawNonce.isEmpty else {
            isLoading = false
            isCompletingSocialSignIn = false
            AppLogger.error("Sign in with Apple: missing nonce (onRequest did not run)", category: .auth)
            self.error = Self.userFacingError(
                message: "Sign in with Apple couldn’t start securely. Close the app and try again."
            )
            return
        }

        // Apple only sends fullName on the very first authorization. Capture it now before the
        // async boundary so it's available for profile hydration after the token exchange.
        let displayName: String? = {
            guard let fn = credential.fullName else { return nil }
            let parts = [fn.givenName, fn.familyName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }()

        Task { @MainActor in
            defer {
                self.isLoading = false
                self.isCompletingSocialSignIn = false
            }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: rawNonce)
                if let name = displayName, !name.isEmpty {
                    await SupabaseService.shared.updateAppleUserDisplayName(name)
                }
                try await UserProfileManager.shared.refreshAfterSocialSignIn(
                    preferredDisplayName: displayName
                )
            } catch {
                self.error = Self.mapAuthError(error, provider: "Apple")
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

    // MARK: - Sign in with Google (native)

    /// Presents the NATIVE Google account sheet (GoogleSignIn SDK) and exchanges the returned ID
    /// token for a Supabase session. Unlike the old web `signInWithOAuth` flow, nothing routes
    /// through `supabase.co`, so the user sees "Your Date Genie" instead of the project URL.
    ///
    /// The GoogleSignIn iOS SDK doesn't expose a nonce on its sign-in API; the ID token is still
    /// verified by Google's signature and its audience (the iOS client ID) on the Supabase side.
    func signInWithGoogle() {
        guard !isLoading else { return }

        guard Config.isGoogleSignInConfigured else {
            error = Self.userFacingError(
                message: "Google Sign-In isn't configured yet. Add GOOGLE_IOS_CLIENT_ID and GOOGLE_REVERSED_CLIENT_ID to Secrets.xcconfig and rebuild."
            )
            return
        }

        guard let presenter = Self.topViewController() else {
            AppLogger.error("Sign in with Google: no presenting view controller", category: .auth)
            error = Self.userFacingError(
                message: "Couldn't open Google Sign-In on this screen. Try again, or use email login."
            )
            return
        }

        // Ensure the SDK has a client ID even if Info.plist auto-read is unavailable.
        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleIOSClientID)
        }

        isLoading = true
        isCompletingSocialSignIn = true

        Task { @MainActor in
            defer {
                self.isLoading = false
                self.isCompletingSocialSignIn = false
            }
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)

                guard let idToken = result.user.idToken?.tokenString else {
                    throw Self.userFacingError(message: "Google sign in did not return an ID token.")
                }
                let accessToken = result.user.accessToken.tokenString

                _ = try await SupabaseService.shared.signInWithGoogleIdToken(
                    idToken: idToken,
                    accessToken: accessToken
                )
                let googleNameRaw = result.user.profile?.name
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let googleName: String? = googleNameRaw.isEmpty ? nil : googleNameRaw
                if let googleName {
                    await SupabaseService.shared.updateAppleUserDisplayName(googleName)
                }
                try await UserProfileManager.shared.refreshAfterSocialSignIn(
                    preferredDisplayName: googleName
                )
            } catch {
                // User dismissed the native sheet — don't surface that as an error.
                let nsError = error as NSError
                let cancelled = nsError.domain == kGIDSignInErrorDomain
                    && nsError.code == GIDSignInError.canceled.rawValue
                if !cancelled {
                    self.error = Self.mapAuthError(error, provider: "Google")
                    AppLogger.error("Sign in with Google failed: \(error)", category: .auth)
                }
            }
        }
    }

    /// Walks the active window's presented chain to find a controller suitable for presenting the
    /// Google sheet from. Returns nil if there is no foreground window scene yet.
    static func topViewController() -> UIViewController? {
        let keyWindow = preferredWindow()
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    /// Prefer the foreground-active scene's key (or first visible) window — critical on iPad
    /// multi-window / Stage Manager where `isKeyWindow` heuristics can miss the right scene.
    /// `nonisolated` so `ASAuthorizationController` presentation can call it off the main actor.
    nonisolated static func preferredWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let ordered = scenes.sorted { lhs, rhs in
            rank(lhs.activationState) < rank(rhs.activationState)
        }
        for scene in ordered {
            if let key = scene.windows.first(where: { $0.isKeyWindow }) { return key }
            if let visible = scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 }) { return visible }
        }
        return nil
    }

    nonisolated private static func rank(_ state: UIScene.ActivationState) -> Int {
        switch state {
        case .foregroundActive: return 0
        case .foregroundInactive: return 1
        case .background: return 2
        case .unattached: return 3
        @unknown default: return 4
        }
    }

    // MARK: - User-facing errors

    static func userFacingError(message: String, code: Int = -1) -> NSError {
        NSError(
            domain: "SocialAuthService",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    /// Maps opaque SDK / network failures to copy reviewers and users can act on.
    static func mapAuthError(_ error: Error, provider: String) -> Error {
        let ns = error as NSError
        if ns.domain == "SocialAuthService" { return error }

        if ns.domain == NSURLErrorDomain {
            return userFacingError(
                message: "Couldn't connect to sign-in service. Check your connection and try again, or use email login."
            )
        }

        let desc = error.localizedDescription
        let lower = desc.lowercased()

        // Most common App Review / iPad failure: Client IDs don't include the Bundle ID.
        if lower.contains("audience") || lower.contains("unacceptable") {
            return userFacingError(
                message: "Sign in with Apple failed (app ID mismatch). In Supabase → Authentication → Providers → Apple → Client IDs, add exactly: com.yourdategenie.app — then try again."
            )
        }
        if lower.contains("nonce") {
            return userFacingError(
                message: "Sign in with Apple failed a security check (nonce). Close the app fully and try again."
            )
        }
        if desc.contains("network") || desc.contains("timed out") || desc.contains("offline")
            || lower.contains("network") || lower.contains("timed out") || lower.contains("offline") {
            return userFacingError(
                message: "Couldn't connect to sign-in service. Check your connection and try again, or use email login."
            )
        }
        if lower.contains("jwt") || lower.contains("provider")
            || lower.contains("invalid") || lower.contains("unauthorized")
            || lower.contains("did not complete") {
            // Keep a short technical hint so dashboard misconfig is diagnosable on-device.
            let hint = desc.count > 120 ? String(desc.prefix(117)) + "…" : desc
            return userFacingError(
                message: "Couldn't complete Sign in with \(provider). \(hint)"
            )
        }
        if lower.contains("profile") || lower.contains("couple") || lower.contains("users") {
            return userFacingError(
                message: "Signed in, but we couldn't finish setting up your account. Try again, or use email login."
            )
        }
        // Fall through with original message so we don't hide the real failure.
        return userFacingError(message: desc.isEmpty
            ? "Couldn't complete Sign in with \(provider). Try email login, or try again in a moment."
            : desc)
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
            Task { @MainActor in
                self.error = Self.userFacingError(
                    message: "Sign in with Apple didn’t return a valid token. Try again, or use email login."
                )
            }
            return
        }

        Task { @MainActor in
            self.isLoading = true
            self.isCompletingSocialSignIn = true
            let rawNonce = self.currentRawNonce
            self.currentRawNonce = nil
            guard let rawNonce, !rawNonce.isEmpty else {
                self.isLoading = false
                self.isCompletingSocialSignIn = false
                self.error = Self.userFacingError(
                    message: "Sign in with Apple couldn’t start securely. Close the app and try again."
                )
                return
            }
            let displayName: String? = {
                guard let fn = credential.fullName else { return nil }
                let parts = [fn.givenName, fn.familyName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }()
            defer {
                self.isLoading = false
                self.isCompletingSocialSignIn = false
            }
            do {
                _ = try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: rawNonce)
                if let name = displayName, !name.isEmpty {
                    await SupabaseService.shared.updateAppleUserDisplayName(name)
                }
                try await UserProfileManager.shared.refreshAfterSocialSignIn(
                    preferredDisplayName: displayName
                )
            } catch {
                self.error = Self.mapAuthError(error, provider: "Apple")
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
            self.error = Self.mapAuthError(error, provider: "Apple")
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding (Sign in with Apple)

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = SocialAuthService.preferredWindow() {
            return window
        }
        // Attach a window to a scene when possible — bare `UIWindow()` has no scene and
        // can fail silently on iPad multi-window.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let scene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first {
            return UIWindow(windowScene: scene)
        }
        return UIWindow()
    }
}
