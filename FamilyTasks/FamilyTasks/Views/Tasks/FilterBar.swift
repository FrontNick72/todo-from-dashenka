import SwiftUI

struct FilterBar: View {
    @Binding var statusFilter: TaskStatus?
    @Binding var priorityFilter: TaskPriority?
    @Binding var tagFilter: String?
    let tags: [Tag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Menu {
                    Button("Все статусы") { statusFilter = nil }
                    ForEach([TaskStatus.open, .completed, .declined], id: \.self) { status in
                        Button(label(for: status)) { statusFilter = status }
                    }
                } label: {
                    chip(statusFilter.map(label(for:)) ?? "Статус")
                }

                Menu {
                    Button("Все приоритеты") { priorityFilter = nil }
                    ForEach([TaskPriority.low, .normal, .high], id: \.self) { priority in
                        Button(label(for: priority)) { priorityFilter = priority }
                    }
                } label: {
                    chip(priorityFilter.map(label(for:)) ?? "Приоритет")
                }

                if !tags.isEmpty {
                    Menu {
                        Button("Все теги") { tagFilter = nil }
                        ForEach(tags, id: \.id) { tag in
                            Button(tag.name) { tagFilter = tag.id }
                        }
                    } label: {
                        chip(tags.first(where: { $0.id == tagFilter })?.name ?? "Теги")
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15))
            .clipShape(Capsule())
    }

    private func label(for status: TaskStatus) -> String {
        switch status {
        case .open: return "Открыта"
        case .completed: return "Выполнено"
        case .declined: return "Не выполнено"
        }
    }

    private func label(for priority: TaskPriority) -> String {
        switch priority {
        case .low: return "Низкий"
        case .normal: return "Средний"
        case .high: return "Высокий"
        }
    }
}
