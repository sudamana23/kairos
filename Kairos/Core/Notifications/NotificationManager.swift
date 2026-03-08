import UserNotifications
import Foundation

// MARK: - NotificationManager
//
// Schedules local (on-device) reminders for Weekly Pulse and Monthly Review.
// Does NOT require a network connection or any server — fires even when the app is closed.

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            await center.notificationSettings().authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule

    /// Call once after permission is granted (or already granted).
    func scheduleAll() async {
        guard await isAuthorized else { return }
        scheduleWeeklyPulse()
        scheduleMonthlyReview()
    }

    func scheduleWeeklyPulse(weekday: Int = 2, hour: Int = 9) {
        center.removePendingNotificationRequests(withIdentifiers: ["kairos.weekly-pulse"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Pulse"
        content.body = "90 seconds. How are you, honestly?"
        content.sound = .default

        var dc = DateComponents()
        dc.weekday = weekday  // 1 = Sunday, 2 = Monday …
        dc.hour    = hour
        dc.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        center.add(UNNotificationRequest(identifier: "kairos.weekly-pulse", content: content, trigger: trigger))
    }

    func scheduleMonthlyReview(day: Int = 1, hour: Int = 10) {
        center.removePendingNotificationRequests(withIdentifiers: ["kairos.monthly-review"])

        let content = UNMutableNotificationContent()
        content.title = "Monthly Review"
        content.body = "New month — time for your review."
        content.sound = .default

        var dc = DateComponents()
        dc.day    = day
        dc.hour   = hour
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        center.add(UNNotificationRequest(identifier: "kairos.monthly-review", content: content, trigger: trigger))
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func cancelWeeklyPulse()   { center.removePendingNotificationRequests(withIdentifiers: ["kairos.weekly-pulse"]) }
    func cancelMonthlyReview() { center.removePendingNotificationRequests(withIdentifiers: ["kairos.monthly-review"]) }
}
