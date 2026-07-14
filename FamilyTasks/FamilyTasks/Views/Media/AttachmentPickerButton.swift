import PhotosUI
import SwiftUI

struct AttachmentPickerButton: View {
    var onPick: (UIImage) -> Void

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingCamera = false

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Menu {
            if isCameraAvailable {
                Button {
                    showingCamera = true
                } label: {
                    Label("Камера", systemImage: "camera")
                }
            }
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Галерея", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "paperclip")
        }
        .onChange(of: photosPickerItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    onPick(image)
                }
                photosPickerItem = nil
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                onPick(image)
            }
        }
    }
}
