import SwiftUI

struct TaskListView: View {
    let spaceId: String
    let currentUid: String
    let partnerUid: String
    let partnerDisplayName: String

    @EnvironmentObject var taskRepository: TaskRepository
    @EnvironmentObject var tagRepository: TagRepository

    enum Segment: String, CaseIterable {
        case assignedToMe = "Мне"
        case createdByMe = "Я поставил(а)"
    }

    enum SortMode {
        case dueDate
        case priority
    }

    @State private var segment: Segment = .assignedToMe
    @State private var sortMode: SortMode = .dueDate
    @State private var statusFilter: TaskStatus?
    @State private var priorityFilter: TaskPriority?
    @State private var tagFilter: String?
    @State private var showingCreate = false
    @State private var navigationPath = NavigationPath()

    private var filteredTasks: [TaskItem] {
        taskRepository.tasks.filter { task in
            let matchesSegment = segment == .assignedToMe ? task.assignedTo == currentUid : task.createdBy == currentUid
            let matchesStatus = statusFilter.map { $0 == task.status } ?? true
            let matchesPriority = priorityFilter.map { $0 == task.priority } ?? true
            let matchesTag = tagFilter.map { task.tagIds.contains($0) } ?? true
            return matchesSegment && matchesStatus && matchesPriority && matchesTag
        }
    }

    private var sortedTasks: [TaskItem] {
        switch sortMode {
        case .dueDate:
            return filteredTasks.sorted { $0.dueAt < $1.dueAt }
        case .priority:
            return filteredTasks.sorted { priorityRank($0.priority) > priorityRank($1.priority) }
        }
    }

    private func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .high: return 2
        case .normal: return 1
        case .low: return 0
        }
    }

    private func toggleComplete(_ task: TaskItem) {
        guard let taskId = task.id else { return }
        let newStatus: TaskStatus = task.status == .completed ? .open : .completed
        Task {
            try? await taskRepository.setStatus(spaceId: spaceId, taskId: taskId, status: newStatus, byUid: currentUid)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                FilterBar(statusFilter: $statusFilter, priorityFilter: $priorityFilter, tagFilter: $tagFilter, tags: tagRepository.tags)

                if sortedTasks.isEmpty {
                    Spacer()
                    Text("Задач пока нет")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(sortedTasks) { task in
                        NavigationLink(value: task.id ?? "") {
                            TaskRowView(
                                task: task,
                                tags: tagRepository.tags,
                                isAssignedToMe: task.assignedTo == currentUid
                            ) {
                                toggleComplete(task)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Задачи")
            .navigationDestination(for: String.self) { taskId in
                if let task = taskRepository.tasks.first(where: { $0.id == taskId }) {
                    TaskDetailView(spaceId: spaceId, task: task, currentUid: currentUid) {
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("По дате") { sortMode = .dueDate }
                        Button("По приоритету") { sortMode = .priority }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                TaskEditView(spaceId: spaceId, currentUid: currentUid, partnerUid: partnerUid, partnerDisplayName: partnerDisplayName)
                    .environmentObject(tagRepository)
                    .environmentObject(taskRepository)
            }
        }
    }
}
