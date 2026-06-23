import Foundation
import FirebaseCore

/// Configures Firebase once, reading `GoogleService-Info.plist` from the app bundle.
/// Firebase on iOS is used ONLY for the business partner `business_listings` collection
/// (project `your-date-genie`). Couple app data stays on Supabase.
enum FirebaseBootstrap {
    private static var didConfigure = false

    static func configureIfNeeded() {
        guard !didConfigure else { return }
        guard Config.isFirebaseConfigured else {
            AppLogger.info("Firebase not configured — add GoogleService-Info.plist to the app target. Business applications will fail until then.")
            return
        }
        guard FirebaseApp.app() == nil else {
            didConfigure = true
            return
        }
        FirebaseApp.configure()
        didConfigure = true
    }
}
