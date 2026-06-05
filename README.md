<h1 align="center">
  <img src="Clipboard/EasyClip_logo.png" width="80" alt="EasyClip" /><br>
  EasyClip
</h1>

<p align="center">
  <strong>macOS 菜单栏剪贴板历史管理工具</strong>
</p>

<p align="center">
  自动记录 · 搜索回溯 · 一键回写 · 本地安全
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2010.15%2B-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.1%2B-orange" alt="Swift">
  <img src="https://img.shields.io/badge/arch-arm64%20%7C%20x86__64-blue" alt="Arch">
</p>

<p align="center">
  🌐 <a href="README.md">中文</a> · <a href="README.en.md">English</a>
</p>

---

## 这是什么

**EasyClip** 是一款轻量级 macOS 剪贴板历史管理工具，常驻菜单栏，自动记录你复制的所有文字和图片。

macOS 系统剪贴板只能记住最后一次复制的内容。复制了新东西，旧的就被覆盖了。EasyClip 自动保存你复制过的每一条文字和图片，需要时一键找回。

**纯本地运行，不联网，不上传任何数据。**

## 功能一览

| 功能 | 说明 |
|------|------|
| 🔄 **自动记录** | 实时监听剪贴板，文字和图片自动入库，无需手动操作 |
| 📋 **卡片展示** | 文字卡片预览 3 行，图片卡片 160px 缩略图，按时间倒序排列 |
| 📌 **置顶** | 重要内容一键置顶，始终在最前面，不受过期清理影响 |
| 🔍 **搜索** | 输入关键词实时过滤文字记录，快速找到历史内容 |
| 👆 **回写粘贴** | 点击卡片即写回剪贴板，直接 Cmd+V 粘贴 |
| 🖼️ **图片预览** | hover 图片按空格键，调用原生 Quick Look 预览原图 |
| ⏱️ **保留策略** | 默认保留 1 天，可选 1/3/5 天，过期自动清理 |
| 🗑️ **删除清空** | 单条删除 + 一键清空（自动保护置顶内容） |
| 🚀 **开机启动** | 设置中一键开启，重启自动运行 |
| 🌓 **深色模式** | 自动跟随系统切换 |
| 🍎 **兼容性** | 最低支持 macOS 10.15 Catalina，Intel + Apple Silicon 通用 |

## 安装

### 直接下载

从 [Releases](../../releases) 页面下载最新版 `EasyClip.app`，拖入 `/Applications` 即可。

### 从源码构建

```bash
# 1. 确保已安装 Xcode（App Store 下载）
# 2. 切换 Xcode 目录
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. 构建 Debug 版本
xcodebuild -project Clipboard.xcodeproj -scheme EasyClip -configuration Debug

# 4. 运行
open ~/Library/Developer/Xcode/DerivedData/Clipboard-*/Build/Products/Debug/EasyClip.app
```

构建 Release 双架构版本：

```bash
xcodebuild -project Clipboard.xcodeproj \
  -scheme EasyClip \
  -configuration Release \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO
```

## 使用方式

1. 启动后，菜单栏会出现 EasyClip 图标
2. **左键点击** 图标 → 打开剪贴板历史面板
3. **右键点击** 图标 → 设置 / 退出
4. 点击任一卡片 → 内容写回剪贴板 → 直接粘贴
5. hover 卡片 → 显示置顶 ⬆️、删除 🗑️ 按钮
6. hover 图片 → 显示预览 👀 按钮，或按空格键

## 技术栈

| 层 | 技术 |
|---|------|
| 语言 | Swift 5.1+ |
| UI | SwiftUI 1.0 + AppKit (NSPopover) |
| 数据 | Core Data (SQLite + External Storage) |
| 剪贴板 | NSPasteboard, 0.5s 轮询 |
| 图片 | NSImage + NSBitmapImageRep (PNG 无损) |
| 启动 | LaunchAgent (launchctl) |
| 预览 | Quartz QLPreviewPanel |

## 为什么兼容 10.15

SwiftUI 的新 API（`@main`、`Image(systemName:)`、`@AppStorage`、`MenuBarExtra` 等）大多需要 macOS 11+。为了让还在用 Catalina 的老 Mac 也能用，EasyClip 全部使用了 10.15 兼容的替代方案：

- `NSApplicationDelegate` 代替 `@main`
- Unicode 字符图标代替 SF Symbols
- `NSStatusBar` + `NSPopover` 代替 `MenuBarExtra`
- `LaunchAgent` 代替 `SMAppService`

详见 [技术规范](docs/technical-spec.md)。

## 项目结构

```
├── Clipboard/
│   ├── main.swift                     # 应用入口
│   ├── AppDelegate.swift              # 菜单栏 + 面板 + 设置
│   ├── Models/
│   │   ├── ContentType.swift          # 内容类型枚举
│   │   └── ClipboardItem+CoreData*.swift
│   ├── Services/
│   │   ├── ClipboardMonitor.swift     # 剪贴板监听
│   │   ├── PersistenceController.swift # 数据持久化
│   │   ├── RetentionManager.swift     # 过期清理
│   │   └── AutoStartManager.swift     # 开机启动
│   ├── ViewModels/
│   │   └── ClipboardViewModel.swift   # 业务逻辑
│   ├── Views/
│   │   ├── ContentView.swift          # 主面板
│   │   ├── ClipboardCardView.swift    # 文字/图片卡片
│   │   ├── SearchBarView.swift        # 搜索框
│   │   ├── EmptyStateView.swift       # 空状态
│   │   ├── FooterView.swift           # 底部操作栏
│   │   └── Settings/SettingsView.swift # 设置窗口
│   └── Helpers/
│       ├── ColorTheme.swift           # 动态色（深色模式）
│       ├── SystemIcon.swift           # Unicode 图标
│       ├── ImageResizer.swift         # 缩略图生成
│       └── DateFormatter+Relative.swift
├── docs/
│   ├── requirements.md                # 需求文档
│   ├── technical-spec.md              # 技术规范
│   ├── design-spec.md                 # 设计规范
│   ├── execution-steps.md             # 开发清单
│   └── prd.md                         # 产品需求文档
└── devlog/                            # 开发日志
```

## 相关文档

- [需求文档](docs/requirements.md) — 功能与非功能需求
- [产品需求文档 PRD](docs/prd.md) — 用户故事 + 验收标准
- [技术规范](docs/technical-spec.md) — 架构、数据模型、关键机制
- [设计规范](docs/design-spec.md) — 色彩、字体、间距、组件
- [开发清单](docs/execution-steps.md) — 分阶段完成情况

## 常见问题

**Q: 为什么复制文件不会记录？**
这是刻意设计的。文件复制在剪贴板中存储的是文件路径字符串，记录这些没有实际意义，且容易产生大量噪音。

**Q: 为什么从 EasyClip 复制内容不会重复记录？**
内部通过 `skipNextPasteboardChange` 标志跳过自身回写引起的剪贴板变更。

**Q: 数据存在哪里？**
数据仅存储在本地 Core Data（SQLite + 外部图片文件），不会上传到任何服务器。

**Q: 支持 iCloud 同步吗？**
v1.0 不支持。未来版本会考虑。

## 许可

MIT License

---

<p align="center">
  <sub>Built with ❤️ on macOS</sub>
</p>
