import AppKit
import LoginLinkFixerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: QuickFixWindowController?
    private var aboutController: AboutWindowController?
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var isConfirmingClipboardLink = false
    private let launchAtLoginController = LaunchAtLoginController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panelController = QuickFixWindowController()
        panelController.onOpen = { url in
            NSWorkspace.shared.open(url)
        }

        self.panelController = panelController
        let aboutController = AboutWindowController()
        self.aboutController = aboutController
        statusItemController = StatusItemController(
            quickFix: { [weak self] in self?.handleQuickFix(confirmBeforeOpening: false) },
            showFixer: { [weak self] in self?.showFixer() },
            fixClipboard: { [weak self] in self?.fixClipboardAndOpen() },
            launchAtLoginState: { [weak self] in self?.launchAtLoginController.state ?? .disabled },
            toggleLaunchAtLogin: { [weak self] in self?.toggleLaunchAtLogin() },
            showAbout: { [weak self] in self?.aboutController?.present() },
            quit: { NSApp.terminate(nil) }
        )
        hotkeyManager = HotkeyManager { [weak self] in
            self?.handleQuickFix()
        }
        hotkeyManager?.register()

        if !LaunchAtLoginController.wasLaunchedAsLoginItem {
            handleQuickFix()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            handleQuickFix()
        }
        return true
    }

    private var clipboardText: String? {
        let clipboard = NSPasteboard.general
        return clipboard.string(forType: .string) ?? clipboard.string(forType: .URL)
    }

    private func handleQuickFix(confirmBeforeOpening: Bool = true) {
        guard !isConfirmingClipboardLink else { return }

        let text = clipboardText ?? ""
        guard let url = try? LinkFixer.clean(text), let host = url.host else {
            panelController?.present(text: text)
            return
        }

        guard confirmBeforeOpening else {
            openClipboardLink(url, text: text)
            return
        }

        isConfirmingClipboardLink = true
        defer { isConfirmingClipboardLink = false }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Open Clipboard Link?"
        alert.informativeText = "Open \(host) in your default browser?"
        alert.addButton(withTitle: "Open Link")
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openClipboardLink(url, text: text)
        }
    }

    private func showFixer() {
        panelController?.present(text: clipboardText ?? "")
    }

    private func fixClipboardAndOpen() {
        guard let text = clipboardText else {
            panelController?.present(error: "The clipboard doesn’t contain text.")
            return
        }

        do {
            openClipboardLink(try LinkFixer.clean(text), text: text)
        } catch {
            panelController?.present(text: text, error: error.localizedDescription)
        }
    }

    private func openClipboardLink(_ url: URL, text: String) {
        if !NSWorkspace.shared.open(url) {
            panelController?.present(text: text, error: "Couldn’t open the link in your browser.")
        }
    }

    private func toggleLaunchAtLogin() {
        do {
            try launchAtLoginController.toggle()
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Couldn’t Update Login Item"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "Open Login Item Settings")
            alert.addButton(withTitle: "Cancel")

            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                launchAtLoginController.openSystemSettings()
            }
        }
    }
}
