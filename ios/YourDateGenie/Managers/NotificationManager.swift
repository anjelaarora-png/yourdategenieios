import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - Push Notification Manager

/// Manages all push notification logic for date reminders and memory capture prompts
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Notification Identifiers
    private struct NotificationIDs {
        static let dateNightReminder = "dateNightReminder"
        static let captureMemoryPrompt = "captureMemoryPrompt"
        static let dayAfterReminder = "dayAfterReminder"
    }
    
    // MARK: - Notification Actions
    struct ActionIDs {
        static let addPhoto = "ADD_PHOTO_ACTION"
        static let later = "LATER_ACTION"
        static let categoryID = "MEMORY_CAPTURE_CATEGORY"
    }
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request notification permission on first app launch
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
                
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories & Actions
    
    private func setupNotificationCategories() {
        let addPhotoAction = UNNotificationAction(
            identifier: ActionIDs.addPhoto,
            title: "Add Photo 📸",
            options: .foreground
        )
        
        let laterAction = UNNotificationAction(
            identifier: ActionIDs.later,
            title: "Later",
            options: []
        )
        
        let memoryCaptureCategory = UNNotificationCategory(
            identifier: ActionIDs.categoryID,
            actions: [addPhotoAction, laterAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        notificationCenter.setNotificationCategories([memoryCaptureCategory])
    }
    
    // MARK: - Schedule Notifications for Date Plan
    
    /// Schedule notifications for a saved date plan
    func scheduleNotificationsForDatePlan(
        datePlanId: UUID,
        dateTitle: String,
        scheduledDate: Date
    ) {
        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted {
                    self?.scheduleNotificationsForDatePlan(
                        datePlanId: datePlanId,
                        dateTitle: dateTitle,
                        scheduledDate: scheduledDate
                    )
                }
            }
            return
        }
        
        // Schedule evening reminder (7 PM on date day)
        scheduleEveningReminder(datePlanId: datePlanId, dateTitle: dateTitle, scheduledDate: scheduledDate)
        
        // Schedule 24-hour after reminder
        schedule24HourReminder(datePlanId: datePlanId, dateTitle: dateTitle, scheduledDate: scheduledDate)
    }
    
    /// Schedule reminder for evening of the date
    private func scheduleEveningReminder(datePlanId: UUID, dateTitle: String, scheduledDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Tonight is your special night ✨"
        content.body = "Don't forget to capture your memory! Open Your Date Genie to save this moment 📸"
        content.sound = .default
        content.categoryIdentifier = ActionIDs.categoryID
        content.userInfo = [
            "datePlanId": datePlanId.uuidString,
            "type": "eveningReminder"
        ]
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: scheduledDate)
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "\(NotificationIDs.dateNightReminder)_\(datePlanId.uuidString)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule evening reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule reminder 24 hours after date
    private func schedule24HourReminder(datePlanId: UUID, dateTitle: String, scheduledDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Add your memory from last night's date 🌹"
        content.body = "How was '\(dateTitle)'? Capture this beautiful moment in your memory gallery."
        content.sound = .default
        content.categoryIdentifier = ActionIDs.categoryID
        content.userInfo = [
            "datePlanId": datePlanId.uuidString,
            "type": "dayAfterReminder"
        ]
        
        guard let triggerDate = Calendar.current.date(byAdding: .hour, value: 24, to: scheduledDate) else { return }
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "\(NotificationIDs.dayAfterReminder)_\(datePlanId.uuidString)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule 24-hour reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel all notifications for a specific date plan
    func cancelNotificationsForDatePlan(datePlanId: UUID) {
        let identifiers = [
            "\(NotificationIDs.dateNightReminder)_\(datePlanId.uuidString)",
            "\(NotificationIDs.dayAfterReminder)_\(datePlanId.uuidString)"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Refresh Pending Notifications
    
    func refreshPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Immediate Test Notification
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your Date Genie ✨"
        content.body = "Your magical date planner is ready to create unforgettable memories!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case ActionIDs.addPhoto:
            handleAddPhotoAction(userInfo: userInfo)
            
        case ActionIDs.later:
            break
            
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleAddPhotoAction(userInfo: [AnyHashable: Any]) {
        if let datePlanIdString = userInfo["datePlanId"] as? String {
            NotificationCenter.default.post(
                name: .openMemoryCapture,
                object: nil,
                userInfo: ["datePlanId": datePlanIdString]
            )
        }
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        if let datePlanIdString = userInfo["datePlanId"] as? String {
            NotificationCenter.default.post(
                name: .openMemoryGallery,
                object: nil,
                userInfo: ["datePlanId": datePlanIdString]
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openMemoryCapture = Notification.Name("openMemoryCapture")
    static let openMemoryGallery = Notification.Name("openMemoryGallery")
}

// MARK: - Badge Management

extension PushNotificationManager {
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}
