import SwiftUI
import CoreData

struct SettingsView: View {
    @State private var retentionDays: Int
    @State private var autoStartEnabled = AutoStartManager.isEnabled
    @State private var showClearConfirmation = false
    @State private var showQuitConfirmation = false
    @Environment(\.managedObjectContext) var viewContext

    init() {
        let stored = UserDefaults.standard.integer(forKey: "retentionDays")
        let valid = (stored == 1 || stored == 3 || stored == 5) ? stored : 1
        if stored == 0 {
            UserDefaults.standard.set(valid, forKey: "retentionDays")
        }
        _retentionDays = State(initialValue: valid)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("设置")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ColorTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 32)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Retention
                VStack(alignment: .leading, spacing: 6) {
                    Text("保留天数")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorTheme.textSecondary)

                    HStack(spacing: 0) {
                        segmentButton("1 天", value: 1, selected: retentionDays)
                        segmentButton("3 天", value: 3, selected: retentionDays)
                        segmentButton("5 天", value: 5, selected: retentionDays)
                    }
                    .background(ColorTheme.searchBackground)
                    .cornerRadius(6)
                }

                // Auto-start
                HStack {
                    Text("开机启动")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Button(action: {
                        let newValue = !autoStartEnabled
                        do {
                            try AutoStartManager.setEnabled(newValue)
                            autoStartEnabled = newValue
                        } catch {
                            print("Auto-start toggle failed: \(error.localizedDescription)")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(autoStartEnabled ? ColorTheme.primary : ColorTheme.border)
                                .frame(width: 10, height: 10)
                            Text(autoStartEnabled ? "已开启" : "已关闭")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: 28)

                Divider()

                // Danger zone
                HStack {
                    Text("数据管理")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorTheme.danger)
                    Spacer()
                    Button("清空所有数据") {
                        showClearConfirmation = true
                    }
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.danger)
                    .alert(isPresented: $showClearConfirmation) {
                        Alert(
                            title: Text("清空所有数据"),
                            message: Text("这将删除全部记录，包括置顶条目。此操作不可撤销。"),
                            primaryButton: .destructive(Text("清空")) {
                                clearAllData()
                            },
                            secondaryButton: .cancel(Text("取消"))
                        )
                    }
                }
                .frame(height: 28)

                Divider()

                HStack {
                    Text("应用")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Button("关闭应用") {
                        showQuitConfirmation = true
                    }
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.textSecondary)
                    .alert(isPresented: $showQuitConfirmation) {
                        Alert(
                            title: Text("确定关闭应用"),
                            message: Text("关闭应用后将无法继续为你记录剪切板内容，已记录的历史内容在保留天数内不会被清空，确定关闭应用吗？"),
                            primaryButton: .default(Text("取消")),
                            secondaryButton: .destructive(Text("确定关闭")) {
                                NSApplication.shared.terminate(nil)
                            }
                        )
                    }
                }
                .frame(height: 28)
            }
            .padding(16)

            Spacer()
        }
        .frame(width: 300, height: 300)
        .background(ColorTheme.background)
    }

    private func segmentButton(_ title: String, value: Int, selected: Int) -> some View {
        Button(action: {
            retentionDays = value
            UserDefaults.standard.set(value, forKey: "retentionDays")
        }) {
            Text(title)
                .font(.system(size: 12, weight: selected == value ? .semibold : .regular))
                .foregroundColor(selected == value ? .white : ColorTheme.textPrimary)
                .padding(.vertical, 5)
                .padding(.horizontal, 14)
                .background(
                    selected == value ? ColorTheme.primary : Color.clear
                )
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func clearAllData() {
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        do {
            let items = try viewContext.fetch(fetchRequest)
            for item in items {
                viewContext.delete(item)
            }
            try viewContext.save()
        } catch {
            print("Clear all data failed: \(error.localizedDescription)")
        }
    }
}
