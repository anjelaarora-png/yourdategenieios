import SwiftUI

@main
struct YourDateGenieApp: App {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @StateObject private var notificationManager = PushNotificationManager.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var supabase = SupabaseService.shared
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(coordinator)
                .environmentObject(memoryManager)
                .environmentObject(supabase)
                .onAppear {
                    notificationManager.requestAuthorization()
                    validateConfiguration()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openMemoryGallery)) { notification in
                    coordinator.showMemoryGallery = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .openMemoryCapture)) { notification in
                    coordinator.isShowingMemoryCapture = true
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Support both app scheme and https (universal link) for partner join
        let scheme = url.scheme ?? ""
        let host = url.host ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if scheme == "https", host.contains("yourdategenie"), path == "partner/join" {
            if let sessionId = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "session" })?.value {
                coordinator.showPartnerJoin(sessionId: sessionId, inviterName: nil)
            }
            return
        }

        guard scheme == "yourdategenie" else { return }

        switch host {
        case "auth-callback":
            handleAuthCallback(url)
        case "home":
            coordinator.dismissToHome()
        case "plan":
            break
        case "partner":
            if path == "join", let sessionId = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "session" })?.value {
                coordinator.showPartnerJoin(sessionId: sessionId, inviterName: nil)
            }
        default:
            print("Unknown deep link: \(url)")
        }
    }
    
    private func handleAuthCallback(_ url: URL) {
        // Supabase may send tokens in query (?key=val) or in fragment (#key=val). Parse both.
        let params = parseAuthCallbackParams(from: url)
        guard !params.isEmpty else { return }
        
        if let accessToken = params["access_token"], let refreshToken = params["refresh_token"] {
            Task {
                do {
                    try await supabase.handleAuthCallback(accessToken: accessToken, refreshToken: refreshToken)
                    let ensuredUser: (UUID, String, String)? = await MainActor.run {
                        guard let user = supabase.currentUser else { return nil }
                        let displayName = [user.firstName, user.lastName].filter { !$0.isEmpty }.joined(separator: " ")
                        let nameForRow = displayName.isEmpty ? (user.email ?? "Guest") : displayName
                        return (user.id, user.email ?? "", nameForRow)
                    }
                    if let (uid, email, name) = ensuredUser {
                        do {
                            try await supabase.ensureUserAndCoupleIfMissing(userId: uid, email: email, name: name)
                        } catch {
                            print("ensureUserAndCoupleIfMissing after auth callback: \(error)")
                        }
                    }
                    await MainActor.run {
                        coordinator.completeSignIn()
                        if !UserProfileManager.shared.hasCompletedPreferences {
                            coordinator.presentHeroBeforeInitialPreferences = true
                        }
                    }
                } catch {
                    print("Auth callback error: \(error)")
                }
            }
            return
        }
        
        // type=email_confirmation without tokens: link may have opened in browser only. We intentionally
        // do not clear pending email state here — the user should open the link in the app or sign in after verifying.
    }
    
    /// Parses access_token, refresh_token, type etc. from URL query and/or fragment (Supabase uses fragment for redirects).
    private func parseAuthCallbackParams(from url: URL) -> [String: String] {
        var result: [String: String] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value { result[item.name] = value }
            }
        }
        if let fragment = url.fragment, !fragment.isEmpty {
            let pairs = fragment.split(separator: "&")
            for pair in pairs {
                let parts = pair.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                    let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                    result[key] = value
                }
            }
        }
        return result
    }
    
    private func validateConfiguration() {
        #if DEBUG
        let missingKeys = AppConfig.validateConfiguration()
        if !missingKeys.isEmpty {
            print("⚠️ Warning: Missing configuration keys: \(missingKeys.joined(separator: ", "))")
            print("Please set these in your environment or Info.plist")
        }
        #endif
    }
}
