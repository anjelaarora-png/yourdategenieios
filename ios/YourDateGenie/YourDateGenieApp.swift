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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        if let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
           let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value {
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
        }
        
        if let type = queryItems.first(where: { $0.name == "type" })?.value,
           type == "email_confirmation" {
            Task {
                await MainActor.run {
                    coordinator.completeSignIn()
                }
            }
        }
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
