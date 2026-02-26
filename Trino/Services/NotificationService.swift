import UserNotifications
import Foundation

struct NotificationService {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func scheduleNotifications(settings: SettingsStore) {
        cancelAll()

        if settings.morningReminderEnabled {
            schedule(
                id: "trino.morning",
                title: "Morning check-in",
                body: "Start strong — open Trino and set your focus for today.",
                time: settings.morningReminderTime
            )
        }

        if settings.middayReminderEnabled {
            schedule(
                id: "trino.midday",
                title: "Midday check-in",
                body: "How are your tasks going? Keep the streak alive.",
                time: settings.middayReminderTime
            )
        }

        if settings.eveningReminderEnabled {
            schedule(
                id: "trino.evening",
                title: "Evening deadline",
                body: "Last chance to complete your tasks and protect your streak.",
                time: settings.eveningReminderTime
            )
        }
    }

    // MARK: - Private

    private static func schedule(id: String, title: String, body: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
