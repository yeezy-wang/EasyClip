import AppKit
import Combine
import CoreData

final class ClipboardMonitor: ObservableObject {
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timerCancellable: AnyCancellable?
    private let context: NSManagedObjectContext
    var skipNextPasteboardChange = false

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount

        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForChanges()
            }
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        if skipNextPasteboardChange {
            skipNextPasteboardChange = false
            return
        }

        captureCurrent()
    }

    private func captureCurrent() {
        let pasteboard = NSPasteboard.general

        // Skip file copies (Finder file copy puts file path as string)
        if let types = pasteboard.types, types.contains(.fileURL) {
            return
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            saveTextItem(text)
            return
        }

        if let tiffData = pasteboard.data(forType: .tiff) {
            saveImageItem(tiffData)
            return
        }

        if let pngData = pasteboard.data(forType: .png) {
            saveImageItem(pngData)
            return
        }
    }

    private var currentSourceApp: String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "未知应用"
    }

    private func saveTextItem(_ text: String) {
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1

        if let lastItem = try? context.fetch(fetchRequest).first,
           lastItem.contentType == ContentType.text.rawValue,
           lastItem.textContent == text {
            return
        }

        let app = currentSourceApp

        context.perform { [weak self] in
            guard let self = self else { return }
            let item = ClipboardItem(context: self.context)
            item.id = UUID()
            item.timestamp = Date()
            item.contentType = ContentType.text.rawValue
            item.textContent = text
            item.sourceApp = app
            item.isPinned = false
            try? self.context.save()
        }
    }

    private func saveImageItem(_ data: Data) {
        let thumbnail = ImageResizer.generateThumbnail(from: data, maxSize: 480)
        let app = currentSourceApp

        context.perform { [weak self] in
            guard let self = self else { return }
            let item = ClipboardItem(context: self.context)
            item.id = UUID()
            item.timestamp = Date()
            item.contentType = ContentType.image.rawValue
            item.imageData = data
            item.thumbnailData = thumbnail
            item.sourceApp = app
            item.isPinned = false
            try? self.context.save()
        }
    }
}
