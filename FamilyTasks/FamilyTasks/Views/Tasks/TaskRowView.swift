import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let tags: [Tag]
    let isAssignedToMe: Bool
    var onToggleComplete: () -> Void = {}

    private var taskTags: [Tag] {
        tags.filter { tag in
            guard let id = tag.id else { return false }
            return task.tagIds.contains(id)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isAssignedToMe {
                Button(action: onToggleComplete) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.status == .completed ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                    Spacer()
                    if task.hasAttachments {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Text(task.priorityLabel)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.priorityColor.opacity(0.15))
                        .foregroundStyle(task.priorityColor)
                        .clipShape(Capsule())

                    Text(task.dueDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(task.statusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !taskTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(taskTags, id: \.id) { tag in
                            Text(tag.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: tag.color).opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(task.statusFillColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    }
}
