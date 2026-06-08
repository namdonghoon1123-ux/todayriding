import Foundation
import UserNotifications

/// 로컬 알림 관리: 권한 요청, 매일 라이딩 리마인더, 라이딩 중 강수 경고.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let dailyReminder = "todayriding.dailyReminder"
        static let rainAlert = "todayriding.rainAlert"
    }

    private init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// 매일 지정 시각에 반복되는 라이딩 리마인더를 예약한다.
    func scheduleDailyReminder(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "오늘 탈까?"
        content.body = "오늘의 라이딩 적합도를 확인해보세요."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.dailyReminder,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])
        center.add(request)
    }

    /// 라이딩 중 강수 경고를 즉시 표시한다.
    func sendRainAlert(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "비 소식"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Identifier.rainAlert,
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}
