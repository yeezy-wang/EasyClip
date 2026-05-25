# EasyClip — 开发执行清单

## Phase 1: 项目骨架

- [x] 创建 Xcode 项目 (macOS App, SwiftUI)
- [x] 配置 Info.plist: LSUIElement=YES, min macOS 10.15
- [x] 创建目录结构 (Models/Services/ViewModels/Views/Helpers)
- [x] 创建 CLAUDE.md 项目指南
- [x] 创建 docs/ 和 devlog/ 目录
- [x] 创建 .gitignore

## Phase 2: 菜单栏 + 核心服务

- [x] main.swift + AppDelegate: NSStatusBar + NSPopover(.transient)
- [x] 程序化菜单栏图标 → 后续替换为自定义 PNG (menubar_icon.png, 21px)
- [x] 左右键交互 (左键弹出面板, 右键菜单)
- [x] Core Data 模型 (ClipboardItem 实体 + 8 属性含 sourceApp)
- [x] PersistenceController (NSPersistentContainer)
- [x] ClipboardMonitor (0.5s 轮询 NSPasteboard.general.changeCount)
- [x] 文字/图片捕获 (string → tiff → png 检测顺序)
- [x] 文件复制过滤 (.fileURL 类型自动跳过)
- [x] 复制去重 (与最新条目 textContent 相同则跳过)
- [x] 自身复制跳过 (skipNextPasteboardChange 标志)
- [x] 来源应用记录 (NSWorkspace.frontmostApplication)
- [x] ImageResizer (NSImage + PNG 无损缩略图, 480px)
- [x] 相对/绝对时间格式化 (zh_CN locale)

## Phase 3: UI 视图

- [x] ContentView (ScrollView + VStack + 置顶/非置顶分区)
- [x] ClipboardCardView (文字卡片 HStack / 图片卡片 VStack)
- [x] SearchBarView (仅在有记录时显示, 不自动聚焦)
- [x] EmptyStateView (空状态 / 无搜索结果 两种模式)
- [x] FooterView (记录计数 + 内联确认清空, 不破坏 popover 事件链)
- [x] SettingsView (保留天数段选/开机启动/清空数据/关闭应用确认)
- [x] ColorTheme (NSColor 动态色, 深色模式自动适配)
- [x] SystemIcon (Unicode 字符图标集: 🔍📋⚙️⬆️⬇️🗑️👀✕)
- [x] 弹窗尺寸 340×620px

## Phase 4: 功能完善

- [x] 置顶/取消置顶 (⬆️未置顶 / ⬇️已置顶)
- [x] 删除单条 (🗑️, hover 时显示)
- [x] 全部清除 (内联确认 "确认清除？[确定] [取消]", 保护置顶项)
- [x] 搜索实时过滤 (textContent CONTAINS[cd] query)
- [x] 点击卡片回写剪贴板 (文字 setString / 图片 setData 原格式)
- [x] 图片 Quick Look 预览 (QLPreviewPanel + 空格键 + 👀 按钮)
- [x] 保留天数设置 (默认 1 天, 可选 1/3/5)
- [x] 过期自动清理 (启动时 + 每小时, 保护置顶项)
- [x] 开机启动 (LaunchAgent plist + launchctl load/unload)
- [x] 关闭应用 (二次确认弹窗 → 停止监控 → terminate)

## Phase 5: UI 打磨

- [x] 菜单栏图标 (自定义 PNG, 21px, isTemplate 模板图)
- [x] 应用图标 (自定义 PNG → icns, 多尺寸)
- [x] 弹窗展开动画 (popover.animates=true)
- [x] 卡片 hover 动画 (背景色 0.15s easeOut)
- [x] 已复制反馈 (蓝色 "已复制" 标签, 1.2s 自动消失)
- [x] 图片来源显示 ("来自"微信"" + 绝对时间)
- [x] 所有时间格式化为中文 (25.05.16 14:30)
- [x] 深色/浅色模式自动适配 (NSColor 动态色)
- [x] 标题文案 "EasyClip - 管理你的剪贴板历史"
- [x] 设置标题 "EasyClip - 设置"
- [x] "您" → "你" 统一文案

## Phase 6: 打包发布

- [x] Release 构建 (arm64 + x86_64 双架构通用二进制)
- [x] 内嵌资源 (menubar_icon.png, AppIcon.icns)
- [x] 产品命名 EasyClip
- [x] 输出到桌面 EasyClip.app

## 验证清单

- [x] 菜单栏图标可见, 左键弹出/关闭面板
- [x] 右键弹出菜单 (设置/退出)
- [x] 复制文字 → 面板出现卡片 → 点击回写粘贴成功
- [x] 复制图片 → 面板出现图片卡片 → 👀/空格键 Quick Look 预览
- [x] 文件复制不产生记录
- [x] 自身复制不重复记录
- [x] 置顶/取消置顶排序正常
- [x] 删除单条正常
- [x] 全部清除正常 (保护置顶项, 内联确认)
- [x] 搜索实时过滤文字
- [x] 保留天数设置生效
- [x] 开机启动可正常工作
- [x] 关闭应用确认弹窗正常 → 进程退出
- [x] 深色/浅色模式切换 UI 正常
- [x] 点击外部区域关闭弹窗
- [x] Intel + Apple Silicon 均可运行
