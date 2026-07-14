import SwiftUI

struct AttachmentThumbnail: View {
    let attachment: Attachment

    var body: some View {
        AsyncImage(url: URL(string: attachment.downloadURL)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo.badge.exclamationmark")
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
