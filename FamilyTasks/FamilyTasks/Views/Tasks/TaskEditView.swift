import SwiftUI

struct TaskEditView: View {
    let spaceId: String
    let currentUid: String
    let partnerUid: String
    let partnerDisplayName: String

    @EnvironmentObject var taskRepository: TaskRepository
    @EnvironmentObject var tagRepository: TagRepository
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var type: TaskType = .scheduled
    @State private var dueAt = Date().addingTimeInterval(3600)
    @State private var priority: TaskPriority = .normal
    @State private var selectedTagIds: Set<String> = []
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Задача") {
                    TextField("Заголовок", text: $title)
                    TextField("Заметки", text: $notes, axis: .vertical)
                }

                Section("Исполнитель") {
                    Text(partnerDisplayName)
                        .foregroundStyle(.secondary)
                }

                Section("Тип") {
                    Picker("Тип", selection: $type) {
                        Text("По дате").tag(TaskType.scheduled)
                        Text("Дедлайн").tag(TaskType.deadline)
                    }
                    .pickerStyle(.segmented)
                    DatePicker(type == .scheduled ? "Дата и время" : "Дедлайн", selection: $dueAt)
                }

                Section("Степень важной важности") {
                    Picker("Приоритет", selection: $priority) {
                        Text("Низкий").tag(TaskPriority.low)
                        Text("Средний").tag(TaskPriority.normal)
                        Text("Высокий").tag(TaskPriority.high)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Теги") {
                    if tagRepository.tags.isEmpty {
                        Text("Тегов пока нет. Добавьте их в настройках.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tagRepository.tags) { tag in
                            Button {
                                toggleTag(tag)
                            } label: {
                                HStack {
                                    Circle().fill(Color(hex: tag.color)).frame(width: 12, height: 12)
                                    Text(tag.name)
                                    Spacer()
                                    if let id = tag.id, selectedTagIds.contains(id) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") { create() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        guard let id = tag.id else { return }
        if selectedTagIds.contains(id) {
            selectedTagIds.remove(id)
        } else {
            selectedTagIds.insert(id)
        }
    }

    private func create() {
        isSubmitting = true
        Task {
            do {
                try await taskRepository.createTask(
                    spaceId: spaceId,
                    title: title,
                    notes: notes.isEmpty ? nil : notes,
                    createdBy: currentUid,
                    assignedTo: partnerUid,
                    type: type,
                    dueAt: dueAt,
                    priority: priority,
                    tagIds: Array(selectedTagIds)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
