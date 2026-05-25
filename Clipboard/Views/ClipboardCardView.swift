import SwiftUI

struct ClipboardCardView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onPreview: (() -> Void)?
    let isJustCopied: Bool
    let onHoverChanged: ((Bool) -> Void)?

    @State private var isHovering = false

    var body: some View {
        if isImageItem {
            imageCard
        } else {
            textCard
        }
    }

    private var isImageItem: Bool {
        item.contentType == ContentType.image.rawValue
    }

    // MARK: - Image card (VStack with large thumbnail)
    private var imageCard: some View {
        VStack(spacing: 4) {
            // Large thumbnail
            if let thumbData = item.thumbnailData, let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .cornerRadius(4)
            } else {
                SystemIcon(name: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(ColorTheme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(ColorTheme.hoverBackground)
                    .cornerRadius(4)
            }

            // Info row
            HStack(spacing: 6) {
                Text(sourceAppText)
                    .font(.system(size: 13))
                    .foregroundColor(ColorTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(absoluteTime)
                    .font(.system(size: 11))
                    .foregroundColor(ColorTheme.textSecondary)

                if isJustCopied {
                    Text("已复制")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ColorTheme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorTheme.primaryLight)
                        .cornerRadius(4)
                } else if isHovering {
                    HStack(spacing: 6) {
                        previewButton
                        pinButton
                        deleteButton
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? ColorTheme.hoverBackground : ColorTheme.background)
        )
        .animation(.easeOut(duration: 0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ColorTheme.border, lineWidth: 0.5)
        )
        .onHover { hovering in
            isHovering = hovering
            onHoverChanged?(hovering)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // MARK: - Text card (HStack with small icon)
    private var textCard: some View {
        HStack(spacing: 8) {
            SystemIcon(name: "doc.text")
                .font(.system(size: 15))
                .foregroundColor(ColorTheme.primary)
                .frame(width: 36, height: 36)
                .background(ColorTheme.hoverBackground)
                .cornerRadius(4)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.wrappedTextContent())
                    .font(.system(size: 13))
                    .foregroundColor(ColorTheme.textPrimary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(absoluteTime)
                    .font(.system(size: 11))
                    .foregroundColor(ColorTheme.textSecondary)
            }

            if isJustCopied {
                Text("已复制")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorTheme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorTheme.primaryLight)
                    .cornerRadius(4)
            } else if isHovering {
                HStack(spacing: 6) {
                    pinButton
                    deleteButton
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? ColorTheme.hoverBackground : ColorTheme.background)
        )
        .animation(.easeOut(duration: 0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ColorTheme.border, lineWidth: 0.5)
        )
        .onHover { hovering in
            isHovering = hovering
            onHoverChanged?(hovering)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // MARK: - Computed properties
    private var absoluteTime: String {
        guard let ts = item.timestamp else { return "" }
        return RelativeDateFormatter.absoluteString(from: ts)
    }

    private var sourceAppText: String {
        let app = item.sourceApp ?? "未知应用"
        return "来自\u{201C}\(app)\u{201D}"
    }

    // MARK: - Buttons
    private var previewButton: some View {
        Button(action: { onPreview?() }) {
            SystemIcon(name: "eye")
                .font(.system(size: 10))
                .foregroundColor(ColorTheme.textSecondary)
                .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var pinButton: some View {
        Button(action: onPin) {
            SystemIcon(name: item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 13))
                .foregroundColor(item.isPinned ? ColorTheme.primary : ColorTheme.textSecondary)
                .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            SystemIcon(name: "trash")
                .font(.system(size: 10))
                .foregroundColor(ColorTheme.danger)
                .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
