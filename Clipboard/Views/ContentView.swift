import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject var viewModel: ClipboardViewModel
    var onSettings: (() -> Void)?

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "timestamp", ascending: false)
        ],
        animation: .default
    )
    private var items: FetchedResults<ClipboardItem>

    private var hasItems: Bool { !items.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EasyClip - 管理你的剪贴板历史")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ColorTheme.textPrimary)
                Spacer()
                SystemIcon(name: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.textSecondary)
                    .onTapGesture {
                        onSettings?()
                    }
            }
            .padding(.horizontal, 20)
            .frame(height: 32)

            Divider()

            if hasItems {
                SearchBarView(text: $viewModel.searchQuery)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }

            if filteredItems.isEmpty {
                EmptyStateView(isSearchEmpty: !viewModel.searchQuery.isEmpty)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        let pinned = filteredItems.filter { $0.isPinned }
                        let unpinned = filteredItems.filter { !$0.isPinned }

                        if !pinned.isEmpty {
                            Section(header: pinnedSectionHeader(count: pinned.count)) {
                                ForEach(pinned) { item in
                                    cardView(for: item)
                                }
                            }
                        }

                        if !unpinned.isEmpty {
                            if !pinned.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)
                            }

                            ForEach(unpinned) { item in
                                cardView(for: item)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }

            Divider()

            FooterView(
                totalCount: viewModel.totalCount,
                unpinnedCount: viewModel.unpinnedCount,
                onClearAll: { viewModel.clearAll() }
            )
            .padding(.horizontal, 12)
        }
        .frame(width: 340, height: 620)
        .background(ColorTheme.background)
    }

    private var filteredItems: [ClipboardItem] {
        viewModel.filteredItems(Array(items))
    }

    private func pinnedSectionHeader(count: Int) -> some View {
        HStack {
            SystemIcon(name: "pin")
                .font(.system(size: 11))
                .foregroundColor(ColorTheme.primary)
            Text("已置顶（\(count)条记录）")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func cardView(for item: ClipboardItem) -> some View {
        let isImage = item.contentType == ContentType.image.rawValue
        return ClipboardCardView(
            item: item,
            onTap: { viewModel.copyItem(item) },
            onPin: { viewModel.togglePin(item) },
            onDelete: { viewModel.deleteItem(item) },
            onPreview: isImage ? { viewModel.previewImage(item) } : nil,
            isJustCopied: viewModel.justCopiedId == item.id,
            onHoverChanged: isImage ? { hovering in
                viewModel.hoveredImageItem = hovering ? item : nil
            } : nil
        )
    }

}
