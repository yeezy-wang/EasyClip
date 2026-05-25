# EasyClip — 技术规范

## 产品概述

EasyClip 是一款 macOS 菜单栏剪贴板历史管理工具。自动记录文字和图片复制内容，支持搜索、置顶、保留策略、Quick Look 预览和回写粘贴。

## 技术栈

| 层 | 选型 | 说明 |
|---|------|------|
| 语言 | Swift 5.1+ | 兼容 Xcode 11+，实际使用 Swift 6.3 |
| UI | SwiftUI 1.0 + AppKit 桥接 | macOS 10.15 兼容 |
| 菜单栏 | AppKit NSStatusBar + NSPopover(.transient) | 左键弹出面板，右键弹出菜单 |
| 持久化 | Core Data (SQLite) | 图片启用 Allow External Storage |
| 响应式 | Combine (Timer.publish) | 0.5s 轮询剪贴板 |
| 图片处理 | AppKit NSImage + NSBitmapImageRep | PNG 无损缩略图 |
| 开机启动 | LaunchAgent (~/Library/LaunchAgents) | launchctl load/unload |
| Quick Look | Quartz QLPreviewPanel | 空格键 / 点击预览图标 |
| 最低系统 | macOS 10.15 (Catalina) | 实际运行于 macOS 26+ |

## 项目结构

```
Clipboard/
├── main.swift                              # NSApplicationMain 入口
├── AppDelegate.swift                       # 菜单栏 + 弹出面板 + 设置窗口
├── Info.plist                              # LSUIElement=YES (隐藏 Dock 图标)
├── ClipboardDataModel.xcdatamodeld/        # Core Data 模型
├── Models/
│   ├── ContentType.swift                   # 枚举: text, image
│   ├── ClipboardItem+CoreDataClass.swift   # NSManagedObject 子类
│   └── ClipboardItem+CoreDataProperties.swift
├── Services/
│   ├── PersistenceController.swift         # NSPersistentContainer 单例
│   ├── ClipboardMonitor.swift              # 剪贴板轮询 + 变更检测 + 去重
│   ├── RetentionManager.swift              # 过期自动清理调度
│   └── AutoStartManager.swift              # LaunchAgent 注册/注销
├── ViewModels/
│   └── ClipboardViewModel.swift            # 搜索/复制/置顶/删除/清空/预览
├── Views/
│   ├── ContentView.swift                   # 弹出面板根视图
│   ├── ClipboardCardView.swift             # 文字/图片卡片 (两种布局)
│   ├── SearchBarView.swift                 # 搜索框
│   ├── EmptyStateView.swift                # 空状态 / 无匹配结果
│   ├── FooterView.swift                    # 记录计数 + 内联确认清空
│   └── Settings/
│       └── SettingsView.swift              # 保留天数/开机启动/清空/退出
├── Helpers/
│   ├── ColorTheme.swift                    # 动态色 (NSColor 适配深色模式)
│   ├── DateFormatter+Relative.swift        # 相对时间 + 绝对时间 (zh_CN)
│   ├── ImageResizer.swift                  # NSImage 高清缩略图生成
│   └── SystemIcon.swift                    # Unicode 字符图标集
├── Assets.xcassets/                        # 应用图标资源
├── menubar_icon.png                        # 菜单栏图标 (21px 模板图)
└── AppIcon.icns                            # 应用图标
```

## 架构

### 组件树

```
NSApplication
 └── AppDelegate (NSApplicationDelegate, NSPopoverDelegate, QLPreviewPanelDataSource)
      ├── statusItem: NSStatusItem          ← 菜单栏图标 (左键弹出/右键菜单)
      ├── popover: NSPopover(.transient)    ← 弹出面板 (340×620px)
      │    └── NSHostingView<AnyView>
      │         ├── Header ("EasyClip - 管理你的剪贴板历史" + ⚙️)
      │         ├── SearchBarView           ← 仅在有记录时显示
      │         ├── ContentView
      │         │    ├── Pinned Section     ← 置顶分区
      │         │    ├── ClipboardCardView  ← 文字卡片 (HStack) / 图片卡片 (VStack)
      │         │    └── EmptyStateView     ← 空状态 / 无搜索结果
      │         └── FooterView              ← 计数 + 内联确认清空
      ├── settingsWindowController          ← 独立 NSWindow
      │    └── SettingsView
      └── rightClickMenu                    ← 右键菜单 (设置/退出)
```

### 数据流

