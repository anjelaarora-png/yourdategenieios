import UIKit

/// UIKit application delegate, wired into the SwiftUI lifecycle via `@UIApplicationDelegateAdaptor`.
///
/// Responsibilities here are intentionally narrow: capture every incoming URL and forward it to
/// the Supabase Auth SDK so OAuth redirects and email-confirmation deep links are processed
/// regardless of whether the app was cold-launched or already running.
///
/// Navigation side-effects (routing to the correct screen after sign-in) are handled by the
/// `.onOpenURL` modifier in `YourDateGenieApp`.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Cold launch

    /// Handles a URL delivered as a launch option when the app is cold-started by tapping an
    /// OAuth redirect or email-confirmation link.
    ///
    /// Note: apps that use the UIScene lifecycle (UIApplicationSupportsMultipleScenes = true,
    /// as configured in this project's Info.plist) receive cold-launch URLs through the scene
    /// connection path instead, which SwiftUI surfaces via `.onOpenURL`. This method acts as a
    /// belt-and-suspenders fallback for any edge case where the URL arrives before a scene is ready.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let url = launchOptions?[.url] as? URL {
            print("[Auth] Deep link received on cold launch: \(url.absoluteString)")
            SupabaseService.shared.handle(url)
        }
        return true
    }

    // MARK: - Warm / background open

    /// Handles a URL when the app is already running (foreground or background) and is opened
    /// via a custom-scheme URL (`yourdategenie://…`).
    ///
    /// In a UIScene-based app this delegate method is called alongside the scene's
    /// `openURLContexts`, so the Supabase SDK may see the URL twice. `AuthClient.handle(_:)`
    /// is idempotent for the same URL, so duplicate calls are safe.
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("[Auth] AppDelegate open URL: \(url.absoluteString)")
        SupabaseService.shared.handle(url)
        return true
    }
}
