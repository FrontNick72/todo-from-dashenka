import SwiftUI

extension TaskItem {
    var dueDescription: String {
        switch type {
        case .scheduled:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: dueAt)
        case .deadline:
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.unitsStyle = .full
            let relative = formatter.localizedString(for: dueAt, relativeTo: Date())
            return dueAt < Date() ? "Просрочено: \(relative)" : relative
        }
    }

    var priorityLabel: String {
        switch priority {
        case .low: return "Низкий"
        case .normal: return "Средний"
        case .high: return "Высокий"
        }
    }

    var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .red
        }
    }

    var statusLabel: String {
        switch status {
        case .open: return "Открыта"
        case .completed: return "Выполнено"
        case .declined: return "Не выполнено"
        }
    }
}
