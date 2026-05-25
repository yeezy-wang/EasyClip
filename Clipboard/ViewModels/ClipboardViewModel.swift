import SwiftUI
import AppKit
import CoreData
import Quartz

class QLPreviewHelper: NSObject, QLPreviewPanelDataSource {
    var url: URL?

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        url != nil ? 1 : 0
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        url as QLPreviewItem?
    }
}

final class ClipboardViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var justCopiedId: UUID?
    var hoveredImageItem: ClipboardItem?
    var onClearCompleted: (() -> Void)?

    private let context: NSManagedObjectContext
    private weak var monitor: ClipboardMonitor?
    private let previewHelper = QLPreviewHelper()

    init(context: NSManagedObjectContext, monitor: ClipboardMonitor? = nil) {
        self.context = context
        self.monitor = monitor
    }

    func filteredItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        guard !searchQuery.isEmpty else { return items }
        return items.filter {
            $0.textContent?.localizedCaseInsensitiveContains(searchQuery) ?? false
        }
    }

    func copyItem(_ item: ClipboardItem) {
        monitor?.skipNextPasteboardChange = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case ContentType.text.rawValue:
            pasteboard.setString(item.textContent ?? "", forType: .string)
        case ContentType.image.rawValue:
            guard let data = item.imageData else { return }
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                pasteboard.setData(data, forType: .png)
            } else {
                pasteboard.setData(data, forType: .tiff)
            }
        default:
            break
        }

        justCopiedId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.justCopiedId = nil
        }
    }

    func previewImage(_ item: ClipboardItem) {
        guard let data = item.imageData else { return }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("clipboard_preview_\(UUID().uuidString).png")
        try? data.write(to: tmp)

        previewHelper.url = tmp
        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = previewHelper
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
        save()
    }

    func deleteItem(_ item: ClipboardItem) {
        context.delete(item)
        save()
    }

    func clearAll() {
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPinned == NO")
        do {
            let items = try context.fetch(fetchRequest)
            for item in items {
                context.delete(item)
            }
            save()
            DispatchQueue.main.async { [weak self] in
                self?.onClearCompleted?()
            }
        } catch {
            print("Clear all failed: \(error.localizedDescription)")
        }
    }

    var unpinnedCount: Int {
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPinned == NO")
        return (try? context.count(for: fetchRequest)) ?? 0
    }

    var totalCount: Int {
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        return (try? context.count(for: fetchRequest)) ?? 0
    }

    private func save() {
        try? context.save()
    }
}
