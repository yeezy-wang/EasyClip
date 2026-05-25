import SwiftUI
import AppKit

enum ColorTheme {
    static let primary = Color(red: 0.145, green: 0.388, blue: 0.922)
    static let primaryLight = Color(red: 0.878, green: 0.906, blue: 1.0)
    static let danger = Color(red: 0.937, green: 0.267, blue: 0.267)

    static var background: Color {
        Color(NSColor.windowBackgroundColor)
    }

    static var textPrimary: Color {
        Color(NSColor.labelColor)
    }

    static var textSecondary: Color {
        Color(NSColor.secondaryLabelColor)
    }

    static var border: Color {
        Color(NSColor.separatorColor)
    }

    static var searchBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }

    static var placeholder: Color {
        Color(NSColor.tertiaryLabelColor)
    }

    static var hoverBackground: Color {
        Color(NSColor.quaternaryLabelColor)
    }

    static var accent: Color { primary }
}
