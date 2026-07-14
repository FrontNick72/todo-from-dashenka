import Foundation
import UserNotifications

enum LocalReminderScheduler {
    static func rescheduleAll(tasks: [TaskItem], currentUid: String) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let myOpenTasks = tasks.filter { $0.assignedTo == currentUid && $0.status == .open && $0.dueAt > Date() }

        for task in myOpenTasks {
            guard let id = task.id else { continue }

            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body = task.type == .deadline ? "Дедлайн наступил" : "Задача назначена на это время"
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: task.dueAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "task-\(id)", content: content, trigger: trigger)
            center.add(request)
        }
    }
}
