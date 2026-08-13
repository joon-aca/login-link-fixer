import AppKit
import LoginLinkFixerCore

@MainActor
final class QuickFixWindowController: NSWindowController, NSTextFieldDelegate {
    var onOpen: ((URL) -> Void)?

    private let inputField = DropTextField(string: "")
    private let hintLabel = NSTextField(labelWithString: "Return to fix & open  ·  Esc to close  ·  ⌥⌘L from anywhere")
    private let errorLabel = NSTextField(labelWithString: "")

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 92),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        super.init(window: panel)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(text: String? = nil, error: String? = nil) {
        if let text {
            inputField.stringValue = text
        } else if let clipboard = NSPasteboard.general.string(forType: .string),
                  LinkFixer.canClean(clipboard) {
            inputField.stringValue = clipboard
        } else {
            inputField.stringValue = ""
        }

        showError(error)
        positionNearTopOfScreen()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(inputField)
        inputField.currentEditor()?.selectedRange = NSRange(location: inputField.stringValue.count, length: 0)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            submit()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            close()
            return true
        }
        return false
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let vibrancy = NSVisualEffectView()
        vibrancy.translatesAutoresizingMaskIntoConstraints = false
        vibrancy.material = .hudWindow
        vibrancy.state = .active
        vibrancy.blendingMode = .behindWindow
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = 14
        vibrancy.layer?.masksToBounds = true
        contentView.addSubview(vibrancy)

        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: "Fix link")
        icon.contentTintColor = .tertiaryLabelColor

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.placeholderString = "Paste or drop the broken Claude login link…"
        inputField.setAccessibilityLabel("Broken login link")
        inputField.font = .systemFont(ofSize: 20, weight: .light)
        inputField.isBordered = false
        inputField.drawsBackground = false
        inputField.focusRingType = .none
        inputField.lineBreakMode = .byTruncatingMiddle
        inputField.delegate = self
        inputField.onDrop = { [weak self] text in
            self?.inputField.stringValue = text
            self?.showError(nil)
        }

        let openButton = NSButton(title: "Open ↗", target: self, action: #selector(openButtonPressed))
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"
        openButton.toolTip = "Fix the link and open it in your default browser"

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.lineBreakMode = .byTruncatingTail

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = .systemRed
        errorLabel.lineBreakMode = .byTruncatingTail
        errorLabel.isHidden = true

        let inputRow = NSStackView(views: [icon, inputField, openButton])
        inputRow.translatesAutoresizingMaskIntoConstraints = false
        inputRow.orientation = .horizontal
        inputRow.spacing = 11
        inputRow.alignment = .centerY
        inputRow.edgeInsets = NSEdgeInsets(top: 0, left: 16, bottom: 0, right: 14)

        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator

        let stack = NSStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.spacing = 0
        stack.addArrangedSubview(inputRow)
        stack.addArrangedSubview(separator)
        stack.addArrangedSubview(hintLabel)
        stack.addArrangedSubview(errorLabel)
        stack.setCustomSpacing(7, after: separator)
        stack.setCustomSpacing(3, after: hintLabel)
        vibrancy.addSubview(stack)

        NSLayoutConstraint.activate([
            vibrancy.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            vibrancy.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            vibrancy.topAnchor.constraint(equalTo: contentView.topAnchor),
            vibrancy.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            icon.widthAnchor.constraint(equalToConstant: 25),
            icon.heightAnchor.constraint(equalToConstant: 25),
            inputRow.heightAnchor.constraint(equalToConstant: 52),
            openButton.widthAnchor.constraint(equalToConstant: 78),
            stack.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor),
            stack.topAnchor.constraint(equalTo: vibrancy.topAnchor),
            stack.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor, constant: -8),
            hintLabel.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor, constant: -16),
            errorLabel.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor, constant: -16),
        ])
    }

    @objc private func openButtonPressed() { submit() }

    private func submit() {
        do {
            let url = try LinkFixer.clean(inputField.stringValue)
            onOpen?(url)
            close()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String?) {
        errorLabel.stringValue = message ?? ""
        errorLabel.isHidden = message == nil
        resizePanel(showingError: message != nil)
    }

    private func positionNearTopOfScreen() {
        guard let panel = window, let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.maxY - frame.height * 0.27))
    }

    private func resizePanel(showingError: Bool) {
        guard let panel = window else { return }
        let height: CGFloat = showingError ? 114 : 92
        var frame = panel.frame
        let delta = height - frame.height
        frame.size.height = height
        frame.origin.y -= delta
        panel.setFrame(frame, display: true, animate: panel.isVisible)
    }
}

@MainActor
private final class DropTextField: NSTextField {
    var onDrop: ((String) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.string, .URL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.string, .URL])
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        droppedText(from: sender.draggingPasteboard) == nil ? [] : .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let text = droppedText(from: sender.draggingPasteboard) else { return false }
        onDrop?(text)
        return true
    }

    private func droppedText(from pasteboard: NSPasteboard) -> String? {
        pasteboard.string(forType: .string) ?? pasteboard.string(forType: .URL)
    }
}
