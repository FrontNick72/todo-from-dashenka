import SwiftUI

struct SettingsView: View {
    let spaceId: String

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var tagRepository: TagRepository

    @State private var newTagName = ""
    @State private var newTagColor: Color = .orange

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    Text(authService.userProfile?.displayName ?? "")
                    Text(authService.userProfile?.email ?? "")
                        .foregroundStyle(.secondary)
                }

                Section("Теги") {
                    if tagRepository.tags.isEmpty {
                        Text("Тегов пока нет")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(tagRepository.tags) { tag in
                        HStack {
                            Circle().fill(Color(hex: tag.color)).frame(width: 14, height: 14)
                            Text(tag.name)
                        }
                    }
                    .onDelete(perform: deleteTags)

                    HStack {
                        ColorPicker("", selection: $newTagColor)
                            .labelsHidden()
                            .frame(width: 30)
                        TextField("Новый тег", text: $newTagName)
                        Button("Добавить") { addTag() }
                            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Уведомления") {
                    Button("Настройки уведомлений") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section {
                    Button("Выйти", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }

    private func addTag() {
        guard let uid = authService.firebaseUser?.uid else { return }
        let name = newTagName
        let color = newTagColor.toHex()
        newTagName = ""
        Task {
            try? await tagRepository.createTag(spaceId: spaceId, name: name, color: color, createdBy: uid)
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            guard let id = tagRepository.tags[index].id else { continue }
            Task {
                try? await tagRepository.deleteTag(spaceId: spaceId, tagId: id)
            }
        }
    }
}
