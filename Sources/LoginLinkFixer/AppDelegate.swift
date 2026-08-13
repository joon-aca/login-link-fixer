import AppKit
import LoginLinkFixerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: QuickFixWindowController?
    private var aboutController: AboutWindowController?
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panelController = QuickFixWindowController()
        panelController.onOpen = { url in
            NSWorkspace.shared.open(url)
        }

        self.panelController = panelController
        let aboutController = AboutWindowController()
        self.aboutController = aboutController
        statusItemController = StatusItemController(
            showFixer: { [weak self] in self?.panelController?.present() },
            fixClipboard: { [weak self] in self?.fixClipboardAndOpen() },
            showAbout: { [weak self] in self?.aboutController?.present() },
            quit: { NSApp.terminate(nil) }
        )
        hotkeyManager = HotkeyManager { [weak self] in
            self?.panelController?.present()
        }
        hotkeyManager?.register()

        panelController.present()
    }

    private func fixClipboardAndOpen() {
        guard let text = NSPasteboard.general.string(forType: .string) else {
            panelController?.present(error: "The clipboard doesn’t contain text.")
            return
        }

        do {
            NSWorkspace.shared.open(try LinkFixer.clean(text))
        } catch {
            panelController?.present(text: text, error: error.localizedDescription)
        }
    }
}
