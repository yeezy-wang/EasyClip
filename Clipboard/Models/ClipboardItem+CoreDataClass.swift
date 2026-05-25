import Foundation
import CoreData

@objc(ClipboardItem)
public class ClipboardItem: NSManagedObject, Identifiable {}

extension ClipboardItem {
    func wrappedTextContent() -> String {
        guard let text = textContent else { return "" }
        let lines = text.components(separatedBy: .newlines).prefix(2).joined(separator: " ")
        if lines.count > 200 {
            return String(lines.prefix(200)) + "..."
        }
        return lines
    }
}
