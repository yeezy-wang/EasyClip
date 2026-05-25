import AppKit

enum ImageResizer {
    static func generateThumbnail(from imageData: Data, maxSize: CGFloat = 240) -> Data? {
        guard let source = NSImage(data: imageData) else { return nil }

        let originalSize = source.size
        let scale = min(maxSize / originalSize.width, maxSize / originalSize.height, 1.0)
        let newSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: CGRect(origin: .zero, size: newSize),
                     from: .zero, operation: .copy, fraction: 1)
        thumbnail.unlockFocus()

        guard let tiff = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }

        return bitmap.representation(using: .png, properties: [:])
    }
}
