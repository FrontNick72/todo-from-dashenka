import SwiftUI

struct RescheduleView: View {
    let spaceId: String
    let taskId: String
    let currentUid: String

    @EnvironmentObject var taskRepository: TaskRepository
    @Environment(\.dismiss) private var dismiss

    @State private var newDate: Date
    @State private var reason = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    init(spaceId: String, taskId: String, currentDueAt: Date, currentUid: String) {
        self.spaceId = spaceId
        self.taskId = taskId
        self.currentUid = currentUid
        _newDate = State(initialValue: currentDueAt)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Новая дата", selection: $newDate)

                Section("Причина переноса") {
                    TextField("Обязательно укажите причину", text: $reason, axis: .vertical)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Перенос даты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }

    private func save() {
        isSubmitting = true
        Task {
            do {
                try await taskRepository.rescheduleDueAt(spaceId: spaceId, taskId: taskId, newDueAt: newDate, reason: reason, byUid: currentUid)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
