import UIKit

struct CompressedImage {
    let data: Data
    let size: CGSize
}

enum ImageCompressor {
    static func compress(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.7) -> CompressedImage? {
        let resized = resize(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: quality) else { return nil }
        return CompressedImage(data: data, size: resized.size)
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxDimension else { return image }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
