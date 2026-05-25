import Foundation
import CoreData

extension ClipboardItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var contentType: String?
    @NSManaged public var textContent: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var isPinned: Bool
    @NSManaged public var sourceApp: String?
}
