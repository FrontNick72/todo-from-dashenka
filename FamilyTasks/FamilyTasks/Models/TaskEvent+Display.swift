import Foundation

extension TaskEvent {
    var summary: String {
        switch type {
        case .created:
            return "Задача создана"
        case .statusChanged:
            return "Статус изменён: \(oldValue ?? "—") → \(newValue ?? "—")"
        case .dateChanged:
            var text = "Дата перенесена"
            if let reason, !reason.isEmpty {
                text += ". Причина: \(reason)"
            }
            return text
        case .commented:
            return "Комментарий: \(newValue ?? "")"
        case .attachmentAdded:
            return "Добавлено фото"
        }
    }
}
