import SwiftUI
import FirebaseFirestore

@MainActor
final class PartnerViewModel: ObservableObject {
    @Published var partnerProfile: UserProfile?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(uid: String) {
        listener?.remove()
        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.partnerProfile = try? snapshot?.data(as: UserProfile.self)
            }
    }

    deinit {
        listener?.remove()
    }
}

struct MainView: View {
    let spaceId: String
    let currentUid: String
    let partnerUid: String

    @StateObject private var taskRepository = TaskRepository()
    @StateObject private var tagRepository = TagRepository()
    @StateObject private var partnerViewModel = PartnerViewModel()

    var body: some View {
        TabView {
            TaskListView(
                spaceId: spaceId,
                currentUid: currentUid,
                partnerUid: partnerUid,
                partnerDisplayName: partnerViewModel.partnerProfile?.displayName ?? "Партнёр"
            )
            .environmentObject(taskRepository)
            .environmentObject(tagRepository)
            .tabItem { Label("Задачи", systemImage: "checklist") }

            SettingsView(spaceId: spaceId)
                .environmentObject(tagRepository)
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .onAppear {
            taskRepository.listen(spaceId: spaceId)
            tagRepository.listen(spaceId: spaceId)
            partnerViewModel.listen(uid: partnerUid)
        }
        .onReceive(taskRepository.$tasks) { tasks in
            LocalReminderScheduler.rescheduleAll(tasks: tasks, currentUid: currentUid)
        }
    }
}
