import SwiftUI

struct FooterView: View {
    let totalCount: Int
    let unpinnedCount: Int
    let onClearAll: () -> Void

    @State private var confirming = false

    var body: some View {
        HStack {
            if confirming {
                Text("确认清除？")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.danger)

                Spacer()

                Button("确定") {
                    confirming = false
                    onClearAll()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorTheme.danger)
                .padding(.horizontal, 4)

                Button("取消") {
                    confirming = false
                }
                .font(.system(size: 12))
                .foregroundColor(ColorTheme.textSecondary)
                .padding(.horizontal, 4)
            } else {
                Text("\(totalCount) 条记录")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.textSecondary)

                Spacer()

                if unpinnedCount > 0 {
                    Button("清除数据（不含已置顶内容）") {
                        confirming = true
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.danger)
                }
            }
        }
        .padding(.horizontal, 2)
        .frame(height: 32)
    }
}
