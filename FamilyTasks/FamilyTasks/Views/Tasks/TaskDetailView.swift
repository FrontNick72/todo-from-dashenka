import SwiftUI

struct TaskDetailView: View {
    let spaceId: String
    let task: TaskItem
    let currentUid: String
    var onDeleted: () -> Void = {}

    @EnvironmentObject var taskRepository: TaskRepository
    @EnvironmentObject var tagRepository: TagRepository
    @StateObject private var commentRepository = CommentRepository()
    @StateObject private var eventRepository = TaskEventRepository()
    @StateObject private var attachmentRepository = AttachmentRepository()

    @State private var newComment = ""
    @State private var pendingCommentImage: UIImage?
    @State private var showingReschedule = false
    @State private var showingDeleteConfirmation = false
    @State private var viewerURL: URL?
    @State private var errorMessage: String?
    @State private var selectedStatus: TaskStatus
    @State private var isSavingStatus = false

    private var taskId: String { task.id ?? "" }

    init(spaceId: String, task: TaskItem, currentUid: String, onDeleted: @escaping () -> Void = {}) {
        self.spaceId = spaceId
        self.task = task
        self.currentUid = currentUid
        self.onDeleted = onDeleted
        _selectedStatus = State(initialValue: task.status)
    }

    private var taskTags: [Tag] {
        tagRepository.tags.filter { tag in
            guard let id = tag.id else { return false }
            return task.tagIds.contains(id)
        }
    }

    private var taskAttachments: [Attachment] {
        attachmentRepository.attachments.filter { $0.attachedTo == .task }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                actionButtons

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Divider()
                gallerySection
                Divider()
                commentsSection
                Divider()
                historySection
            }
            .padding()
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Удалить задачу?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { deleteTask() }
            Button("Отмена", role: .cancel) {}
        }
        .onAppear {
            commentRepository.listen(spaceId: spaceId, taskId: taskId)
            eventRepository.listen(spaceId: spaceId, taskId: taskId)
            attachmentRepository.listen(spaceId: spaceId, taskId: taskId)
        }
        .sheet(isPresented: $showingReschedule) {
            RescheduleView(spaceId: spaceId, taskId: taskId, currentDueAt: task.dueAt, currentUid: currentUid)
                .environmentObject(taskRepository)
        }
        .sheet(item: $viewerURL) { url in
            PhotoViewerView(url: url)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text(task.priorityLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(task.priorityColor.opacity(0.15))
                    .foregroundStyle(task.priorityColor)
                    .clipShape(Capsule())

                Text(task.statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(task.dueDescription)
                .font(.subheadline)

            if !taskTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(taskTags, id: \.id) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: tag.color).opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Выполнено") { selectedStatus = .completed }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedStatus == .completed ? .green : Color(.systemGray4))
                    .foregroundStyle(selectedStatus == .completed ? .white : .primary)

                Button("Не выполнено") { selectedStatus = .declined }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedStatus == .declined ? .gray : Color(.systemGray4))
                    .foregroundStyle(selectedStatus == .declined ? .white : .primary)

                Button("Перенести дату") { showingReschedule = true }
                    .buttonStyle(.bordered)
            }

            if selectedStatus != task.status {
                Button {
                    saveStatus()
                } label: {
                    if isSavingStatus {
                        ProgressView()
                    } else {
                        Text("Сохранить")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSavingStatus)
            }
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Фото")
                    .font(.headline)
                Spacer()
                AttachmentPickerButton { image in
                    uploadTaskPhoto(image)
                }
            }

            if taskAttachments.isEmpty {
                Text("Пока нет фото")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(taskAttachments) { attachment in
                        AttachmentThumbnail(attachment: attachment)
                            .onTapGesture {
                                viewerURL = URL(string: attachment.downloadURL)
                            }
                    }
                }
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Комментарии")
                .font(.headline)

            if commentRepository.comments.isEmpty {
                Text("Комментариев пока нет")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(commentRepository.comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.text)
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    let commentAttachments = attachmentRepository.attachments.filter {
                        $0.attachedTo == .comment && $0.commentId == comment.id
                    }
                    if !commentAttachments.isEmpty {
                        HStack {
                            ForEach(commentAttachments) { attachment in
                                AttachmentThumbnail(attachment: attachment)
                                    .onTapGesture {
                                        viewerURL = URL(string: attachment.downloadURL)
                                    }
                            }
                        }
                    }
                }
            }

            if let pendingCommentImage {
                Image(uiImage: pendingCommentImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                AttachmentPickerButton { image in
                    pendingCommentImage = image
                }
                TextField("Комментарий", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                Button("Отправить") { addComment() }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("История")
                .font(.headline)

            if eventRepository.events.isEmpty {
                Text("История пуста")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(eventRepository.events) { event in
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.summary)
                        .font(.footnote)
                    Text(event.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func saveStatus() {
        isSavingStatus = true
        Task {
            do {
                try await taskRepository.setStatus(spaceId: spaceId, taskId: taskId, status: selectedStatus, byUid: currentUid)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSavingStatus = false
        }
    }

    private func addComment() {
        let text = newComment
        let image = pendingCommentImage
        newComment = ""
        pendingCommentImage = nil
        Task {
            do {
                let commentId = try await commentRepository.addComment(spaceId: spaceId, taskId: taskId, authorUid: currentUid, text: text)
                if let image {
                    try await attachmentRepository.uploadAttachment(
                        spaceId: spaceId, taskId: taskId, image: image,
                        attachedTo: .comment, commentId: commentId, uploadedBy: currentUid
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func uploadTaskPhoto(_ image: UIImage) {
        Task {
            do {
                try await attachmentRepository.uploadAttachment(
                    spaceId: spaceId, taskId: taskId, image: image,
                    attachedTo: .task, commentId: nil, uploadedBy: currentUid
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteTask() {
        Task {
            do {
                try await taskRepository.deleteTask(spaceId: spaceId, taskId: taskId)
                onDeleted()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
