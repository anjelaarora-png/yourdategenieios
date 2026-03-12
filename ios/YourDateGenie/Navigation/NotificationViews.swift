import SwiftUI

// MARK: - App Notification Model
struct AppNotification: Identifiable, Equatable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool = false
    var imageUrl: String?
    
    enum NotificationType: String {
        case datePlanReady = "plan_ready"
        case dateReminder = "reminder"
        case newInspiration = "inspiration"
        case giftIdea = "gift"
        case specialOccasion = "occasion"
        case weekendSuggestion = "weekend"
    }
    
    var icon: String {
        switch type {
        case .datePlanReady: return "sparkles"
        case .dateReminder: return "calendar.badge.clock"
        case .newInspiration: return "lightbulb.fill"
        case .giftIdea: return "gift.fill"
        case .specialOccasion: return "star.fill"
        case .weekendSuggestion: return "sun.max.fill"
        }
    }
    
    var accentColor: Color {
        switch type {
        case .datePlanReady: return Color.luxuryGold
        case .dateReminder: return Color.luxuryGoldLight
        case .newInspiration: return Color(hex: "FFD700")
        case .giftIdea: return Color(hex: "FF69B4")
        case .specialOccasion: return Color(hex: "FFB347")
        case .weekendSuggestion: return Color(hex: "87CEEB")
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var showNotificationsSheet = false
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private init() {
        loadSampleNotifications()
    }
    
    private func loadSampleNotifications() {
        notifications = [
            AppNotification(
                type: .weekendSuggestion,
                title: "Weekend Magic Awaits!",
                message: "The weather looks perfect for a rooftop dinner. Want us to plan something special?",
                timestamp: Date(),
                imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .newInspiration,
                title: "New Experience Unlocked",
                message: "A hidden speakeasy just opened nearby - perfect for your next adventure!",
                timestamp: Date().addingTimeInterval(-3600),
                imageUrl: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .datePlanReady,
                title: "Your Genie Has Ideas!",
                message: "Based on your preferences, we've crafted 3 magical evening plans for you.",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true,
                imageUrl: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=100&h=100&fit=crop"
            ),
            AppNotification(
                type: .giftIdea,
                title: "Thoughtful Gesture Alert",
                message: "We found the perfect surprise to make your next date unforgettable.",
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                imageUrl: "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=100&h=100&fit=crop"
            )
        ]
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
    }
}

// MARK: - Notification Bell Button
struct NotificationBellButton: View {
    @ObservedObject var notificationManager: NotificationManager
    @State private var bellAnimation = false
    
    var body: some View {
        Button {
            notificationManager.showNotificationsSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    if notificationManager.unreadCount > 0 {
                        Circle()
                            .fill(Color.luxuryGold.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)
                    }
                    
                    Image(systemName: notificationManager.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.luxuryGold)
                        .rotationEffect(.degrees(bellAnimation && notificationManager.unreadCount > 0 ? 15 : 0))
                        .animation(
                            notificationManager.unreadCount > 0 ?
                            .easeInOut(duration: 0.15).repeatCount(6, autoreverses: true) : .default,
                            value: bellAnimation
                        )
                }
                
                if notificationManager.unreadCount > 0 {
                    Text("\(notificationManager.unreadCount)")
                        .font(Font.bodySans(10, weight: .bold))
                        .foregroundColor(Color.luxuryMaroon)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(LinearGradient.goldShimmer)
                        )
                        .offset(x: 8, y: -8)
                }
            }
        }
        .onAppear {
            if notificationManager.unreadCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    bellAnimation = true
                }
            }
        }
    }
}

// MARK: - Notifications Sheet View
struct NotificationsSheetView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.luxuryMaroon
                    .ignoresSafeArea()
                
                if notificationManager.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(Color.luxuryMuted)
                        
                        Text("No notifications yet")
                            .font(Font.header(18, weight: .regular))
                            .foregroundColor(Color.luxuryCream)
                        
                        HStack(spacing: 4) {
                            Text("We'll let you know when there's something")
                                .font(Font.bodySans(14, weight: .regular))
                                .foregroundColor(Color.luxuryMuted)
                            Text("magical!")
                                .font(Font.tangerine(26, weight: .bold))
                                .italic()
                                .foregroundColor(Color.luxuryGold)
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationManager.notifications) { notification in
                                NotificationRow(notification: notification) {
                                    notificationManager.markAsRead(notification)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationManager.unreadCount > 0 {
                        Button {
                            notificationManager.markAllAsRead()
                        } label: {
                            Text("Mark All Read")
                                .font(Font.bodySans(13, weight: .medium))
                                .foregroundColor(Color.luxuryGold)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.luxuryGold.opacity(0.8))
                    }
                }
            }
            .toolbarBackground(Color.luxuryMaroon, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    if let imageUrl = notification.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty, .failure:
                                notification.accentColor.opacity(0.3)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        notification.accentColor.opacity(0.3)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(notification.accentColor.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: notification.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(Font.bodySans(14, weight: notification.isRead ? .medium : .bold))
                            .foregroundColor(notification.isRead ? Color.luxuryCreamMuted : Color.luxuryCream)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.luxuryGold)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(Font.bodySans(13, weight: .regular))
                        .foregroundColor(Color.luxuryMuted)
                        .lineLimit(2)
                    
                    Text(timeAgo(notification.timestamp))
                        .font(Font.bodySans(11, weight: .regular))
                        .foregroundColor(Color.luxuryMuted.opacity(0.7))
                }
            }
            .padding(14)
            .background(
                notification.isRead ? Color.luxuryMaroonLight.opacity(0.5) : Color.luxuryMaroonLight
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        notification.isRead ? Color.clear : notification.accentColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
