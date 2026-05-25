import SwiftUI

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            SystemIcon(name: "magnifyingglass")
                .foregroundColor(ColorTheme.placeholder)
                .font(.system(size: 14))

            TextField("搜索剪贴板（仅支持文本搜索）", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13))
                .foregroundColor(ColorTheme.textPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    SystemIcon(name: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(ColorTheme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(ColorTheme.searchBackground)
        .cornerRadius(8)
    }
}
