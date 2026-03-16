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
        guard url.scheme == "yourdategenie" else { return }
        
        let host = url.host ?? ""
        
        switch host {
        case "auth-callback":
            handleAuthCallback(url)
        case "home":
            coordinator.dismissToHome()
        case "plan":
            break
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
                    await MainActor.run {
                        coordinator.completeSignIn()
                    }
                } catch {
                    print("Auth callback error: \(error)")
                }
            }
            return
        }
        
        // type=email_confirmation without tokens: user confirmed in browser; still need to sign in in app
        if params["type"] == "email_confirmation" {
            Task {
                await MainActor.run {
                    coordinator.completeSignIn()
                }
            }
        }
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
