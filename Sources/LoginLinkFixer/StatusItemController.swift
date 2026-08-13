import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let showFixer: () -> Void
    private let fixClipboard: () -> Void
    private let quit: () -> Void

    init(showFixer: @escaping () -> Void, fixClipboard: @escaping () -> Void, quit: @escaping () -> Void) {
        self.showFixer = showFixer
        self.fixClipboard = fixClipboard
        self.quit = quit
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: "Login Link Fixer")
            button.target = self
            button.action = #selector(statusItemPressed)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Login Link Fixer (⌥⌘L)"
        }
    }

    @objc private func statusItemPressed() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Show Link Fixer", action: #selector(show), keyEquivalent: "")
            menu.addItem(withTitle: "Fix Clipboard & Open", action: #selector(fix), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit Login Link Fixer", action: #selector(quitApp), keyEquivalent: "q")
            menu.items.forEach { $0.target = self }
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            showFixer()
        }
    }

    @objc private func show() { showFixer() }
    @objc private func fix() { fixClipboard() }
    @objc private func quitApp() { quit() }
}
