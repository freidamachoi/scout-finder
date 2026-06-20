import Foundation
import UserNotifications

/// Local-notification helper. The app fires a notification after a search (manual or
/// background) when new listings are found.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Notify about new finds. `listings` are the brand-new ones from a run.
    func notifyNewListings(_ listings: [Listing]) async {
        guard !listings.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        let count = listings.count
        content.title = count == 1 ? "New Scout listing" : "\(count) new Scout listings"
        if let first = listings.first {
            content.body = count == 1 ? first.title : "Including: \(first.title)"
        }
        content.sound = .default
        content.badge = NSNumber(value: count)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
