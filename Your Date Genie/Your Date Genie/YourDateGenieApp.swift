import SwiftUI

@main
struct YourDateGenieApp: App {
    @StateObject private var coordinator = NavigationCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(coordinator)
        }
    }
}
