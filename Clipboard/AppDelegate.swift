import AppKit
import SwiftUI
import Quartz

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, QLPreviewPanelDataSource {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindowController: NSWindowController?
    private var rightClickMenu: NSMenu!
    private var previewURL: URL?
    private let persistenceController = PersistenceController.shared
    private let clipboardMonitor: ClipboardMonitor
    private let retentionManager: RetentionManager
    private lazy var clipboardViewModel = ClipboardViewModel(
        context: persistenceController.viewContext,
        monitor: clipboardMonitor
    )

    override init() {
        clipboardMonitor = ClipboardMonitor(context: persistenceController.viewContext)
        retentionManager = RetentionManager(context: persistenceController.viewContext)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = menuBarIcon()
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }

        rightClickMenu = NSMenu()
        rightClickMenu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ","))
        rightClickMenu.addItem(NSMenuItem.separator())
        rightClickMenu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        rightClickMenu.delegate = self

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 620)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = createHostingController()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            return self?.handleKeyEvent(event)
        }

        clipboardViewModel.onClearCompleted = { [weak self] in
            guard let self = self, self.popover.isShown else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard self.popover.isShown else { return }
                self.popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            }
        }

        clipboardMonitor.start()
        retentionManager.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        retentionManager.stop()
        persistenceController.save()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        clipboardMonitor.stop()
        return .terminateNow
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard event.keyCode == 49 else { return event }
        guard popover.isShown else { return event }
        guard let imageItem = clipboardViewModel.hoveredImageItem,
              let data = imageItem.imageData else { return event }

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("clipboard_preview_\(UUID().uuidString).png")
        try? data.write(to: tmp)
        previewURL = tmp

        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = self
            panel.makeKeyAndOrderFront(nil)
        }
        return nil
    }

    // MARK: QLPreviewPanelDataSource
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL != nil ? 1 : 0
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        previewURL as QLPreviewItem?
    }

    func popoverDidShow(_ notification: Notification) {
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        clipboardViewModel.searchQuery = ""
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem.button else { return }

        if let event = NSApp.currentEvent, event.type == .rightMouseDown {
            statusItem.popUpMenu(rightClickMenu)
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    @objc func openSettings() {
        if popover.isShown {
            popover.performClose(nil)
        }

        let context = persistenceController.viewContext
        let settingsView = SettingsView()
            .environment(\.managedObjectContext, context)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "EasyClip - 设置"
        window.setContentSize(NSSize(width: 300, height: 300))
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)

        settingsWindowController = NSWindowController(window: window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        clipboardMonitor.stop()
        retentionManager.stop()
        persistenceController.save()
        NSApplication.shared.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func createHostingController() -> NSHostingController<AnyView> {
        let context = persistenceController.viewContext

        let rootView = ContentView(
            viewModel: clipboardViewModel,
            onSettings: { [weak self] in
                self?.openSettings()
            }
        )
        .environment(\.managedObjectContext, context)
        .environmentObject(clipboardMonitor)

        return NSHostingController(rootView: AnyView(rootView))
    }

    private func menuBarIcon() -> NSImage {
        guard let raw = Bundle.main.image(forResource: "menubar_icon") ?? NSImage(contentsOfFile: Bundle.main.path(forResource: "menubar_icon", ofType: "png") ?? "") else {
            return defaultMenuBarIcon()
        }
        let size = NSSize(width: 21, height: 21)
        let image = NSImage(size: size)
        image.isTemplate = true
        image.lockFocus()
        raw.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        image.unlockFocus()
        return image
    }

    private func defaultMenuBarIcon() -> NSImage {
        let size = NSSize(width: 21, height: 21)
        let image = NSImage(size: size)
        image.isTemplate = true
        image.lockFocus()
        let lineWidth: CGFloat = 1.4
        let inset = lineWidth / 2 + 1
        let boardRect = CGRect(x: inset, y: inset + 2, width: size.width - inset * 2, height: size.height - inset * 2 - 2)
        let clipRect = CGRect(x: size.width / 2 - 4, y: 1, width: 8, height: 3)
        let path = NSBezierPath(); path.lineWidth = lineWidth; path.lineJoinStyle = .round; path.lineCapStyle = .round
        path.move(to: NSPoint(x: clipRect.minX, y: clipRect.maxY))
        path.line(to: NSPoint(x: clipRect.minX, y: clipRect.minY))
        path.line(to: NSPoint(x: clipRect.maxX, y: clipRect.minY))
        path.line(to: NSPoint(x: clipRect.maxX, y: clipRect.maxY))
        path.move(to: NSPoint(x: boardRect.minX, y: boardRect.maxY))
        path.line(to: NSPoint(x: boardRect.minX, y: boardRect.minY + 2))
        path.appendArc(from: NSPoint(x: boardRect.minX, y: boardRect.minY + 2), to: NSPoint(x: boardRect.minX + 2, y: boardRect.minY), radius: 2)
        path.line(to: NSPoint(x: boardRect.maxX - 2, y: boardRect.minY))
        path.appendArc(from: NSPoint(x: boardRect.maxX - 2, y: boardRect.minY), to: NSPoint(x: boardRect.maxX, y: boardRect.minY + 2), radius: 2)
        path.line(to: NSPoint(x: boardRect.maxX, y: boardRect.maxY))
        path.close()
        path.stroke()
        image.unlockFocus()
        return image
    }
}