```
NSPasteboard.general ──(0.5s 轮询 changeCount)──→ ClipboardMonitor
                    │                                    │
                    │                    skipNextPasteboardChange? ──→ 跳过
                    │                    fileURL 类型? ──→ 跳过 (文件复制)
                    │                    string 类型? ──→ 去重检查 → saveTextItem
                    │                    tiff/png 类型? ──→ saveImageItem
                    │                                    │
                    │                              PersistenceController
                    │                              (Core Data → SQLite + 外部 blob)
                    │                                    │
                    │                              @FetchRequest
                    │                                    │
                    │                              ClipboardViewModel
                    │                              (filteredItems, copyItem, togglePin, deleteItem, clearAll)
                    │                                    │
                    ▼                              SwiftUI Views (自动更新)
```

### 图片处理管线

```
原始图片 (TIFF/PNG) ──→ 存入 Core Data (原字节, Allow External Storage)
                 └──→ NSImage.resize(480px max, .high 插值) → PNG 无损缩略图
                                                                     │
                                                              ClipboardCardView
                                                              (160px 高度, .fit 模式)
```

## Core Data 模型

**实体: ClipboardItem**

| 属性 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| timestamp | Date | 是 | 捕获时间，排序依据 |
| contentType | String | 是 | "text" / "image" |
| textContent | String? | 否 | 原始文字，支持 CONTAINS 搜索 |
| imageData | Binary | 否 | 原始图片字节，Allow External Storage |
| thumbnailData | Binary | 否 | 480px PNG 缩略图，Allow External Storage |
| sourceApp | String? | 否 | 来源应用名 (NSWorkspace.frontmostApplication) |
| isPinned | Boolean | 是 | 默认 false |

**索引:** timestamp, isPinned, textContent

**排序:** isPinned DESC, timestamp DESC

## 关键机制

### 剪贴板监听 (ClipboardMonitor)

```swift
// 0.5s 轮询，检测 changeCount 变化
Timer.publish(every: 0.5, on: .main, in: .common)
    .autoconnect()
    .sink { checkForChanges() }

// 检测顺序
1. pasteboard.types 包含 .fileURL → 跳过 (文件复制)
2. pasteboard.string(forType: .string) → 去重检查 → saveTextItem
3. pasteboard.data(forType: .tiff) → saveImageItem
4. pasteboard.data(forType: .png) → saveImageItem

// 去重: 与最新条目 textContent 完全相同则跳过
// 自身复制跳过: 设置了 skipNextPasteboardChange 标志
```

### 图片缩略图 (ImageResizer)

```swift
// NSImage + NSBitmapImageRep, PNG 无损
NSImage(size: newSize).lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
source.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
bitmap.representation(using: .png, properties: [:])
```

### 保留清理 (RetentionManager)

```swift
// 启动时 + 每小时执行
let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())
// 条件: isPinned == false AND timestamp < cutoffDate
// retentionDays 默认 1 天，可选 1/3/5
```

### 全部清除

```swift
// 删除 isPinned == false 的所有条目
// 内联确认 (无模态弹窗) → 不破坏 popover 事件链
```

### 开机启动 (AutoStartManager)

```swift
// LaunchAgent plist → ~/Library/LaunchAgents/com.easyclip.launcher.plist
// launchctl load → 启用
// launchctl unload + 删除 plist → 禁用
// Key: RunAtLoad = true
```

### 菜单栏交互

```swift
// 左键点击 → toggle popover
// 右键点击 → popUpMenu (设置/退出)
// button.sendAction(on: [.leftMouseDown, .rightMouseDown])
```

### Quick Look 预览

```swift
// QLPreviewPanelDataSource (AppDelegate)
// 触发: 空格键 (keyCode 49) 或点击 👀 按钮
// 图片写入临时文件 → QLPreviewPanel 预览
```

### 弹窗行为

```swift
// NSPopover(.transient) + NSHostingView
// 点击外部自动关闭 (transient behavior)
// popoverDidShow → makeKey() + 搜索框不自动聚焦
// popoverDidClose → 清空搜索文本
```

## 10.15 兼容性适配

| 不可用 API | 替代方案 |
|-----------|---------|
| `@main` / `App` 协议 (11+) | `main.swift` + `NSApplicationDelegate` |
| `Image(systemName:)` (11+) | `SystemIcon` View (Unicode 字符) |
| `NSImage(systemSymbolName:)` (11+) | `SystemIcon` View (Unicode 字符) |
| `@AppStorage` (11+) | `UserDefaults.standard` + `@State` + Binding |
| `onChange(of:)` (11+) | Button action 直接处理 |
| `@StateObject` (11+) | `@ObservedObject` |
| `LazyVStack` (11+) | `VStack` |
| `UTType` (11+) | `kUTTypeJPEG` (CoreServices) |
| `SMAppService` (13+) | LaunchAgent plist + launchctl |
| `Settings` scene (11+) | 独立 NSWindow + NSHostingController |
| `animation(_:value:)` (11+) | `animation(_:)` (所有属性) |
| `ScrollViewReader` (11+) | AppKit NSScrollView 手动滚动 |
