import SwiftUI

struct EmptyStateView: View {
    var isSearchEmpty: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            SystemIcon(name:  isSearchEmpty ? "magnifyingglass" : "clipboard")
                .font(.system(size: 32))
                .foregroundColor(ColorTheme.textSecondary.opacity(0.5))

            Text(isSearchEmpty ? "无匹配结果" : "暂无剪贴板历史")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ColorTheme.textSecondary)

            Text(isSearchEmpty ? "尝试其他关键词" : "复制文字或图片即可开始")
                .font(.system(size: 11))
                .foregroundColor(ColorTheme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
