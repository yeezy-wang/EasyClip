import SwiftUI

struct SystemIcon: View {
    let name: String

    var body: some View {
        Text(character)
    }

    private var character: String {
        switch name {
        case "magnifyingglass": return "\u{1F50D}"       // 🔍
        case "clipboard":       return "\u{1F4CB}"       // 📋
        case "gearshape":       return "\u{2699}\u{FE0F}"  // ⚙️
        case "doc.text":        return "\u{1F4CB}"       // 📋
        case "pin":             return "\u{2B06}\u{FE0F}" // ⬆️
        case "pin.fill":        return "\u{2B07}\u{FE0F}" // ⬇️
        case "trash":           return "\u{1F5D1}\u{FE0F}" // 🗑️
        case "eye":             return "\u{1F440}"       // 👀
        case "xmark":           return "\u{2715}"        // ✕
        default:                return "?"
        }
    }
}
