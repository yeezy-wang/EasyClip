# EasyClip — macOS 剪贴板历史管理器

macOS 原生菜单栏剪贴板历史管理工具。自动记录文字和图片复制内容，支持搜索、置顶、保留策略、Quick Look 预览和重新粘贴。

## 产品名

EasyClip（原剪贴板历史管理器 Clipboard History Manager）

## 技术栈

- Swift 5.1+ / SwiftUI 1.0 + AppKit 桥接 / Core Data / Combine
- 最低 macOS 10.15 (Catalina)
- 开发工具：Xcode 11+
- 实际构建: Swift 6.3 / Xcode 26.5 / macOS 26+

## 项目规范文件

| 文件 | 路径 | 说明 |
|------|------|------|
| 需求文档 | [docs/requirements.md](docs/requirements.md) | 用户语言的功能和非功能需求 |
| 技术规范 | [docs/technical-spec.md](docs/technical-spec.md) | 架构、数据模型、关键机制、兼容适配 |
| 设计规范 | [docs/design-spec.md](docs/design-spec.md) | 色彩、字体、间距、组件规格 |
| 执行步骤 | [docs/execution-steps.md](docs/execution-steps.md) | 分阶段开发完成清单 |
| 开发日志 | [devlog/](devlog/) | 每日开发记录（按日期命名：YYYY-MM-DD.md） |

## 工作约定

### 开发流程
1. 严格按照 `docs/execution-steps.md` 的 Phase 顺序推进，不跳阶段
2. 每个 Phase 完成后先跑验证，通过后再进入下一 Phase
3. 遇到模糊需求先确认，不自行扩大范围

### 代码规范
- 文件名使用英文 PascalCase
- SwiftUI View 文件名与结构体名一致
- 所有业务逻辑放在 ViewModel/Service 层，View 只做展示
- Core Data 操作通过 PersistenceController 统一管理
- 颜色/字体/间距使用 ColorTheme / Design Spec 中的常量，不硬编码

### 开发日志
- 每天工作结束时在 `devlog/` 创建 `YYYY-MM-DD.md`
- 记录：完成事项、待办事项、遇到的问题、决策记录

### 验证要求
- 每阶段至少一次手动功能验证
- Phase 2+ 需要单元测试覆盖核心逻辑
- 改完代码后构建确认（`xcodebuild` 或 Xcode Cmd+R）

## 构建与运行

```bash
# 前置条件：安装 Xcode（Mac App Store）
# 切换到 Xcode developer directory
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 构建 Debug 版本
cd clipboard
xcodebuild -project Clipboard.xcodeproj -scheme EasyClip -configuration Debug

# 构建 Release 双架构版本
xcodebuild -project Clipboard.xcodeproj -scheme EasyClip -configuration Release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO

# 运行
open ~/Library/Developer/Xcode/DerivedData/Clipboard-*/Build/Products/Debug/EasyClip.app
```

## 项目结构

```
clipboard/
├── CLAUDE.md                              # 项目 AI 助手指南
├── docs/                                  # 项目规范文档
│   ├── requirements.md
│   ├── technical-spec.md
│   ├── design-spec.md
│   └── execution-steps.md
├── devlog/                                # 每日开发日志
├── .gitignore
├── project.yml                            # XcodeGen 配置 (备用)
├── generate_xcodeproj.py                  # pbxproj 生成脚本
├── Clipboard.xcodeproj/                   # Xcode 项目文件
├── Clipboard/                             # 主应用代码
│   ├── main.swift                         # NSApplicationMain 入口
│   ├── AppDelegate.swift                  # 菜单栏 + 弹出面板 + 设置窗口
│   ├── Info.plist                         # LSUIElement=YES
│   ├── menubar_icon.png                   # 菜单栏图标 (21px 模板图)
│   ├── AppIcon.icns                       # 应用图标
│   ├── ClipboardDataModel.xcdatamodeld/   # Core Data 模型
│   ├── Models/
│   │   ├── ContentType.swift
│   │   └── ClipboardItem+CoreData*.swift
│   ├── Services/
│   │   ├── PersistenceController.swift
│   │   ├── ClipboardMonitor.swift
│   │   ├── RetentionManager.swift
│   │   └── AutoStartManager.swift
│   ├── ViewModels/
│   │   └── ClipboardViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── ClipboardCardView.swift
│   │   ├── SearchBarView.swift
│   │   ├── EmptyStateView.swift
│   │   ├── FooterView.swift
│   │   └── Settings/SettingsView.swift
│   └── Helpers/
│       ├── ColorTheme.swift
│       ├── DateFormatter+Relative.swift
│       ├── ImageResizer.swift
│       └── SystemIcon.swift
└── ClipboardTests/                        # 单元测试
```

## 架构要点

- **菜单栏桥接**：使用 AppKit NSStatusBar + NSPopover(.transient)，不用 SwiftUI 的 MenuBarExtra
- **左右键分离**：左键弹出面板，右键弹出菜单（`sendAction(on: [.leftMouseDown, .rightMouseDown])`）
- **剪贴板监听**：0.5s 轮询 NSPasteboard.general.changeCount，无 push 事件可用
- **图片原图**：TIFF/PNG 原字节存入 Core Data（Allow External Storage），回写时不转换
- **图片缩略图**：NSImage + PNG 无损，480px 生成，160px 显示
- **置顶保护**：全部清除和过期清理均不删除 isPinned = true 的条目
- **文件过滤**：检测 pasteboard.types 包含 .fileURL 时跳过
- **自身复制过滤**：skipNextPasteboardChange 标志防止重新记录
- **清空确认**：内联确认按钮代替模态弹窗，不破坏 NSPopover 事件链
- **开机启动**：LaunchAgent plist (~/Library/LaunchAgents) + launchctl load/unload
- **深色模式**：所有背景/文字色使用 NSColor 动态色
- **10.15 兼容**：使用 main.swift + AppDelegate, Unicode 图标, UserDefaults 代替 @AppStorage
